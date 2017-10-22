HEROKUISH_DESCRIPTION = 'Herokuish uses Docker and Buildpacks to build applications like Heroku'
HEROKUISH_REPO_NAME ?= gliderlabs/herokuish
HEROKUISH_VERSION ?= 0.3.19
HEROKUISH_ARCHITECTURE = amd64
HEROKUISH_PACKAGE_NAME = herokuish_$(HEROKUISH_VERSION)_$(HEROKUISH_ARCHITECTURE).deb

DOKKU_DESCRIPTION = 'Docker powered PaaS that helps you build and manage the lifecycle of applications'
DOKKU_REPO_NAME ?= dokku/dokku
DOKKU_ARCHITECTURE = amd64

define PLUGN_DESCRIPTION
Hook system that lets users extend your application with plugins
Plugin triggers are simply scripts that are executed by the system.
You can use any language you want, so long as the script is
executable and has the proper language requirements installed
endef
PLUGN_REPO_NAME ?= dokku/plugn
PLUGN_VERSION ?= 0.2.2
PLUGN_ARCHITECTURE = amd64
PLUGN_PACKAGE_NAME = plugn_$(PLUGN_VERSION)_$(PLUGN_ARCHITECTURE).deb
PLUGN_URL = https://github.com/dokku/plugn/releases/download/v$(PLUGN_VERSION)/plugn_$(PLUGN_VERSION)_linux_x86_64.tgz

define SSHCOMMAND_DESCRIPTION
Turn SSH into a thin client specifically for your app
Simplifies running a single command over SSH, and
manages authorized keys (ACL) and users in order to do so.
endef
SSHCOMMAND_REPO_NAME ?= dokku/sshcommand
SSHCOMMAND_VERSION ?= 0.6.0
SSHCOMMAND_ARCHITECTURE = amd64
SSHCOMMAND_PACKAGE_NAME = sshcommand_$(SSHCOMMAND_VERSION)_$(SSHCOMMAND_ARCHITECTURE).deb
SSHCOMMAND_URL ?= https://raw.githubusercontent.com/dokku/sshcommand/v$(SSHCOMMAND_VERSION)/sshcommand

define SIGIL_DESCRIPTION
Standalone string interpolator and template processor
Sigil is a command line tool for template processing
and POSIX-compliant variable expansion. It was created
for configuration templating, but can be used for any
text processing.
endef
SIGIL_REPO_NAME ?= gliderlabs/sigil
SIGIL_VERSION ?= 0.4.0
SIGIL_ARCHITECTURE = amd64
SIGIL_PACKAGE_NAME = gliderlabs_sigil_$(SIGIL_VERSION)_$(SIGIL_ARCHITECTURE).deb
SIGIL_URL = https://github.com/gliderlabs/sigil/releases/download/v$(SIGIL_VERSION)/sigil_$(SIGIL_VERSION)_Linux_x86_64.tgz

ifndef IS_RELEASE
	IS_RELEASE = true
endif

export PLUGN_DESCRIPTION
export SIGIL_DESCRIPTION
export SSHCOMMAND_DESCRIPTION

.PHONY: install-from-deb deb-all deb-herokuish deb-dokku deb-plugn deb-setup deb-sshcommand deb-sigil

install-from-deb:
	@echo "--> Initial apt-get update"
	sudo apt-get update -qq > /dev/null
	sudo apt-get install -qq -y apt-transport-https

	@echo "--> Installing docker"
	wget -nv -O - https://get.docker.com/ | sh

	@echo "--> Installing dokku"
	wget -nv -O - https://packagecloud.io/gpg.key | apt-key add -
	@echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ trusty main" | sudo tee /etc/apt/sources.list.d/dokku.list
	sudo apt-get update -qq > /dev/null
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get install -yy dokku

