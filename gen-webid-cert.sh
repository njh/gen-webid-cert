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

# FIXME: first check for openssl

# Be safe about permissions
LASTUMASK=`umask`
umask 077


echo "Please enter your name: "
read NAME
echo "Please enter your WebID [example https://www.example.com/foaf.rdf#me]: "
read WEBID


# Create an OpenSSL configuration file
OPENSSL_CONFIG=`mktemp -q /tmp/webid-openssl-conf.XXXXXXXX`
if [ ! $? -eq 0 ]; then
    echo "Could not create temporary client config file. exiting"
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
basicConstraints = critical,CA:false
extendedKeyUsage = critical,clientAuth
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

rm $OPENSSL_CONFIG

# Display information about the certificate that was generated
openssl x509 -in webid.pem -noout -text

# FIXME: offer to convert to P12 format
# echo "Would you like to create a PKCS12 archive? "
# openssl pkcs12 -export -clcerts \
#   -name "$NAME" \
#   -in webid.pem \
#   -inkey webid.pem \
#   -out webid.p12


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


# Restore umask
umask $LASTUMASK


# FIXME: offer to load into Keychain on Mac OS X
