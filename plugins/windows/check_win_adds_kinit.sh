#!/bin/bash

while getopts "p:r:s:u:v:" opt; do
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
        v )
            verbose=$OPTARG
            ;;
    esac
done

if [ -z "$user" ] || [ -z "$password" ] || [ -z "$server" ]; then
    echo "UNKNOWN - Missing Argument - check_ms_ad_kinit -u <user> -p <password> -s <server>"
    exit 3
else
    if [ -z "$realm"]; then
        realm=${user/*@/}
    fi

 krb5config="[libdefaults]
  default_ccache_name = MEMORY:
  default_realm = $realm
  dns_lookup_kdc = no
  dns_lookup_realm = no
[realms]
  $realm = {
    kdc = $server
    admin_server = $server
  }"

    if [ -n "$verbose" ] && [ $verbose -gt 0 ]; then
        echo "REALM: $realm"
        echo "Server: $server"
        echo "User: $user"
        echo "Password: $password"
        echo -e "krb5.conf:\n$krb5config"
    fi

    result=$(env KRB5_CONFIG=<(echo -e "$krb5config") kinit $user < <(echo $password) 2>&1 > /dev/null)

    retvalue=$?
    #kdestroy
    if [ "$retvalue" -eq "0" ]; then
        echo "OK - Ticket granted"
        exit 0
    elif [ "$retvalue" -eq "1" ]; then
        echo "CRITICAL - Failed to get ticket $result"
        exit 2
    else
        echo "UNKNOWN - kinit returned: $retvalue, $result"
        exit 3
    fi
fi
