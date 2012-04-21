#!/bin/sh
#
# gen-webid-cert.sh: WebID Self-signed Certificate Generator
#
# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <http://unlicense.org/>
#

# Be safe about permissions
umask 077

echo "WebID Self-signed Certificate Generator."
echo "This script will create a certificate and snippet of RDF for you."
echo "For more information about WebID visit: http://webid.info/"
echo

# Check that OpenSSL is available
command -v openssl >/dev/null 2>&1 || {
  echo >&2 "The scripts requires OpenSSL but it is not available. Aborting."
  exit 1
}

# Check that certificate already exists
if [ -e webid.pem -o -e webid.p12 ]; then
    echo >&2 "webid.pem already exists."
    echo >&2 "Please delete it if you would like to create a new one."
    exit 1
fi

# Ask for certificate details
read -p "Please enter your name: " NAME
[ -z "$NAME" ] && { echo "No name given, aborting."; exit 1; }
read -p "Please enter your WebID [example https://www.example.com/foaf.rdf#me]: " WEBID
[ -z "$WEBID" ] && { echo "No WebID given, aborting."; exit 1; }

# Create an OpenSSL configuration file
OPENSSL_CONFIG=`mktemp -q /tmp/webid-openssl-conf.XXXXXXXX`
if [ ! $? -eq 0 ]; then
    echo >&2 "Could not create temporary OpenSSL config file. Aborting."
    exit 1
fi

cat <<EOF > $OPENSSL_CONFIG
[ req ]
default_md = sha1
default_bits = 2048
distinguished_name = req_distinguished_name
encrypt_key = no
string_mask = nombstr
x509_extensions = req_ext

[ req_distinguished_name ] 
commonName = Common Name (eg, YOUR name)
commonName_default = WebID for $NAME
UID = A user ID
UID_default="$WEBID"

[ req_ext ]
subjectKeyIdentifier = hash
subjectAltName = critical,@subject_alt
basicConstraints = CA:false
extendedKeyUsage = clientAuth
nsCertType = client

[ subject_alt ]
URI.1="$WEBID"
EOF

# Create the self-signed certificate as a PEM file
openssl req -new -batch \
  -days 3650 \
  -config $OPENSSL_CONFIG \
  -keyout webid.pem \
  -out webid.pem \
  -x509

RESULT=$?

rm -f $OPENSSL_CONFIG

if [ ! $RESULT -eq 0 ]; then
    echo >&2 "Failed to create certificate. Aborting."
    exit 1
fi

# Display information about the certificate that was generated
openssl x509 -in webid.pem -noout -text

# Offer to convert to P12 format
read -p "Would you like to create a P12 file (for import into Firefox)? [y/N]" DOP12
if [ "$DOP12" == 'y' -o "$DOP12" == 'Y' ]; then
    openssl pkcs12 -export -clcerts \
      -name "WebID for $NAME" \
      -in webid.pem \
      -inkey webid.pem \
      -out webid.p12
fi

# Offer to load the certificate into Keychain on Mac OS X
if [ -e ~/Library/Keychains/login.keychain ]; then
    read -p "Would you like to import the certificate into your Mac OS X keychain? [y/N]" DOIMPORT
    if [ "$DOIMPORT" == 'y' -o "$DOIMPORT" == 'Y' ]; then
        security import webid.pem -k ~/Library/Keychains/login.keychain
    fi
fi


# Display RDF/XML
MODULUS=`openssl rsa -in webid.pem -modulus -noout | awk '{print substr($0,9)}'`
EXPONENT=`openssl rsa -in webid.pem -text -noout | awk '/Exponent/ { print $2 }'`
echo
echo "Upload this RDF/XML to the location of your WebID:"
echo
echo "<?xml version=\"1.0\"?>"
echo "<rdf:RDF"
echo " xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\""
echo " xmlns:cert=\"http://www.w3.org/ns/auth/cert#\""
echo " xmlns:foaf=\"http://xmlns.com/foaf/0.1/\">"
echo "  <foaf:Person rdf:about=\"$WEBID\">"
echo "    <foaf:name>$NAME</foaf:name>"
echo "    <cert:key>"
echo "      <cert:RSAPublicKey>"
echo "        <cert:modulus rdf:datatype=\"http://www.w3.org/2001/XMLSchema#hexBinary\">$MODULUS</cert:modulus>"
echo "        <cert:exponent rdf:datatype=\"http://www.w3.org/2001/XMLSchema#integer\">$EXPONENT</cert:exponent>"
echo "      </cert:RSAPublicKey>"
echo "    </cert:key>"
echo "  </foaf:Person>"
echo "</rdf:RDF>"
echo
echo "Your certificate has been written to webid.pem in the current directory."
echo
