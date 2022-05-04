# home.io

Collection of automation scripts to deploy and manage my internal home lab environment.

## Ansible

I'm currently using Ansible to deploy some of my servers, including the following:

- Heimdall
  - Deploy docker container to host my Heimdall server.
- Pi-hole
  - Deploy both the primary and secondary pi-hole / DNS servers.

More to come:

- PFSense
- Networking Solution (With DHCP)
- Internal CI/CD (Jenkins?)

## Other future fluff

I'm also planning to deploy some of my other servers / services via `k8s` in the future. To be decided.

## Why have this home lab configuration public?

Well... I'd like to think that I have something to contribute to the community, and if my scripts are useful, I'd like to share them. Obviously this reveals a little bit of how I'm configuring my home lab and network, but I would like to still share as much as I can.