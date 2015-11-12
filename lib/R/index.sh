#!/bin/bash

curl -X PUT \
     -H 'Content-Type: application/json' \
     http://localhost:8092/LINCS1/_design/byfield \
     -d @byfield.ddoc