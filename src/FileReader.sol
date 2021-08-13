pragma ton-solidity >= 0.48.0;

import "IData.sol";
import "IOptions.sol";
import "FSCache.sol";
import "INode.sol";

contract FileReader is IOptions, FSCache {

    mapping (uint16 => string[]) public _cdata;

    function read_file(SessionS ses, InputS input) external view returns (Std std, SessionS o_ses, INodeEventS[] ines, IOEventS[] ios, uint16 action) {
        /* Validate session info: uid, gid and wd */
        (uint16 uid, uint16 gid, uint16 wd) = ses.unpack();
        o_ses = SessionS(uid, gid, wd);
        (uint8 c, string[] args, uint flags, string target) = input.unpack();
        string out;
        string err;

        /* Process related operations in separate subroutines */

        if (c == echo) out = _echo(flags, args);
        if (c == cmp) out = _cmp(flags, args, wd);

        if (_op_file_read(c))
            (out, err) = _read_file(c, args, flags, wd);

        if (target != "") {
            (uint16 tgt, ) = _lookup_inode_in_dir(target, wd);
            ios.push(tgt < INODES ? IOEventS(IO_MKFILE, wd, 0, target, out) : IOEventS(IO_WR_APPEND, wd, tgt, target, out));
            out = "";
        }
        std = Std(out, err);
        if (!err.empty()) action |= PRINT_ERROR;
        if (!out.empty()) action |= PRINT_OUT;
        if (!ios.empty()) action |= IO_EVENT;
        ines = ines;
    }

    function _get_text_data(uint16 ino) internal view returns (string out) {
        INodeS inode = _inodes[ino];
        string text = inode.text_data;
        if (!text.empty())
            out = text;
        else {
            uint16[] blocks = _dc[ino];
            for (uint16 b: blocks)
                out.append(_cdata[1][b]);
        }
    }

    /* File stat operations common routine */
    function _read_file(uint8 c, string[] args, uint flags, uint16 wd) private view returns (string out, string err) {
        ErrS[] errors;
        for (string s: args) {
            (uint16 ino, uint8 ft) = _lookup_inode_in_dir(s, wd);
            if (ino >= INODES && _inodes.exists(ino)) {
                if ((c == cat || c == paste || c == wc) && ft != FT_REG_FILE) {
                    errors.push(ErrS(1, _command_reason(c), EISDIR, s));
                    continue;
                }
                if (c == cat) out.append(_cat(flags, ino));
                if (c == paste) out.append(_paste(ino));
                if (c == wc) out.append(_wc(flags, ino));
            } else
                errors.push(ErrS(1, _command_reason(c), ENOENT, s));
        }
        for (ErrS e: errors)
            err.append(_error_message2(c, e));
    }
    /********************** File system read commands *************************/
    // read contents(inode)

    function _cat(uint flags, uint16 ino) private view returns (string out) {
        bool number_lines = (flags & _n) > 0;
        bool number_nonempty_lines = (flags & _b) > 0;
        bool dollar_at_line_end = (flags & _E + _e + _A) > 0;
        bool suppress_repeated_empty_lines = (flags & _s) > 0;
        bool convert_tabs = (flags & _T + _t + _A) > 0;
        bool show_nonprinting = (flags & _v + _e + _t + _A) > 0;

        bool repeated_empty_line = false;
        string[] lines = _get_lines(_inodes[ino].text_data);
        for (uint16 i = 0; i < uint16(lines.length); i++) {
            string line = lines[i];
            uint16 len = uint16(line.byteLength());

            string prefix = (number_lines || (len > 0 && number_nonempty_lines)) ? format("   {}  ", i + 1) : "";
            string suffix = dollar_at_line_end ? "$" : "";
            string body;
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
                    string s = line.substr(j, 1);
                    body.append((convert_tabs && s == "\t") ? "^I" : s);
                }
                body = _if(body, show_nonprinting && len > 1 && line.substr(len - 2, 1) == "\x13", "^M");
            }
            out.append(prefix + body + suffix + "\n");
        }
    }

    function _paste(uint16 inode) private view returns (string out) {
        return _inodes[inode].text_data;
    }

    function _echo(uint flags, string[] ss) private pure returns (string out) {
        bool no_trailing_newline = (flags & _n) > 0;
        uint len = ss.length;
        if (len > 0) out = ss[0];
        for (uint i = 1; i < len; i++)
            out.append(" " + ss[i]);
        if (!no_trailing_newline)
            out.append("\n");
    }

    function _wc(uint flags, uint16 ino) private view returns (string out) {
        INodeS inode = _inodes[ino];
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
        (, , , uint32 bc, , string file_name, string text) = inode.unpack();
        (uint16 lc, uint16 wc, uint32 cc, uint16 mw) = _line_and_word_count(text);

        out = _if("", print_lines, format("  {} ", lc));
        out = _if(out, print_words, format(" {} ", wc));
        out = _if(out, print_bytes, format(" {} ", bc));
        out = _if(out, print_chars, format(" {} ", cc));
        out = _if(out, print_max_width, format(" {} ", mw));
        out.append(file_name + "\n");
    }

    function _cmp(uint flags, string[] args, uint16 wd) private view returns (string out) {
        bool verbose = (flags & _l) > 0;
        bool print_bytes = (flags & _b) > 0;

        (uint16 i1,) = _lookup_inode_in_dir(args[0], wd);
        (uint16 i2,) = _lookup_inode_in_dir(args[1], wd);
        string t1 = _inodes[i1].text_data;
        string t2 = _inodes[i2].text_data;
        bytes b1 = bytes(t1);
        bytes b2 = bytes(t2);
        for (uint16 i = 0; i < t1.byteLength(); i++) {
            uint8 u1 = uint8(b1[i]);
            uint8 u2 = uint8(b2[i]);
            if (u1 != u2) {
                if (!verbose)
                    return _inodes[i1].file_name + " " + _inodes[i2].file_name + " differ: byte" + _if(format(" {}", i), print_bytes, format(" is {}", u1)) + "\n";
                out += format("{:3} {:3} {:3}\n", i, u1, u2);
            }
        }
    }

    /******* Helpers ******************/

    function init() external override accept {
        _init_commands();
        _init_errors();
        _sync_fs_cache();
    }

}
