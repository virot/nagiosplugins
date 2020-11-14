#!/bin/bash

while getopts "p:r:s:u:" opt; do
    case "$opt" in
        p )
            password=$OPTARG
            ;;
        r )
            realm=$OPTARG
            ;;
        s )
            server=$OPTARG
            ;;
        u )
            user=$OPTARG
            ;;
    esac
done

if [ -z "$user" ] || [ -z "$password" ] || [ -z "$server" ]; then
    echo "UNKNOWN - Missing Argument - check_ms_ad_kinit -u <user> -p <password> -s <server>"
    return 3
fi

if [ -z "$realm"]; then
    realm=${user/*@/}
fi

function cleanup {
    if [ -x $KRB5CCNAME ]; then
        rm $KRB5CCNAME
    fi
    if [ -x $KRB5_CONFIG ]; then
        rm $KRB5_CONFIG
    fi
}

trap cleanup EXIT

export KRB5_CONFIG=/tmp/krb5_$RANDOM.conf
export KRB5CCNAME=/tmp/krb5_CC_$RANDOM

cat > $KRB5_CONFIG << EOF
[libdefaults]
  default_realm = $realm
  dns_lookup_kdc = false
[realms]
  AD.VIROT.SE = {
    kdc = $server
    admin_server = $server
  }
EOF


#export KRB5_CONFIG=<(echo $KRB5CONF); KRB5CCNAME=FILE:<(echo bla); kinit $user < <(echo $password) > /dev/null
result=$(kinit $user < <(echo $password) 2>&1 > /dev/null)
retvalue=$?
#kdestroy
#KRB5_CONFIG=<(echo $KRB5CONF); KRB5CCNAME=FILE:<(echo bla); cat $KRB5_CONFIG
if [ "$retvalue" -eq "0" ]; then
    echo "OK - Ticket granted"
    return 0
elif [ "$retvalue" -eq "1" ]; then
    echo "CRITICAL - Failed to get ticket $result"
    return 2
else
    echo "UNKNOWN - kinit returned: $retvalue, $result"
    return 3
fi
                                                                                                                                                                                                                                                                                                                         ~                                                                                                                                                                                                                                                                                                                            ~                                                                                                                                                                                                                                                                                                                            ~                                                                             