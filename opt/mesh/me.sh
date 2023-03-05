#set -x

function err() {
    $D $1 -- --h $h --s $i &&  tail -n15 trace.log | head -n-5
    exit 1
}
function run_input() {
    read -p '> ' -rsn1 i
    $R $1 --h $h --s $i >$of
    grep -q Error $of && err $1
    h=`jq -r .hout $of`
    printf "\n"
    jq -r .cmd $of >scr
    source scr
}

function open() {
    TOC=../../bin/tonos-cli
    DTOC=~/bin/0.65.0/tonos-cli
    X=$1
    IDEV=$2
    CFG=etc/$X.conf
    RCMD="runx"
    DCMD="debug run"
    R="$TOC -c $CFG $RCMD -m"
    D="$DTOC -c $CFG $DCMD -d build/$X.debug.json -m"
    of=${X}_$IDEV.res
    h=0
}

open mesh onc

while true
do
    run_input $IDEV
done
