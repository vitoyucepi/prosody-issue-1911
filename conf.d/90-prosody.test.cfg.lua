VirtualHost "prosody.test"

ssl = {
    certificate = "/etc/prosody/certs/prosody.test/cert.pem";
    key = "/etc/prosody/certs/prosody.test/key.pem";
}

Component "conference.prosody.test" "muc"
Component "upload.prosody.test" "http_file_share"
http_host = "prosody.test"
