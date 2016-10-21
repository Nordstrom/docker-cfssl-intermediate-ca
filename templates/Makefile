export project_root := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
export build := $(project_root)/../build

include $(project_root)/Makefile.utils

export AWS_DEFAULT_REGION := us-west-2

ifndef s3_bucket
$(error s3_bucket must be defined)
endif

ifndef s3_path
$(error s3_path must be defined)
endif

ifndef internal_dns_domain
$(error internal_dns_domain must be defined)
endif

.PHONY: serve

serve: $(build)/intermediate-ca.pem $(build)/intermediate-ca-key.pem $(build)/intermediate-ca-config.json | cfssl
	$(CFSSL) serve -port=8887 -config=$(build)/intermediate-ca-config.json -ca=$(build)/intermediate-ca.pem -ca-key=$(build)/intermediate-ca-key.pem

tls-cert: $(build)/intermediate-ca-tls.crt $(build)/intermediate-ca-tls.key

intermediate-ca: $(build)/intermediate-ca.pem

$(build)/intermediate_ca_auth_key: | $(build)
	cat /dev/urandom | hexdump -ve '1/1 "%.2x"' | fold -w 64 | head -n 1 > "$@"
	# cat /dev/urandom | xxd -l 120 -ps -c 32 | head -n 1 > "$@"

$(build)/intermediate-ca-config.json: intermediate-ca-config.json.tmpl $(build)/intermediate_ca_auth_key $(build)/year $(build)/month | $(build)
	@echo "Templating $@"
	@intermediate_ca_auth_key=$$(cat $(build)/intermediate_ca_auth_key) \
	  month=$$(cat $(build)/month) \
	  year=$$(cat $(build)/year) \
	  $(SIGIL) -p -f "$<" > "$@"

$(build)/root-ca-config.json: root-ca-config.json.tmpl $(build)/year $(build)/month
$(build)/intermediate-ca-csr.json: intermediate-ca-csr.json.tmpl $(build)/year $(build)/month
$(build)/intermediate-ca-tls-csr.json: intermediate-ca-tls-csr.json.tmpl $(build)/year $(build)/month
$(build)/root-ca-config.json $(build)/intermediate-ca-csr.json $(build)/intermediate-ca-tls-csr.json: | $(build)
	@echo "Templating $@"
	@month=$$(cat $(build)/month) \
	  year=$$(cat $(build)/year) \
	  $(SIGIL) -p -f "$<" > "$@"

$(build)/intermediate-ca-key.pem $(build)/intermediate-ca.csr: $(build)/intermediate-ca-csr.json | $(build) cfssl
	$(CFSSL) genkey -initca "$<" | cfssljson -bare $(build)/intermediate-ca

$(build)/intermediate-ca-tls-key.pem: $(build)/intermediate-ca-tls-csr.json
$(build)/intermediate-ca-tls.csr: $(build)/intermediate-ca-tls-csr.json
$(build)/intermediate-ca-tls-key.pem $(build)/intermediate-ca-tls.csr: | $(build) cfssl
	$(CFSSL) genkey "$<" | cfssljson -bare $(build)/intermediate-ca-tls

$(build)/intermediate-ca.pem: $(build)/intermediate-ca.csr $(build)/root-ca.pem $(build)/root-ca-key.pem $(build)/root-ca-config.json | $(build) cfssl
	$(CFSSL) sign \
	  -profile="intermediate-ca" \
	  -config="$(build)/root-ca-config.json" \
	  -ca="$(build)/root-ca.pem" \
	  -ca-key="$(build)/root-ca-key.pem" \
	  -hostname="certificate-authority.$(internal_dns_domain)" \
	  -csr="$<" \
	  | cfssljson -bare $(build)/intermediate-ca

$(build)/intermediate-ca-tls.crt: $(build)/intermediate-ca-tls.pem
	cp $< $@

$(build)/intermediate-ca-tls.key: $(build)/intermediate-ca-tls-key.pem
	cp $< $@

$(build)/intermediate-ca-tls.pem: $(build)/intermediate-ca-tls.csr $(build)/intermediate-ca.pem $(build)/intermediate-ca-key.pem $(build)/intermediate-ca-config.json | $(build) cfssl
	$(CFSSL) sign \
	  -profile="server" \
	  -config="$(build)/intermediate-ca-config.json" \
	  -ca="$(build)/intermediate-ca.pem" \
	  -ca-key="$(build)/intermediate-ca-key.pem" \
	  -hostname="cfssl.$(internal_dns_domain),certificate-authority.$(internal_dns_domain),ca.$(internal_dns_domain)" \
	  -csr="$<" \
	  | cfssljson -bare $(build)/intermediate-ca-tls

$(build)/project_root:
$(build)/build_path:
$(build)/project_root $(build)/build_path: | $(build)
	echo "$(build)" > "$@"

$(build)/root-ca.pem: $(build)/root-ca.pem.enc
$(build)/root-ca-key.pem: $(build)/root-ca-key.pem.enc
$(build)/root-ca.pem $(build)/root-ca-key.pem: | awscli
	$(AWS) kms decrypt \
	  --ciphertext-blob="fileb://$<" \
	  --output=text \
	  --query=Plaintext \
	  | base64 --decode > "$@"

$(build)/root-ca.pem.enc: | $(build) awscli
	$(AWS) s3 cp s3://$(s3_bucket)/$(s3_path)/$$(basename $@) "$@"

$(build)/root-ca-key.pem.enc: | $(build) awscli
	$(AWS) s3 cp s3://$(s3_bucket)/$(s3_path)/$$(basename $@) "$@"

$(build)/year:
	date +"%Y" > $@

$(build)/month:
	date +"%b" | tr '[:upper:]' '[:lower:]' > $@

$(build):
	mkdir -p $@

clean:
	rm -rf $(build)
