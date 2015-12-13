#!/bin/bash

COUCH_HOST='52.35.41.246'
BUCKET='LINCS'

curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/debug \
	-d @debug.ddoc
	
curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/dev_debug \
	-d @debug.ddoc
	
curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/lincs \
	-d @lincs.ddoc
	
	
curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/dev_lincs \
	-d @debug.ddoc
	
curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/lincs_dash \
	-d @lincs.ddoc
	
	
curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/dev_lincs_dash \
	-d @debug.ddoc

curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/lincs_zscore \
	-d @lincs.ddoc
	
	
curl -X PUT \
	-H 'Content-Type: application/json' \
	http://${COUCH_HOST}:8092/${BUCKET}/_design/dev_lincs_zscore \
	-d @debug.ddoc
