pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract whatis is Utility {

    function exec(Session /*session*/, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, string[] args, ) = input.unpack();
        if (args.empty())
            return "whatis what?\n";
        for (string s: args) {
            if (_is_command_page_available(s, inodes, data)) {
                (string name, string purpose, , , , ) = _get_command_page(s, inodes, data);
                out.append(name + " (1)\t\t\t - " + purpose + "\n");
            } else
                out.append(s + ": nothing appropriate.\n");
        }
    }

    function _is_command_page_available(string command_name, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (bool) {
        uint16 usr_dir_index = _resolve_absolute_path("/usr", inodes, data);
        (uint16 command_index, uint8 ft) = _lookup_dir(inodes[usr_dir_index], data[usr_dir_index], command_name);
        return ft > FT_UNKNOWN && inodes.exists(command_index) && data.exists(command_index);
    }

    function _get_command_page(string command, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        (string[] command_data, uint n_fields) = stdio.split(_get_file_contents_at_path("/usr/" + command, inodes, data), "\n");
        if (n_fields > 5)
            return (command_data[0], command_data[1], stdio.join_fields(stdio.get_tsv(command_data[3]), "\n"),
                stdio.get_tsv(command_data[2]), command_data[4], stdio.get_tsv(command_data[5]));
    }

     function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"whatis",
"[-dlv] name ...",
"display one-line manual page descriptions",
"Searches the manual page names and displays the manual page descriptions of any name matched.",
"-d      emit debugging messages\n\
-l      do not trim output to terminal width\n\
-v      print verbose warning messages",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
