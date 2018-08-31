#!/bin/bash

curl https://get.acme.sh | /bin/bash
DOMAIN=vn.lamit.win
acme.sh --issue -d $DOMAIN -d *.$DOMAIN --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please --debug --renew
cp -rf ~/.acme.sh/$DOMAIN .
