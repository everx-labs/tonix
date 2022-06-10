pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract grep is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        (uint16 wd, string[] v_args, string flags, ) = p.get_env();
        if (v_args.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            p.puts(libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n"));
            return p;
        }
        string[] params;
        string[] f_args;
        uint n_args = v_args.length;

        for (uint i = 0; i < n_args; i++) {
            string param = v_args[i];
            (, uint8 t, , ) = fs.resolve_relative_path(param, wd, inodes, data);
            if (t == ft.FT_UNKNOWN)
                params.push(param);
            else
                f_args.push(param);
        }

        for (string param: f_args) {
            (uint16 index, uint8 t, , ) = fs.resolve_relative_path(param, sb.ROOT_DIR, inodes, data);
            if (t != ft.FT_UNKNOWN)
                p.puts(_grep(flags, fs.get_file_contents(index, inodes, data), params));
            else {
                p.perror("Failed to resolve relative path for" + param);
//                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _grep(string flags, string text, string[] params) private pure returns (string out) {
        (string[] lines, uint n_lines) = text.split("\n");
        bool invert_match = arg.flag_set("v", flags);
        bool match_lines = arg.flag_set("x", flags);
        uint n_params = params.length;

        string pattern;
        if (n_params > 0)
            pattern = params[0];

        uint p_len = pattern.byteLength();
        for (uint i = 0; i < n_lines; i++) {
            string line = lines[i];
            if (line.empty())
                continue;
            bool found = false;
            if (match_lines)
                found = line == pattern;
            else {
                if (p_len > 0) {
                    uint l_len = line.byteLength();
                    for (uint j = 0; j < l_len - p_len; j++)
                        if (line.substr(j, p_len) == pattern) {
                            found = true;
                            break;
                        }
                }
            }
            if (invert_match)
                found = !found;
            if (found || p_len == 0)
                out.append(line + "\n");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"grep",
"[OPTION...] PATTERNS [FILE...]",
"print lines that match patterns",
"Searches for PATTERNS in each FILE and prints each line that matches a pattern.",
"-v      invert the sense of matching, to select non-matching lines\n\
-x      select only those matches that exactly match the whole line",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
