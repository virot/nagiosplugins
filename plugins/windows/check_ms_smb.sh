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

if [ -z "$user" ] || [ -z "$password" ] || [ -z "$server" ]; then
    echo "UNKNOWN - Missing Argument - check_ms_lanmanserver -u <user> -p <password> -s <server>"
    return 3
fi

resultpre=$(smbclient -L $server -U $user < <(echo $password) 2>&1)
retvalue=$?

result=$(sed -e 's/^Enter [^\n]*//' <<< "$resultpre")

if [ "$retvalue" -eq "0" ]; then
    echo "OK - SMB connected"
    return 0
elif [ "$retvalue" -eq "1" ]; then
    echo "CRITICAL - failed to connect: $result"
    return 2
else
    echo "UNKNOWN - SMB returned: $retvalue, $result"
    return 3
fi