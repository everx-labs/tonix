pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract hostname is Utility {

    function exec(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , , string flags, ) = _get_env(args);
        ec = EXECUTE_SUCCESS;
        string host_name = _val("HOSTNAME", args);
        bool long_host_name = _flag_set("f", flags);
        bool addresses = _flag_set("i", flags);

        (string[] f_hostname, uint n_fields) = _split(_get_file_contents_at_path("/etc/hostname", inodes, data), "\n");
        if (n_fields > 0) {
            string s_domain = "tonix";
            if (addresses && n_fields > 1)
                out = f_hostname[1];
            else {
                out = f_hostname[0];
                if (long_host_name)
                    out.append("." + s_domain);
            }
        } else
            out = host_name;
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("hostname", "show or set the system's host name", "[-afis]",
            "Display the system's hostname and address",
            "afis", 0, 0, [
            "alias names",
            "long host name (FQDN)",
            "addresses for the host name",
            "short host name"]);
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
"0.01");
    }

}
