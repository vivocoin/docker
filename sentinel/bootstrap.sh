#!/bin/sh

USERNAME=
PASSWORD=
VIVODHOST=

if [ -f /run/secrets/vivo-rpcuser ] && [ "$SECRET_OVERRIDE" = "0" ]
then
	USERNAME=$(cat /run/secrets/vivo-rpcuser)
else
	USERNAME=$VIVO_RPCUSER
fi

if [ -f /run/secrets/vivo-rpcpass ] && [ "$SECRET_OVERRIDE" = "0" ]
then
	PASSWORD=$(cat /run/secrets/vivo-rpcpass)
else
	PASSWORD=$VIVO_RCPPASSWORD
fi

VIVODHOST=$VIVO_HOSTNAME

mkdir /home/vivo/.vivocore
chmod 700 /home/vivo/.vivocore
echo "rpcuser=$USERNAME
rpcpassword=$PASSWORD
" > /home/vivo/.vivocore/vivo.conf
chmod 600 /home/vivo/.vivocore/vivo.conf

mkdir /home/vivo/sentinel
mkdir /home/vivo/sentinel/database
echo "vivo_conf=/home/vivo/.vivocore/vivo.conf
vivo_host=$VIVODHOST

network=mainnet
db_name=/home/vivo/sentinel/database/sentinel.db
db_driver=sqlite
" >> /home/vivo/sentinel/sentinel.conf
chmod 600 /home/vivo/sentinel/sentinel.conf

chown vivo: -R /home/vivo

crontab -u vivo /opt/wallet/vivo/sentinel/crontab
