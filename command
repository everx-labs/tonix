#set -x
#echo $# $0 $1 $2 $3
fn=$1
shift
param=$1

case $fn in
    b_exec|builtin_read_fs|builtin_help|exec|ustat|read_fs_to_env)
        util=$param;;
    read_local)
        util=$param;
        shift;
        fn=b_exec;
        input=`cat $1`;
        ;;
    display_help)
        util=help;;
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
boc=vfs/tmp/sbin/$util.boc

args() {
   case $fn in
        builtin_read_fs)
           jq '{e: .}' run/env >vfs/tmp/tosh/shell_in;
#           jq -s 'add' vfs/tmp/tosh/shell_in vfs/tmp/fs;;
           jq -s 'add' vfs/tmp/tosh/shell_in run/fs;;
        ustat|uadm|induce)
            jq -s add vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out run/fs;;
        exec)
            jq --rawfile args run/args '. + {$args}' run/fs;;
        exec_env)
            jq --rawfile args run/args --rawfile pool run/pool '. + {$args} + {$pool}' run/fs;;
        on_exec)
            jq '{e: .}' run/env >vfs/tmp/tosh/shell_in;
            jq -s 'add' vfs/tmp/tosh/shell_in vfs/tmp/tosh/post_exec;;
        on_b_exec)
            jq '{e: .}' run/env >vfs/tmp/tosh/shell_in;
            jq '.delta=(.wr // [])' vfs/tmp/tosh/post_b_exec >vfs/tmp/tosh/delta_in;
            jq -s 'add' vfs/tmp/tosh/shell_in vfs/tmp/tosh/delta_in;;
        fwrite)
            jq -s add vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out vfs/tmp/fs vfs/tmp/tosh/write_path vfs/tmp/tosh/write_contents;;
        handle_action)
#            jq '.inodes_in = .inodes | .data_in = .data | del(.inodes, .data)' vfs/tmp/fs >vfs/tmp/tmpfs/fs_in;
            jq '.inodes_in = .inodes | .data_in = .data | del(.inodes, .data)' run/fs >vfs/tmp/tmpfs/fs_in;
            jq -s 'add' vfs/tmp/session  vfs/tmp/tosh/tosh_process_input.out vfs/tmp/tmpfs/fs_in vfs/tmp/tmpfs/delta;;
        alter)
            jq '.inodes_in = .inodes | .data_in = .data | del(.inodes, .data)' run/fs >vfs/tmp/tmpfs/fs_in;
            jq -s 'add' vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out vfs/tmp/tmpfs/fs_in;;
        read_profile)
            jq -Rs '{profile: .}' vfs/etc/profile;;
        read_local)
            jq -r '{e: .}' run/env | jq --arg v "$input" '.e[0]=$v';;
        display_man_page)
            jq '{e: .}' run/env >vfs/tmp/tosh/s_env;
            jq -s '{help_files: .}' vfs/usr/share/man_pages >vfs/tmp/tosh/s_man_pages;
            jq -s add vfs/tmp/tosh/s_man_pages vfs/tmp/tosh/s_env;;
        builtin)
            jq -s add vfs/tmp/session vfs/tmp/tosh/tosh_process_input.out run/fs;;
        *)
            echo '{}';;
    esac
}

filter() {
    case $fn in
        get_command_info)
            cp $1 vfs/usr/share/$util.info;;
        builtin_help)
            cp $1 vfs/usr/share/$util.help;;
        command_help)
            cp $1 vfs/usr/share/$util.man;;
        read_profile)
            jq '.env' $1 >vfs/tmp/tosh/env3;;
        read_local)
           cp $1 vfs/tmp/tosh/post_b_exec;;
        builtin_read_fs|ustat)
            cp $1 vfs/tmp/tosh/post_b_exec;;
        exec)
#            cp $1 tmp/post_exec;;
            jq -rj '.out' $1 >run/stdout;
            jq -rj '.err' $1 >run/stderr;;
        display_man_page)
            cp $1 vfs/tmp/tosh/post_exec;;
        display_help|b_exec)
            cp $1 vfs/tmp/tosh/post_b_exec;;
        on_exec)
            jq -r 'if has("env") then .env else empty end' $1 >vfs/tmp/tosh/env3_t;
            if [ -s vfs/tmp/tosh/env3_t ]; then
                cp vfs/tmp/tosh/env3_t run/env;
            fi;
            jq -rj '.env[1]' $1 >run/stdout;
            jq -rj '.env[2]' $1 >run/stderr;
            ;;
        on_b_exec)
            jq -r 'if has("env") then .env else empty end' $1 >vfs/tmp/tosh/env3_t;
            if [ -s vfs/tmp/tosh/env3_t ]; then
                cp vfs/tmp/tosh/env3_t run/env;
            fi;
            jq -rj '.env[1]' $1 >run/stdout;
            jq -rj '.env[2]' $1 >run/stderr;
            ;;
        uadm|induce)
            if [ -s vfs/tmp/tosh/cmd_errors ]; then
                echo User admin command execution error!;
                jq '.[]' vfs/tmp/tosh/cmd_errors;
            else
                cp $1 vfs/tmp/tmpfs/delta;
                ./vfs/bin/tmpfs handle_action;
            fi;;
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
