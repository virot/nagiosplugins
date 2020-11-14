#!/bin/bash

while getopts "p:r:s:u:" opt; do
    case "$opt" in
        s )
            server=$OPTARG
            ;;
        u )
            user=$OPTARG
            ;;
        p )
            password=$OPTARG
            ;;
    esac
done

if [ -z "$server" ]; then
    echo "UNKNOWN - Missing Argument - check_ms_ad_rpcclient [-u <user> -p <password>] -s <server>"
    return 3
fi

if [ ! -z "$user" ] && [ -z "$password" ]; then
    echo "UNKNOWN - Missing Argument - check_ms_ad_rpcclient [-u <user> -p <password>] -s <server>"
    return 3
fi

if [ -z "$user" ]; then
  resultpre=$(rpcclient -I $server $server -U "" -N -c "exit" 2>&1)
  retvalue=$?
else
  resultpre=$(rpcclient -I $server $server -U $user -e -c "exit" < <(echo $password) 2>&1)
  retvalue=$?
fi

result=$(sed -e "1d" <<< "$resultpre")

if [ "$retvalue" -eq "0" ]; then
    echo "OK - RPC connected"
    return 0
elif [ "$retvalue" -eq "1" ]; then
    echo "CRITICAL - failed to connect: $result"
    return 2
else
    echo "UNKNOWN - rpcclient returned: $retvalue, $result"
    return 3
fi