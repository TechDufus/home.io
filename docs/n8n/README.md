# n8n Automation Platform

n8n is a workflow automation tool that runs on my homelab infrastructure, providing integrations and automations for various services.

## Server Details
- **Host**: techdufus@10.0.20.150
- **Timezone**: America/Chicago
- **Public URL**: https://n8n.techdufus.com
- **Access**: Via Cloudflare Tunnel

## Prerequisites Installation

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Docker
sudo apt install docker.io

# Add user to docker group (logout/login required after)
sudo groupadd docker
sudo gpasswd -a $USER docker

# Test Docker installation
docker run hello-world
```

## Cloudflare Tunnel Setup

```bash
# Add Cloudflare GPG key
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add Cloudflare repository
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Install cloudflared
sudo apt-get update && sudo apt-get install cloudflared

# Install tunnel as a service (replace with your own tunnel token)
sudo cloudflared service install <YOUR_TUNNEL_TOKEN>
```

## n8n Docker Setup

```bash
# Create Docker volume for persistent data
docker volume create n8n_data

# Run n8n container
docker run -it -d \
  --restart unless-stopped \
  --name n8n \
  -p 5678:5678 \
  -e GENERIC_TIMEZONE="America/Chicago" \
  -e TZ="America/Chicago" \
  -e WEBHOOK_URL="https://n8n.techdufus.com" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n
```

## Container Management

```bash
# Check container status
docker ps -a

# View logs
docker logs n8n

# Stop/Start container
docker stop n8n
docker start n8n

# Access container shell
docker exec -it n8n /bin/sh

# Update n8n (stop, remove, and recreate with latest image)
docker stop n8n
docker rm n8n
docker pull docker.n8n.io/n8nio/n8n
# Then run the docker run command above again
```

## Data Locations

- **Docker Volume**: `n8n_data` (contains all n8n data and configurations)
- **Container Data**: `/home/node/.n8n` (inside container)
- **Host Port**: 5678 (proxied through Cloudflare tunnel)

## Backup Strategy

Automated backups are handled by a dedicated n8n workflow that:
1. Exports all workflows to JSON format
2. Commits them to a GitHub repository: https://github.com/TechDufus/wouldnt-you-like-to-know
3. Sends Discord notifications on success/failure

The backup repository serves as version control for all n8n workflows and allows easy restoration if needed.

## Useful Resources

- [Official n8n Documentation](https://docs.n8n.io/)
- [n8n Workflow Templates](https://n8n.io/workflows)
- [Backup Workflow Template](https://n8n.io/workflows/1534-back-up-your-n8n-workflows-to-github/)
