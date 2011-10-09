#!/bin/bash -ex

# make sure we have make, pcre and junk
if [ -e /etc/redhat-release ]; then
	OS=redhat;
elif [ -e /etc/debian_version ]; then
	OS=debian;
fi

if [ $OS ]; then
	if [ $OS = 'redhat' ]; then
		yum install -y pcre-devel make gcc git;
	elif [ $OS = 'debian' ]; then
		apt-get install -y libpcre3 libpcre3-dev build-essential git;
	fi
else
	echo -e "I only understand Debian/RedHat/CentOS and this box does not appear to be any.\nExiting.\n- love, $0.";
	exit 2;
fi

# grab last stable.  HAProxy's site versions nicely - these will still be here after the next update
mkdir /usr/local/src || echo "Oops, /usr/local/src exists!"
cd /usr/local/src || exit 2
wget http://haproxy.1wt.eu/download/1.4/src/haproxy-1.4.17.tar.gz
tar xvfz haproxy-1.4.18.tar.gz
cd haproxy-1.4.18

# tricky.  awk will exit 1 if this isn't an x86_64 system...
if uname -a | grep x86_64 ; then
	make TARGET=linux26 CPU=x86_64 USE_PCRE=1
else 
	make TARGET=linux26 CPU=686 USE_PCRE=1
fi

make install
ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy

# grab carlo's haproxyctl script/init
cd /usr/local
git clone https://github.com/flores/haproxyctl.git
ln -s /usr/local/haproxyctl/haproxyctl.rb /etc/init.d/haproxyctl

# remove make and gcc
if [ $OS = 'redhat' ]; then
	chkconfig --add haproxyctl;
	yum remove -y gcc make
elif [ $OS = 'debian' ]; then
	apt-get purge build-essential
fi
