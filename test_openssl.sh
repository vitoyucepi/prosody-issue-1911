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
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

print_status() {
    address=$1
    host=$2
    subject=$3
    if check_subject "$host" "$subject"; then
      echo "Success: $address:$port with hostname $host."
      return 0
    else
      echo "Fail: $address:$port with hostname $host, got $subject"
      return 1
    fi
}

check_server() {
    address=$1
    host=$2
    xmpp_ports=$3
    xmpps_ports=$4
    https_ports=$5

    status=0
    for port in $xmpp_ports; do
        subject=$(test_starttls "$address:$port" "$host" | get_subject)
        print_status "$address:$port" "$host" "$subject" || status=1
        echo "$address:$port $status"
    done
    for port in $xmpps_ports $https_ports; do
        subject=$(test_tls "$address:$port" "$host" | get_subject)
        print_status "$address:$port" "$host" "$subject" || status=1
        echo "$address:$port $status"
    done
    return $status
}

main() {
    status=0
    check_server '127.0.0.1' 'prosody.test' '5222 5269' '5223 5270' '5281' || status=1
    check_server 'google.com' 'google.com' '' '' '443' || status=1
    return $status
}

main "$@"
