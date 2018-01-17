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
 if [[ $? -eq 0 ]]; then
   echo " ✓ ${2}"
 else
   echo " ✗ ${2}"
   failures=$((failures+1))
 fi
}


# Settings
name="Test User"
uri="http://example.com/test#id"
genp12='N'
addtokeychain='N'

# Run the script
input="$name\n$uri\n$genp12\n$addtokeychain\n"
output="$(printf "$input" | ./gen-webid-cert.sh 2>&1)"
result="$?"

# Verify that it worked
assert "[ '$result' -eq 0 ]" "Script returns status of 0"
assert "[ -e webid.pem ]" "Creates a file called webid.pem"


# Clean up any files we created
rm -f webid.pem webid.p12

echo
echo "$failures tests failed"
exit $failures
