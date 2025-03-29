# Reproduction for [prosody issue 1911](https://issues.prosody.im/1911)

## Details:

When I define custom ssl config for a virtual host, it doesn't apply to connections on direct_tls port, such as `5223`.

## Reproduction:

1. Create `certs/default` and `certs/prosody.test` directories.
1. Create `conf.d` directory.
1. Create the default self-signed certificate.
   ```sh
   openssl req \
     -new \
     -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
     -x509 \
     -days 3650 \
     -nodes \
     -sha256 \
     -subj '/CN=localhost' \
     -addext 'basicConstraints=CA:false' \
     -addext 'subjectAltName = DNS:localhost' \
     -out certs/default/cert.pem \
     -keyout certs/default/key.pem \
   ;
   ```
2. Create certificate for virtual host.
   ```sh
   openssl req \
     -new \
     -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
     -x509 \
     -days 3650 \
     -nodes \
     -sha256 \
     -subj '/CN=prosody.test' \
     -addext 'basicConstraints=CA:false' \
     -addext 'subjectAltName = DNS:prosody.test, DNS:*.prosody.test' \
     -out certs/prosody.test/cert.pem \
     -keyout certs/prosody.test/key.pem \
   ;
   ```
3. Create a `compose.yaml` file.
   Insert your own keys and certificates or use the ones I provide.
   <details><summary>compose.yaml</summary>

   ```yaml
   services:
     prosody:
       image: "prosodyim/prosody:13.0"
       restart: always
       ports:
         - "5222:5222"
         - "5223:5223"
         - "5269:5269"
         - "5270:5270"
         - "5280:5280"
         - "5281:5281"
       volumes:
         - prosody_data:/var/lib/prosody
         - ./conf.d:/etc/prosody/conf.d
         - ./certs:/etc/prosody/certs
       environment:
         LOCAL: root
         DOMAIN: prosody.test
         PASSWORD: root
         PROSODY_ADMINS: root@prosody.test
         PROSODY_CERTIFICATES: /path/does/not/exist

   volumes:
     prosody_data: {}
   ```

   </details>
4. Start compose project.
   I use `docker compose up` to test the behavior.
5. Connect to the server using the client.
   Your account would be login:*root@prosody.test* password:*root*.
   I use gajim to test this.
6. Test the connection with testssl.sh.
   <details><summary>testssl.sh</summary>

   ```sh
   docker run --rm -it drwetter/testssl.sh -S --ip 192.168.0.1 prosody.test:5281
   docker run --rm -it drwetter/testssl.sh -S --ip 192.168.0.1 --xmpphost prosody.test --starttls xmpp prosody.test:5222
   docker run --rm -it drwetter/testssl.sh -S --ip 192.168.0.1 --xmpphost prosody.test prosody.test:5223
   docker run --rm -it drwetter/testssl.sh -S --ip 192.168.0.1 --xmpphost prosody.test --starttls xmpp prosody.test:5269
   docker run --rm -it drwetter/testssl.sh -S --ip 192.168.0.1 --xmpphost prosody.test prosody.test:5270
   docker run --rm -it drwetter/testssl.sh -S --ip 192.168.0.1 prosody.test:5281
   ```
7. Test the connection with curl.
   <details><summary>curl.sh</summary>

   ```sh
   curl --connect-to prosody.test::127.0.0.1: https://prosody.test:5281/file_share/ -v -k
   ```

   </details>
8. Test the connection with openssl.
   <details><summary>openssl.sh</summary>

   ```sh
   openssl s_client -connect 127.0.0.1:5222 -starttls xmpp -xmpphost prosody.test -showcerts < /dev/null
   openssl s_client -connect 127.0.0.1:5223 -servername prosody.test -showcerts < /dev/null
   openssl s_client -connect 127.0.0.1:5269 -starttls xmpp-server -xmpphost prosody.test -showcerts < /dev/null
   openssl s_client -connect 127.0.0.1:5270 -servername prosody.test -showcerts < /dev/null
   openssl s_client -connect 127.0.0.1:5281 -servername prosody.test -showcerts < /dev/null
   ```

   </details>

## Observed behavior:
On ports `5222` and `5269`, prosody responds with the correct self-signed certificate,
but on ports `5223`, `5270`, and `5281`, prosody uses the default certificate.

## Expected behavior:
Prosody should return correct certificates on direct_tls and https ports.
