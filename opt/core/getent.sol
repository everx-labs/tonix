pragma ton-solidity >= 0.67.0;

import "putil_stat.sol";

contract getent is putil_stat {
    using libstring for string;
    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        uint n_params = params.length;
        if (n_params > 0) {
            string db_name = params[0];
            string key = n_params > 1 ? params[1] : "";
            uint16 db_inode = fs.resolve_absolute_path("/etc/" + db_name, inodes, data);
            if (db_inode >= sb.ROOT_DIR) {
                string text = fs.get_file_contents(db_inode, inodes, data);
                (string[] lines, ) = text.split("\n");
                for (string line: lines) {
                    (string[] fields, uint n_fields) = line.split(":");
                    if (key.empty() || n_fields > 0 && fields[0] == key)
                        e.puts(line);
                }
            } else
                e.perror("Unknown database: " + db_name + "\n Try `getent --help' or `getent --usage' for more information.");
        } else
            e.perror("wrong number of arguments\nTry `getent --help' or `getent --usage' for more information.");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"getent",
"[option]... database key...",
"get entries from Name Service Switch libraries",
"Displays entries from databases supported by the Name Service Switch libraries, which are configured in /etc/nsswitch.conf.  If one or more key arguments are provided, then only the entries that match the supplied keys will be displayed. Otherwise, if no key is provided, all entries will be displayed.  Supported databases:",
"-i     Disables IDN encoding in lookups for ahosts/getaddrinfo",
"",
"Written by Boris",
"",
"nsswitch.conf",
"0.02");
    }

}
