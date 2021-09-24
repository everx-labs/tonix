pragma ton-solidity >= 0.49.0;

import "Format.sol";
import "SyncFS.sol";
import "CacheFS.sol";

contract PrintFormatted is Format, SyncFS, CacheFS {

    /* Process commands which do not require intrinsic knowledge about the file system */
    function process_command(Session session, InputS input) external view returns (string out, string err) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        Err[] errors;
        session.wd = session.wd;

        /* "pure" commands */
        if (c == basename) out = _basename(args, flags);
        if (c == dirname) out = _dirname(args);
        if (c == echo) out = _echo(flags, args);
        if (c == uname) out = _uname(flags);

        /* informational commands */
        if (c == help) out = _help(args);
        if (c == man) out = _man(args);
        if (c == whatis) out = _whatis(args);

        err = _print_errors(c, errors);
    }

    /* Format text data most likely obtained from a text file */
    function format_text(InputS input, string[][] texts, Arg[] args) external pure returns (string out) {
        return _format_text(input, texts, args);
    }

    /* Format text data most likely obtained from a text file */
    function process_text_files(Session session, InputS input, Arg[] args) external view returns (string out, string err) {
        Err[] errors;

        uint len = args.length;
        string[][] texts;
        for (uint i = 0; i < len; i++) {
            (, , uint16 idx, , ) = args[i].unpack();

            texts.push(_fs.inodes[idx].text_data);
        }
        session.wd = session.wd;
        out = _format_text(input, texts, args);
        err = _print_errors(input.command, errors);
    }

    /* Print error messages */
    function print_error_message(uint8 command, Err[] errors) external view returns (string err) {
        return _print_errors(command, errors);
    }

    function _format_text(InputS input, string[][] texts, Arg[] args) internal pure returns (string out) {
        (uint8 c, string[] s_args, uint flags) = input.unpack();

        if (c == paste) out = _paste(flags, texts);
        uint n_texts = texts.length;
        string[] params;

        for (uint i = 0; i < n_texts; i++) {
            string[] text = texts[i];
            if (text.empty()) {
                params.push(s_args[i]);
                continue;
            }
            if (c == cat) out.append(_cat(flags, text));
            if (c == colrm) out.append(_colrm(text, params));
            if (c == column) out.append(_column(flags, text, params));
            if (c == cut) out.append(_cut(flags, text, params));
            if (c == expand) out.append(_expand(flags, text, params));
            if (c == grep) out.append(_grep(flags, text, params));
            if (c == head) out.append(_head(flags, text, args[i], params));
            if (c == look) out.append(_look(flags, text, params));
//            if (c == more) out.append(_more(flags, text, args)); // Belongs to terminal
            if (c == rev) out.append(_rev(text));
            if (c == tail) out.append(_tail(flags, text, args[i], params));
            if (c == tr) out.append(_tr(flags, text, params));
            if (c == unexpand) out.append(_unexpand(flags, text, params));
            if (c == wc) out.append(_wc(flags, text, args[i]));
            out.append("\n");
        }
    }
    /* Text processing commands */

    function _cat(uint flags, string[] text) private pure returns (string out) {
        bool number_lines = (flags & _n) > 0;
        bool number_nonempty_lines = (flags & _b) > 0;
        bool dollar_at_line_end = (flags & _E + _e + _A) > 0;
        bool suppress_repeated_empty_lines = (flags & _s) > 0;
        bool convert_tabs = (flags & _T + _t + _A) > 0;
        bool show_nonprinting = (flags & _v + _e + _t + _A) > 0;

        bool repeated_empty_line = false;
        for (uint i = 0; i < text.length; i++) {
            string line_in = text[i];
            uint len = line_in.byteLength();

            string line_out = (number_lines || (len > 0 && number_nonempty_lines)) ? format("   {}  ", uint16(i + 1)) : "";
            if (len == 0) {
                if (suppress_repeated_empty_lines) {
                    if (repeated_empty_line)
                        continue;
                    repeated_empty_line = true;
                }
            } else {
                if (suppress_repeated_empty_lines && repeated_empty_line)
                    repeated_empty_line = false;
                line_out.append(convert_tabs ? _translate(line_in, "\t", "^I") : line_in);
                line_out = _if(line_out, show_nonprinting && len > 1 && line_in.substr(len - 2, 1) == "\x13", "^M");
            }
            line_out = _if(line_out, dollar_at_line_end, "$");
            out.append(line_out + "\n");
        }
    }

    function _colrm(string[] text, string[] params) private pure returns (string out) {
        uint stop;
        uint n_params = params.length;
        uint start;
        bool success;
        bool second_cut = false;

        if (n_params > 0)
            (start, success) = stoi(params[0]);
        if (start < 1 || !success)
            return "error";
        if (n_params > 1) {
            (stop, success) = stoi(params[1]);
            if (stop < start || !success)
                return "also an error";
            second_cut = true;
        }
        for (string s: text) {
            if (s.empty())
                continue;
            uint s_len = s.byteLength();
            out.append(s.substr(0, math.min(s_len, start - 1)));
            if (second_cut && stop < s_len)
                out.append(s.substr(stop, s_len - stop));
            out.append("\n");
        }
    }

    function _column(uint flags, string[] text, string[] params) private pure returns (string out) {
        bool ignore_empty_lines = (flags & _e) == 0;
        bool create_table = (flags & _t) > 0;
        bool use_delimiter = (flags & _s) > 0;

        string delimiter = use_delimiter && !params.empty() ? params[0] : " ";

        string[][] table;

        for (string s: text) {
            if (s.empty() && !ignore_empty_lines)
                continue;
            if (create_table)
                table.push(_split(s, " "));
            else
                out.append(s + "\n");
        }
        if (create_table)
            out.append(_format_table(table, delimiter, "\n", ALIGN_LEFT));
    }

    function _cut(uint flags, string[] text, string[] params) private pure returns (string out) {
        bool set_fields = (flags & _f) > 0;
        bool use_delimiter = (flags & _d) > 0;
        bool only_delimited = (flags & _s) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        string delimiter = "\t";
        string s_fields;
        uint16 field;
        uint n_params = params.length;

        if (!params.empty() && use_delimiter) {
            delimiter = params[0];
            if (set_fields && n_params > 1) {
                s_fields = params[1];
                (uint fld, bool success) = stoi(s_fields);
                if (success)
                    field = uint16(fld);
            }
        }

        for (uint i = 0; i < text.length; i++) {
            string[] fields = _split(text[i], delimiter);
            uint f_len = fields.length;
            string matched;
            if (field < f_len)
                matched = fields[field];
            if (!matched.empty() && !(only_delimited && f_len == 1))
                out.append(matched + line_delimiter);
        }
    }

    function _grep(uint flags, string[] text, string[] params) private pure returns (string out) {
        bool invert_match = (flags & _v) > 0;
        bool match_lines = (flags & _x) > 0;

//        string pattern = args[0].path;
        string pattern = params[0];

        uint p_len = pattern.byteLength();
        for (uint i = 0; i < text.length; i++) {
            string line = text[i];
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

    function _head(uint flags, string[] text, Arg arg, string[] params) private pure returns (string out) {
        bool num_lines = (flags & _n) > 0;
        bool never_headers = (flags & _q) > 0;
        bool always_headers = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        uint len = text.length;
        string file_name = arg.path;
        uint n_lines = 10;
        uint n_params = params.length;

        if (num_lines && n_params > 0) {
            (uint start, bool success) = stoi(params[0]);
            if (start < 1 || !success)
                return "error";
            n_lines = start;
        }
        if (n_lines > len)
            n_lines = len;

        if (!file_name.empty() && (always_headers || !never_headers))
             out = "==> " + file_name + " <==\n";

        for (uint i = 0; i < n_lines; i++)
            out.append(text[i] + line_delimiter);
    }

    /* Actually a CRT command */
    /*function _more(uint flags, string[] text, Arg[] args) private pure returns (string out) {
        bool ring_bell = (flags & _d) == 0;
        bool logical_lines = (flags & _f) > 0; // wrap lines
        bool pause_after_form_feed = (flags & _l) == 0;
        bool clean_line_ends = (flags & _c) > 0;
        bool clean_screen = (flags & _p) > 0;
        bool squeeze_blank_lines = (flags & _s) > 0;
        bool underlining = (flags & _u) == 0;
    }*/

    function _paste(uint flags, string[][] texts) private pure returns (string out) {
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        for (uint i = 0; i < texts.length; i++)
            for (uint j = 0; j < texts[i].length; j++)
                out.append(texts[i][j] + line_delimiter);
    }

    function _rev(string[] text) private pure returns (string out) {
        for (string line: text) {
            uint line_len = line.byteLength();
            for (uint i = line_len - 1; i > 0; i--)
                out.append(line.substr(i, 1));
            out.append("\n");
        }
    }

    function _tail(uint flags, string[] text, Arg arg, string[] params) private pure returns (string out) {
        bool num_lines = (flags & _n) > 0;
        bool never_headers = (flags & _q) > 0;
        bool always_headers = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        string file_name = arg.path;
        uint n_lines = 10;
        uint len = text.length;
        uint n_params = params.length;

        if (num_lines && n_params > 0) {
            (uint start, bool success) = stoi(params[0]);
            if (start < 1 || !success)
                return "error";
            n_lines = start;
        }

        if (n_lines > len)
            n_lines = len;

        if (!file_name.empty() && (always_headers || !never_headers))
             out = "==> " + file_name + " <==\n";

        for (uint i = len - n_lines; i < len; i++)
            out.append(text[i] + line_delimiter);
    }

    function _tr(uint flags, string[] text, string[] params) private pure returns (string out) {
        bool delete_chars = (flags & _d) > 0;
        bool squeeze_repeats = (flags & _s) > 0;
        string set_from;
        string set_to;

        if (!params.empty()) {
            set_from = params[0];
            set_to = !delete_chars && params.length > 1 ? params[1] : "";
        }

        for (string line: text)
            out.append(squeeze_repeats ? _tr_squeeze(line, set_from) : _translate(line, set_from, set_to) + "\n");
    }

    function _expand(uint flags, string[] text, string[] params) private pure returns (string out) {
        bool convert_initial_tabs = (flags & _i) > 0;
        bool use_tab_size = (flags & _t) > 0;
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            (uint tsize, bool success) = stoi(params[0]);
            if (tsize < 1 || !success)
                return "error";
            tab_size = uint16(tsize);
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
                    out.append(line.substr(p, line.byteLength() - p));
                } else
                    out.append(line);
            } else
                out.append(_translate(line, "\t", tab_spaces));
            out.append("\n");
        }
    }

    function _look(uint flags, string[] text, string[] params) private pure returns (string out) {
//        bool binary_search = (flags & _b) > 0;
//        bool alphanum_set = (flags & _d) > 0;
//        bool ignore_case = (flags & _f) > 0;
        bool use_term_char = (flags & _t) > 0;

        string pattern = !params.empty() ? params[0] : "";
        string term_char = use_term_char && params.length > 1 ? params[1] : "\n";

        uint16 p = _strchr(pattern, term_char);
        if (p > 0)
            pattern = pattern.substr(0, p - 1);

        uint pattern_len = pattern.byteLength();
        for (string line: text) {
            uint line_len = line.byteLength();
            if (line_len >= pattern_len)
                if (line.substr(0, pattern_len) == pattern)
                    out.append(line + "\n");
        }
    }

    function _unexpand(uint flags, string[] text, string[] params) private pure returns (string out) {
        bool convert_all_blanks = (flags & _a) > 0;
        bool use_tab_size = (flags & _t) > 0;
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            (uint tsize, bool success) = stoi(params[0]);
            if (tsize < 1 || !success)
                return "error";
            tab_size = uint16(tsize);
        }

        string pattern = _spaces(tab_size);
        for (string line: text) {
            if (convert_all_blanks)
                out.append(_translate(line, pattern, "\t"));
            else {
                uint p = 0;
                while (line.substr(p, 1) == " ")
                    p++;
                if (p > 0) {
                    (uint n_tabs, uint n_spaces) = math.divmod(p, tab_size);
                    for (uint i = 0; i < n_tabs; i++)
                        out.append("\t");
                    for (uint i = 0; i < n_spaces; i++)
                        out.append(" ");
                    out.append(line.substr(p, line.byteLength() - p));
                } else
                    out.append(line);
            }
            out.append("\n");
        }
    }

    function _wc(uint flags, string[] text, Arg arg) private pure returns (string out) {
        bool print_bytes = true;
        bool print_chars = false;
        bool print_lines = true;
        bool print_max_width = false;
        bool print_words = true;

        if (flags > 0) {
            print_bytes = (flags & _c) > 0;
            print_chars = (flags & _m) > 0;
            print_lines = (flags & _l) > 0;
            print_max_width = (flags & _L) > 0;
            print_words = (flags & _w) > 0;
        }

        string file_name = arg.path;
        uint16 file_size = arg.dir_index;

        (uint16 lc, uint16 wc, uint32 cc, uint16 mw) = _line_and_word_count(text);

        out = _if("", print_lines, format("  {} ", lc));
        out = _if(out, print_words, format(" {} ", wc));
        out = _if(out, print_bytes, format(" {} ", file_size));
        out = _if(out, print_chars, format(" {} ", cc));
        out = _if(out, print_max_width, format(" {} ", mw));
        out.append(file_name);
    }

    /* Informational commands */
    function _help(string[] args) private view returns (string out) {
        if (args.empty())
            return "Commands: " + _join_fields(_get_file_contents("/etc/command_list"), " ") + "\n";

        for (string s: args) {
            if (!_is_command_info_available(s)) {
                out.append("help: no help topics match" + _quote(s) + "\nTry" + _quote("help help") + "or" + _quote("man -k " + s) + "or" + _quote("info " + s) + "\n");
                break;
            }
            out.append(_get_help_text(s));
        }
    }

    function _man(string[] args) private view returns (string out) {
        for (string s: args)
            out.append(_is_command_info_available(s) ? _get_man_text(s) : "No manual entry for " + s + "\n");
    }

    function _whatis(string[] args) private view returns (string out) {
        if (args.empty())
            return "whatis what?\n";

        for (string s: args) {
            if (_is_command_info_available(s)) {
                (string name, string purpose, , , , ) = _get_command_info(s);
                out.append(name + " (1)\t\t\t - " + purpose + "\n");
            } else
                out.append(s + ": nothing appropriate.\n");
        }
    }

    /* "Pure" commands */
    function _basename(string[] args, uint flags) private pure returns (string out) {
        bool multiple_args = (flags & _a) > 0; // -a
        string line_terminator = ((flags & _z) > 0) ? "\x00" : "\n";

        if (multiple_args)
            for (string s: args) {
                (, string not_dir) = _dir(s);
                out.append(not_dir + line_terminator);
            }
        else {
            (, out) = _dir(args[0]);
            out.append(line_terminator);
        }
    }

    function _dirname(string[] args) internal pure returns (string out) {
        for (string s: args) {
            (string dir, ) = _dir(s);
            out += dir + "\n";
        }
    }

    function _echo(uint flags, string[] ss) private pure returns (string out) {
        bool no_trailing_newline = (flags & _n) > 0;
        out = _join_fields(ss, " ");
        if (!no_trailing_newline)
            out.append("\n");
    }

    function _uname(uint flags) private pure returns (string out) {
        if ((flags & _a) > 0) return "Tonix FileSys TON TONOS TON";
        if ((flags & _s) > 0 || flags == 0) out = "Tonix ";
        if ((flags & _n) > 0) out.append("FileSys ");
        if ((flags & _i + _m) > 0) out.append("TON ");
        if ((flags & _o) > 0) out.append("TON OS ");
        if ((flags & _p) > 0) out.append("TON ");
    }

    /* Imports helpers */
    function _get_imported_file_contents(string path, string file_name) internal view returns (string[] text) {
        uint16 dir_index = _resolve_absolute_path(path);
        (uint16 file_index, uint8 ft) = _fetch_dir_entry(file_name, dir_index);
        if (ft > FT_UNKNOWN)
            return _fs.inodes[file_index].text_data;
        return ["Failed to read file " + file_name + " at path " + path + "\n"];
    }

    function _fetch_element(uint16 index, string path, string file_name) internal view returns (string) {
        if (index > 0) {
            string[] text = _get_imported_file_contents(path, file_name);
            return text.length > 1 ? text[index - 1] : _element_at(1, index, text, "\t");
        }
    }

    /* Informational commands helpers */
    function _get_man_text(string s) private view returns (string) {
        (string name, string purpose, string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(s);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options;
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("\t" + "-" + option_names.substr(i, 1) + "\t" + option_descriptions[i] + "\n");
        options.append("\t" + "--help\tdisplay this help and exit\n\t--version\n\t\toutput version information and exit\n");

        return name + "(1)\t\t\t\t\tUser Commands\n\nNAME\n\t" + name + " - " + purpose + "\n\nSYNOPSIS\n" + usage +
            "\nDESCRIPTION\n\t" + description + "\n\n" + options;
    }

    function _get_help_text(string command) private view returns (string) {
        (string name, , string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(command);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options = "\n";
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_names.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + usage + description + options;
    }

    function _is_command_info_available(string command_name) private view returns (bool) {
        uint16 bin_dir_index = _get_file_index("/bin");
        (uint16 command_index, uint8 ft) = _fetch_dir_entry(command_name, bin_dir_index);
        return ft > FT_UNKNOWN && _fs.inodes.exists(command_index);
    }

    function _get_command_info(string command) private view returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        string[] command_info = _get_imported_file_contents("/bin", command);
        return (command_info[0], command_info[1], _join_fields(_get_tsv(command_info[3]), "\n"),
            _get_tsv(command_info[2]), command_info[4], _get_tsv(command_info[5]));
    }

    /* Print error helpers */
    function _print_errors(uint8 command, Err[] errors) internal view returns (string err) {
        string command_name = _fetch_element(command, "/etc", "command_list");
        string command_specific_reason = _command_specific_reason(command);
        for (Err error: errors) {
            (uint8 reason, uint16 explanation, string arg) = error.unpack();
            string s_reason = reason > 0 ? _fetch_element(reason, "/usr", "reasons") : command_specific_reason;
            string s_explanation = _fetch_element(explanation, "/usr", "status");
            err = command_name + ": " + s_reason + _quote(arg);
            if (explanation > 0)
                err.append(s_explanation.empty() ? format("\n Failed expl. lookup r {} e {}\n", reason, explanation) : ": " + s_explanation);
            err.append("\n");
        }
    }

    function _command_specific_reason(uint8 c) internal pure returns (string) {
        if (c == file) return "cannot open";
        if (c == ln) return "failed to access";
        if (c == stat || c == cp || c == mv) return "cannot stat";
        if (c == du || c == ls || _op_access(c)) return "cannot access";
        if (c == rm) return "cannot remove";
        if (c == rmdir) return "failed to remove";
    }

    /* Initialization routine */
    function _init() internal override accept {
        _sync_fs_cache();
    }

}
