#!/bin/bash
#uuid=$(uuidgen)
MYBACKUPDIR=./backup/$(hostname)/$(date +%Y%m%d)
rpm -qa | sort | sudo tee $MYBACKUPDIR/packages.txt
sudo mkdir -p ${MYBACKUPDIR}/etc/sysconfig
sudo mkdir -p ${MYBACKUPDIR}/etc/pki/ca-trust/source/anchors
sudo cp -aR /etc/sysconfig/{iptables,docker-*} ${MYBACKUPDIR}/etc/sysconfig/
sudo cp -aR /etc/dnsmasq* /etc/cni ${MYBACKUPDIR}/etc/
#sudo cp -aR /etc/pki/ca-trust/source/anchors/* ${MYBACKUPDIR}/etc/pki/ca-trust/source/anchors/
