#!/bin/bash
export INTERACTIVE=true;
export VERSION=${VERSION:="3.10"}
export DOMAIN=${DOMAIN:="$(curl -s ipinfo.io/ip).nip.io"}
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"}

## check for '-a' flag with getopts
while getopts a o; do case $o in (a) INTERACTIVE=false; esac done
## Make the script interactive to set the variables
if $INTERACTIVE ; then
	read -rp "Domain to use: ($DOMAIN): " choice;
	if [ "$choice" != "" ] ; then
		export DOMAIN="$choice";
	fi
	read -rp "OpenShift Version: ($VERSION): " choice;
	if [ "$choice" != "" ] ; then
		export VERSION="$choice";
	fi
	read -rp "IP: ($IP): " choice;
	if [ "$choice" != "" ] ; then
		export IP="$choice";
	fi
	echo
fi
#ssh
if [ ! -f ~/.ssh/id_rsa ]; then
	ssh-keygen -q -f ~/.ssh/id_rsa -N ""
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	ssh -o StrictHostKeyChecking=no root@$IP "pwd" < /dev/null
fi
# install the following base packages
if [ ! -f /etc/yum.repos.d/origin.repo ]; then
	yum install -y  wget nano
	cd /etc/yum.repos.d
	wget https://github.com/openshift/origin/releases/download/v3.10.0/origin.repo
	cd
fi
yum update -y
yum -y install atomic-openshift-utils openshift-ansible ansible pyOpenSSL python-cryptography python-lxml python2-pip python-devel python-passlib java-1.8.0-openjdk-headless httpd-tools
# openshift-ansible
[ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible && git fetch && git checkout release-${VERSION} && cd ..
# edit /etc/hosts
cat <<EOD > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${IP}		${DOMAIN} 
EOD
# add ${DOMAIN}.ini
echo "#auto" > ${DOMAIN}.ini
cat <<EOD > ./${DOMAIN}.ini
#autogen ${DOMAIN}.ini
[OSEv3:children]
masters
nodes
etcd
nfs
[masters]
${DOMAIN}
[etcd]
${DOMAIN}
[nfs]
${DOMAIN}
[nodes]
${DOMAIN} openshift_node_group_name="node-config-all-in-one" 
[OSEv3:vars]
ansible_ssh_user=root
openshift_deployment_type=origin
#openshift_public_hostname=${DOMAIN}
openshift_master_default_subdomain=${DOMAIN}
os_sdn_network_plugin_name='redhat/openshift-ovs-multitenant'
osm_use_cockpit=True
containerized=True
#openshift_master_cluster_method=native
openshift_master_cluster_hostname=${DOMAIN}
#openshift_master_cluster_public_hostname=${DOMAIN}
#openshift_master_ca_certificate={'cafile':'/root/$DOMAIN/ca.cer','certfile':'/root/$DOMAIN/$DOMAIN.cer','keyfile':'/root/$DOMAIN/$DOMAIN.key'}
#openshift_master_overwrite_named_certificates=true
#openshift_master_named_certificates=[{'cafile':'/root/$DOMAIN/ca.cer','certfile':'/root/$DOMAIN/$DOMAIN.cer','keyfile':'/root/$DOMAIN/$DOMAIN.key','name':['${DOMAIN}']}]
#openshift_hosted_router_certificate={'cafile':'/root/$DOMAIN/ca.cer','certfile':'/root/$DOMAIN/$DOMAIN.cer','keyfile':'/root/$DOMAIN/$DOMAIN.key'}
openshift_master_identity_providers=[{'name':'htpasswd_auth','login':'true','challenge':'true','kind':'HTPasswdPasswordIdentityProvider'}]
openshift_disable_check=disk_availability,docker_storage,memory_availability,docker_image_availability
openshift_metrics_install_metrics=true
openshift_logging_install_logging=false
EOD
# run check
ansible-playbook -i ${DOMAIN}.ini openshift-ansible/playbooks/prerequisites.yml
# run deploy
ansible-playbook -i ${DOMAIN}.ini openshift-ansible/playbooks/deploy_cluster.yml
