#!/bin/bash

USERNAME=$(</dev/urandom tr -dc '12345qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c10; echo "")
PASSWORD=$(</dev/urandom tr -dc '12345qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c20; echo "")
NETWORKNAME="vivonet"
DAEMONNAME="vivo-vivod-1"
SENTINELNAME="vivo-sentinel-1"
DAEMONIMAGE="vivocoin/vivo-vivod"
SENTINELIMAGE="vivocoin/vivo-sentinel"
PUBLICATION="12845:12845"
DOCKERPARAMS=

if [ "$(docker network ls --filter name=$NETWORKNAME -q)" = "" ]
then
	docker network create -d overlay $NETWORKNAME
fi
DOCKERPARAMS="$DOCKERPARAMS --network $NETWORKNAME"

MODE="swarm"
if [ "$MODE" = "swarm" ] && ! docker secret ls &>/dev/null
then
	MODE="env"
fi

if [ "$MODE" = "swarm" ]
then
	if [ "$(docker secret ls | grep vivo-rpcuser)" = "" ]
	then
		echo $USERNAME | docker secret create vivo-rpcuser -
	fi
	DOCKERPARAMS="$DOCKERPARAMS --secret vivo-rpcuser"
	
	if [ "$(docker secret ls | grep vivo-rpcpass)" = "" ]
	then
		echo $PASSWORD | docker secret create vivo-rpcpass -
	fi
	DOCKERPARAMS="$DOCKERPARAMS --secret vivo-rpcpass"

	docker service create $DOCKERPARAMS --name $DAEMONNAME --hostname $DAEMONNAME -p $PUBLICATION $DAEMONIMAGE
	docker service create $DOCKERPARAMS --name $SENTINELNAME --hostname $SENTINELNAME -e VIVO_HOSTNAME=$DAEMONNAME $SENTINELIMAGE
else
	DOCKERPARAMS="$DOCKERPARAMS -e VIVO_RPCUSER=$USERNAME"
	DOCKERPARAMS="$DOCKERPARAMS -e VIVO_RCPPASSWORD=$PASSWORD"

	docker create $DOCKERPARAMS --name $DAEMONNAME --hostname $DAEMONNAME -p $PUBLICATION $DAEMONIMAGE
	docker start $DAEMONNAME
	docker create $DOCKERPARAMS --name $SENTINELNAME --hostname $SENTINELNAME -e VIVO_HOSTNAME=$DAEMONNAME $SENTINELIMAGE
	docker start $SENTINELNAME
fi
