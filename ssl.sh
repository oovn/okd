#!/bin/bash

curl https://get.acme.sh | /bin/bash
DOMAIN=lamit.win
acme.sh --issue -d $DOMAIN -d *.$DOMAIN -d *.apps.$DOMAIN --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please --debug --renew
cp -rf ~/.acme.sh/$DOMAIN .
