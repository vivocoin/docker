#!/bin/sh

if [ ! -d /home/vivo/.vivocore ] || [ ! -f /home/vivo/.vivocore/vivo.conf ]
then
	sh /opt/wallet/vivo/bootstrap.sh
fi

exec su -l vivo -s /bin/sh -c "exec /opt/wallet/vivo/vivod $@"
