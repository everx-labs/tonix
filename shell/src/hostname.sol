pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract hostname is Utility {
    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, , uint flags) = input.unpack();

        bool long_host_name = (flags & _f) > 0;
        bool addresses = (flags & _i) > 0;

        (string[] f_hostname, uint n_fields) = _split(_get_file_contents_at_path("/etc/hostname", inodes, data), "\n");
        if (n_fields > 0) {
            string s_domain = "tonix";

            if (addresses && n_fields > 1)
                return f_hostname[1];
            out = f_hostname[0];
            if (long_host_name)
                out.append("." + s_domain);
        } else {
            out = session.host_name;
        }
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
