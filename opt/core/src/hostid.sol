pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";

contract hostid is putil_stat {

function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        string host_name = e.env_value("HOSTNAME");
        bool long_host_name = e.flag_set("f");
        bool addresses = e.flag_set("i");

        (string[] f_hostname, uint n_fields) = libstring.split(fs.get_file_contents_at_path("/etc/hostname", inodes, data), "\n");
        if (n_fields > 0) {
            string sdomain = "tonix";
            if (addresses && n_fields > 1)
                e.puts(f_hostname[1]);
            else {
                e.puts(f_hostname[0]);
                if (long_host_name)
                    e.puts("." + sdomain);
            }
        } else
            e.puts(host_name);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"hostid",
"[OPTION]",
"print the numeric identifier for the current host",
"Print the numeric identifier (in hexadecimal) for the current host.",
"",
"",
"Written by Boris",
"",
"gethostid",
"0.02");
    }

}
