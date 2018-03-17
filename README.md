gen-webid-cert.sh
=================

[![Build Status](https://travis-ci.org/njh/gen-webid-cert.svg?branch=master)](https://travis-ci.org/njh/gen-webid-cert)

`gen-webid-cert.sh` is a shell script to create a self-signed certificate for
use with [WebID](http://webid.info/). A WebID can be used to login to a website
using a client certificate, along with a FOAF document providing information
about you.

It works by creating a self-signed client certificate, where the Subject
Alternative Name (SAN) in the certificate points to the URI of yourself in a 
[FOAF](http://xmlns.com/foaf/spec/) document. The FOAF document the references
the Public Key of your certificate, allowing you to prove that you are the
person described in the FOAF document.

The script requires:
- A bourne compatible shell, such as [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
- The `openssl` command line tool

When you run the shell script it asks you for:
- Your Name
- Your WebID (a URI that can be de-referenced in a FOAF document) 

It then outputs:
- `webid.pem` - a PEM encoded file containing your private key and certificate
- `webid.p12` (*optional*) - a P12 encoded file, for loading into Firefox
- A snippet of a RDF/XML encoded FOAF document to STDOUT

If running on Mac OS, it will offer to add the certificate to your Keychain.



Testing
-------

A shell script called `test.sh` is provided to ensure that the main script is
working on your system. 

This script is run by Travis: https://travis-ci.org/njh/gen-webid-cert/


License
-------

`gen-webid-cert.sh` is licensed using [The Unlicense](http://unlicense.org/).
