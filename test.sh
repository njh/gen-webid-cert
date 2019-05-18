#!/bin/sh
#
# Test harness to verify that gen-webid-cert.sh is working
#


# Avoid clobbering an existing key/certificate
if [ -e webid.pem -o -e webid.p12 ]; then
    echo >&2 "Error: webid.pem or webid.p12 exists."
    echo >&2 "Please remove before running the test suite."
    exit 1
fi


failures=0

assert() {
 eval "${1}"
 if [ $? -eq 0 ]; then
   echo " ✓ ${2}"
 else
   echo " ✗ ${2}"
   failures=$((failures+1))
 fi
}


# Settings
name="Test User"
uri="http://example.com/test#id"
cn=""
genp12='N'
addtokeychain='N'

# Run the script
input="$name\n$uri\n$cn\n$genp12\n$addtokeychain\n"
output="$(printf "$input" | ./gen-webid-cert.sh 2>&1)"
result="$?"

# Verify that it worked
assert "[ '$result' -eq 0 ]" "Script returns status of 0"
assert "[ -e webid.pem ]" "Creates a file called webid.pem"

assert "echo '$output' | grep -Eq '<foaf:name>Test User</foaf:name>'" "RDF output contains <foaf:name>"

subject="$(openssl x509 -noout -subject -in webid.pem 2>&1)"
assert "echo '$subject' | grep -Eq '$name'" "Cert subject contains the user's name"

# Clean up any files we created
rm -f webid.pem webid.p12

# Run the script with a custom name
cn="Custom CN"
input="$name\n$uri\n$cn\n$genp12\n$addtokeychain\n"
output="$(printf "$input" | ./gen-webid-cert.sh 2>&1)"
result="$?"

# Verify that it worked
assert "[ '$result' -eq 0 ]" "Script returns status of 0"
assert "[ -e webid.pem ]" "Creates a file called webid.pem"

assert "echo '$output' | grep -Eq '<foaf:name>Test User</foaf:name>'" "RDF output contains <foaf:name>"

subject="$(openssl x509 -noout -subject -in webid.pem 2>&1)"
assert "echo '$subject' | grep -Eq '$cn'" "Cert subject contains the custom CN"


# Clean up any files we created
rm -f webid.pem webid.p12


echo
echo "$failures tests failed"
exit $failures
