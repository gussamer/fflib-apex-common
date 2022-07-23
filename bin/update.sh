#!/usr/bin/env bash
git fetch upstream
git checkout master
git merge upstream/master && wait
npm update --save
git add --all
git commit -m "updated from upstream version"