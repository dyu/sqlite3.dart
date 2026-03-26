#!/bin/sh

set -e

CURRENT_DIR=$PWD
# locate
if [ -z "$BASH_SOURCE" ]; then
    SCRIPT_DIR=`dirname "$(readlink -f $0)"`
elif [ -e '/bin/zsh' ]; then
    F=`/bin/zsh -c "print -lr -- $BASH_SOURCE(:A)"`
    SCRIPT_DIR=`dirname $F`
elif [ -e '/usr/bin/realpath' ]; then
    F=`/usr/bin/realpath $BASH_SOURCE`
    SCRIPT_DIR=`dirname $F`
else
    F=$BASH_SOURCE
    while [ -h "$F" ]; do F="$(readlink $F)"; done
    SCRIPT_DIR=`dirname $F`
fi
# change pwd
cd $SCRIPT_DIR

mkdir -p target && cd target

SQLITE_YEAR="2023"
SQLITE_VERSION="3420000"

GZ_DIR="sqlite-autoconf-$SQLITE_VERSION"
GZ_FILE="$GZ_DIR.tar.gz"

[ -e "$GZ_FILE" ] || curl -LO "https://sqlite.org/$SQLITE_YEAR/$GZ_FILE"
[ -e "$GZ_DIR" ] || tar -xvzf $GZ_FILE

cd $GZ_DIR
[ -e Makefile ] || ./configure
make

SQLITE_DIR="$PWD"
LIBS_DIR="$SQLITE_DIR/.libs"
cd $SCRIPT_DIR/..

copy_bins() {
  
OUT_DIR='target/sqlite'
mkdir -p $OUT_DIR

LIB_PREFIX=''
LIB_SUFFIX='dll'

UNAME=`uname`
case "$UNAME" in
    Darwin)
    LIB_PREFIX='lib'
    LIB_SUFFIX='dylib'
    cp $SQLITE_DIR/sqlite3 $OUT_DIR/
    ;;
    Linux)
    LIB_PREFIX='lib'
    LIB_SUFFIX='so'
    cp $SQLITE_DIR/sqlite3 $OUT_DIR/
    ;;
    *)
    cp $SQLITE_DIR/sqlite3.exe $OUT_DIR/
    ;;
esac

cp "$LIBS_DIR/${LIB_PREFIX}sqlite3.$LIB_SUFFIX" $OUT_DIR/
echo "Copied files to $OUT_DIR/"
du -sh $OUT_DIR/*

}

copy_bins

[ -e .dart_tool/sqlite3_build ] || CC=/opt/llvm/bin/clang CXX=/opt/llvm/bin/clang++ cmake \
-Dclang=/opt/llvm/bin/clang \
-S assets/wasm -B .dart_tool/sqlite3_build

cmake --build .dart_tool/sqlite3_build/ -t output -j
