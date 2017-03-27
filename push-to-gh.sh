#!/usr/bin/env bash
set -e

[ "$TRAVIS_BRANCH" == "master" -a "$TRAVIS_PULL_REQUEST" == "false" ] || exit

git clone "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" demo >& /dev/null

pushd demo
git checkout gh-pages
git config user.name "Travis-CI"
git config user.email "user@example.com"
git rm * -rf
popd

cp -r build index.htm .travis.yml demo/

cd demo
git add .
git commit -m "Deployed ${TRAVIS_BUILD_NUMBER} to Github Pages"
git push -q origin HEAD >& /dev/null
