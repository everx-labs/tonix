pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";

contract hostname is putil_stat {

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
"hostname",
"[-afis]",
"show or set the system's host name",
"Display the system's hostname and address",
"-a      alias names\n\
-f      long host name (FQDN)\n\
-i      addresses for the host name\n\
-s      short host name",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
