pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract tr is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (uint16 wd, string[] v_args, string flags, ) = _get_env(argv);
        string[] params;
        for (string arg: v_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_tr(flags, _get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(arg);
        }
    }

    function _tr(string flags, string texts, string[] params) private pure returns (string out) {
        (string[] text, ) = _split(texts, "\n");
        bool delete_chars = _flag_set("d", flags);
        bool squeeze_repeats = _flag_set("s", flags);
        string set_from;
        string set_to;

        if (!params.empty()) {
            set_from = params[0];
            set_to = !delete_chars && params.length > 1 ? params[1] : "";
        }

        for (string line: text)
            out.append(squeeze_repeats ? _tr_squeeze(line, set_from) : _translate(line, set_from, set_to) + "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("tr", "translate or delete characters", "[OPTION]... SET1 [SET2]",
            "Translate, squeeze, and/or delete characters from standard input, writing to standard output.",
            "ds", 1, M, [
            "delete characters in SET1, do not translate",
            "replace each sequence of a repeated character that is listed in the last specified SET, with a single occurrence of that character"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tr",
"[OPTION]... SET1 [SET2]",
"translate or delete characters",
"Translate, squeeze, and/or delete characters from standard input, writing to standard output.",
"-d      delete characters in SET1, do not translate\n\
-s      replace each sequence of a repeated character that is listed in the last specified SET, with a single occurrence of that character",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
