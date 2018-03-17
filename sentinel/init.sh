#!/bin/sh

if [ ! -d /home/vivo/.vivocore ] || [ ! -f /home/vivo/.vivocore/vivo.conf ]
then
	sh /opt/wallet/vivo/sentinel/bootstrap.sh
fi

exec crond -f -l 2
