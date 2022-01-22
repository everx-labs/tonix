#set -x
fn=$1
shift
param=$1

case $fn in
    exec|ustat|induce|uadm|main|command_help)
        util=$param;;
    display_man_page)
        util=man;;
    *)
        util=command;;
esac

abi=build/$util.abi.json
boc=bin/$util.boc

args() {
   case $fn in
        ustat|uadm|induce)
            jq --rawfile args run/export '. + {$args}' run/fs;;
        execute_command)
            jq -n --rawfile args run/args --rawfile page run/comp_spec --rawfile pool run/pool '{$args, $page, $pool}';;
        exec)
            jq --rawfile args run/export '. + {$args}' run/fs;;
        main)
            jq --rawfile argv run/export '. + {$argv}' run/fs;;
        display_man_page)
            jq -n --rawfile v run/export --slurpfile v1 vfs/usr/share/man_pages '{args: $v, help_files: $v1}';;
        *)
            echo '{}';;
    esac
}

filter() {
    case $fn in
        execute_command)
            echo `jq -r '.res' $1`;;
        exec|main)
            jq -rj '.out' $1 >run/stdout;
            jq -rj '.err' $1 >run/stderr;;
        display_man_page)
            jq -rj '.out' $1 >run/stdout;;
        induce|uadm)
            jq 'if (.ec == "0") then . else empty end' $1 >tmp/delta;
            if [ -s tmp/delta ]; then
                cat tmp/delta;
            fi;;
        *)
            ;;
    esac
}

args >tmp/${util}_$fn.args
~/bin/tonos-cli -j run --boc $boc --abi $abi $fn tmp/${util}_$fn.args >tmp/${util}_$fn.out
filter tmp/${util}_$fn.out
