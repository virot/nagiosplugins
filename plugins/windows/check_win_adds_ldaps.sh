#!/bin/bash

while getopts "p:b:s:u:v:c:" opt; do
    case "$opt" in
        p )
            password=$OPTARG
            ;;
        b )
            base=$OPTARG
            ;;
        s )
            server=$OPTARG
            ;;
        u )
            user=$OPTARG
            ;;
	c )
            rootca=$OPTARG
	    ;;
	v )
            verbose=$OPTARG
	    ;;
    esac
done

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

if [ -z "$user" ] || [ -z "$password" ] || [ -z "$server" ]; then
    echo "UNKNOWN - Missing Argument - check_win_adds_ldap -u <user> -p <password> -s <server> -b <object> -c <rootca>"
    exit 3
else

    rootcacorrect=$(sed -e 's/-----[BEGIND]\{3,5\}\sCERTIFICATE-----//g' -e 's/.\{64\}/&\n/g' <<< $rootca)

    if [ ! -z "$verbose" ] && [ $verbose -gt 0 ]; then
        echo "Object: $base"
        echo "Server: $server"
        echo "User: $user"
        echo "Password: $password"
        echo -e "-----BEGIN CERTIFICATE-----\n$rootcacorrect\n-----END CERTIFICATE-----"
    fi
    
    #export KRB5_CONFIG=<(echo $KRB5CONF); KRB5CCNAME=FILE:<(echo bla); kinit $user < <(echo $password) > /dev/null
    #result=$(LDAPTLS_CACERT=<(echo $rootca) LDAPTLS_REQCERT=require ldapsearch -H ldaps://$server:636 -x -b "$base" -D "$user" -y <(echo -n $password) -s base 2>&1 > /dev/null)
    result=$(LDAPTLS_CACERT=<(echo -e "-----BEGIN CERTIFICATE-----\n$rootcacorrect\n-----END CERTIFICATE-----\n") LDAPTLS_REQCERT=require ldapsearch -H ldaps://$server:636 -x -b "$base" -D "$user" -y <(echo -n $password) -s base 2>&1 > /dev/null)
    retvalue=$?
    #kdestroy
    #KRB5_CONFIG=<(echo $KRB5CONF); KRB5CCNAME=FILE:<(echo bla); cat $KRB5_CONFIG
    if [ "$retvalue" -eq "0" ]; then
        echo "OK - LDAP Connected"
        exit 0
    elif [ "$retvalue" -eq "10" ]; then
        echo "WARNING - $base object missing"
        exit 1 
    elif [ "$retvalue" -eq "255" ]; then
        echo "CRITICAL - Server not found/dont respond: $result"
        exit 2
    elif [ "$retvalue" -eq "49" ]; then
        echo "CRITICAL - Unable to authenticate $result"
        exit 2
    else
        echo "UNKNOWN - ldapsearch returned: $retvalue, $result"
        exit 3
    fi
fi
