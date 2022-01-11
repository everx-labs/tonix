pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract pathchk is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, string[] args, uint flags) = input.unpack();
        string[] params;

        for (string arg: args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, session.wd, inodes, data);
            if (ft == FT_UNKNOWN)
                params.push(arg);
            else
                out.append(_pathchk(flags, _get_file_contents(index, inodes, data), params) + "\n");
        }
    }

    function _pathchk(uint flags, string texts, string[] params) private pure returns (string out) {
        (string[] text, ) = _split(texts, "\n");
        bool convert_initial_tabs = (flags & _i) > 0;
        bool use_tab_size = (flags & _t) > 0;
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            tab_size = _atoi(params[0]);
            if (tab_size < 1)
                return "error";
        }

        string tab_spaces = _spaces(tab_size);
        for (string line: text) {
            if (convert_initial_tabs) {
                uint p = 0;
                while (line.substr(p, 1) == "\t")
                    p++;
                if (p > 0) {
                    for (uint i = 0; i < p; i++)
                        out.append(tab_spaces);
                    out.append(line.substr(p));
                } else
                    out.append(line);
            } else
                out.append(_translate(line, "\t", tab_spaces));
            out.append("\n");
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("pathchk", "check whether file names are valid or portable", "[OPTION]... NAME...",
            "Diagnose invalid or unportable file names.",
            "pP", 1, M, [
            "check for most POSIX systems",
            "check for empty names and leading \"-\""]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"pathchk",
"[OPTION]... NAME...",
"check whether file names are valid or portable",
"Diagnose invalid or unportable file names.",
-p      check for most POSIX systems\n\
-P      check for empty names and leading \"-\"",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
