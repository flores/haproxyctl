#!/bin/bash -ex

# make sure we have make, pcre and junk
if [ -e /etc/redhat-release ]; then
	OS=redhat;
elif [ -e /etc/debian_version ]; then
	OS=debian;
fi

if [ $OS ]; then
	if [ $OS = 'redhat' ]; then
		yum install -y pcre-devel make gcc libgcc git;
	elif [ $OS = 'debian' ]; then
		apt-get update;
		apt-get install -y libpcre3 libpcre3-dev build-essential libgcc1 git;
	fi
else
	echo -e "I only understand Debian/RedHat/CentOS and this box does not appear to be any.\nExiting.\n- love, $0.";
	exit 2;
fi

# grab last stable.  HAProxy's site versions nicely - these will still be here after the next update
mkdir /usr/local/src || echo "Oops, /usr/local/src exists!"
cd /usr/local/src || exit 2
wget http://haproxy.1wt.eu/download/1.4/src/haproxy-1.4.20.tar.gz

# check the checksum
MD5CHECK=`md5sum /usr/local/src/haproxy-1.4.20.tar.gz |awk '{print $1}'`
if [ "$MD5CHECK" != "0cd3b91812ff31ae09ec4ace6355e29e" ] ; then
        echo -e "MD5s do not match!\nBailing.";
        exit 2;
fi

tar xvfz haproxy-1.4.20.tar.gz
cd haproxy-1.4.20

if uname -a | grep x86_64 ; then
	make TARGET=linux26 CPU=x86_64 USE_PCRE=1
else 
	make TARGET=linux26 CPU=686 USE_PCRE=1
fi

make install

if [ -e /usr/sbin/haproxy ]; then
  rm -f /usr/sbin/haproxy
fi
  
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
	apt-get purge -y build-essential
fi
