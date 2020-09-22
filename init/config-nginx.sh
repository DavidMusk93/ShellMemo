#!/bin/bash

set -x

isInstalled(){
    dpkg-query -l | egrep -q 'ii[[:blank:]]*'$1'[[:blank:]]'
}

tryInstall(){
    for pkg;do isInstalled $pkg || apt install $pkg -y;done
}

loadEnvironmentVariable(){
    for i in HOST PORT USERNAME PASSWORD;do
        eval "$i=\$ENV_$i"
    done
    [ $HOST ] && [ $PORT ] && [ $USERNAME ] && [ $PASSWORD ]
}

configFileServer(){
    CONF=file-server.conf
    PWDFILE=.htpasswd
    NGINX_ROOT=/etc/nginx
    AVAILABLE_CONF=$NGINX_ROOT/sites-available
    ENABLED_CONF=$NGINX_ROOT/sites-enabled
    tryInstall nginx apache2-utils
    cat>$CONF<<EOF
server{
    listen $PORT;
    server_name $HOST;
    charset utf-8;

    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;
    sendfile on;
    sendfile_max_chunk 1m;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 60;
    gzip on;

    root /home/sun;

    location /Downloads/{
    }

    location /Documents/{
        auth_basic "personal files";
        auth_basic_user_file $PWDFILE;
    }
}
EOF
    htpasswd -cb $PWDFILE $USERNAME $PASSWORD
    mv $PWDFILE $NGINX_ROOT && mv $CONF $AVAILABLE_CONF
    (cd $ENABLED_CONF && test -e default && unlink default)
    ln -sfn $AVAILABLE_CONF/$CONF $ENABLED_CONF/
    nginx -t && systemctl restart nginx && systemctl status nginx
}

if ! [ $EUID -eq 0 ];then
    echo "root is required"
    exit 0
fi
test -f .conf && . .conf
loadEnvironmentVariable || exit 1
configFileServer
