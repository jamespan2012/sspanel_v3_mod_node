#!/bin/bash
#2018-9-4 09:10:09 十一修改版
#blog：blog.67cc.cn

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Author:	wulabing
#	Dscription: SSR glzjin server for manyuser (only)
#	Version: 2.1
#	Blog: https://www.wulabing.com
#	Special thanks: Toyo
#====================================================

sh_ver="2.1.1"
libsodium_folder="/etc/libsodium"
shadowsocks_install_folder="/root"
shadowsocks_folder="${shadowsocks_install_folder}/shadowsocks"
config="${shadowsocks_folder}/userapiconfig.py"
debian_sourcelist="/etc/apt/source.list"

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"


#notification information
Info="${Green}[Info]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[Error]${Font}"
Notification="${Yellow}[Notification]${Font}"

check_system(){
	if [[ -f /etc/redhat-system ]]; then
		system="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		system="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		system="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		system="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		system="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		system="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		system="centos"
	else 
		system="other"
	fi
}
basic_installation(){
	if [[ ${system} == "centos" ]]; then
		yum -y install vim tar wget git 
	elif [[ ${system} == "debian" || ${system} == "ubuntu" ]]; then
		sed -i '/^deb cdrom/'d /etc/apt/sources.list
		apt-get update
		apt-get -y install vim tar wget git 
	else
		echo -e "${Error} Don't support this System"
		exit 1
	fi
}

dependency_installation(){
	if [[ ${system} == "centos" ]]; then
		yum -y install python-setuptools && easy_install pip
		yum -y install git
	elif [[ ${system} == "debian" || ${system} == "ubuntu" ]]; then
		apt-get -y install python-setuptools && easy_install pip
		apt-get -y install git
	fi
	
}
development_tools_installation(){
	if [[ ${system} == "centos" ]]; then
		yum -y groupinstall "Development Tools"
		if [[ $? -ne 0 ]]; then
			echo -e "${Error} Development Tools installation FAIL"
			exit 1
		fi
	else
		apt-get -y install build-essential 
		if [[ $? -ne 0 ]]; then
			echo -e "${Error} build-essential installation FAIL"
			exit 1
		fi
	fi
	
}
libsodium_installation(){
	mkdir -p ${libsodium_folder} && cd ${libsodium_folder}
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.13/libsodium-1.0.13.tar.gz
	if [[ ! -f ${libsodium_folder}/libsodium-1.0.13.tar.gz ]]; then
		echo -e "${Error} libsodium download FAIL"
		exit 1
	fi
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	if [[ $? -ne 0 ]]; then 
		echo -e "${Error} libsodium install FAIL"
		exit 1
	fi
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig

	rm -rf ${libsodium_folder}

}
SSR_dependency_installation(){
	if [[ ${system} == "centos" ]]; then
		cd ${shadowsocks_folder}
		yum -y install python-devel
		yum -y install libffi-devel
		yum -y install openssl-devel
		pip install requests
		pip install -r requirements.txt		
	else
		pip install cymysql
		pip install requests
	fi
}

