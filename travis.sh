#!/bin/sh
# This script is invoked from my Travis commands
# It bootstraps to grab the a binary release and run it
set -ex # exit on errors

PACKAGE=$1
if [ -z "$PACKAGE" ]; then
    echo No arguments provided, please pass the project name as the first argument
    exit 1
fi
shift

OS=$TRAVIS_OS_NAME
if [ -z "$OS" ]; then
    OS=linux
fi

if [ "$OS" = "windows" ]; then
    EXT=\.zip
else
    EXT=\.tar\.gz
fi

echo Downloading and running $PACKAGE...
# Don't go for the API since it hits the Appveyor GitHub API limit and fails
RELEASES=$(curl --silent --show-error https://github.com/ndmitchell/$PACKAGE/releases)
URL=https://github.com/$(echo $RELEASES | grep -o '\"[^\"]*-x86_64-'$OS$EXT'\"' | sed s/\"//g | head -n1)
VERSION=$(echo $URL | sed -n 's@.*-\(.*\)-x86_64-'$OS$EXT'@\1@p')
TEMP=$(mktemp -d .$PACKAGE-XXXXX)

cleanup(){
    rm -r $TEMP
}
trap cleanup EXIT

retry(){
    ($@) && return
    sleep 15
    ($@) && return
    sleep 15
    $@
}

retry curl --progress-bar --location -o$TEMP/$PACKAGE.tar.gz $URL
if [ "$OS" = "windows" ]; then
    7z x -y $TEMP/$PACKAGE.zip -o$TEMP -r
else
    tar -xzf $TEMP/$PACKAGE.tar.gz -C$TEMP
fi
$TEMP/$PACKAGE-$VERSION/$PACKAGE $*
