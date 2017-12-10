#!/bin/bash

SETUP_HEX=../setup.hex
FINAL_HEX=../firmware/release/u2f-firmware.hex
FLASH_TOOLS=0
SN=
SN_build=
SN_setup=CAFEBABEFFFFFFF0

if [[ $# != "2" ]]
then

    echo "usage: $0 <prog-zip> <port>"
    exit 1
fi

unzip -o $1

rm -f $1

port=$2
attest_priv=priv.pem
attest_pub=pub.der
SN_build=$(cat sn.txt)
wkey=$(cat trans_keys.txt|head -n 1|tr -d '\r')
rkey=$(cat trans_keys.txt|tail -n 1|tr -d '\r')

export PATH=$PATH:..:.

echo "programming setup..."
flash.sh $SETUP_HEX $port

while [[ "$?" -ne "0" ]] ; do
    echo "$port is retrying program... "
    sleep 0.2
    flash.sh $SETUP_HEX $port
done


echo "configuring..."

client.py configure $attest_priv $wkey $rkey -s $SN_setup #>/dev/null

while [[ "$?" -ne "0" ]] ; do
    sleep .2

    client.py configure $attest_priv $wkey $rkey -s $SN_setup

done


flash.sh prog.hex $port

while [[ "$?" -ne "0" ]] ; do
    sleep .2
    flash.sh prog.hex $port
done

[[ "$?" -ne "0" ]] && exit 1

echo "waiting to unplug"
sleep 0.2

while [[ "$?" -eq 0 ]] ; do

    sleep 0.5
    client.py wink -s "$SN_build"

done

echo "done."
