pragma ton-solidity >= 0.56.0;

import "../include/fs_types.sol";
import "inode.sol";
import "er.sol";
import "vars.sol";

library dirent {

    function parse_entry(string s) internal returns (DirEntry) {
        uint p = str.chr(s, "\t");
        if (p > 1) {
            optional(int) index_u = stoi(s.substr(p));
            return DirEntry(inode.file_type(s.substr(0, 1)), s.substr(1, p - 2), index_u.hasValue() ? uint16(index_u.get()) : er.ENOENT);
        }
    }

    function parse_param(string s) internal returns (DirEntry) {
        (string attrs, string name, string value) = vars.split_var_record(s);
        return DirEntry(inode.file_type(attrs), name, name.empty() ? er.ENOENT : str.toi(value));
    }

    function parse_param_index(string params) internal returns (DirEntry[] contents) {
        (string[] lines, ) = stdio.split(params, "\n");
        for (string s: lines)
            contents.push(parse_param(s));
    }

    function read_dir_data(bytes dir_data) internal returns (DirEntry[] contents, int16 status) {
        (string[] lines, ) = stdio.split(dir_data, "\n");
        for (string s: lines)
            contents.push(parse_entry(s));
        status = int16(contents.length);
    }

    function read_dir_verbose(bytes dir_data) internal returns (DirEntry[] contents, int16 status, string out) {
        (string[] lines, ) = stdio.split(dir_data, "\n");
        for (string s: lines) {
            if (s.empty())
                out.append("Empty dir entry line\n");
            else {
                (string s_head, string s_tail) = str.split(s, "\t");
                if (s_head.empty())
                    out.append("Empty file type and name: " + s + "\n");
                else if (s_tail.empty())
                    out.append("Empty inode reference: " + s + "\n");
                else {
                    uint h_len = s_head.byteLength();
                    if (h_len < 2)
                        out.append("File type and name too short: " + s_head + "\n");
                    else {
                        DirEntry de = DirEntry(inode.file_type(s_head.substr(0, 1)), s_head.substr(1), str.toi(s_tail));
                        contents.push(de);
                        out.append(dirent.print(de));
                    }
                }
            }
        }
        status = int16(contents.length);
    }

    function print(DirEntry de) internal returns (string) {
        (uint8 file_type, string file_name, uint16 index) = de.unpack();
        return dir_entry_line(index, file_name, file_type);
    }

    function read_dir(Inode ino, bytes data) internal returns (DirEntry[] contents, int16 status) {
        if (!inode.is_dir(ino.mode))
            status = -er.ENOTDIR;
        else
            return read_dir_data(data);
    }

    function get_symlink_target(Inode ino, bytes node_data) internal returns (DirEntry target) {
        if (!inode.is_symlink(ino.mode))
            target.index = er.ENOSYS;
        else
            return parse_entry(node_data);
    }

    function dir_entry_line(uint16 index, string file_name, uint8 file_type) internal returns (string) {
        return format("{}{}\t{}\n", inode.file_type_sign(file_type), file_name, index);
    }

}
