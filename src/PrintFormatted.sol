pragma ton-solidity >= 0.49.0;

import "Format.sol";
import "SyncFS.sol";
import "ImportFS.sol";

contract PrintFormatted is Format, SyncFS, ImportFS {

    /* Process commands which do not require intrinsic knowledge about the file system */
    function process_command(SessionS session, InputS input) external view returns (string out, string err) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        ErrS[] errors;

        /* "pure" commands */
        if (c == basename) out = _basename(args, flags);
        if (c == dirname) out = _dirname(args);
        if (c == echo) out = _echo(flags, args);
        if (c == uname) out = _uname(flags);

        /* informational commands */
        if (c == help) out = _help(args);
        if (c == man) out = _man(args);
        if (c == whatis) out = _whatis(args);
        if (c == lslogins) (out, errors) = _lslogins(flags, args, session);

        err = _print_errors(c, errors);
    }

    /* Format text data most likely obtained from a text file */
    function format_text(InputS input, string[][] texts, ArgS[] args) external pure returns (string out) {
        return _format_text(input, texts, args);
    }

    /* Format text data most likely obtained from a text file */
    function process_text_files(SessionS session, InputS input, ArgS[] args) external view returns (string out, string err) {
        ErrS[] errors;

        uint16 len = uint16(args.length);
        string[][] texts;
        for (uint16 i = 0; i < len; i++) {
            (, , uint16 idx, , ) = args[i].unpack();

            texts.push(_fs.inodes[idx].text_data);
        }

        out = _format_text(input, texts, args);
        err = _print_errors(input.command, errors);
    }

    /* Print error messages */
    function print_error_message(uint8 command, ErrS[] errors) external view returns (string err) {
        return _print_errors(command, errors);
    }

    function _format_text(InputS input, string[][] texts, ArgS[] args) internal pure returns (string out) {
        (uint8 c, , uint flags) = input.unpack();

        if (c == paste) out = _paste(flags, texts);

        for (string[] text: texts) {
            if (c == cat) out.append(_cat(flags, text));
            if (c == column) out.append(_column(flags, text, args));
            if (c == cut) out.append(_cut(flags, text, args));
            if (c == grep) out.append(_grep(flags, text, args));
            if (c == head) out.append(_head(flags, text, args));
            if (c == tail) out.append(_tail(flags, text, args));
            if (c == wc) out.append(_wc(flags, text, args));
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
        string[] lines = text;
        for (uint16 i = 0; i < uint16(lines.length); i++) {
            string line_in = lines[i];
            uint16 len = uint16(line_in.byteLength());

            string line_out = (number_lines || (len > 0 && number_nonempty_lines)) ? format("   {}  ", i + 1) : "";
            if (len == 0) {
                if (suppress_repeated_empty_lines) {
                    if (repeated_empty_line)
                        continue;
                    repeated_empty_line = true;
                }
            } else {
                if (suppress_repeated_empty_lines && repeated_empty_line)
                    repeated_empty_line = false;
                for (uint16 j = 0; j < len; j++) {
                    string s = line_in.substr(j, 1);
                    line_out.append((convert_tabs && s == "\t") ? "^I" : s);
                }
                line_out = _if(line_out, show_nonprinting && len > 1 && line_in.substr(len - 2, 1) == "\x13", "^M");
            }
            line_out = _if(line_out, dollar_at_line_end, "$");
            out.append(line_out + "\n");
        }
    }

    function _column(uint flags, string[] text, ArgS[] args) private pure returns (string out) {
        bool ignore_empty_lines = (flags & _e) == 0;
        bool create_table = (flags & _t) > 0;
        string delimiter = " ";

        if (!args.empty()) {
            ArgS arg = args[0];
            delimiter = arg.path;
        }

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

    function _cut(uint flags, string[] text, ArgS[] args) private pure returns (string out) {
        bool set_fields = (flags & _f) > 0;
        bool use_delimiter = (flags & _d) > 0;
        bool only_delimited = (flags & _s) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        string delimiter = "\t";
        uint16 field;
        if (!args.empty()) {
            ArgS arg = args[0];
            if (use_delimiter)
                delimiter = arg.path;
            if (set_fields)
                field = arg.dir_index;
        }

        for (uint16 i = 0; i < uint16(text.length); i++) {
            string[] fields = _split(text[i], delimiter);
            uint f_len = fields.length;
            string matched;
            if (field < f_len)
                matched = fields[field];
            if (!matched.empty() && !(only_delimited && f_len == 1))
                out.append(matched + line_delimiter);
        }
    }

    function _grep(uint flags, string[] text, ArgS[] args) private pure returns (string out) {
        bool invert_match = (flags & _v) > 0;
        bool match_lines = (flags & _x) > 0;

        string pattern;

        if (!args.empty()) {
            ArgS arg = args[0];
            pattern = arg.path;
        }

        uint p_len = pattern.byteLength();
        for (uint16 i = 0; i < uint16(text.length); i++) {
            string line = text[i];
            bool found = false;
            if (match_lines) {
                found = line == pattern;
            } else {
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

    function _head(uint flags, string[] text, ArgS[] args) private pure returns (string out) {
        bool num_lines = (flags & _n) > 0;
        bool never_headers = (flags & _q) > 0;
        bool always_headers = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        uint16 len = uint16(text.length);
        string file_name;
        uint16 n_lines = 10;

        if (!args.empty()) {
            ArgS arg = args[0];
            file_name = arg.path;
            if (num_lines)
                n_lines = arg.dir_index;
        }

        if (n_lines > len)
            n_lines = len;

        if (!file_name.empty() && (always_headers || !never_headers))
             out = "==> " + file_name + " <==\n";

        for (uint16 i = 0; i < n_lines; i++)
            out.append(text[i] + line_delimiter);
    }

    function _paste(uint flags, string[][] texts) private pure returns (string out) {
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";

        for (uint i = 0; i < texts.length; i++)
            for (uint j = 0; j < texts[i].length; j++)
                out.append(texts[i][j] + line_delimiter);
    }

    function _tail(uint flags, string[] text, ArgS[] args) private pure returns (string out) {
        bool num_lines = (flags & _n) > 0;
        bool never_headers = (flags & _q) > 0;
        bool always_headers = (flags & _v) > 0;
        string line_delimiter = (flags & _z) > 0 ? "\x00" : "\n";
        string file_name;
        uint16 n_lines = 10;
        uint16 len = uint16(text.length);

        if (!args.empty()) {
            ArgS arg = args[0];
            file_name = arg.path;
            if (num_lines)
                n_lines = arg.dir_index;
        }
        if (n_lines > len)
            n_lines = len;

        if (!file_name.empty() && (always_headers || !never_headers))
             out = "==> " + file_name + " <==\n";

        for (uint16 i = len - n_lines; i < len; i++)
            out.append(text[i] + line_delimiter);
    }

    function _wc(uint flags, string[] text, ArgS[] args) private pure returns (string out) {
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

        string file_name;
        uint16 file_size;

        if (!args.empty()) {
            ArgS arg = args[0];
            file_name = arg.path;
            file_size = arg.dir_index;
        }

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
            return "Commands:\t" + _join_fields(_get_file_contents("/etc/command_list"), " ") + "\n";

        for (string s: args) {
            string help_text = _get_help_text(s);
            if (!help_text.empty())
                out.append(help_text);
            else {
                out.append("help: no help topics match" + _quote(s) + "\nTry" + _quote("help help") + "or" + _quote("man -k " + s) + "or" + _quote("info " + s) + "\n");
                break;
            }
        }
    }

    function _man(string[] args) private view returns (string out) {
        for (string s: args) {
            string text = _get_man_text(s);
            out.append(text.empty() ? "No manual entry for " + s + "\n" : text);
        }
    }

    function _whatis(string[] args) private view returns (string out) {
        if (args.empty())
            return "whatis what?\n";

        for (string s: args) {
            (string name, string purpose, , , , ) = _get_command_info(s);
            out.append(name == "failed to read command data\n" ? (s + ": nothing appropriate.\n") : (name + " (1)\t\t\t - " + purpose + "\n"));
        }
    }

    function _lslogins(uint flags, string[] args, SessionS session) internal view returns (string out, ErrS[] errors) {
        bool print_system = (flags & _s) > 0 || (flags & _u) == 0;
        bool print_user = (flags & _u) > 0 || (flags & _s) == 0;
        string field_separator;
        if ((flags & _c) > 0)
            field_separator = ":";
        field_separator = _if(field_separator, (flags & _n) > 0, "\n");
        field_separator = _if(field_separator, (flags & _r) > 0, " ");
        field_separator = _if(field_separator, (flags & _z) > 0, "\x00");
        if (field_separator.byteLength() > 1)
            return ("Mutually exclusive options\n", [ErrS(0, mutually_exclusive_options, "")]);
        bool formatted_table = field_separator.empty();
        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GID", "GROUP"]];
        if (args.empty() && session.uid < GUEST_USER) {
            for ((, UserInfo user_info): _users) {
                (uint16 uid, uint16 gid, string s_owner, string s_group, ) = user_info.unpack();
                if (print_system || print_user)
                    table.push([format("{}", uid), s_owner, format("{}", gid), s_group]);
            }
        } else {
            string user_name = args[0];
            for ((, UserInfo user_info): _users)
                if (user_info.user_name == user_name) {
                    (uint16 uid, uint16 gid, , string s_group, string home_dir) = user_info.unpack();
                    table = [["Username:", user_name],
                         ["UID:", format("{}", uid)],
                         ["Home directory:", home_dir],
                         ["Primary group:", s_group],
                         ["GID:", format("{}", gid)]];
                    break;
                }
        }
        out.append(_format_table(table, field_separator, "\n", formatted_table ? ALIGN_LEFT : ALIGN_NONE));
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
        for (Mount m: _imports)
            if (m.fs.sb.file_system_OS_type == path)
                for (( , INodeS inode): m.fs.inodes)
                    if (inode.file_name == file_name)
                        return inode.text_data;
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

    function _get_help_text(string s) private view returns (string) {
        (string name, , string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(s);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options;
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_names.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + usage + description + "\n" + options;
    }

    function _get_command_info(string s) private view returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        string[] command_info = _get_imported_file_contents("commands", s);
        uint16 len = uint16(command_info.length);
        if (!command_info.empty()) {
            name = command_info[0];
            if (len > 1) purpose = command_info[1];
            if (len > 3) desc = _join_fields(_get_tsv(command_info[3]), "\n");
            if (len > 2) uses = _get_tsv(command_info[2]);
            if (len > 4) option_names = command_info[4];
            if (len > 5) option_descriptions = _get_tsv(command_info[5]);
        } else
            name = "failed to read command data\n";
    }

    /* Print error helpers */
    function _print_errors(uint8 command, ErrS[] errors) internal view returns (string err) {
        string command_name = _fetch_element(command, "etc", "command_list");
        string command_specific_reason = _command_specific_reason(command);
        for (ErrS error: errors) {
            (uint8 reason, uint16 explanation, string arg) = error.unpack();
            string s_reason = reason > 0 ? _fetch_element(reason, "errors", "reasons") : command_specific_reason;
            string s_explanation = _fetch_element(explanation, "errors", "status");
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
        address data_volume = address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb);
        ExportFS(data_volume).rpc_mountd_exports{value: 0.5 ton}();
        ExportFS(data_volume).rpc_mountd_exports{value: 0.3 ton}();
        ExportFS(address.makeAddrStd(0, 0x4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981)).rpc_mountd_exports{value: 1 ton}();
        ExportFS(address.makeAddrStd(0, 0x41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420)).rpc_mountd_exports{value: 1 ton}();
        ExportFS(address.makeAddrStd(0, 0x41e37889496dce38efdeb5764cf088287171d72c523c370b37bb6b3621d1f93e)).rpc_mountd_exports{value: 1 ton}();
        ExportFS(address.makeAddrStd(0, 0x4e5561b275d060ff0d0919ccc7e485d08c8e1fe9abd92af6cdf19ebfb2dd5421)).rpc_mountd_exports{value: 1 ton}();
    }
}
