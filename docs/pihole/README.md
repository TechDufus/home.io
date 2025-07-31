# Pi-hole Documentation

Pi-hole is a network-wide ad blocker that acts as a DNS sinkhole, protecting your devices from unwanted content without installing any client-side software.

## Overview

This homelab runs a redundant Pi-hole setup with:
- **Primary Pi-hole**: 10.0.0.5
- **Secondary Pi-hole**: Configured for high availability
- **Gravity Sync**: Automatic synchronization between primary and secondary instances

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Primary DNS    │     │ Secondary DNS   │
│   Pi-hole       │────▶│   Pi-hole       │
│  10.0.0.5       │     │                 │
└─────────────────┘     └─────────────────┘
        │                        │
        └────────┬───────────────┘
                 │
         ┌───────▼────────┐
         │ Network Clients│
         └────────────────┘
```

## Features

- **DNS-based Ad Blocking**: Blocks ads at the network level
- **Custom Blocklists**: Configured with curated ad lists
- **DHCP Management**: Static DHCP reservations for network devices
- **Custom DNS Records**: Local DNS entries for internal services
- **High Availability**: Dual Pi-hole setup with Gravity Sync
- **Web Interface**: Admin dashboard for monitoring and configuration

## Deployment

### Prerequisites

- Ubuntu/Debian-based system
- Static IP address
- Ansible installed on control machine

### Installation

Deploy Pi-hole using Ansible:

```bash
# Deploy primary Pi-hole
ansible-playbook ansible/playbooks/pihole.yaml --limit primary-dns

# Deploy secondary Pi-hole
ansible-playbook ansible/playbooks/pihole.yaml --limit secondary-dns
```

### Configuration Files

Key configuration files managed by Ansible:

- `04-pihole-static-dhcp.conf`: Static DHCP reservations
- `05-pihole-custom-cname.conf`: CNAME records for internal services
- `custom.list`: Local DNS entries
- `adlist.csv`: Blocklist sources

## Usage

### Web Interface

Access the Pi-hole admin interface:
- Primary: http://10.0.0.5/admin
- Secondary: http://[secondary-ip]/admin

Default password is stored in `ansible/roles/pihole-primary/files/admin-ui.password`

### Common Tasks

**Update Gravity (blocklists)**:
```bash
pihole -g
```

**Check Pi-hole status**:
```bash
pihole status
```

**Temporarily disable blocking**:
```bash
pihole disable 5m  # Disable for 5 minutes
```

**Add domain to whitelist**:
```bash
pihole -w example.com
```

**Add domain to blacklist**:
```bash
pihole -b ads.example.com
```

## Gravity Sync

Gravity Sync automatically synchronizes configuration between primary and secondary Pi-hole instances:

- Blocklists
- Whitelists/Blacklists
- Local DNS records
- DHCP reservations

Sync runs automatically via cron job every 15 minutes.

### Manual Sync

```bash
gravity-sync push  # Push from primary to secondary
gravity-sync pull  # Pull from secondary to primary
```

## Network Configuration

### Client DNS Settings

Configure network clients to use Pi-hole:
- Primary DNS: 10.0.0.5
- Secondary DNS: [secondary-pi-hole-ip]

### Router Configuration

For network-wide coverage, configure your router's DHCP settings:
1. Set Pi-hole as primary DNS server
2. Set secondary Pi-hole as fallback DNS
3. Disable any built-in ad blocking features

## Maintenance

### Updating Pi-hole

```bash
pihole -up
```

### Backup Configuration

Configuration is automatically backed up via the `download_config.sh` script:

```bash
./ansible/roles/pihole-primary/scripts/download_config.sh
```

### Log Rotation

Pi-hole logs are automatically rotated. View recent queries:

```bash
pihole -t  # Tail the log
```

## Troubleshooting

### DNS Resolution Issues

1. Check Pi-hole service status:
   ```bash
   systemctl status pihole-FTL
   ```

2. Test DNS resolution:
   ```bash
   dig @10.0.0.5 google.com
   ```

3. Check for blocking:
   ```bash
   pihole -q example.com
   ```

### High Memory Usage

Clear query logs if needed:
```bash
pihole flush
```

### Gravity Sync Issues

Check sync status:
```bash
gravity-sync status
```

View sync logs:
```bash
journalctl -u gravity-sync
```

## Security Considerations

- Admin interface is password-protected
- Consider using HTTPS with a reverse proxy
- Regularly update Pi-hole and underlying OS
- Monitor query logs for suspicious activity
- Use firewall rules to restrict access

## Integration with Home Lab

Pi-hole integrates with other services:
- Provides DNS for all containers and VMs
- Custom DNS entries for internal services
- CNAME records for service aliases
- DHCP reservations for static IPs

## Resources

- [Official Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole GitHub Repository](https://github.com/pi-hole/pi-hole)
- [Gravity Sync Documentation](https://github.com/vmstan/gravity-sync)
- [Pi-hole Discourse Community](https://discourse.pi-hole.net/)