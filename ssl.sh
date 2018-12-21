#!/bin/bash

export DOMAIN=lamit.win
export MAIL=info@lamit.win
#####################
# Enabled EPEL Repo
sed -i '6 s/^.*$/enabled=1/' /etc/yum.repos.d/epel.repo

# Install CertBot
yum install -y certbot

# Configure Let's Encrypt certificate
certbot certonly --manual \
                 --preferred-challenges dns \
                 --email $MAIL \
                 --server https://acme-v02.api.letsencrypt.org/directory \
                 --agree-tos \
                 -d $DOMAIN \
                 -d *.$DOMAIN \
                 -d *.apps.$DOMAIN \

## Add Entries on your Host DNS Zone Editor
## Ex: 
##     Name: _acme-challenge.yourdomain.com | Type: TXT | Data: xjPMg-I6BokgUVOyIN3NJlIqbc9xGXUzyQE98dPdt1E
#####

# Add Cron Task to renew certificate
echo "@monthly  certbot renew --pre-hook=\"oc scale --replicas=0 dc router\" --post-hook=\"oc scale --replicas=1 dc router\"" > certbotcron
crontab certbotcron
rm certbotcron

# Repair openshift_metrics_schema_installer_image, see here for more information:
# https://github.com/openshift/origin-metrics/issues/429#issuecomment-418271287
cat <<EOT >> inventory.ini
openshift_master_overwrite_named_certificates=true
openshift_master_cluster_hostname=console-internal.${DOMAIN}
openshift_master_cluster_public_hostname=console.${DOMAIN}
openshift_master_named_certificates=[{"certfile": "/etc/letsencrypt/live/${DOMAIN}/cert.pem", "keyfile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem", "names": ["console.${DOMAIN}"]}]
openshift_hosted_router_certificate={"certfile": "/etc/letsencrypt/live/${DOMAIN}/cert.pem", "keyfile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem", "cafile": "/etc/letsencrypt/live/${DOMAIN}/chain.pem"}
openshift_hosted_registry_routehost=registry.apps.${DOMAIN}
openshift_hosted_registry_routecertificates={"certfile": "/etc/letsencrypt/live/${DOMAIN}/cert.pem", "keyfile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem", "cafile": "/etc/letsencrypt/live/${DOMAIN}/chain.pem"}
openshift_hosted_registry_routetermination=reencrypt
openshift_metrics_schema_installer_image=docker.io/alv91/origin-metrics-schema-installer:v3.10
EOT

ansible-playbook -i inventory.ini openshift-ansible/playbooks/redeploy-certificates.yml