deb-all: deb-setup deb-herokuish deb-dokku deb-plugn deb-sshcommand deb-sigil
	mv /tmp/*.deb .
	@echo "Done"

deb-setup:
	@echo "-> Updating deb repository and installing build requirements"
	@sudo apt-get update -qq > /dev/null
	@sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get install -qq -y gcc git build-essential wget ruby-dev ruby1.9.1 lintian > /dev/null 2>&1
	@command -v fpm > /dev/null || sudo gem install fpm --no-ri --no-rdoc
	@ssh -o StrictHostKeyChecking=no git@github.com || true

deb-herokuish:
	rm -rf /tmp/tmp /tmp/build $(HEROKUISH_PACKAGE_NAME)
	mkdir -p /tmp/tmp /tmp/build

	@echo "-> Creating deb files"
	@echo "#!/usr/bin/env bash" >> /tmp/tmp/post-install
	@echo "sleep 5" >> /tmp/tmp/post-install
	@echo "count=\`sudo docker images | grep gliderlabs/herokuish | wc -l\`" >> /tmp/tmp/post-install
	@echo 'if [ "$$count" -ne 0 ]; then' >> /tmp/tmp/post-install
	@echo "  echo 'Removing old herokuish image'" >> /tmp/tmp/post-install
	@echo "  sudo docker rmi gliderlabs/herokuish" >> /tmp/tmp/post-install
	@echo "fi" >> /tmp/tmp/post-install
	@echo "echo 'Importing herokuish into docker (around 5 minutes)'" >> /tmp/tmp/post-install
	@echo "sudo docker build -t gliderlabs/herokuish /var/lib/herokuish 1> /dev/null" >> /tmp/tmp/post-install

	@echo "-> Cloning repository"
	git clone -q "https://github.com/$(HEROKUISH_REPO_NAME).git" --branch "v$(HEROKUISH_VERSION)" /tmp/tmp/herokuish > /dev/null
	rm -rf /tmp/tmp/herokuish/.git /tmp/tmp/herokuish/.gitignore

	@echo "-> Copying files into place"
	mkdir -p "/tmp/build/var/lib"
	cp -rf /tmp/tmp/herokuish /tmp/build/var/lib/herokuish

	@echo "-> Creating $(HEROKUISH_PACKAGE_NAME)"
	sudo fpm -t deb -s dir -C /tmp/build -n herokuish -v $(HEROKUISH_VERSION) -a $(HEROKUISH_ARCHITECTURE) -p $(HEROKUISH_PACKAGE_NAME) --deb-pre-depends 'docker-engine-cs (>= 1.9.1) | docker-engine (>= 1.9.1)' --deb-pre-depends sudo --after-install /tmp/tmp/post-install --url "https://github.com/$(HEROKUISH_REPO_NAME)" --description $(HEROKUISH_DESCRIPTION) --license 'MIT License' .
	mv *.deb /tmp

deb-dokku:
	rm -rf /tmp/tmp /tmp/build dokku_*_$(DOKKU_ARCHITECTURE).deb
	mkdir -p /tmp/tmp /tmp/build

	cp -r debian /tmp/build/DEBIAN
	mkdir -p /tmp/build/usr/bin
	mkdir -p /tmp/build/usr/share/doc/dokku
	mkdir -p /tmp/build/usr/share/dokku/contrib
	mkdir -p /tmp/build/usr/share/lintian/overrides
	mkdir -p /tmp/build/usr/share/man/man1
	mkdir -p /tmp/build/var/lib/dokku/core-plugins/available

	cp dokku /tmp/build/usr/bin
	cp LICENSE /tmp/build/usr/share/doc/dokku/copyright
	find . -name ".DS_Store" -depth -exec rm {} \;
	cp -r plugins/* /tmp/build/var/lib/dokku/core-plugins/available
	find plugins/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | while read plugin; do touch /tmp/build/var/lib/dokku/core-plugins/available/$$plugin/.core; done
	$(MAKE) help2man
	$(MAKE) addman
	cp /usr/local/share/man/man1/dokku.1 /tmp/build/usr/share/man/man1/dokku.1
	gzip -9 /tmp/build/usr/share/man/man1/dokku.1
	cp contrib/dokku-installer.py /tmp/build/usr/share/dokku/contrib
	git describe --tags > /tmp/build/var/lib/dokku/VERSION
	cat /tmp/build/var/lib/dokku/VERSION | cut -d '-' -f 1 | cut -d 'v' -f 2 > /tmp/build/var/lib/dokku/STABLE_VERSION
ifneq (,$(findstring false,$(IS_RELEASE)))
	sed -i.bak -e "s/^/`date +%s`:/" /tmp/build/var/lib/dokku/STABLE_VERSION && rm /tmp/build/var/lib/dokku/STABLE_VERSION.bak
endif
	rm /tmp/build/DEBIAN/lintian-overrides
	mv debian/lintian-overrides /tmp/build/usr/share/lintian/overrides/dokku
	git rev-parse HEAD > /tmp/build/var/lib/dokku/GIT_REV
	sed -i "s/^Version: .*/Version: `cat /tmp/build/var/lib/dokku/STABLE_VERSION`/g" /tmp/build/DEBIAN/control
	dpkg-deb --build /tmp/build "/tmp/dokku_`cat /tmp/build/var/lib/dokku/STABLE_VERSION`_$(DOKKU_ARCHITECTURE).deb"
	lintian "/tmp/dokku_`cat /tmp/build/var/lib/dokku/STABLE_VERSION`_$(DOKKU_ARCHITECTURE).deb"

