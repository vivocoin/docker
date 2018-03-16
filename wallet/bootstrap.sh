#!/bin/sh

. /opt/wallet/vivo/function.sh

USERNAME=
PASSWORD=

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

mkdir /home/vivo/.vivocore
chmod 700 /home/vivo/.vivocore
echo "rpcuser=$USERNAME
rpcpassword=$PASSWORD
rpcbind=[::]
rpcallowip=::/0
" > /home/vivo/.vivocore/vivo.conf
chmod 600 /home/vivo/.vivocore/vivo.conf

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
	timeout -t 30 su -l vivo -s /bin/sh -c "/opt/wallet/vivo/vivod -printtoconsole"
	while :
	do
		if [ "$(ps | grep vivod)" = "" ]
		then
			break
		fi
		sleep 1
		killall vivod
	done
	checkdat
fi

chmod o-rwx -R /vivo /home/vivo
chown vivo: -R /vivo /home/vivo
