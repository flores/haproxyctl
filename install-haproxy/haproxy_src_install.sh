#!/bin/bash -ex
#
# This installs latest HAProxy from source along with HAProxyCTL
#
# It will clobber files and stuff and is only meant as a very
# quick and dirty (but sometimes handy) installer.
#

HAPROXYVER="1.5.0"
MD5EXPECTED="e33bb97e644e98af948090f1ecebbda9"
STARTINGDIR=$PWD

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
wget http://haproxy.1wt.eu/download/1.5/src/haproxy-$HAPROXYVER.tar.gz

# get rid of an existing haproxy
if [ -e /usr/local/haproxy ]; then
  rm -fr /usr/local/haproxy
fi

# check the checksum
MD5CHECK=`md5sum /usr/local/src/haproxy-$HAPROXYVER.tar.gz |awk '{print $1}'`
if [ ${MD5CHECK} != ${MD5EXPECTED} ] ; then
        echo -e "MD5s do not match!\nBailing.";
        exit 2;
fi

tar xvfz haproxy-$HAPROXYVER.tar.gz
rm haproxy-$HAPROXYVER.tar.gz

cd haproxy-$HAPROXYVER

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
if [ -e /usr/local/haproxyctl ]; then
  cd haproxyctl;
  git pull;
else
  git clone https://github.com/flores/haproxyctl.git
  ln -s /usr/local/haproxyctl/haproxyctl /etc/init.d/haproxyctl
fi

# remove make and gcc
if [ $OS = 'redhat' ]; then
	chkconfig --add haproxyctl;
	yum remove -y gcc make
elif [ $OS = 'debian' ]; then
	apt-get purge -y build-essential
fi

cd $STARTINGDIR
