pragma ton-solidity >= 0.61.0;

import "putil_stat.sol";

contract grep is putil_stat {

function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
//        (uint16 wd, string[] v_args, string flags, ) = p.get_env();
        string[] v_args = e.params();
        uint16 wd = e.get_cwd();
        if (v_args.empty()) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            e.puts(libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n"));
            return e;
        }
        string[] params;
        string[] f_args;
        uint n_args = v_args.length;

        for (uint i = 0; i < n_args; i++) {
            string param = v_args[i];
            (, uint8 t, , ) = fs.resolve_relative_path(param, wd, inodes, data);
            if (t == libstat.FT_UNKNOWN)
                params.push(param);
            else
                f_args.push(param);
        }

        for (string param: f_args) {
            (uint16 index, uint8 t, , ) = fs.resolve_relative_path(param, sb.ROOT_DIR, inodes, data);
            if (t != libstat.FT_UNKNOWN)
                e.puts(_grep(e, fs.get_file_contents(index, inodes, data), params));
            else {
                e.perror("Failed to resolve relative path for" + param);
//                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _grep(shell_env e, string text, string[] params) private pure returns (string out) {
        (string[] lines, uint n_lines) = text.split("\n");
        bool invert_match = e.flag_set("v");
        bool match_lines = e.flag_set("x");
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
