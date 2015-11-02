#!/bin/bash

ENCRYPT=false
DECRYPT=false

while [[ $# > 0 ]]
do
key="$1"

case $key in
    -e|--encrypt)
    ENCRYPT=true
    ;;
    -d|--decrypt)
    DECRYPT=true
    ;;
    -k|--key)
    KEYFILE="$2"
    shift # past argument
    ;;
esac
shift # past argument or value
done

if [ $ENCRYPT = false ] && [ $DECRYPT = false ]; then
    echo "USAGE: cryptconfig -e || --encrypt ||  -d || --decrypt -k path/to/keyfile"; 
    exit 0
fi

if [ -z "$KEYFILE" ]; then
    echo "USAGE: cryptconfig -e || --encrypt ||  -d || --decrypt -k path/to/keyfile"; 
    exit 0
fi

if [ $ENCRYPT = true ]; then
   #encrypt with public key
   openssl rsautl -encrypt -inkey $KEYFILE -pubin -in config.json -out config.json.enc
else
   #decrypt with private key
   openssl rsautl -decrypt -inkey $KEYFILE -in config.json.enc -out config.json
fi

exit 0

