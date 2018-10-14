# This startup script is designed for Google's Container-Optimzed OS.
#
# Prerequisites:
#
# 1. Download PlexusPlay into PPP_DIR.
# 2. Create certificates from letsencrypt into /mnt/stateful_partition/etc/letsencrypt.

PPP_DIR="/home/buser_paul/ppp"
cd "${PPP_DIR}/aggregator"
docker build -t aggregator .
docker run -d -v /mnt/stateful_partition/etc/letsencrypt:/etc/letsencrypt -p 8080:8080 aggregator \
  --use_ssl \
  --cert_path /etc/letsencrypt/live/plexusplay.app/fullchain.pem \
  --privkey_path /etc/letsencrypt/live/plexusplay.app/privkey.pem

cd "${PPP_DIR}/web"
docker build -t frontend \
  --build-arg elm_config=./conf/ConfigProd.elm \
  --build-arg nginx_config=./conf/ngingx-prod.conf \
  --build-arg htpasswd=./conf/htpasswd-prod \
  .
docker run -d -v /mnt/stateful_partition/etc/letsencrypt:/etc/letsencrypt -p 443:443 frontend
