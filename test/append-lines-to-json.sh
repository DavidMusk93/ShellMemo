#!/bin/bash

eraseLastTwoLines(){
    sed -n -e :a -e 'N;1,2!{P;D;};ba' $1
}

OLD_CONF=config.json
NEW_CONF=config.json.x

#redirect output (>) would truncate destination file firstly
eraseLastTwoLines $OLD_CONF>$NEW_CONF

cat>>$NEW_CONF<<'EOF'
    },
    "websocket":{
        "enabled":true,
        "path":"/sun312/",
        "host":"rn.guohuasun.com"
    },
    "mux":{
        "enabled":true,
        "concurrency":8,
        "idle_timeout":60
    }
}
EOF
