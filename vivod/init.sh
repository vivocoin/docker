#!/bin/sh

if [ ! -d $HOME/.vivocore ] || [ ! -f $HOME/.vivocore/vivo.conf ]
then
	sh /opt/wallet/vivo/bootstrap.sh
fi

exec /opt/wallet/vivo/vivod $@
