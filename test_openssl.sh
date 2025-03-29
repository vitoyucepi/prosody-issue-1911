#!/usr/bin/env sh

get_subject() {
    grep 'subject' | cut -d "=" -f2-
}

test_starttls() {
    address=$1
    host=$2
    openssl s_client -connect "$address" -starttls xmpp -xmpphost "$host" -showcerts </dev/null 2>&1
}

test_tls() {
    address=$1
    host=$2
    openssl s_client -connect "$address" -servername "$host" -showcerts </dev/null 2>&1
}

check_subject() {
    expected=$1
    actual=$2
    case "$actual" in
        *$expected* )
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

check_sevrer() {
    address=$1
    host=$2
    xmpp_ports=$3
    xmpps_ports=$4
    https_ports=$5
    for port in $xmpp_ports; do
        subject=$(test_starttls "$address:$port" "$host" | get_subject)
        if check_subject "$address" "$subject"; then
            echo "1 $address $port $subject"
        else
            echo "2 $address $port $subject"
        fi
    done
    for port in $xmpps_ports $https_ports; do
        subject=$(test_tls "$address:$port" "$host" | get_subject)
        if check_subject "$address" "$subject"; then
            echo "1 $address $port $subject"
        else
            echo "2 $address $port $subject"
        fi
    done
}

main() {
    check_server '127.0.0.1' 'prosody.test' '5222 5269' '5223 5270' '5281'
    check_server 'google.com' 'google.com' '' '' '443'
}

main "$@"
