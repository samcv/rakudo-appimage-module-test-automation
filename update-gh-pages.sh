#!/usr/bin/env bash
# Adapted from script by Yuriy Tymchuk 2013
# and here https://gist.github.com/domenic/ec8b0fc8ab45f39403dd
# https://sleepycoders.blogspot.com/2013/03/sharing-travis-ci-generated-files.html
TARGET_BRANCH="gh-pages"
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$TARGET_BRANCH"  ]; then
  printf "Starting to update gh-pages\n"

  #copy data we're interested in to other place
  mkdir -p "$HOME/staging"
  APPIMAGENAME=$(basename "$(find . -name '*.AppImage')")
  if [ "$BLEAD" ]; then
    NAME="blead"
  else
    NAME='star'
  fi
  mv "$APPIMAGENAME" "$NAME-${P6SCRIPT}${APPIMAGENAME}"
  cp *.AppImage $HOME/staging

  #go to home and setup git
  cd -- "$HOME" || echo "Couldn't cd into $HOME"; exit 1
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis"
    # Save some useful information
  REPO=`git config remote.origin.url`
  SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
  SHA=`git rev-parse --verify HEAD`
  git clone -v $REPO gh-pages
  cd gh-pages
  git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
  # Copy our files from staging to the repo
  cp -Rf $HOME/staging/* .
  if [ -z `git diff --exit-code` ]; then
    echo "No changes to the output on this push; exiting."
    exit 0
  fi
  #add, commit and push files
  git add -f .
  git commit -m "Travis build $TRAVIS_BUILD_NUMBER pushed to gh-pages"
  git push -fv origin gh-pages

  echo -e "Done magic with push\n"
fi
