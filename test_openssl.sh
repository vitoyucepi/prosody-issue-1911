#!/usr/bin/env sh

get_subject() {
    grep 'subject' | cut -d "=" -f2-
}

test_starttls() {
    port=$1
    host=$2
    openssl s_client -connect 127.0.0.1:"$port" -starttls xmpp -xmpphost "$host" -showcerts </dev/null 2>&1
}

test_tls() {
    port=$1
    host=$2
    openssl s_client -connect 127.0.0.1:"$port" -servername "$host" -showcerts </dev/null 2>&1
}

main() {
    xmpp_client_starttls=$(test_starttls 5222 prosody.test | get_subject)
    xmpp_server_starttls=$(test_starttls 5269 prosody.test | get_subject)
    xmpp_client_tls=$(xmpp_test_tls 5223 prosody.test | get_subject)
    xmpp_server_tls=$(test_tls 5270 prosody.test | get_subject)
    https=$(test_tls 5281 prosody.test | get_subject)

    echo "XMPP c2s connection on port 5222 using starttls, expected 'CN = prosody.test', got '$xmpp_client_starttls'"
    echo "XMPP c2s connection on port 5223 using direct tls, expected 'CN = prosody.test', got '$xmpp_client_tls'"
    echo "XMPP s2s connection on port 5269 using starttls, expected 'CN = prosody.test', got '$xmpp_server_starttls'"
    echo "XMPP s2s connection on port 5270 using direct tls, expected 'CN = prosody.test', got '$xmpp_server_tls'"
    echo "HTTPS connection on port 5281, expected 'CN = prosody.test', got '$https'"
}

main "$@"
