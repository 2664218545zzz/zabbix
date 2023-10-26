#! /bin/bash
# 1.安装依赖
yum -y install openssl-devel pcre-devel expat-devel libtool gcc gcc-c++ wget make

# 2.下载apache2.4.57软件包
cd /usr/src &&\
tar xf httpd-2.4.57.tar.gz -C /usr/local/
tar xf apr-1.6.5.tar.gz -C /usr/local/
tar xf apr-util-1.6.3.tar.gz -C /usr/local/


# 3.开始编译
cd /usr/local/apr-1.6.5 &&\
	./configure --prefix=/usr/local/apr &&\
	make && make install &&\
cd ../apr-util-1.6.3 &&\
        ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr/bin/apr-1-config &&\
	make && make install &&\
cd ../httpd-2.4.57 &&\
./configure --prefix=/usr/local/httpd \
--enable-so \
--enable-ssl \
--enable-cgi \
--enable-rewrite \
--with-zlib \
--with-pcre \
--with-apr=/usr/local/apr \
--with-apr-util=/usr/local/apr-util/ \
--enable-modules=most \
--enable-mpms-shared=all \
--with-mpm=prefork &&\
       make && make install &&\

# 4.配置apache
echo 'export PATH=/usr/local/httpd/bin:$PATH' > /etc/profile.d/httpd.sh
ln -s /usr/local/httpd/include /usr/include/httpd
echo 'MANPATH /usr/local/httpd/man' >> /etc/man.config
sed -i '/#ServerName/s/#//g' /usr/local/httpd/conf/httpd.conf

# 5.编写service文件
cat > /usr/lib/systemd/system/httpd.service <<EOF
[Unit]
Description=httpd server daemon
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/httpd/bin/apachectl start
ExecStop=/usr/local/httpd/bin/apachectl stop
ExecReload=/bin/kill -HUP $MAINPID
[Install]
WantedBy=multi-user.target
EOF
# 记载文件并启动服务
systemctl daemon-reload
systemctl  restart  httpd
systemctl  enable  httpd


