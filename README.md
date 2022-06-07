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

More to come:

- PFSense or OPNSense
- Networking Solution (With DHCP) - Currently handled by gateway.
- Internal CI/CD (Jenkins?)

## Other future fluff

I'm also planning to deploy some of my other servers / services via `k8s` in the future. To be decided.

## Why have this home lab configuration public?

Well... I'd like to think that I have something to contribute to the community, and if my scripts are useful, I'd like to share them. Obviously this reveals a little bit of how I'm configuring my home lab and network, but I would like to still share as much as I can.
