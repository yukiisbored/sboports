#!/bin/bash
mkdir -p /var/log/packages
mkdir -p /home/travis/build/pink-mist/sbotools/cover_db
touch "/var/log/packages/aaa_base-14.1-x86_64-1"
cp -a t/travis-deps/*pkg /sbin/
echo "127.0.0.1 slackware.uk" >> /etc/hosts
mkdir -p /usr/sbo/repo
touch "/usr/sbo/repo/SLACKBUILDS.TXT"

if [ "$TEST_MULTILIB" = "1" ]
then
	mkdir -p /etc/profile.d/
	touch /etc/profile.d/32dev.sh
elif [ "$TEST_MULTILIB" = "2" ]
then
	mkdir -p /etc/profile.d/ /usr/sbin/
	touch /etc/profile.d/32dev.sh
	cp -a t/travis-deps/convertpkg-compat32 /usr/sbin
fi
git config --global user.email "sbotools@gitlab.com"
git config --global user.name "GitLab CI"
echo "travis-deps/install.sh: Done.";
