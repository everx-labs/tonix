pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract jobs is Shell {

    function _index_of(string s_array, string arg) internal pure returns (uint) {
        (string[] fields, uint n_fields) = _split(s_array, " ");
        for (uint i = 0; i < n_fields; i++)
            if (arg == fields[i])
                return i + 1;
    }

    function _add_job(string s_input, mapping (uint => ItemHashMap) env_in, mapping (uint16 => Job) jobs_in) internal pure returns (uint16 ec, string out, mapping (uint => ItemHashMap) env, InputS input, string script, mapping (uint16 => Job) jobs_out) {
        //(ec, out, env, input, pc, parse_errors, script, jobs, session) = _parse_input(s_input, env_in, jobs_in);
        uint p = _strrchr(s_input, ">");
        uint q = _strrchr(s_input, "<");
        (string c, string s_args) = _strsplit(s_input, " ");
        string out_redirect = p > 0 ? _strtok(s_input, p, " ") : "";
        string in_redirect = q > 0 ? _strtok(s_input, q, " ") : "";

        string[] args;
        string short_options;
        string[] long_options;
        string s_action;

        env = env_in;
        if (!s_args.empty())
            (args, short_options, long_options) = _parse_args(s_args);

        uint flags;// = _parse_short_options(short_options);
        input = InputS(0, args, flags);

        if (s_action.empty()) {
            s_action = _shell_command(c);

            if (!s_action.empty()) {
                script = "./vfs/usr/bin/tosh" + " " + s_action + " " + c + ";";
                if (!out_redirect.empty()) {
                    script.append("./vfs/bin/tmpfs fopen " + out_redirect + ";");
                    script.append("./vfs/bin/tmpfs fwrite vfs/tmp/tmpfs/file_in;");
                    script.append("./vfs/bin/tmpfs fclose " + out_redirect + ";");
                }
            } else {
                string comp;// = _try_complete(c, env_in);
                if (!comp.empty()) {
                    (, string func_name) = _strsplit(comp, " ");
                    string func_body = env_in[tvm.hash("function")].value[tvm.hash(func_name)].value;
                    script = "./vfs" + func_body + " " + c + ";";
                }
            }
        }
//        pc = ParsedCommand(c, args, short_options, long_options, in_redirect, out_redirect, action, s_action);

        string cmd_type;// = _lookup_command_type_string(c, env);
        uint16[] none;
        jobs_out = jobs_in;
        optional (uint16, Job) max_id = jobs_out.max();
        uint16 id;
        if (max_id.hasValue())
            (id, ) = max_id.get();
        id++;
        jobs_out[id] = Job(id, id, none, "new", "", out, "", s_input, c, cmd_type, s_args, args, short_options, long_options, in_redirect, out_redirect, s_action, script, ec);
    }

    function _shell_command(string c) internal pure returns (string s_action) {
        if (_op_builtin_s(c) || _op_builtin_job_s(c) || _op_builtin_read_fs_s(c) || _op_builtin_read_fs_to_env_s(c) ||
            _op_stat_s(c) || _op_file_s(c) || _op_access_s(c) || _is_pure_s(c) || _op_dev_stat_s(c) || _op_format_s(c) || _op_user_admin_s(c) ||
            _op_user_stats_s(c) || _op_user_access_s(c) || _reads_file_fixed_s(c) || _op_filesystem_s(c) || _op_dev_admin_s(c) || c == "login" || c == "help") {
            if (_op_builtin_s(c)) s_action = "exec_builtin";
            if (_op_builtin_read_fs_s(c)) s_action = "read_fs";
            if (_op_builtin_read_fs_to_env_s(c)) s_action = "read_fs_to_env";
            if (_op_file_s(c) || _op_access_s(c)) s_action = "induce";
            if (_is_pure_s(c)) s_action = "exec";
            if (_op_dev_stat_s(c)) s_action = "exec";
            if (_op_format_s(c)) s_action = "exec";
            if (_op_user_admin_s(c)) s_action = "uadm";
            if (_op_user_stats_s(c)) s_action = "ustat";
            if (_op_user_access_s(c)) s_action = "exec";
            if (_reads_file_fixed_s(c)) s_action = "exec";
            if (_op_filesystem_s(c)) s_action = "alter";
            if (_op_dev_admin_s(c)) s_action = "exec";
            if (c == "login") s_action = "authorize";
            if (c == "help") s_action = "format_builtin_help";
        }
    }

    function _is_pure_s(string c) internal pure returns (bool) {
        return c == "basename" || c == "dirname" || c == "pathchk" || c == "uname";
    }

    function _op_stat_s(string c) internal pure returns (bool) {
        return c == "cksum" || c == "du" || c == "file" || c == "getent" || c == "ls" || c == "namei" || c == "stat";
    }

    function _op_format_s(string c) internal pure returns (bool) {
        return c == "cat" || c == "colrm" || c == "column" || c == "cut" || c == "expand" || c == "grep" || c == "head" || c == "look"
           || c == "more" || c == "paste" || c == "rev" || c == "tail" || c == "tr" || c == "unexpand" || c == "wc";
    }

    function _op_fs_status_s(string c) internal pure returns (bool) {
        return c == "cksum" || c == "du" || c == "file" || c == "ls" || c == "stat";
    }

    function _op_filesystem_s(string c) internal pure returns (bool) {
        return c == "mke2fs" || c == "fsck" || c == "mount" || c == "umount";
    }

    function _op_dev_stat_s(string c) internal pure returns (bool) {
        return c == "df" || c == "findmnt" || c == "lsblk" || c == "mountpoint";
    }

    function _op_dev_admin_s(string c) internal pure returns (bool) {
        return c == "losetup" || c == "mknod" || c == "mount" || c == "udevadm" || c == "umount";
    }

    function _op_access_s(string c) internal pure returns (bool) {
        return c == "chgrp" || c == "chmod" || c == "chown";
    }

    function _op_file_s(string c) internal pure returns (bool) {
        return c == "cp" || c == "cmp" || c == "dd" || c == "fallocate" || c == "ld" || c == "ln" || c == "mkdir" || c == "mv" || c == "rm"
           || c == "rmdir" || c == "tar" || c == "touch" || c == "truncate";
    }

    function _op_file_action_s(string c) internal pure returns (bool) {
        return c == "cp" || /*c == "cmp" || c == "dd" || */c == "fallocate" || c == "ld" || c == "ln" || c == "mkdir" || c == "mv" || c == "rm"
           || c == "rmdir" || c == "tar" || c == "touch" || c == "truncate";
    }

    function _op_builtin_s(string c) internal pure returns (bool) {
        return c == "login" || c == "logout";
    }

    function _op_builtin_job_s(string c) internal pure returns (bool) {
        return c == "declare" || c == "type" || c == "hash" || c == "command" || c == "alias" || c == "unalias" || c == "unset" || c == "readonly"
            || c == "export" || c == "enable" || c == "builtin" || c == "echo" || c == "complete" || c == "ulimit" || c == "compopt" || c == "mapfile";
    }

    function _op_builtin_read_fs_s(string c) internal pure returns (bool) {
        return c == "test";
    }

    function _op_builtin_read_fs_to_env_s(string c) internal pure returns (bool) {
        return c == "pwd" || c == "cd" || c == "dirs" || c == "pushd" || c == "popd" || c == "compgen";
    }

    function _op_user_access_s(string c) internal pure returns (bool) {
        return c == "login" || c == "logout" || c == "newgrp";
    }

    function _op_network_s(string c) internal pure returns (bool) {
        return c == "account" || c == "mount" || c == "ping";
    }

    function _op_user_admin_s(string c) internal pure returns (bool) {
        return c == "gpasswd" || c == "groupadd" || c == "groupdel" || c == "groupmod" || c == "useradd" || c == "userdel" || c == "usermod";
    }

    function _op_user_stats_s(string c) internal pure returns (bool) {
        return c == "finger" || c == "fuser" || c == "id" || c == "last" || c == "lslogins" || c == "ps" || c == "utmpdump" || c == "who" || c == "whoami" || c == "hostname";
    }

    function _reads_file_fixed_s(string c) internal pure returns (bool) {
        return c == "man" || c == "whatis" || c == "whereis";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"jobs",
"[-lnprs] [jobspec ...] or jobs -x command [args]",
"Display status of jobs.",
"Lists the active jobs.  JOBSPEC restricts output to that job. Without options, the status of all active jobs is displayed.",
"-l        lists process IDs in addition to the normal information\n\
-n        lists only processes that have changed status since the last notification\n\
-p        lists process IDs only\n\
-r        restrict output to running jobs\n\
-s        restrict output to stopped jobs",
"If -x is supplied, COMMAND is run after all job specifications that appear in ARGS have been replaced with the process ID\n\
of that job's process group leader.",
"Returns success unless an invalid option is given or an error occurs. If -x is used, returns the exit status of COMMAND.");
    }
}
