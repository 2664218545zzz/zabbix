#! /bin/bash
# 1.设置你的域名目录文件
# 示例
# domain_name="www.pupu.com"
domain_name="www.pupu.com"


# 2.创建域名虚拟主机家目录并写入php页面
mkdir /usr/local//httpd/htdocs/$domain_name &&\
cat > /usr/local/httpd/htdocs/$domain_name/index.php <<EOF
<?php
    phpinfo();
?>
EOF

# 3.创建apache用户，并设置htdocs目录的属主和属组
useradd apache -M -s /sbin/nologin
chown apache.apache /usr/local/httpd/htdocs

# 4.启用代理模块
sed -i '/proxy_module/s/#//g' /usr/local/httpd/conf/httpd.conf
sed -i '/proxy_fcgi_module/s/#//g' /usr/local/httpd/conf/httpd.conf

# 5.添加php服务支持
cat >> /usr/local/httpd/conf/httpd.com <<EOF
AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps
EOF

# 6.添加虚拟主机配置文件
cat >> /usr/local/httpd/conf/httpd.conf <<EOF
<VirtualHost *:80>
    DocumentRoot "/usr/local/httpd/htdocs/$domain_name"
    ServerName $domain_name
    ProxyRequests Off
    ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/usr/local/httpd/htdocs/$domain_name/$1
    <Directory "/usr/local/httpd/htdocs/$domain_name">
        Options none
        AllowOverride none
        Require all granted
    </Directory>
</VirtualHost>
EOF


# 7.设置index.php文件优先级
sed -i '/DirectoryIndex/s/index.html/index.php index.html/g' /usr/local/httpd/conf/httpd.conf

# 8.重启apache服务与php
systemctl restart httpd
systemctl restart php-fpm










