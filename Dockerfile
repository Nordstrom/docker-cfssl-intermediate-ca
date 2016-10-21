FROM quay.io/nordstrom/awscli:1.11.5-1
MAINTAINER Nordstrom Kubernetes Platform Team "invcldtm@nordstrom.com"

ARG CFSSL_VERSION

USER root

RUN apt-get update -qy \
 && apt-get install -qy \
      make \
      bsdmainutils \
      nginx

RUN curl -Lo /usr/bin/cfssl https://pkg.cfssl.org/R${CFSSL_VERSION}/cfssl_linux-amd64 && chmod +x /usr/bin/cfssl
RUN curl -Lo /usr/bin/cfssljson https://pkg.cfssl.org/R${CFSSL_VERSION}/cfssljson_linux-amd64 && chmod +x /usr/bin/cfssljson
COPY build/sigil /usr/bin/sigil
RUN chmod +x /usr/bin/sigil
COPY start.sh /bin/start.sh
COPY templates /home/ubuntu/templates
COPY nginx.conf /etc/nginx/nginx.conf
