#!/usr/bin/env bash
check_status(){
	kernel_version=`uname -r | awk -F "-" '{print $1}'`
	kernel_version_full=`uname -r`
	if [[ ${kernel_version_full} = "4.14.129-bbrplus" ]]; then
		kernel_status="BBRplus"
	elif [[ ${kernel_version} = "3.10.0" || ${kernel_version} = "3.16.0" || ${kernel_version} = "3.2.0" || ${kernel_version} = "4.4.0" || ${kernel_version} = "3.13.0"  || ${kernel_version} = "2.6.32" || ${kernel_version} = "4.9.0" ]]; then
		kernel_status="Lotserver"
	elif [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "4" ]] && [[ `echo ${kernel_version} | awk -F'.' '{print $2}'` -ge 9 ]] || [[ `echo ${kernel_version} | awk -F'.' '{print $1}'` == "5" ]]; then
		kernel_status="BBR"
	else 
		kernel_status="noinstall"
	fi

	if [[ ${kernel_status} == "Lotserver" ]]; then
		if [[ -e /appex/bin/lotServer.sh ]]; then
			run_status=`bash /appex/bin/lotServer.sh status | grep "LotServer" | awk  '{print $3}'`
			if [[ ${run_status} = "running!" ]]; then
				run_status="1"
			else 
				run_status="0"
			fi
		elif [[ -e /appex/bin/serverSpeeder.sh ]]; then
			run_status=`bash /appex/bin/serverSpeeder.sh status | grep "ServerSpeeder" | awk  '{print $3}'`
			if [[ ${run_status} = "running!" ]]; then
				run_status="1"
			else 
				run_status="0"
			fi
		else 
			run_status="0"
		fi
	elif [[ ${kernel_status} == "BBR" ]]; then
		run_status=`sysctl net.ipv4.tcp_congestion_control | awk -F "= " '{print $2}'`
		if [[ ${run_status} == "bbr" ]]; then
			run_status=`lsmod | grep "bbr" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_bbr" || `sysctl net.core.default_qdisc|awk -F "= " '{print $2}'` == "fq" ]]; then
				run_status="2"
			else 
				run_status="0"
			fi
		elif [[ ${run_status} == "bbr2" ]]; then
			if [[ `sysctl net.core.default_qdisc|awk -F "= " '{print $2}'` =~ "fq" ]]; then
				run_status="7"
			else 
				run_status="0"
			fi
		elif [[ ${run_status} == "tsunami" ]]; then
			run_status=`lsmod | grep "tsunami" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_tsunami" ]]; then
				run_status="3"
			else 
				run_status="0"
			fi
		elif [[ ${run_status} == "nanqinlang" ]]; then
			run_status=`lsmod | grep "nanqinlang" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_nanqinlang" ]]; then
				run_status="4"
			else 
				run_status="0"
			fi
		else 
			run_status="0"
		fi
	elif [[ ${kernel_status} == "BBRplus" ]]; then
		run_status=`sysctl net.ipv4.tcp_congestion_control | awk -F "= " '{print $2}'`
		if [[ ${run_status} == "bbrplus" ]]; then
			run_status=`lsmod | grep "bbrplus" | awk '{print $1}'`
			if [[ ${run_status} == "tcp_bbrplus" ]]; then
				run_status="6"
			else 
				run_status="0"
			fi
		else 
			run_status="0"
		fi
	fi
}
check_status
echo ${run_status}
