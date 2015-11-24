#!/bin/bash

npm run docs
cp -R ./docs/api/* ../CouchLincsDoc/CouchLincs/api
cp -R ./docs/CouchLincs/1.0.0/* ../CouchLincsDoc/CouchLincs
git --git-dir=../CouchLincsDoc/CouchLincs/.git --work-tree=../CouchLincsDoc/CouchLincs commit -am "Documentation update"
git --git-dir=../CouchLincsDoc/CouchLincs/.git --work-tree=../CouchLincsDoc/CouchLincs push