modify_API(){
	sed -i '/API_INTERFACE/c \API_INTERFACE = '\'${API}\''' ${config}
}
modify_NODE_ID(){
	sed -i '/NODE_ID/c \NODE_ID = '${NODE_ID}'' ${config}
}
modify_SPEEDTEST(){
	sed -i '/SPEED/c \SPEEDTEST = '${SPEEDTEST}'' ${config}
}
modify_CLOUDSAFE(){
	sed -i '/CLOUD/c \CLOUDSAFE = '${CLOUDSAFE}'' ${config}
}
modify_MU_SUFFIX(){
	sed -i '/MU_SUFFIX/c \MU_SUFFIX = '\'${MU_SUFFIX}\''' ${config}
}
modify_MU_REGEX(){
	sed -i '/MU_REGEX/c \MU_REGEX = '\'${MU_REGEX}\''' ${config}
}
modify_WEBAPI_URL(){
	sed -i '/WEBAPI_URL/c \WEBAPI_URL = '\'${WEBAPI_URL}\''' ${config}
}
modify_WEBAPI_TOKEN(){
	sed -i '/WEBAPI_TOKEN/c \WEBAPI_TOKEN = '\'${WEBAPI_TOKEN}\''' ${config}
}
modify_MYSQL(){
	sed -i '/MYSQL_HOST/c \MYSQL_HOST = '\'${MYSQL_HOST}\''' ${config}
	sed -i '/MYSQL_PORT/c \MYSQL_PORT = '${MYSQL_PORT}'' ${config}
	sed -i '/MYSQL_USER/c \MYSQL_USER = '\'${MYSQL_USER}\''' ${config}
	sed -i '/MYSQL_PASS/c \MYSQL_PASS = '\'${MYSQL_PASS}\''' ${config}
	sed -i '/MYSQL_DB/c \MYSQL_DB = '\'${MYSQL_DB}\''' ${config}
}
selectApi(){
	echo -e "${Yellow}please select the api:${Font}"
	echo -e "1.modwebapi"
	echo -e "2.glzjinmod(mysql_connect)"
	stty erase '^H' && read -p "(default:modwebapi):" API
	if [[ -z ${API} || ${API} == "1" ]]; then
		API="modwebapi"
	elif [[ ${API} == "2" ]]; then
		API="glzjinmod"
	else
		echo -e "${Error} you can only select in 1 or 2"
		exit 1
	fi
}
common_set(){
	stty erase '^H' && read -p "NODE_ID(节点编号):" NODE_ID
    stty erase '^H' && read -p "SPEEDTEST_CIRCLE(测速周期，default:6):" SPEEDTEST
	[[ -z ${SPEEDTEST} ]] && SPEEDTEST="6"
	stty erase '^H' && read -p "CLOUDSAFE_ON(云安全，0 or 1,default:1):" CLOUDSAFE
	[[ -z ${CLOUDSAFE} ]] && CLOUDSAFE="1"
	stty erase '^H' && read -p "ANTISSATTACK(ss攻击抵抗，自动封禁连接方式或密码错误的IP，0 or 1,default:0):" ANTISSATTACK
	[[ -z ${ANTISSATTACK} ]] && ANTISSATTACK="0"
	stty erase '^H' && read -p "MU_SUFFIX(default:zhaoj.in):" MU_SUFFIX
	[[ -z ${MU_SUFFIX} ]] && MU_SUFFIX="zhaoj.in"
	stty erase '^H' && read -p "MU_REGEX(default:%5m%id.%suffix):" MU_REGEX
	[[ -z ${MU_REGEX} ]] && MU_REGEX="%5m%id.%suffix"		
}
modwebapi_set(){
	stty erase '^H' && read -p "WEBAPI_URL(对接域名或IP，格式http://www.baidu.com):" WEBAPI_URL
	stty erase '^H' && read -p "WEBAPI_TOKEN(对接token，配置文件中修改):" WEBAPI_TOKEN
}
mysql_set(){
	stty erase '^H' && read -p "MYSQL_HOST(IP addr or domain):" MYSQL_HOST
	stty erase '^H' && read -p "MYSQL_PORT(default:3306):" MYSQL_PORT
	[[ -z ${MYSQL_PORT} ]] && MYSQL_PORT="3306"
	stty erase '^H' && read -p "MYSQL_USER(default:root):" MYSQL_USER
	[[ -z ${MYSQL_USER} ]] && MYSQL_USER="root"
	stty erase '^H' && read -p "MYSQL_PASS:" MYSQL_PASS
	[[ -z ${MYSQL_PASS} ]] && MYSQL_PASS="root"
	stty erase '^H' && read -p "MYSQL_DB(default:sspanel):" MYSQL_DB
	[[ -z ${MYSQL_DB} ]] && MYSQL_DB="sspanel"
}
modify_ALL(){
	modify_CLOUDSAFE
	modify_API
	modify_MU_REGEX
	modify_MU_SUFFIX
	modify_MYSQL
	modify_NODE_ID
	modify_SPEEDTEST
	modify_WEBAPI_TOKEN
	modify_WEBAPI_URL
}
iptables_OFF(){
		systemctl disable firewalld &>/dev/null
		systemctl disable iptables &>/dev/null
		chkconfig iptables off &>/dev/null
		iptables -F	&>/dev/null
}
SSR_installation(){
	check_system
#select api

	selectApi
	echo ${API}
	common_set

	if [[ ${API} == "modwebapi" ]]; then
		modwebapi_set
	else
		mysql_set
	fi
	
#basic install	
	basic_installation
	dependency_installation
	development_tools_installation
	libsodium_installation
	
	cd ${shadowsocks_install_folder} && git clone -b manyuser https://github.com/glzjin/shadowsocks.git 
	cd shadowsocks && cp apiconfig.py userapiconfig.py && cp config.json user-config.json
	
	SSR_dependency_installation


#final option
	modify_ALL
	iptables_OFF

	echo -e "${OK} SSR manyuser for glzjin installation complete"
	chmod +x /root/shadowsocks/run.sh && ./root/shadowsocks/run.sh
	if [[ `ps -ef | grep server.py |grep -v grep | wc -l` -ge 1 ]];then
	echo -e "${OK} ${GreenBG} 后端已启动 ${Font}"
else
	echo -e "${OK} ${RedBG} 后端未启动 ${Font}"
	echo -e "请检查配置文件是否正确、检查是否代码错误请反馈"
	exit 1
fi
	echo -e "如果重启，请手动启动SS：
启动：./root/shadowsocks/run.sh
启动（日志模式）：./root/shadowsocks/logrun.sh
停止：./root/shadowsocks/stop.sh
日志：./root/shadowsocks/tail.sh"
}
SSR_installation