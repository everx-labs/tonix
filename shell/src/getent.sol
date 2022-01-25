pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract getent is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (, string[] params, , ) = arg.get_env(argv);

        uint n_args = params.length;
        if (n_args > 0) {
            string db_name = params[0];
            string key;
            if (n_args > 1)
                key = params[1];
            uint16 db_inode = fs.resolve_absolute_path("/etc/" + db_name, inodes, data);
            if (db_inode < INODES) {
                err = "Unknown database: " + db_name + "\n Try `getent --help' or `getent --usage' for more information.";
                ec = EXECUTE_FAILURE;
            } else {
                string text = fs.get_file_contents(db_inode, inodes, data);
                (string[] lines, ) = stdio.split(text, "\n");
                for (string line: lines) {
                    if (key.empty())
                        out.append(line + "\n");
                    else {
                        (string[] fields, uint n_fields) = stdio.split(line, ":");
                        if (n_fields > 0)
                            if (fields[0] == key)
                                out.append(line + "\n");
                    }
                }
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"getent",
"[option]... database key...",
"get entries from Name Service Switch libraries",
"Displays entries from databases supported by the Name Service Switch libraries, which are configured in /etc/nss‐witch.conf.  If one or more key arguments are provided, then only the entries that match the supplied keys will be displayed. Otherwise, if no key is provided, all entries will be displayed.  Supported databases:",
"-i     Disables IDN encoding in lookups for ahosts/getaddrinfo",
"",
"Written by Boris",
"",
"nsswitch.conf",
"0.01");
    }

}
