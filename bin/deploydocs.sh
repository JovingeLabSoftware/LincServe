#!/bin/bash

npm run docs
cp -R ./docs/api/* ../../LincServeDoc/api
cp -R ./docs/CouchLincs/1.0.0/* ../../LincServeDoc/CouchLincs
git --git-dir=../../LincServeDoc/.git --work-tree=../../LincServeDoc commit -am "Documentation update"
git --git-dir=../../LincServeDoc/.git --work-tree=../../LincServeDoc push origin gh-pages

