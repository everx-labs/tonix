set -x
#echo $# $0 $1 $2 $3
fn=$1
shift
param=$1

case $fn in
    b_exec|exec|ustat|read_fs_to_env|exec_env|induce|uadm)
        util=$param;;
    read_local)
        util=$param;
        shift;
        fn=b_exec;
        input=`cat $1`;
        ;;
    command_help)
        util=$param;;
    display_man_page)
        util=man;;
    handle_action)
        util=tmpfs;;
    *)
        util=command;;
esac

abi=build/$util.abi.json
boc=bin/$util.boc

args() {
   case $fn in
        ustat|uadm|induce)
#            jq -s add vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out run/fs;;
            jq --rawfile args run/export '. + {$args}' run/fs;;
        execute_command)
#            jq -n --slurpfile annotation run/annotation '{$annotation}';;
            jq -n --rawfile args run/args --rawfile page run/comp_spec --rawfile pool run/pool '{$args, $page, $pool}';;
        exec)
            jq --rawfile args run/export '. + {$args}' run/fs;;
        fwrite)
            jq -s add vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out vfs/tmp/fs vfs/tmp/tosh/write_path vfs/tmp/tosh/write_contents;;
        handle_action)
            jq '.inodes_in = .inodes | .data_in = .data | del(.inodes, .data)' run/fs >vfs/tmp/tmpfs/fs_in;
            jq -s 'add' vfs/tmp/session  vfs/tmp/tosh/tosh_process_input.out vfs/tmp/tmpfs/fs_in vfs/tmp/tmpfs/delta;;
        alter)
            jq '.inodes_in = .inodes | .data_in = .data | del(.inodes, .data)' run/fs >vfs/tmp/tmpfs/fs_in;
            jq -s 'add' vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out vfs/tmp/tmpfs/fs_in;;
        display_man_page)
            jq -n --rawfile v run/args --slurpfile v1 vfs/usr/share/man_pages '{args: $v, help_files: $v1}';;
        *)
            echo '{}';;
    esac
}

filter() {
    case $fn in
        execute_command)
#            eval `jq -r '.res' $1`;;
            echo `jq -r '.res' $1`;;
        ustat)
            cp $1 vfs/tmp/tosh/post_b_exec;;
        exec)
            jq -rj '.out' $1 >run/stdout;
            jq -rj '.err' $1 >run/stderr;;
        display_man_page)
            jq -rj '.out' $1 >run/stdout;;
        b_exec)
            cp $1 vfs/tmp/tosh/post_b_exec;;
        uadm)
            cp $1 tmp/delta;;
        induce)
#            if [ -s vfs/tmp/tosh/cmd_errors ]; then
#                echo User admin command execution error!;
#                jq '.[]' vfs/tmp/tosh/cmd_errors;
#            else
                cp $1 tmp/delta;
                ./tmpfs handle_action;;
        handle_action)
            cp $1 vfs/tmp/tmpfs/fs_out;
            cp vfs/tmp/tmpfs/fs_out run/fs;;
        alter)
            cp $1 vfs/tmp/tmpfs/fs_out;;
        *)
            ;;
    esac
}

args >tmp/${util}_$fn.args
~/bin/tonos-cli -j run --boc $boc --abi $abi $fn tmp/${util}_$fn.args >tmp/${util}_$fn.out
filter tmp/${util}_$fn.out
