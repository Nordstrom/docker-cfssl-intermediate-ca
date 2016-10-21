#!/bin/bash

make tls-cert \
  year=2016 \
  month=oc \
  s3_bucket=sst-rfid-team \
  s3_path=staging/certificate-authority \
  internal_dns_domain=platform.nonprod.aws.cloud.nordstrom.net \

build=/home/ubuntu/build
mkdir -p /etc/nginx/ssl/
mv ${build}/intermediate-ca-tls.key /etc/nginx/ssl/
mv ${build}/intermediate-ca-tls.crt /etc/nginx/ssl/

echo "Starting nginx"
nginx -g "daemon on;"

tail -f /var/log/nginx/access.log /var/log/nginx/error.log &
exec cfssl serve \
  -port=8888 \
  -ca=${build}/intermediate-ca.pem \
  -ca-key=${build}/intermediate-ca-key.pem \
  -config=${build}/intermediate-ca-config.json
