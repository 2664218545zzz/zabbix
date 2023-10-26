#! /bin/bash

# 设置虚拟主机域名,默认如下
domain_name="www.pupu.com"

# 1.安装zabbix依赖
yum -y install net-snmp-devel mysql-devel libevent-devel &&\
yum -y install http://mirror.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/OpenIPMI-devel-2.0.31-3.el8.x86_64.rpm &&\

# 2.创建zabbix用户与组
groupadd --system zabbix
useradd --system -g zabbix -d /usr/lib/zabbix -s /sbin/nologin -c "Zabbix Monitoring System" zabbix

# 3.编译zabbix
cd /usr/src &&\
	tar -zxvf zabbix-6.4.6.tar.gz -C /usr/local

# 4.配置数据库，创建zabbix库，创建zabbix用户并自定义密码
database="zabbix"
user="zabbix"
password="2664218545Z"

mysql -e "create database $database character set utf8mb4 collate utf8mb4_bin;"
mysql -e "create user '$user'@'localhost' identified by '$password';"
mysql -e "grant all privileges on $user.* to 'zabbix'@'localhost';"
mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"

# 5.编辑zabbix，导入zabbix库文件
cd /usr/local/zabbix-6.4.6/database/mysql/ &&\
	mysql -u$user -p$password $database < schema.sql &&\
	mysql -u$user -p$password $database < images.sql &&\
	mysql -u$user -p$password --default-character-set=utf8mb4 $database < data.sql &&\
	mysql -e "SET GLOBAL log_bin_trust_function_creators = 0;"

# 6.设置环境变量
export CFLAGS="-std=gnu99"

# 7.开始编译安装zabbix
cd /usr/local/zabbix-6.4.6/ &&\
	./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --with-openipmi &&\
	make install &&\

# 8.编辑主配置文件
cat >> /usr/local/etc/zabbix_server.conf <<EOF
DBPassword=$password
EOF

# 9.配置service文件
rm /usr/local/httpd/htdocs/$domain_name/*
cp -r ui/* /usr/local/httpd/htdocs/$domain_name/

# 10.设置htdocs目录属主属组
chown -R apache.apache /usr/local/httpd/htdocs/

# 11.赋予conf文件777权限
chmod 777 /usr/local/httpd/htdocs/$domain_name/conf

# 12.域名访问参数不满足，继续配置
sed -ri 's/(post_max_size =).*/\1 16M/g' /etc/php.ini
sed -ri 's/(max_execution_time =).*/\1 300/g' /etc/php.ini
sed -ri 's/(max_input_time =).*/\1 300/g' /etc/php.ini
sed -i '/;date.timezone/a date.timezone = Asia/Shanghai' /etc/php.ini

# 13.重启php服务
systemctl restart php-fpm



