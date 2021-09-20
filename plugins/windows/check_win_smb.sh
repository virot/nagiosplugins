#!/bin/bash

while getopts "p:s:u:v:" opt; do
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
        v )
            verbose=$OPTARG
            ;;
    esac
done
echo $server
if [ -z "$user" ] || [ -z "$password" ] || [ -z "$server" ]; then
    echo "UNKNOWN - Missing Argument - check_ms_lanmanserver -u <user> -p <password> -s <server>"
    return 3
else

    if [ -n "$verbose" ] && [ $verbose -gt 0 ]; then
        echo "Server: $server"
        echo "User: $user"
        echo "Password: $password"
    fi

    result=$(smbclient -L $server -U $user%$password -m SMB3 -e --option='client min protocol=SMB2' 2>/dev/null)
    retvalue=$?
    
    
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
fi
