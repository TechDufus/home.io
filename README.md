# home.io

Collection of automation scripts to deploy and manage my internal home lab environment.

## Ansible

I'm currently using Ansible to deploy some of my servers, including the following:

- Dashy
![image](https://user-images.githubusercontent.com/46715299/172434308-e8682356-f708-4f4d-836a-97a89d64d009.png)

- Portainer
![image](https://user-images.githubusercontent.com/46715299/172434420-46bbac21-37c7-4da6-85d3-4d447f524c8b.png)

- Home Assistant
- Glances endpoints
- Pi-hole(s)
  - Deploy both the primary and secondary pi-hole / DNS servers.
- ProxMox Config
- [Flux Nodes](https://runonflux.io/)

## Terraform

Terraform is used to provision the VMs needed for everything running on my home server(s)

I've structured this such that, each `base` VM needed is contained in it's own terraform module so I can create any X amount of that same base config as I want. (See [vars.auto.tfvars](https://github.com/matthewjdegarmo/home.io/blob/main/terraform/vars.auto.tfvars) for an example.)

## More to come:

- PFSense or OPNSense
- Networking Solution (With DHCP) - Currently handled by gateway.
- Internal CI/CD (Jenkins?)

I'm also planning to deploy some of my other servers / services via `k8s` in the future. To be decided.

## Why have this home lab configuration public?

Well... I'd like to think that I have something to contribute to the community, and if my scripts are useful, I'd like to share them. Obviously this reveals a little bit of how I'm configuring my home lab and network, but I would like to still share as much as I can.


## Quirks

1. When deploying a VM with Terraform, or when Terraform needs to make a change to a VM (nameserver, IP, or anything to make VM reboot, etc), ProxMox will auto-assign a new MAC address to the VM. The behavior of this breaks default SSH authentication without specifying StrictHostKeyChecking=no manually, which I'd like to avoid.

Example of what happens when terraform regenerates a MAC address:
![image](https://user-images.githubusercontent.com/46715299/172637211-000b6223-0f86-4242-9dcc-6dbb0c73789a.png)

### Solution to #1
When deploying a `NEW` VM, you do not need to specify the MAC Address (`macaddr` variable) in your variable map. BUT once the VM is deployed and a MAC exists for that VM, it's a good idea to add that MAC Address to your variable map so Terraform keeps this MAC address and doesn't regenerate it.

Example `vars.auto.tfvars` definition of a new VM:
`Initial Terraform Deployment`

```terraform
container-host = {
  "container-host" = {
    hostname     = "container-host"
    vmid         = "107"
    ip_address   = "10.0.0.7"
  }
}
```

`Post-Terraform Deployment`

```terraform
container-host = {
  "container-host" = {
    hostname     = "container-host"
    vmid         = "107"
    ip_address   = "10.0.0.7"
    macaddr      = "06:74:60:C0:37:F6"
  }
}
```

**NOTE**: You do not actually need to re-run Terraform to update the MAC Address. You can just update the variable map with the new MAC Address. You can confirm your terraform config / state by running `terraform plan` to confirm your config matches your state.
