# Deploying FlyPDF to Oracle Cloud (or any Ubuntu VM)

This deploys the **backend API** (auth, AI chat, email) and serves the
**frontend** over HTTPS. HTTPS is required for the native "Share to contacts"
feature and for secure auth.

You need:
- An Oracle Cloud **Always Free** VM (Ubuntu 22.04), or any Ubuntu server
- Its **public IP**
- A **domain name** pointed at that IP (for free HTTPS via Let's Encrypt).
  No domain? You can still run on `http://IP` but `navigator.share` with files
  and some browser features need HTTPS — a domain is strongly recommended.
- SSH access (Oracle default user is `ubuntu` on Ubuntu images)

---

## 1. Open the ports (Oracle Cloud console)

In **Networking → Virtual Cloud Network → Security List**, add Ingress rules:
- TCP **80** (HTTP) from 0.0.0.0/0
- TCP **443** (HTTPS) from 0.0.0.0/0

Then on the VM itself, allow them through the OS firewall:
```bash
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save    # persist across reboots
```

## 2. Point your domain at the server

Create a DNS **A record**: `flypdf.yourdomain.com → <your VM public IP>`.
Wait until `ping flypdf.yourdomain.com` resolves to the IP.

## 3. SSH in and install dependencies

```bash
ssh ubuntu@<your-ip>

sudo apt update && sudo apt -y upgrade
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt -y install nodejs nginx certbot python3-certbot-nginx git
```

## 4. Get the code onto the server

```bash
sudo mkdir -p /opt/flypdf && sudo chown $USER:$USER /opt/flypdf
cd /opt/flypdf
git clone https://github.com/dbordusenko/nexus_ai_office.git .
# (or rsync your local FlyPDF folder up)

cd /opt/flypdf/backend
npm install --omit=dev
```

## 5. Configure secrets (.env)

```bash
cd /opt/flypdf/backend
cp .env.example .env
nano .env
```
Fill in:
- `GROQ_API_KEY=...` (for AI chat)
- SMTP settings for real email (Gmail App Password works — see .env.example)
- `AUTH_SECRET=` a long random string: `openssl rand -hex 32`

## 6. Run the backend as a service

```bash
sudo cp /opt/flypdf/deploy/flypdf-backend.service /etc/systemd/system/
# Edit User/paths inside if your username isn't "ubuntu":
sudo nano /etc/systemd/system/flypdf-backend.service

sudo systemctl daemon-reload
sudo systemctl enable --now flypdf-backend
sudo systemctl status flypdf-backend     # should be "active (running)"
```

## 7. Configure nginx + HTTPS

```bash
sudo cp /opt/flypdf/deploy/nginx-flypdf.conf /etc/nginx/sites-available/flypdf
sudo sed -i 's/YOUR_DOMAIN/flypdf.yourdomain.com/' /etc/nginx/sites-available/flypdf
sudo ln -sf /etc/nginx/sites-available/flypdf /etc/nginx/sites-enabled/flypdf
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Free HTTPS certificate (auto-configures the TLS server block + redirect)
sudo certbot --nginx -d flypdf.yourdomain.com
```

## 8. Done — verify

- Frontend: `https://flypdf.yourdomain.com`
- API health: `https://flypdf.yourdomain.com/api/health`

The frontend auto-detects it's not on localhost and calls `${origin}/api`,
which nginx proxies to the backend. No frontend code change needed.

---

## Updating later

```bash
cd /opt/flypdf && git pull
cd backend && npm install --omit=dev
sudo systemctl restart flypdf-backend
```

## Logs / troubleshooting

```bash
sudo journalctl -u flypdf-backend -f      # backend logs
sudo tail -f /var/log/nginx/error.log     # nginx logs
```

## Notes
- `users.json`, `.auth_secret`, `.env` stay on the server and are gitignored —
  never committed. Back them up separately if needed.
- For production-grade user storage, migrate `users.json` to SQLite/Postgres
  later; the current file store is fine for early users.
