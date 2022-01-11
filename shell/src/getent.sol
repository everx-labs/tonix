pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract getent is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (string[] args, , ) = _get_args(e[IS_ARGS]);

        uint n_args = args.length;
        if (n_args > 0) {
            string db_name = args[0];
            string key;
            if (n_args > 1)
                key = args[1];
            uint16 db_inode = _resolve_absolute_path("/etc/" + db_name, inodes, data);
            if (db_inode < INODES)
                err = "Unknown database: " + db_name + "\n Try `getent --help' or `getent --usage' for more information.";
            else {
                string text = _get_file_contents(db_inode, inodes, data);
                (string[] lines, ) = _split(text, "\n");
                for (string line: lines) {
                    if (key.empty())
                        out.append(line + "\n");
                    else {
                        (string[] fields, uint n_fields) = _split(line, ":");
                        if (n_fields > 0)
                            if (fields[0] == key)
                                out.append(line + "\n");
                    }
                }
            }
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
            "getent",
            "get entries from Name Service Switch libraries",
            "[option]... database key...",
            "Displays entries from databases supported by the Name Service Switch libraries, which are configured in /etc/nss‐witch.conf.  If one or more key arguments are provided, then only the entries that match the supplied keys will be displayed. Otherwise, if no key is provided, all entries will be displayed.  Supported databases:",
            "i",
            1,
            2, [
                "disable IDN encoding in lookups"]);
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