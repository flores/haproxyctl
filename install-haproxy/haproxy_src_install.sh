#!/bin/bash
#
# This installs latest HAProxy from source along with HAProxyCTL
#
# It will clobber files and stuff and is only meant as a very
# quick and dirty (but sometimes handy) installer.
#

HAPROXYVER="1.5.3"
MD5EXPECTED="e999a547d57445d5a5ab7eb6a06df9a1"
STARTINGDIR=$PWD

# make sure we have make, pcre and junk
if [[ -e /etc/redhat-release ]]; then
  OS=redhat;
elif [[ -e /etc/debian_version ]]; then
  OS=debian;
fi

if [[ -n $OS ]]; then
  if [[ ${OS} == 'redhat' ]]; then
    yum install -y pcre-devel make gcc libgcc git;
  elif [[ ${OS} == 'debian' ]]; then
    apt-get update;
    apt-get install -y libpcre3 libpcre3-dev build-essential libgcc1 git;
  fi
else
  echo -e "I only understand Debian/RedHat/CentOS and this box does not appear to be any.\nExiting.";
  exit 2;
fi

# grab last stable.  HAProxy's site versions nicely - these will still be here after the next update
echo "I will try to build in /usr/local/src"
mkdir /usr/local/src || echo "Oops, /usr/local/src exists!"
cd /usr/local/src || exit 2
if [[ -e /usr/local/src/haproxy-${HAPROXYVER}.tar.gz ]]; then
  echo "using the existing haproxy-$HAPROXYVER.tar.gz.  If you have problems maybe rm it and we will grab it again"
else
  echo "I am grabbing ${HAPROXYVER} and will expand it under /usr/local/src/haproxy-${HAPROXYVER}"
  wget http://haproxy.1wt.eu/download/1.5/src/haproxy-$HAPROXYVER.tar.gz
fi


# check the checksum
echo "Verifying the md5"
MD5CHECK=$(md5sum /usr/local/src/haproxy-${HAPROXYVER}.tar.gz |awk '{print $1}')
if [[ ${MD5CHECK} != ${MD5EXPECTED} ]] ; then
  echo -e "MD5s do not match!\nBailing.";
  exit 2;
fi

tar xvfz haproxy-${HAPROXYVER}.tar.gz
rm haproxy-${HAPROXYVER}.tar.gz

cd haproxy-${HAPROXYVER}

echo "Making it!"
if uname -a | grep x86_64 ; then
  make TARGET=linux26 CPU=x86_64 USE_PCRE=1 || exit 2
else
  make TARGET=linux26 CPU=686 USE_PCRE=1 || exit 2
fi

if [[ -e /usr/local/haproxy ]]; then
  echo "Removing old haproxy from /usr/local/haproxy"
  rm -fr /usr/local/haproxy
fi

echo "Make installing!"
make install

if [[ -e /usr/sbin/haproxy ]]; then
  echo "Removing /usr/sbin/haproxy"
  rm -f /usr/sbin/haproxy
fi

echo "Symlinking /usr/local/sbin/haproxy to /usr/sbin/haproxy"
ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy

echo "Grabbing latest haproxyctl"
if [[ -e /usr/local/haproxyctl ]]; then
  cd /usr/local/haproxyctl;
  git pull;
else
  cd /usr/local
  git clone https://github.com/flores/haproxyctl.git
fi

echo "dropping it into /etc/init.d/haproxyctl"
ln -s /usr/local/haproxyctl/haproxyctl /etc/init.d/haproxyctl || exit 2

echo "removing make and gcc"
if [[ ${OS} == 'redhat' ]]; then
  chkconfig --add haproxyctl;
  yum remove -y gcc make
elif [[ ${OS} == 'debian' ]]; then
  apt-get purge -y build-essential
fi

cd $STARTINGDIR
echo "I think it is all done!"
