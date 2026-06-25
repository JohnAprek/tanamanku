#!/usr/bin/env bash
#
# Setup akses n8n dari luar via Tailscale (aman, tanpa buka port router).
# Jalankan di LAPTOP Linux yang menjalankan Docker n8n.
#
#   chmod +x setup-tailscale.sh
#   ./setup-tailscale.sh
#
set -euo pipefail

echo "==> 1/4 Install Tailscale (kalau belum ada)"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "    Tailscale sudah terpasang, lewati."
fi

echo "==> 2/4 Login & aktifkan Tailscale"
echo "    Akan muncul link untuk login di browser. Pakai akun yang SAMA dengan iPad."
sudo tailscale up

echo "==> 3/4 Aktifkan HTTPS publik di dalam tailnet (MagicDNS + HTTPS)"
echo "    Pastikan fitur HTTPS & MagicDNS aktif di admin console:"
echo "    https://login.tailscale.com/admin/dns"

echo "==> 4/4 Expose n8n (localhost:5678) sebagai HTTPS lewat Tailscale Serve"
sudo tailscale serve --bg 5678

echo
echo "Selesai. Cek alamatnya:"
tailscale serve status || true
echo
echo "Nama host laptop di tailnet:"
tailscale status --self --json 2>/dev/null | grep -o '"DNSName":[^,]*' | head -n1 || tailscale status | head -n1
echo
echo "Buka alamat https://<nama>.ts.net di iPad (setelah install app Tailscale & login)."
echo "Jangan lupa isi N8N_HOST & WEBHOOK_URL di file .env sesuai nama itu, lalu:"
echo "    docker compose up -d"
