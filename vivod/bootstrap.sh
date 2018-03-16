#!/bin/sh

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

mkdir $HOME/.vivocore
chmod 700 $HOME/.vivocore
echo "disablewallet=1
enableprivatesend=0
#enableinstantsend=0
rpcuser=$USERNAME
rpcpassword=$PASSWORD
rpcbind=[::]
rpcallowip=::/0
" > $HOME/.vivocore/vivo.conf
chmod 600 $HOME/.vivocore/vivo.conf
