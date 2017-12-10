# Run this to generate multiple firmware files with different keys


if [[ $# != "2" ]]
then

    echo "usage: $0 <count> <output-dir>"
    exit 1
fi

attest_priv=keys/device-key.pem
attest_pub=keys/attest.der.der
starting_sn=8AB8CAFE00001000
firmware=firmware
count=$1
outdir=$2


function inc_hex {
    a=$((0x$1 + 1))
    a=$(printf "%x\n" $a)
    echo ${a^^}
}

echo seq 1 $count

rm -f $firmware/src/cert.c


# fix path in meta file to point to new location for files that are "dynamic"
sed -i "s/u2f-zero.*firmware.*src.*cert.c/u2f-programmer\/$firmware\/src\/cert.c/g"  \
    $firmware/release/src/cert.__i
sed -i "s/u2f-zero.*firmware.*src.*descriptors.c/u2f-programmer\/$firmware\/src\/descriptors.c/g"  \
    $firmware/release/src/descriptors.__i


for i in `seq 1 $count` ; do

    echo "Running for $attest_pub $starting_sn $firmware"
    ./presetup.sh $attest_pub $starting_sn $firmware "temp"

    [[ "$?" -ne "0" ]] && exit 1


    rm -f $outdir/prog"$i".zip
    echo "$starting_sn" > sn.txt
    cp $firmware/release/u2f-firmware.hex prog.hex
    cp $attest_priv priv.pem
    cp $attest_pub pub.der
    mv temp.raw trans_keys.txt

    zip -j $outdir/prog"$i".zip trans_keys.txt sn.txt prog.hex priv.pem pub.der
    [[ "$?" -ne "0" ]] && exit 1

    rm -f temp.raw temp.mac trans_keys.txt pub.der priv.pem prog.hex sn.txt
    [[ "$?" -ne "0" ]] && exit 1

    echo "done $starting_sn"

    starting_sn=$(inc_hex $starting_sn)

done

echo "done."



