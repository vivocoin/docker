#!/bin/sh

. /opt/wallet/vivo/function.sh

USERNAME=
PASSWORD=
MNPRIVKEY=
EXTERNALIP=

if [ -f /run/secrets/vivo-rpcuser ] && [ $SECRET_OVERRIDE = 0 ]
then
	USERNAME=$(cat /run/secrets/vivo-rpcuser)
else
	USERNAME=$VIVO_RPCUSER
fi

if [ -f /run/secrets/vivo-rpcpass ] && [ $SECRET_OVERRIDE = 0 ]
then
	PASSWORD=$(cat /run/secrets/vivo-rpcpass)
else
	PASSWORD=$VIVO_RCPPASSWORD
fi

if [ -f /run/secrets/vivo-mnprivkey ] && [ $SECRET_OVERRIDE = 0 ]
then
	MNPRIVKEY=$(cat /run/secrets/vivo-mnprivkey)
else
	MNPRIVKEY=$VIVO_MNPRIVKEY
fi

if [ -f /run/secrets/vivo-externalip ] && [ $SECRET_OVERRIDE = 0 ]
then
	MNPRIVKEY=$(cat /run/secrets/vivo-externalip)
else
	EXTERNALIP=$VIVO_EXTERNALIP
fi

# vivo.conf
mkdir /home/vivo/.vivocore
chmod 700 /home/vivo/.vivocore
echo -n "rpcuser=$USERNAME
rpcpassword=$PASSWORD
rpcbind=[::]
rpcallowip=::/0

masternode=1
masternodeprivkey=$MNPRIVKEY
externalip=$EXTERNALIP
" > /home/vivo/.vivocore/vivo.conf
chmod 600 /home/vivo/.vivocore/vivo.conf

# sentinel.conf
mkdir /home/vivo/sentinel
mkdir /home/vivo/sentinel/database
echo -n "vivo_conf=/home/vivo/.vivocore/vivo.conf

network=mainnet
db_name=/home/vivo/sentinel/database/sentinel.db
db_driver=sqlite
" >> /home/vivo/sentinel/sentinel.conf
chmod 600 /home/vivo/sentinel/sentinel.conf

[ ! -d /vivo/blocks ] && mkdir /vivo/blocks
ln -s /vivo/blocks /home/vivo/.vivocore/blocks
[ ! -d /vivo/chainstate ] && mkdir /vivo/chainstate
ln -s /vivo/chainstate /home/vivo/.vivocore/chainstate
[ ! -d /vivo/database ] && mkdir /vivo/database
ln -s /vivo/database /home/vivo/.vivocore/database

chmod o-rwx -R /vivo /home/vivo
chown vivo: -R /vivo /home/vivo

# HACK!
if ! checkdat
then
	timeout -t 5 su -l vivo -s /bin/sh -c "/opt/wallet/vivo/vivod -printtoconsole -disablewallet=1"
	while :
	do
		if [ "$(ps | grep vivod | grep -v grep)" = "" ]
		then
			break
		fi
		sleep 1
		killall vivod &>/dev/null
	done
	checkdat
fi

crontab -u vivo /opt/wallet/vivo/sentinel/crontab

chmod o-rwx -R /vivo /home/vivo
chown vivo: -R /vivo /home/vivo
