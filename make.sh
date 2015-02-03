#!/bin/bash
#
# make.sh
#
# Build a package

set -e

instance=$1
if [ -z "$instance" ] ; then
    instance="digcolproc"
	echo "Default version ${digcolproc}"
fi

version=$2
if [ -z "$version" ] ; then
	version="1.0"
	echo "Default version ${version}"
fi

if [ -d target ] ; then
    rm -rf target
fi
mkdir target


revision=$(git rev-parse HEAD)
app=$instance-$version
expect=target/$app.tar.gz

echo "Build $expect, revision $revision"

app=$instance-$version
if [ -d $app ] ; then
    rm -rf $app
fi


rsync -av --exclude='.git' --exclude='.gitignore' --exclude='make.sh' . $app
# set permissions
for f in $(find "$app" -type f  -name "*.sh" )
do
    chmod 744 $f
done

echo $revision>$app/revision.txt
tar -zcvf $expect $app
rm -rf $app

if [ -f $expect ] ; then
    echo "Build ok."
else
	echo -e "Unable to build ${expect}"
fi