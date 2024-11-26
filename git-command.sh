#!/usr/bin/env bash

cd app-repo
git add .
git commit -m "remote commit from jenkins"
git push origin master