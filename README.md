# Ampernetacle Plus

This is a Terraform configuration to deploy a Kubernetes cluster on
[Oracle Cloud Infrastructure][oci]. It creates a few virtual machines
and uses [kubeadm] to install a Kubernetes control plane on the first
machine, and join the other machines as worker nodes.

It's a fork from [Original Ampertacle Repository][original-ampertable] and
adds new amazing new features and improvements.

By default, it deploys a 4-node cluster using ARM machines. Each machine
has 1 OCPU and 6 GB of RAM, which means that the cluster fits within
Oracle's (pretty generous if you ask me) [free tier][freetier].

**It is not meant to run production workloads,**
but it's great if you want to learn Kubernetes with a "real" cluster
(i.e. a cluster with multiple nodes) without breaking the bank, *and*
if you want to develop or test applications on ARM.

## Getting started

1. Create an Oracle Cloud Infrastructure account (just follow [this link][createaccount]).
2. Have installed or [install kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl).
3. Have installed or [install terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/oci-get-started).
4. Have installed or [install OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).
5. Have installed ssh/scp or [install Openssh](https://www.openssh.org/).
6. Configure [OCI credentials](https://learn.hashicorp.com/tutorials/terraform/oci-build?in=terraform/oci-get-started).
   If you obtain a session token (with `oci session authenticate`), make sure to put the correct region, and when prompted for the profile name, enter `DEFAULT` so that Terraform finds the session token automatically.
7. Download this project and enter its folder.
8. `terraform init`
9. `terraform apply -parallelism=1`

That's it!

At the end of the `terraform apply`, a `kubeconfig` file is generated
in this directory. To use your new cluster, you can do:

Linux
```bash
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
```

Windows
```powershell
$env:KUBECONFIG="$pwd\kubeconfig"
kubectl get nodes
```

The command above should show you 4 nodes, named `node1` to `node4`.

You can also log into the VMs. At the end of the Terraform output
you should see a command that you can use to SSH into the first VM
(just copy-paste the command).

## Windows

It works with Windows 10/Powershell 7.

It may be necesssary to change the execution policy to unrestricted.

[PowerShell ExecutionPolicy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.6)

## Customization

Check `variables.tf` to see tweakable parameters. You can change the number
of nodes, the size of the nodes, or switch to Intel/AMD instances if you'd
like. Keep in mind that if you switch to Intel/AMD instances, you won't get
advantage of the free tier.

## Stopping the cluster

`terraform destroy`

## Best practices at Cluster

1. Define resources (requests and limits) for all containers ([Manage Resources Container - Official Documentation][manage-resources-containers])
2. Define liveness probe for all containers ([Liveness and Readiness Probes - Official Documentation][liveness-readiness-startup-probes])
3. Define readiness proble for all containers ([Liveness and Readiness Probes - Official Documentation][liveness-readiness-startup-probes])

### Resources, Liveness and Readiness Probe important information:

- Resources
   - `requests`: Necessary resources to start/ready
      - `requests.cpu`: In millicpu. Example "2m".
      - `requests.memory`: Memory Unit. Example "5Mi".
   - `limits`: Limit to restart
      - `limits.cpu`: In millicpu. Example "2m".
      - `limits.memory`: Memory Unit. Example "5Mi".

- Liveness
   - `failureThreshold`: After a probe fails failureThreshold times in a row, Kubernetes considers that the overall check has failed: the container is not ready/healthy/live. Defaults to 3.
   - `initialDelaySeconds`: Number of seconds after the container has started before startup, liveness or readiness probes are initiated.
   - `periodSeconds`: How often (in seconds) to perform the probe. Default to 10 seconds. The minimum value is 1.
   - `successThreshold`:  Minimum consecutive successes for the probe to be considered successful after having failed. Defaults to 1. Must be 1 for liveness and startup Probes. Minimum value is 1.
   - `timeoutSeconds`:  Number of seconds after which the probe times out. Defaults to 1 second. Minimum value is 1.


## Implementation details

This Terraform configuration:

- generates an OpenSSH keypair and a kubeadm token
- deploys 4 VMs using Ubuntu 22.04
- uses cloud-init to install and configure everything
- installs Docker and Kubernetes packages
- runs `kubeadm init` on the first VM
- runs `kubeadm join` on the other VMs
- installs the Weave CNI plugin
- transfers the `kubeconfig` file generated by `kubeadm`
- patches that file to use the public IP address of the machine

## Caveats

This doesn't install the [OCI cloud controller manager][ccm],
which means that you cannot
create services with `type: LoadBalancer`; or rather, if you create
such services, their `EXTERNAL-IP` will remain `<pending>`.

To expose services, use `NodePort`.

Likewise, there is no ingress controller and no storage class.

These might be added in a later iteration of this project.
Meanwhile, if you want to install it manually, you can check
the [OCI cloud controller manager github repository][ccm].

## Remarks

Oracle Cloud also has a managed Kubernetes service called
[Container Engine for Kubernetes (or OKE)][oke]. That service
doesn't have the caveats mentioned above; however, it's not part
of the free tier.

## What does "Ampernetacle" mean?

It's a *porte-manteau* between Ampere, Kubernetes, and Oracle.
It's probably not the best name in the world but it's the one
we have! If you have an idea for a better name let us know. 😊

## Possible errors and how to address them

### Authentication problem

If you configured OCI authentication using a session token
(with `oci session authenticate`), please note that this token
is valid 1 hour by default. If you authenticate, then wait more
than 1 hour, then try to `terraform apply`, you will get
authentication errors.

#### Symptom

The following message:

```
 Error: 401-NotAuthenticated
│ Service: Identity Compartment
│ Error Message: The required information to complete authentication was not provided or was incorrect.
│ OPC request ID: [...]
│ Suggestion: Please retry or contact support for help with service: Identity Compartment
```

#### Solution

Authenticate or re-authenticate, for instance with
`oci session authenticate`.

If prompted for the profile name, make sure to enter `DEFAULT`
so that Terraform automatically uses the session token.

If you previously used `oci session authenticate`, you
should be able to refresh the session with
`oci session refresh --profile DEFAULT`.

### Capacity issue

#### Symptom

If you get a message like the following one:
```
Error: 500-InternalError
│ ...
│ Service: Core Instance
│ Error Message: Out of host capacity.
```

It means that there isn't enough servers available at the moment
on OCI to create the cluster.

#### Solution

One solution is to switch to a different *availability domain*.
This can be done by changing the `availability_domain` input variable. (Thanks @uknbr for the contribution!)

Note 1: some regions have only one availability domain. In that
case you cannot change the availability domain.

Note 2: OCI accounts (especially free accounts) are tied to a
single region, so if you get that problem and cannot change the
availability domain, you can [create another account][createaccount].

### Using the wrong region

#### Symptom

When doing `terraform apply`, you get this message:

```
oci_identity_compartment._: Creating...
╷
│ Error: 404-NotAuthorizedOrNotFound
│ Service: Identity Compartment
│ Error Message: Authorization failed or requested resource not found
│ OPC request ID: [...]
│ Suggestion: Either the resource has been deleted or service Identity Compartment need policy to access this resource. Policy reference: https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm
│
│
│   with oci_identity_compartment._,
│   on main.tf line 1, in resource "oci_identity_compartment" "_":
│    1: resource "oci_identity_compartment" "_" {
│
╵
```

#### Solution

Edit `~/.oci/config` and change the `region=` line to put the correct region.

To know what's the correct region, you can try to log in to
https://cloud.oracle.com/ with your account; after logging in,
you should be redirected to an URL that looks like
https://cloud.oracle.com/?region=us-ashburn-1 and in that
example the region is `us-ashburn-1`.

### Troubleshooting cluster creation

After the VMs are created, you can log into the VMs with the
`ubuntu` user and the SSH key contained in the `id_rsa` file
that was created by Terraform.

Then you can check the cloud init output file, e.g. like this:
```
tail -n 100 -f /var/log/cloud-init-output.log
```

### Troubleshooting ssh powershell

```
# 1. Reset inheritance (remove all inherited permissions)
icacls "id_rsa" /inheritance:r

# 2. Grant explicit Read (R) access only to your current username
icacls "id_rsa" /grant:r "$($env:USERNAME):(R)"
```

### Troubleshooting NLB Creation or Detroying

Error: 409-Conflict, Invalid State Transition of NLB lifeCycle state from Updating to Updating
Try reduce parallelism or run terraform apply or destroy again
```
terraform apply -parallelism=1
terraform destroy -parallelism=1
```
### Useful
```
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

```
terraform apply *>&1 | Tee-Object -FilePath ("apply-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
terraform destroy *>&1 | Tee-Object -FilePath ("apply-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
```

### Force Unlock

```
terraform force-unlock d574b9c2-35b3-203c-5592-8e26bdb24846
```

## Digital Plat

To register a free domain, useful for tests and pocs.

https://domain.digitalplat.org/
https://github.com/DigitalPlatDev/FreeDomain/blob/main/documents/tutorial/getting-started/1.1-register-account.md
https://github.com/DigitalPlatDev/FreeDomain/blob/main/documents/tutorial/getting-started/1.2-dns-hosting.md



[ccm]: https://github.com/oracle/oci-cloud-controller-manager
[createaccount]: https://bit.ly/free-oci-dat-k8s-on-arm
[freetier]: https://www.oracle.com/cloud/free/
[kubeadm]: https://kubernetes.io/docs/reference/setup-tools/kubeadm/
[oci]: https://www.oracle.com/cloud/compute/
[oke]: https://www.oracle.com/cloud-native/container-engine-kubernetes/
[manage-resources-containers]: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
[liveness-readiness-startup-probes]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
[original-ampertable]: https://github.com/jpetazzo/ampernetacle