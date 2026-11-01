# OKE Infrastructure on OCI with Terraform

Deploys a managed Kubernetes cluster (**OKE**) on Oracle Cloud (OCI) and, on top of it, a sample
web application (nginx) installed with **Helm** and exposed through a public Load Balancer.
Everything is created with a single `terraform apply`.

## Architecture

```
                         Internet
                            │
             ┌──────────────┴───────────────┐
             │                              │
   ┌─────────▼──────────┐         ┌─────────▼──────────┐
   │ api subnet (public) │         │ lb subnet (public)  │
   │ 10.0.0.0/28         │         │ 10.0.20.0/24        │
   │ Kubernetes API      │         │ Load Balancer (80)  │
   └─────────┬──────────┘         └─────────┬──────────┘
             │                              │ NodePorts
   ┌─────────▼──────────────────────────────▼─────────┐
   │ workers subnet (private) 10.0.10.0/24             │
   │ node pool nodes ─► NAT Gateway / Service GW       │
   └───────────────────────────────────────────────────┘
                  VCN 10.0.0.0/16  (prefix: demo-)
```

| Component | Details |
|---|---|
| Network | VCN, Internet Gateway, NAT Gateway, Service Gateway, 2 route tables, 3 regional subnets with security lists |
| Cluster | OKE `BASIC_CLUSTER` (free control plane), Flannel CNI, public endpoint |
| Nodes | Node pool spread across all ADs; configurable shape, OCPUs, memory and count |
| App | Local `hello-app` chart (unprivileged nginx, 2 replicas) + 10 Mbps flexible `LoadBalancer` Service |

## Structure

```
infra/
├── main.tf            # Wires the 3 modules together and writes the kubeconfig file
├── providers.tf       # oci, kubernetes and helm providers
├── variables.tf       # Input variables (with defaults)
├── outputs.tf
├── versions.tf
├── terraform.tfvars   # Credentials and values
└── modules/
    ├── network/       # STEP 1: VCN, gateways, route tables, subnets, security lists
    ├── oke/           # STEP 2: cluster, node pool, kubeconfig
    └── app/           # STEP 3: helm_release + charts/hello-app
```

Data flow between modules: `network` → (VCN and subnet IDs) → `oke` → (kubeconfig) →
`kubernetes`/`helm` providers → `app`.

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [OCI CLI](https://docs.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm) installed and on the `PATH`.
  The `kubernetes` and `helm` providers run it (`oci ce cluster generate-token`) to get the cluster token.
- An OCI API key (`.pem` key pair + fingerprint) for a user with permissions on the compartment, for example:
  ```
  allow group <group> to manage virtual-network-family in compartment <compartment>
  allow group <group> to manage cluster-family        in compartment <compartment>
  allow group <group> to manage instance-family       in compartment <compartment>
  allow group <group> to manage load-balancers        in compartment <compartment>
  ```
- Optional: `kubectl` and `helm` to inspect the cluster.

## Configuration

Create `infra/terraform.tfvars`:

```hcl
# OCI credentials
tenancy_ocid     = "ocid1.tenancy.oc1..xxxx"
user_ocid        = "ocid1.user.oc1..xxxx"
fingerprint      = "aa:bb:cc:..."
private_key_path = "C:/path/to/your-private-key.pem"
region           = "us-ashburn-1"

# Where resources are created
compartment_ocid = "ocid1.compartment.oc1..xxxx"
prefix           = "demo"

# Recommended: restrict the Kubernetes API to your IP
api_allowed_cidr = "203.0.113.10/32"
```

Other optional variables (see [infra/variables.tf](infra/variables.tf)):

| Variable | Default | Description |
|---|---|---|
| `kubernetes_version` | `null` | K8s version (e.g. `v1.31.1`). `null` = latest available |
| `node_shape` | `VM.Standard.E4.Flex` | Use `VM.Standard.A1.Flex` for the Always Free tier (ARM) |
| `node_ocpus` / `node_memory_gbs` | `1` / `8` | Resources per node |
| `node_count` | `2` | Number of nodes |
| `node_boot_volume_gbs` | `50` | Boot volume per node |
| `ssh_public_key` | `null` | SSH public key for the nodes |
| `vcn_cidr`, `*_subnet_cidr` | see diagram | Network ranges |
| `namespace` / `replicas` / `message` | `demo` / `2` / text | App parameters |

## Deployment

```powershell
cd infra
terraform init
terraform plan
terraform apply
```

The first `apply` takes about 15–20 minutes (cluster + nodes + Load Balancer). At the end:

```
app_url         = "http://<public-ip>"
kubeconfig_path = ".../infra/kubeconfig"
```

## Using kubectl

The `infra/kubeconfig` file gets its token through the OCI CLI, which by default uses the
`[DEFAULT]` profile in `~/.oci/config`. If that profile belongs to **another tenancy/user**, the
cluster responds with `the server has asked for the client to provide credentials`. To use the same
credentials as Terraform:

```powershell
$env:OCI_CLI_TENANCY     = "ocid1.tenancy.oc1..xxxx"
$env:OCI_CLI_USER        = "ocid1.user.oc1..xxxx"
$env:OCI_CLI_FINGERPRINT = "aa:bb:cc:..."
$env:OCI_CLI_KEY_FILE    = "C:/path/to/your-private-key.pem"
$env:OCI_CLI_REGION      = "us-ashburn-1"
$env:KUBECONFIG          = "$PWD\kubeconfig"

kubectl get nodes
kubectl get pods,svc -n demo
```

(Terraform already does this internally: see `k8s_exec_env` in [infra/providers.tf](infra/providers.tf).)

## Teardown

```powershell
terraform destroy
```

The Load Balancer is **not created by Terraform** but by Kubernetes (from the `LoadBalancer` Service).
The `app` module depends on `oke`, so it is uninstalled before the cluster is deleted, but if the
cluster goes away before Kubernetes removes the LB, the LB is left **orphaned** in the `lb` subnet
and the destroy fails when deleting the subnet, the VCN and its gateways.

If that happens: delete the LB manually in the console (*Networking → Load Balancers*, the one with
the `app_url` IP) and run `terraform destroy` again.

## Known issues

| Symptom | Cause / fix |
|---|---|
| `the server has asked for the client to provide credentials` | The OCI CLI signs the token with another account. Terraform handles this with `OCI_CLI_*`; for `kubectl` see [Using kubectl](#using-kubectl). |
| Pods in `ImageInspectError`, Helm ends with `context deadline exceeded` | The nodes use CRI-O, which rejects short image names. Use the fully qualified name: `docker.io/...`. |
| `No node image found for ...` | There is no OKE image for that version and shape combination. Change `kubernetes_version` or `node_shape`. |
| `destroy` fails on the `lb` subnet or the VCN | Orphaned Load Balancer, see [Teardown](#teardown). |

## Security

- **Do not commit** `terraform.tfvars`, the `*.pem` keys, `terraform.tfstate*` or `kubeconfig`:
  the state stores the kubeconfig and account data in plain text. The [.gitignore](.gitignore) already excludes them.
- Restrict `api_allowed_cidr` to your IP: by default the Kubernetes API is open to `0.0.0.0/0`.
- For team work, use a remote state backend (for example, OCI Object Storage).
