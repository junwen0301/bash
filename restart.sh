#!/usr/bin/env bash
echo `ps -ef | grep ' [g]ost' | cut -c 9-15| xargs kill -s 9`
TMP=`cat /etc/rc.local|grep gost`
echo '#!/usr/bin/env bash' > /root/tmp.sh
echo "${TMP}" >> /root/tmp.sh
chmod +x /root/tmp.sh
bash /root/tmp.sh
rm -f /root/tmp.sh
ps -ef | grep '[g]ost'
