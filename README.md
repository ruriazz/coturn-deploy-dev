# Panduan Deployment Coturn TURN Server

## Prerequisites

1. **Server Requirements:**
   - VPS/Server dengan IP publik
   - Minimum 1GB RAM, 1 CPU core
   - Ubuntu 20.04+ atau CentOS 8+ (recommended)
   - Docker dan Docker Compose terinstall

2. **Network Requirements:**
   - Port 3478 (UDP/TCP) untuk STUN/TURN
   - Port 5349 (UDP/TCP) untuk TURNS (TLS)
   - Port range 49152-65535 (UDP) untuk media relay

## Setup Instructions

### 1. Persiapkan Directory
```bash
mkdir coturn-deploy && cd coturn-deploy
mkdir certs logs
```

### 2. Buat File Konfigurasi
- Simpan `docker-compose.yml` di root directory
- Simpan `coturn.conf` di root directory
- Edit konfigurasi sesuai kebutuhan

### 3. Konfigurasi yang Harus Diubah

**Di file `coturn.conf`:**
```bash
# Ganti dengan IP publik server Anda
relay-ip=YOUR_SERVER_PUBLIC_IP
external-ip=YOUR_SERVER_PUBLIC_IP

# Ganti dengan domain Anda
realm=yourdomain.com

# Ganti kredensial default
user=username1:strong_password_123
user=username2:another_strong_pass
```

**Di file `docker-compose.yml`:**
```bash
# Update environment variables
TURN_USERNAME=your_username
TURN_PASSWORD=your_secure_password
```

### 4. Setup SSL/TLS (Optional tapi Recommended)

Untuk menggunakan TURNS (secure), buat sertifikat SSL:

```bash
# Self-signed certificate (untuk testing)
openssl req -x509 -newkey rsa:4096 -keyout certs/turn_server_pkey.pem \
    -out certs/turn_server_cert.pem -days 365 -nodes \
    -subj "/C=ID/ST=West Java/L=Depok/O=YourOrg/CN=yourdomain.com"

# Diffie-Hellman parameters
openssl dhparam -out certs/turn_server_dh.pem 2048
```

Kemudian uncomment baris SSL di `coturn.conf`:
```bash
cert=/etc/coturn/certs/turn_server_cert.pem
pkey=/etc/coturn/certs/turn_server_pkey.pem
dh-file=/etc/coturn/certs/turn_server_dh.pem
```

### 5. Deploy

```bash
# Start service
docker-compose up -d

# Check logs
docker-compose logs -f coturn

# Check status
docker-compose ps
```

### 6. Testing TURN Server

Test dengan turnutils:
```bash
# Test STUN
docker exec coturn-server turnutils_stunclient YOUR_SERVER_IP

# Test TURN credentials
docker exec coturn-server turnutils_uclient -t -u testuser -w testpass YOUR_SERVER_IP
```

Test dari eksternal:
```bash
# Install coturn-utils di mesin lain
sudo apt install coturn-utils

# Test dari client
turnutils_uclient -t -u testuser -w testpass YOUR_SERVER_IP
```

## Monitoring & Maintenance

### Health Check
Service sudah dilengkapi health check. Monitor dengan:
```bash
docker-compose ps
docker inspect coturn-server | grep Health -A 10
```

### Log Monitoring
```bash
# Real-time logs
docker-compose logs -f coturn

# Log files
ls -la logs/
tail -f logs/turn.log
```

### Performance Tuning

**Untuk high-traffic production:**

1. **Increase ulimits:**
```yaml
# Tambahkan di docker-compose.yml
ulimits:
  nofile:
    soft: 65536
    hard: 65536
```

2. **Optimize kernel parameters:**
```bash
# /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
```

3. **Database mode (untuk banyak user):**
Uncomment pengaturan database di `coturn.conf` dan tambahkan service database.

## Security Best Practices

1. **Firewall Configuration:**
```bash
# UFW example
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 5349/udp
sudo ufw allow 49152:65535/udp
```

2. **Strong Credentials:**
- Gunakan password minimal 16 karakter
- Rotate credentials secara berkala
- Pertimbangkan menggunakan database authentication

3. **Regular Updates:**
```bash
# Update container image
docker-compose pull
docker-compose up -d
```

## WebRTC Integration Example

```javascript
// JavaScript WebRTC configuration
const iceServers = [
    {
        urls: ['stun:YOUR_SERVER_IP:3478']
    },
    {
        urls: ['turn:YOUR_SERVER_IP:3478'],
        username: 'testuser',
        credential: 'testpass'
    },
    {
        urls: ['turns:YOUR_SERVER_IP:5349'],
        username: 'testuser', 
        credential: 'testpass'
    }
];

const peerConnection = new RTCPeerConnection({
    iceServers: iceServers
});
```

## Troubleshooting

### Common Issues:

1. **Connection refused:**
   - Check firewall settings
   - Verify port configuration
   - Ensure network_mode: host atau port mapping benar

2. **Authentication failed:**
   - Verify username/password di coturn.conf
   - Check realm configuration

3. **High CPU usage:**
   - Monitor concurrent connections
   - Consider scaling horizontally
   - Optimize port range

### Useful Commands:
```bash
# Container stats
docker stats coturn-server

# Network test
netstat -tulpn | grep :3478

# Process monitoring
docker exec coturn-server ps aux
```