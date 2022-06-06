pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract hostid is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = arg.get_env(argv);
        if (params.empty() && flags.empty())
            ec = EXECUTE_SUCCESS;
        string host_name = vars.val("HOSTNAME", argv);
        bool long_host_name = arg.flag_set("f", flags);
        bool addresses = arg.flag_set("i", flags);

        (string[] f_hostname, uint n_fields) = libstring.split(fs.get_file_contents_at_path("/etc/hostname", inodes, data), "\n");
        if (n_fields > 0) {
            string sdomain = "tonix";
            if (addresses && n_fields > 1)
                out = f_hostname[1];
            else {
                out = f_hostname[0];
                if (long_host_name)
                    out.append("." + sdomain);
            }
        } else
            out = host_name;
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
"0.01");
    }

}