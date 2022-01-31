pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract tr is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;
        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_tr(flags, fs.get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(s_arg);
        }
    }

    function _tr(string flags, string texts, string[] params) private pure returns (string out) {
        (string[] text, ) = stdio.split(texts, "\n");
        bool delete_chars = arg.flag_set("d", flags);
        bool squeeze_repeats = arg.flag_set("s", flags);
        string set_from;
        string set_to;

        if (!params.empty()) {
            set_from = params[0];
            set_to = !delete_chars && params.length > 1 ? params[1] : "";
        }

        for (string line: text)
            out.append(squeeze_repeats ? stdio.tr_squeeze(line, set_from) : stdio.translate(line, set_from, set_to) + "\n");
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
