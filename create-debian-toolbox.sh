#!/bin/bash

#distro and release variables
RELEASE=${1:-latest}
DISTRO=${2:-debian}

container=$DISTRO-toolbox

# sterilize the environment
podman rm -f $container || true
toolbox rm -f $container || true

# Get hostname
hostname=$(hostname)

# Check if hostname is empty
if [ -z "$hostname" ]
then
      hostname=$container
fi

# pull docker image
podman pull $DISTRO:$RELEASE

# create toolbox
toolbox -y create -c $container --image docker.io/$DISTRO:$RELEASE

#modify container
podman start $container
podman exec -it $container sh -exc '
	hostname '$hostname'
	
	umount /var/log/journal
	
	if [ -e /etc/apt/sources.list.d/debian.sources ]; then
    		sed -i "/^Types:/ s/deb$/deb deb-src/" /etc/apt/sources.list.d/debian.sources
	fi
	
	apt update
	apt install -y sudo libcap2-bin nala
	apt clean
	
	sed -i "s/nullok_secure/nullok/" /etc/pam.d/common-auth
	sed -i "/^hosts:/ s/files dns myhostname/files myhostname dns/" /etc/nsswitch.conf
'

#run and modify toolbox
toolbox run --container $container sh -exc '
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
	
	sudo nala install -y flatpak-xdg-utils wget libfribidi0 libfontconfig1 libharfbuzz-dev libasound2 libthai0 libgl1 x11-xserver-utils adwaita-icon-theme-full
'

toolbox enter --container $container
