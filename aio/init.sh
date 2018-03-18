#!/bin/sh

. /opt/wallet/vivo/function.sh

if [ ! -d /home/vivo/.vivocore ] || [ ! -f /home/vivo/.vivocore/vivo.conf ]
then
	sh /opt/wallet/vivo/bootstrap.sh
fi

STATUS=0

su -l vivo -s /bin/sh -c "/opt/wallet/vivo/vivod -daemon -printtoconsole"
crond -l 2

trap stopcont 15

while sleep 5
do
	ps | grep vivod | grep -v grep &>/dev/null
	VIVOD_STATUS=$?
	ps | grep crond | grep -v grep &>/dev/null
	CRON_STATUS=$?
	if [ $VIVOD_STATUS -ne 0 -o $CRON_STATUS -ne 0 ]
	then
		echo "vivod or crond exited!"
		STATUS=1
		break
	fi
done

stopcont
exit $STATUS
