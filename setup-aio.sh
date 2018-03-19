#!/bin/bash

RPCUSERNAME=
RPCPASSWORD=
# only modify these option if you know what you are doing or you have been asked to
VIVONETPORT=12845
VIVORPCPORT=9998
BINDIP=
MODE="env" # if you use a docker swarm setup, write "swarm" here

# !!! ONLY FOR DEBUGGING !!!
DEBUG=0

function checkip()
{
	local OCTET1=$(echo $1 | cut -d. -f1)
	local OCTET2=$(echo $1 | cut -d. -f2)
	local OCTET3=$(echo $1 | cut -d. -f3)
	local OCTET4=$(echo $1 | cut -d. -f4)
	if [ $OCTET1 -lt 0 ] || [ $OCTET1 -gt 255 ]
	then
		echo "Invalid first IP octet, <0 or >255"
		return 1
	fi
	if [ $OCTET2 -lt 0 ] || [ $OCTET2 -gt 255 ]
	then
		echo "Invalid second IP octet, <0 or >255"
		return 1
	fi
	if [ $OCTET3 -lt 0 ] || [ $OCTET3 -gt 255 ]
	then
		echo "Invalid third IP octet, <0 or >255"
		return 1
	fi
	if [ $OCTET4 -lt 0 ] || [ $OCTET4 -gt 255 ]
	then
		echo "Invalid fourth IP octet, <0 or >255"
		return 1
	fi

	return 0
}

function isrouteable()
{
	if ! checkip $1
	then
		echo "Invlid IP address given"
		return 1
	fi
	local OCTET1=$(echo $1 | cut -d. -f1)
	local OCTET2=$(echo $1 | cut -d. -f2)
	local OCTET3=$(echo $1 | cut -d. -f3)
	local OCTET4=$(echo $1 | cut -d. -f4)
	# 0.0.0.0 - 0.255.255.255
	if [ "$OCTET1" = "0" ]
	then
		return 1
	# 10.0.0.0 - 10.255.255.255 RFC1918
	elif [ "$OCTET1" = "10" ]
	then
		return 1
	# 100.64.0.0 - 10.127.255.255
	elif [ "$OCTET1" = "100" ]
	then
		if [ $OCTET2 -ge 64 ] && [ $OCTET2 -le 127 ]
		then
			return 1
		fi
	# 127.0.0.0 - 127.255.255.255 AKA Loopback
	elif [ "$OCTET1" = "127" ]
	then
		return 1
	# 169.254.0.0 - 169.254.255.255 AKA Link-Local (APIPA)
	elif [ "$OCTET1" = "169" ]
	then
		if [ "$OCTET2" = "254" ]
		then
			return 1
		fi
	# 172.16.0.0 - 172.31.255.255 RFC1918
	elif [ "$OCTET1" = "172" ]
	then
		if [ $OCTET2 -ge 16 ] && [ $OCTET2 -le 31 ]
		then
			return 1
		fi
	# 192.0.0.0 - 192.255.255.255 multiple
	elif [ "$OCTET1" = "192" ]
	then
		if [ "$OCTET2" = "0" ]
		then
			# 192.0.0.0 - 192.0.0.255
			if [ "$OCTET3" = "0" ]
			then
				return 1
			# 192.0.2.0 - 192.0.2.255 TEST-NET-1
			elif [ "$OCTET3" = "2" ]
			then
				return 1
			fi
		elif [ "$OCTET2" = "88" ]
		then
			# 192.88.99.0 - 192.88.99.255 6to4 anycast
			if [ "$OCTET3" = "99" ]
			then
				return 1
			fi
		# 192.168.0.0 - 192.168.255.255 RFC1918
		elif [ "$OCTET2" = "168" ]
		then
			return 1
		fi
	# 198.0.0.0 - 198.255.255.255 multiple
	elif [ "$OCTET1" = "198" ]
	then
		# 198.18.0.0 - 198.19.0.0
		if [ $OCTET2 -ge 18 ] && [ $OCTET2 -le 19 ]
		then
			return 1
		# 198.51.100.0 - 192.51.100.255 TEST-NET-2
		elif [ "$OCTET2" = "51" ]
		then
			if [ "$OCTET3" = "100" ]
			then
				return 1
			fi
		fi
	# 203.0.113.0 - 203.0.113.255 TEST-NET-3
	elif [ "$OCTET1" = "203" ]
	then
		if [ "$OCTET2" = "0" ]
		then
			if [ "$OCTET3" = "113" ]
			then
				return 1
			fi
		fi
	# 224.0.0.0 - 239.255.255.255 multicast
	elif [ $OCTET1 -ge 224 ] && [ $OCTET1 -le 239 ]
	then
		return 1
	# 240.0.0.0 - 255.255.255.255
	elif [ $OCTET1 -ge 240 ] && [ $OCTET1 -le 255 ]
	then
		return 1
	fi

	return 0
}

