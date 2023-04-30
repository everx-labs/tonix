#set -x
function err() {
    $TOC debug run -d build/$X.debug.json -m $1 -- --h $h --vin $v --s "$i"
    tail -n15 trace.log | head -n-5
    exit 1
}
function run_input() {
#    read -rsn1 i
    read -s -n3 i
    $R $1 --h $h --vin $v --s "$i" >$of || err $1
    h=`jq -r .hout $of`
    v=`jq -r .vout $of`
    jq -r .cmd $of >tmp/scr
    source tmp/scr
}

function open() {
    IDEV=$2
    X=$1
    CFG=etc/$1.conf
    TOC="../../bin/tonos-cli -c $CFG "
    R="../../bin/tonos-cli -c $CFG runx -m "
    mkdir -p tmp
    of=tmp/${1}_$IDEV.res
    h=0
    v=`cat default.cfg`
}

open tup ona

while true
do
    run_input $IDEV
done
