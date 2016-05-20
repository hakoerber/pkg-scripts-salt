NAME=salt
CHECKOUT=develop
DESCRIPTION="Infrastructure automation and management system."
UPSTREAMREMOTE=origin
URL=https://github.com/whatevsz/salt.git
ARCH=all

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILDDIR=$(ROOT_DIR)/upstream/build
UPSTREAMDIR=$(ROOT_DIR)/upstream/salt
OUTDIR=$(ROOT_DIR)/packages

.PHONY: all clean prepare clone upstream_udpate build rpm

all: | clean prepare clone upstream_update build rpm

clean:
	rm -rf $(BUILDDIR)/*

prepare:
	mkdir -p $(UPSTREAMDIR)
	mkdir -p $(BUILDDIR)
	mkdir -p $(OUTDIR)

clone:
	[[ -e $(UPSTREAMDIR)/.git ]] || git clone $(URL) $(UPSTREAMDIR)

upstream_update:
	cd $(UPSTREAMDIR) && \
	git fetch $(UPSTREAMREMOTE) && \
	git checkout $(UPSTREAMREMOTE)/$(CHECKOUT) || git checkout tags/$(CHECKOUT)

build:
	cd upstream/salt && \
	python setup.py build && \
	python setup.py install --prefix=/usr --root=$(BUILDDIR)

rpm:
	$(eval VERSION := $(shell cd upstream/salt && git describe --tags --long HEAD | sed -e 's/^v//'))
	fpm \
	-t rpm \
	-s dir \
	--name $(NAME) \
	--version $(VERSION) \
	--description $(DESCRIPTION) \
	--url $(URL) \
	--package $(OUTDIR) \
	--force \
	--architecture=$(ARCH) \
	--depends python-jinja2 \
	--depends python2-msgpack \
	--depends PyYAML \
	--depends python-markupsafe \
	--depends python-requests \
	--depends python-futures \
	--depends python-crypto \
	--depends python-zmq \
	--depends python-tornado \
	./upstream/build/usr/=/usr/ \
	./upstream/salt/pkg/salt-minion.service=/usr/lib/systemd/system/ \
	./upstream/salt/pkg/salt-master.service=/usr/lib/systemd/system/ \
	./upstream/salt/pkg/salt-syndic.service=/usr/lib/systemd/system

