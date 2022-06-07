# Ansible

These are my ansible scripts that deploy / configure my homelab assets.


## Usage

With the `ansible.cfg` file(s), you do not need to specify the hosts file directly. `hosts.ini` is already specified in the `ansible.cfg` file.

To run a playbook, you simply need to include the playbook and any specific tags you need.

```bash
# Deploy full ProxMox config.
ansible-playbook ./playbooks/proxmox.yaml

# Deploy only Dashy on the container-host
ansible-playbook ./playbooks/container-host.yaml --tags dashy

# Deploy all Secondary Pi-Hole servers
ansible-playbook ./playbooks/pihole.yaml --tags secondary
```
![image](https://user-images.githubusercontent.com/46715299/172456122-f2a08288-80e5-490a-934b-94c26f9e5623.png)

## Secrets

There are encrypted secrets sprinkled throughout the playbooks. To decrypt them, you need to specify the `--vault-password-file` option or have the password present in the secret file listed for `vault_password_file` in the `ansible.cfg` file. I manage this vault secret outside of source control (obviously) but I don't want to have to type it in every time. 😊


## Hosts

The `hosts.ini` file is a simple list of hosts that you want to run the playbook on. This file needs to be built while considering the configuration specified in the terraform configuration as well to ensure IPs are correct.
