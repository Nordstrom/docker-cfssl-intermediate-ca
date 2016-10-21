image_registry := quay.io/nordstrom
image_name := cfssl-intermediate-ca
cfssl_version := 1.2
image_release := $(cfssl_version)-1

ifdef http_proxy
build_args := --build-arg="http_proxy=$(http_proxy)"
build_args += --build-arg="https_proxy=$(http_proxy)"
endif

build_args += --build-arg CFSSL_VERSION=$(cfssl_version)

build := $(PWD)/build

.PHONY: build/image tag/image push/image

build/image: $(build)/sigil
	docker build $(build_args) -t $(image_name) .

tag/image: build/image
	docker tag $(image_name) $(image_registry)/$(image_name):$(image_release)

push/image: tag/image
	docker push $(image_registry)/$(image_name):$(image_release)

$(build)/sigil: $(GOPATH)/src/github.com/gliderlabs/sigil/build/linux/sigil
	cp $< $@

$(GOPATH)/src/github.com/gliderlabs/sigil/build/linux/sigil: $(GOPATH)/src/github.com/gliderlabs/sigil
	cd $(GOPATH)/src/github.com/gliderlabs/sigil && \
	  make deps build

$(GOPATH)/src/github.com/gliderlabs/sigil: | go
	go get -u github.com/gliderlabs/sigil

$(build):
	mkdir -p $@

go: /usr/local/bin/go

/usr/local/bin/go:
	brew install go
