pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "../lib/pw.sol";

contract login is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (bool pre_auth, bool use_hostname, bool autologin, bool preserve_env, , , , ) = p.flag_values("fhpr");
        string a_host_name = p.opt_value("h");
        string a_user_name = p.opt_value("f");

        (string etc_passwd, , , ) = fs.get_passwd_group(inodes, data);
        (string pwd_line, s_passwd res) = pw.getnam(a_user_name, etc_passwd);
        if (pwd_line.empty())
            p.perror("login incorrect");

        (string pw_name, uint16 pw_uid, uint16 pw_gid, string pw_gecos, string pw_dir, string pw_shell) = res.unpack();
        string v_list = vars.as_var_list("-ir", [
            ["UID", str.toa(pw_uid)],
            ["GID", str.toa(pw_gid)],
            ["EUID", str.toa(pw_uid)]]);
        v_list.append(vars.as_var_list("-x", [
            ["USER", pw_name],
            ["HOME", pw_dir],
            ["SHELL", pw_shell],
            ["SHLVL", "1"],
            ["HOSTNAME", a_host_name],
            ["WD", str.toa(sb.ROOT_DIR)],
            ["PWD", "/"],
            ["OLDPWD", "/"]
            ]));
        (string[] lines, ) = v_list.split("\n");
        for (string line: lines)
            p.puts(vars.print_reusable(line));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"login",
"[-h host] [username] -r host",
"begin session on the system",
"Establish a new session with the system.",
"-f      do not perform authentication, user is preauthenticated\n\
-h      name of the remote host for this login\n\
-r      perform autologin protocol for rlogin",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