function checkport()
{
	local IP=$1
	local PORT=$2
	local NOBAIL=$3

	if ! checkip $IP
	then
		echo "Invlid IP address given"
		return 1
	fi

	local NSOUT=$(netstat -lnt 2>/dev/null | grep ":$PORT")
	# nothing is listening on $PORT
	if [ "$NSOUT" = "" ]
	then
		return 0
	else
		# something is litening on $IP:$PORT
		if echo $NSOUT | grep $IP &>/dev/null
		then
			return 1
		# something is litening on 0.0.0.0:$PORT
		elif echo $NSOUT | grep "0.0.0.0" &>/dev/null
		then
			if [ "$NOBAIL" = "" ]
			then
				echo "Something using \"$PORT\" on all IP addresses, bailing"
				echo "If you already have a masternode, specify \"bind=externalip:$VIVONETPORT\" in the currently running masternode's vivo.conf and restart it"
				exit 1
			else
				return 1
			fi
		# $IP:$PORT free
		else
			return 0
		fi
	fi
}

function discoverip()
{
	local HTTPOUT=$(wget http://canihazip.com/s -O - 2>/dev/null)
	if [ "$HTTPOUT" = "" ]
	then
		return
	fi
	if ! checkport $HTTPOUT $VIVONETPORT 1>&2
	then
		return
	else
		echo $HTTPOUT
	fi
}

if [ ! "$UID" = 0 ]
then
	echo "This script must be run as root"
	exit 1
fi

# check dependencies
if ! which docker &>/dev/null
then
	echo "docker not installed"
	echo "If you want to install docker press enter, otherwise press Ctrl+C"
	read < /proc/self/fd/2
	wget -q http://get.docker.com/ -O - | sh
fi
if ! which docker-init &>/dev/null
then
	echo "docker-init not found in PATH"
	echo "You may have an older version of docker which doesnt include tini as an init"
	echo "Please install a newer version of docker or put docker-init in PATH"
	exit 1
fi

EXIP=
BIND=0.0.0.0
if [ ! "$BINDIP" = "" ]
then
	if ! checkip $BINDIP
	then
		echo "Invalid IP address given to configuration"
		exit 1
	fi
	BIND=$BINDIP
	if ! isrouteable $BIND
	then
		echo "Bind IP is not routable, discovering external IP..."
		EXIP=$(discoverip)
		if ! checkip $EXIP
		then
			echo "Could not detect external IP"
			EXIP=
		else
			echo "Using external IP: $EXIP"
		fi
	fi
else
	# detect external IP if any
	IFIPS=
	IFIPCNT=0
	CMDOUT=$(ip a || ifconfig)
	for ip in $(echo "$CMDOUT" | grep 'inet ' | tr -s ' ' | cut -d' ' -f3 | cut -d/ -f1)
	do
		if ! isrouteable $ip
		then
			echo "Non-routable IP: $ip"
			continue
		fi
		if ! checkport $ip $VIVONETPORT
		then
			echo "IP already occupied: $ip"
			continue
		fi
		if [ "$IFIPS" = "" ]
		then
			IFIPS=$ip
		else
			IFIPS="$IFIPS $ip"
		fi
		IFIPCNT=$(($IFIPCNT + 1))
		
	done
	
	# do we have an IP or are we behind NAT?
	HASIP=0
	if [ "$IFIPCNT" = "0" ]
	then
		echo "No external IP addresses found attached to network interfaces, trying to find actual external IP..."
		HTTPOUT=$(wget http://canihazip.com/s -O - 2>/dev/null)
		if [ "$HTTPOUT" = "" ]
		then
			echo "Failed to detect external IP"
		elif ! checkport $HTTPOUT $VIVONETPORT
		then
			echo "Detected external IP is in use or invalid"
		else
			echo "Detected external IP: $HTTPOUT"
			IFIPCNT=1
			IFIPS=$HTTPOUT
		fi
	else
		HASIP=1
	fi
	
	if [ $IFIPCNT -eq 0 ]
	then
		echo "No free external IP address found on your system, please provide your external IP:"
		while :
		do
			echo -n "External IP: "
			read EXIP < /proc/self/fd/2
			if ! isroutable $EXIP
			then
				echo "IP address \"$EXIP\" is not routeable on the Internet"
				continue
			elif ! checkport $EXIP $VIVONETPORT
			then
				echo "IP address \"$EXIP\" already used"
				continue
			else
				echo "Using provided IP: $EXIP"
				break
			fi
		done
	elif [ $IFIPCNT -eq 1 ]
	then
		EXIP=$IFIPS
		echo "Only 1 usable external IP address found, using \"$EXIP\""
		if [ ! "$HASIP" = "0" ]
		then
			BIND=$EXIP
		fi
	else
		echo "Multiple external IP addresses detected, choose which you want to use for hosting VIVO"
		while :
		do
			CNT=0
			for ip in $IFIPS
			do
				CNT=$(($CNT + 1))
				echo "$CNT) $ip"
			done
			echo -n "Your choice: "
			read CHOICE < /proc/self/fd/2
			CNT=0
			IPCHOICE=
			for ip in $IFIPS
			do
				CNT=$(($CNT + 1))
				if [ "$CNT" = "$CHOICE" ]
				then
					IPCHOICE=$ip
				fi
			done
			if [ "$IPCHOICE" = "" ]
			then
				echo "Invalid choice, try again"
			else
				echo "You chose $IPCHOICE"
				EXIP=$IPCHOICE
				BIND=$IPCHOICE
				break
			fi
		done
	fi
fi

while :
do
	if ! checkport 127.0.0.1 $VIVORPCPORT true
	then
		VIVORPCPORT=$(($VIVORPCPORT + 1))
	else
		break
	fi
done

MNPK=
echo "Please generate a masternode private key and copy it here:"
while :
do
	if [ ! "$DEBUG" = 0 ]
	then
		MNPK=7eJ7wzphM58uhEW8Uvcii6uweKf2pgZHiuHSiX41RRR6RctTiaS
		break
	fi
	echo -n "MNPK: "
	read MNPK < /proc/self/fd/2
	if [ ! "$(echo -n $MNPK | wc -c)" = "51" ]
	then
		echo "Invalid masternode private key given, try again"
	else
		echo "OK"
		break
	fi
done

echo
echo

if [ "$RPCUSERNAME" = "" ]
then
	USERNAME=$(</dev/urandom tr -dc '12345qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c10)
	echo "Generated RPC username: $USERNAME"
else
	USERNAME=$RPCUSERNAME
	echo "Given RPC username: $USERNAME"
fi
if [ "$RPCPASSWORD" = "" ]
then
	PASSWORD=$(</dev/urandom tr -dc '12345qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c20)
	echo "Generated RPC password: $PASSWORD"
else
	PASSWORD=$RPCPASSWORD
	echo "Given RPC password: $PASSWORD"
fi

MNPRIVKEY=$MNPK
echo "Masternode private key: $MNPRIVKEY"
EXTERNALIP=$EXIP
echo "Used external IP: $EXTERNALIP"
echo "Used bind address: $BIND"
DAEMONIMAGE="vivocoin/aio"
PUBLICATION="-p $BIND:12845:12845 -p 127.0.0.1:$VIVORPCPORT:9998"
echo "VIVO RPC port: $VIVORPCPORT"
DAEMONIDX=1

DOCKERPARAMS=

if [ "$MODE" = "swarm" ] && ! docker secret ls &>/dev/null
then
	MODE="env"
fi

if [ "$MODE" = "swarm" ]
then
	# rpcuser=
	if [ "$(docker secret ls | grep vivo-rpcuser)" = "" ]
	then
		echo $USERNAME | docker secret create vivo-rpcuser -
	fi
	DOCKERPARAMS="$DOCKERPARAMS --secret vivo-rpcuser"

	# rpcpassword=
	if [ "$(docker secret ls | grep vivo-rpcpass)" = "" ]
	then
		echo $PASSWORD | docker secret create vivo-rpcpass -
	fi
	DOCKERPARAMS="$DOCKERPARAMS --secret vivo-rpcpass"

	# masternodeprivkey=
	if [ "$(docker secret ls | grep vivo-mnprivkey)" = "" ]
	then
		echo $MNPRIVKEY | docker secret create vivo-mnprivkey -
	fi
	DOCKERPARAMS="$DOCKERPARAMS --secret vivo-mnprivkey"

	# externalip=
	if [ "$(docker secret ls | grep vivo-externalip)" = "" ]
	then
		echo $EXTERNALIP | docker secret create vivo-externalip -
	fi
	DOCKERPARAMS="$DOCKERPARAMS --secret vivo-externalip"

	while :
	do
		if docker service ls | grep "vivo-mn-$DAEMONIDX" &>/dev/null
		then
			DAEMONIDX=$(($DAEMONIDX + 1))
		else
			break
		fi
	done

	DAEMONNAME="vivo-mn-$DAEMONIDX"
	echo "docker container name: $DAEMONNAME"
	VOLUME="vivo-mndata-$DAEMONIDX:/vivo"
	docker service create $DOCKERPARAMS --name $DAEMONNAME --hostname $DAEMONNAME -v $VOLUME $PUBLICATION $DAEMONIMAGE
else
	# rpcuser=
	DOCKERPARAMS="$DOCKERPARAMS -e VIVO_RPCUSER=$USERNAME"
	# rpcpassword=
	DOCKERPARAMS="$DOCKERPARAMS -e VIVO_RCPPASSWORD=$PASSWORD"
	# masternodeprivkey=
	DOCKERPARAMS="$DOCKERPARAMS -e VIVO_MNPRIVKEY=$MNPRIVKEY"
	# externalip=
	DOCKERPARAMS="$DOCKERPARAMS -e VIVO_EXTERNALIP=$EXTERNALIP"

	while :
	do
		if docker ps -a | grep "vivo-mn-$DAEMONIDX" &>/dev/null
		then
			DAEMONIDX=$(($DAEMONIDX + 1))
		else
			break
		fi
	done

	DAEMONNAME="vivo-mn-$DAEMONIDX"
	echo "docker container name: $DAEMONNAME"
	VOLUME="vivo-mndata-$DAEMONIDX:/vivo"
	docker create $DOCKERPARAMS --name $DAEMONNAME --hostname $DAEMONNAME -v $VOLUME $PUBLICATION $DAEMONIMAGE
	docker start $DAEMONNAME
fi
