#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

REPO_URL="https://github.com/JevonFunay/typo3-container.git"
ENV_S3_URI="s3://typo3-container/.env"

APP_DIR="/home/ec2-user/app"
dnf update -y
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
docker-compose version
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"
aws s3 cp "$ENV_S3_URI" "$APP_DIR/.env"
chmod 600 "$APP_DIR/.env"
sed -i -e 's/\r$//' -e '/^PUBLIC_HOST=/d' "$APP_DIR/.env"
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
PUBLIC_HOST=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
printf '\nPUBLIC_HOST=%s\n' "$PUBLIC_HOST" >> "$APP_DIR/.env"
chown -R ec2-user:ec2-user "$APP_DIR"
docker-compose up -d
docker-compose ps
