#!/bin/bash

openssl req -x509 -newkey rsa:4096 \
    -keyout certs/turn_server_pkey.pem \
    -out certs/turn_server_cert.pem \
    -days 365 -nodes \
    -config certs/coturn.cnf

echo "=== GENERATE DH PARAMETERS ==="
openssl dhparam -out certs/turn_server_dh.pem 2048

echo "=== SET PERMISSIONS ==="
chmod 644 certs/turn_server_cert.pem
chmod 600 certs/turn_server_pkey.pem
chmod 644 certs/turn_server_dh.pem

docker compose -f docker-compose.yaml up -d