deb-plugn:
	rm -rf /tmp/tmp /tmp/build $(PLUGN_PACKAGE_NAME)
	mkdir -p /tmp/tmp /tmp/build /tmp/build/usr/bin

	@echo "-> Downloading package"
	wget -q -O /tmp/tmp/plugn-$(PLUGN_VERSION).tgz $(PLUGN_URL)
	cd /tmp/tmp/ && tar zxf /tmp/tmp/plugn-$(PLUGN_VERSION).tgz

	@echo "-> Copying files into place"
	cp /tmp/tmp/plugn /tmp/build/usr/bin/plugn && chmod +x /tmp/build/usr/bin/plugn

	@echo "-> Creating $(PLUGN_PACKAGE_NAME)"
	sudo fpm -t deb -s dir -C /tmp/build -n plugn \
			 --version $(PLUGN_VERSION) \
			 --architecture $(PLUGN_ARCHITECTURE) \
			 --package $(PLUGN_PACKAGE_NAME) \
			 --url "https://github.com/$(PLUGN_REPO_NAME)" \
			 --maintainer "Jose Diaz-Gonzalez <dokku@josediazgonzalez.com>" \
			 --category utils \
			 --description "$$PLUGN_DESCRIPTION" \
			 --license 'MIT License' \
			 .
	mv *.deb /tmp

deb-sshcommand:
	rm -rf /tmp/tmp /tmp/build $(SSHCOMMAND_PACKAGE_NAME)
	mkdir -p /tmp/tmp /tmp/build /tmp/build/usr/local/bin

	@echo "-> Downloading package"
	wget -q -O /tmp/tmp/sshcommand-$(SSHCOMMAND_VERSION) $(SSHCOMMAND_URL)

	@echo "-> Copying files into place"
	mkdir -p "/tmp/build/usr/local/bin"
	cp /tmp/tmp/sshcommand-$(SSHCOMMAND_VERSION) /tmp/build/usr/local/bin/sshcommand
	chmod +x /tmp/build/usr/local/bin/sshcommand

	@echo "-> Creating $(SSHCOMMAND_PACKAGE_NAME)"
	sudo fpm -t deb -s dir -C /tmp/build -n sshcommand \
			 --version $(SSHCOMMAND_VERSION) \
			 --architecture $(SSHCOMMAND_ARCHITECTURE) \
			 --package $(SSHCOMMAND_PACKAGE_NAME) \
			 --url "https://github.com/$(SSHCOMMAND_REPO_NAME)" \
			 --maintainer "Jose Diaz-Gonzalez <dokku@josediazgonzalez.com>" \
			 --category admin \
			 --description "$$SSHCOMMAND_DESCRIPTION" \
			 --license 'MIT License' \
			 .
	mv *.deb /tmp

deb-sigil:
	rm -rf /tmp/tmp /tmp/build $(SIGIL_PACKAGE_NAME)
	mkdir -p /tmp/tmp /tmp/build /tmp/build/usr/bin

	@echo "-> Downloading package"
	wget -q -O /tmp/tmp/sigil-$(SIGIL_VERSION).tgz $(SIGIL_URL)
	cd /tmp/tmp/ && tar zxf /tmp/tmp/sigil-$(SIGIL_VERSION).tgz

	@echo "-> Copying files into place"
	cp /tmp/tmp/sigil /tmp/build/usr/bin/sigil && chmod +x /tmp/build/usr/bin/sigil

	@echo "-> Creating $(SIGIL_PACKAGE_NAME)"
	sudo fpm -t deb -s dir -C /tmp/build -n gliderlabs-sigil \
			 --version $(SIGIL_VERSION) \
			 --architecture $(SIGIL_ARCHITECTURE) \
			 --package $(SIGIL_PACKAGE_NAME) \
			 --url "https://github.com/$(SIGIL_REPO_NAME)" \
			 --maintainer "Jose Diaz-Gonzalez <dokku@josediazgonzalez.com>" \
			 --category utils \
			 --description "$$SIGIL_DESCRIPTION" \
			 --license 'MIT License' \
			 .
	mv *.deb /tmp
