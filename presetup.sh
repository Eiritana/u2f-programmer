#!/bin/bash

if [[ $# != "4" ]]
then
    echo "usage: $0 <attestation-public-key.der> <new-SN-for-U2F-token> <firmware> <output>"
    exit 1

fi

attest_pub=$1
SN_build=$2
firmware=$3
output=$4

echo "configuring..."

./client.py preconfigure $output

echo "generate attestation certificate..."
echo "for file $attest_pub"
./cbytes.py $attest_pub > $firmware/src/cert.c

[[ "$?" -ne "0" ]] && exit 1

wkey=$(./cbytes.py "$(cat $output.mac|head -n 1)" -s)
[[ "$?" -ne "0" ]] && exit 1

rkey=$(./cbytes.py "$(cat $output.mac|tail -n 1)" -s)
[[ "$?" -ne "0" ]] && exit 1


echo "" >> $firmware/src/cert.c
echo "code uint8_t WMASK[] = $wkey;" >> $firmware/src/cert.c
echo "code uint8_t RMASK[] = $rkey;" >> $firmware/src/cert.c


if [[ -n $SN_build ]] ; then
    echo "setting SN to $SN_build"
    sed -i "/#define SER_STRING.*/c\#define SER_STRING \"$SN_build\""  $firmware/src/descriptors.c
    rm -f $firmware/release/u2f-firmware.omf
fi

echo "done."
echo "building..."

PATH1=$PATH
cur=`pwd`
cd $firmware/release && make all && cd $cur

[[ "$?" -ne "0" ]] && exit 1

export PATH=$PATH1

echo "Build files are:"
echo "    prog.hex"
echo "    $output.raw"
