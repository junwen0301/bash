#!/bin/bash


NAME=rps
DESC=rps

# cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# cpupower frequency-set -g performance
# activate rps/rfs by script: https://gist.github.com/wsgzao/18828f69147635f3e38a14690a633daf
# double ring buffer size: ethtool -G p1p1 [rx|tx] 4096, ethtool -g p1p1
# double NAPI poll budget: sysctl -w net.core.netdev_budget=600

rps() {
  net_interface=`ip link show | grep "state UP" | awk '{print $2}' | egrep -v '^docker|^veth' | tr ":\n" " "`
  cpu_num=`cat /proc/cpuinfo |grep "processor"|wc -l`
  if [ $cpu_num == 1 ]
  then
      return
  fi
  info=0
  for ((k=0; k<$cpu_num; k++))
  do
      info=$(($info+$((1<<k))))
  done
  info=`printf %x $info`
  for em in ${net_interface[@]}
  do
      rq_count=`ls /sys/class/net/$em/queues/rx-* -d | wc -l`
      rps_flow_cnt_value=`expr 32768 / $rq_count`

      for ((i=0; i< $rq_count; i++))
      do
          echo $rps_flow_cnt_value > /sys/class/net/$em/queues/rx-$i/rps_flow_cnt
      done

      flag=0
      while [ -f /sys/class/net/$em/queues/rx-$flag/rps_cpus ]
      do
          echo $info >  /sys/class/net/$em/queues/rx-$flag/rps_cpus
          flag=$(($flag+1))
      done
  done
  echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
  sysctl -p
}

check_rps() {
  ni_list=`ip link show | grep "state UP" | awk '{print $2}' | egrep -v "^docker|^veth" | tr ":\n" " "`
  for n in $ni_list
  do
      rx_queues=`ls /sys/class/net/$n/queues/ | grep "rx-[0-9]"`
      for q in $rx_queues
      do
          rps_cpus=`cat /sys/class/net/$n/queues/$q/rps_cpus`
          rps_flow_cnt=`cat /sys/class/net/$n/queues/$q/rps_flow_cnt`

          echo "[$n]" $q "--> rps_cpus =" $rps_cpus ", rps_flow_cnt =" $rps_flow_cnt
      done
  done
  rps_sock_flow_entries=`cat /proc/sys/net/core/rps_sock_flow_entries`
  echo "rps_sock_flow_entries =" $rps_sock_flow_entries
  if [ $rps_sock_flow_entries -eq 0 ]; then
      rps
  fi
}

stop_rps() {
  cpu_num=`cat /proc/cpuinfo |grep "processor"|wc -l`
  if [ $cpu_num == 1 ]
  then
      return
  fi
  info=$(($cpu_num/4))
  if [ $(($cpu_num%4)) -gt 0 ]
  then
      info=$(($info+1))
  fi
  for ((i=0; i< $info; i++))
  do
      info_out=${info_out}0
  done
  net_interface=`ip link show | grep "state UP" | awk '{print $2}' | egrep -v '^docker|^veth' | tr ":\n" " "`
  for em in ${net_interface[@]}
  do
      echo 0 | tee /sys/class/net/$em/queues/*/rps_flow_cnt
      echo $info_out | tee /sys/class/net/$em/queues/*/rps_cpus
  done
  echo 0 > /proc/sys/net/core/rps_sock_flow_entries
  sysctl -p
}

case "$1" in
  start)
        echo -n "Starting $DESC: "
        rps
        check_rps
        ;;
  stop)
        echo -n "Stoping $DESC. "
	stop_rps
	check_rps
        ;;
  restart|reload|force-reload)
        echo -n "Restart is not supported. "
        ;;
  status)
        check_rps
        ;;
  *)
        echo "Usage: $0 [start|status]"
        ;;
esac

exit 0
