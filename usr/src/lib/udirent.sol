pragma ton-solidity >= 0.57.0;

import "inode.sol";
import "liberr.sol";
import "vars.sol";
import "libstat.sol";

/*struct s_dirent {
	uint16 d_fileno;
    uint16 d_reclen;
	uint8 d_type;
	uint16 d_namlen;
	string d_name;
}*/

struct s_direct {
    uint16 d_ino;       // inode number of entry
    uint16 d_reclen;    // length of this record
    uint8  d_type;      // file type, see below
    uint8  d_namlen;    // length of string in d_name
    string d_name;      // name with length <= UFS_MAXNAMLEN
}

library udirent {

    using libstring for string;

    function getdents(uint16 fd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal returns (uint8 ec, string buf) {
        if (!inodes.exists(fd) || !data.exists(fd))
            ec = err.EBADF;
        buf = data[fd];
    }

    function parse_entry(string s) internal returns (DirEntry) {
        uint p = str.strchr(s, "\t");
        if (p > 1) {
            optional(int) index_u = stoi(s.substr(p));
            return DirEntry(libstat.file_type(s.substr(0, 1)), s.substr(1, p - 2), index_u.hasValue() ? uint16(index_u.get()) : err.ENOENT);
        }
    }

    function parse_param(string s) internal returns (DirEntry) {
        (string attrs, string name, string value) = vars.split_var_record(s);
        return DirEntry(libstat.file_type(attrs), name, name.empty() ? err.ENOENT : str.toi(value));
    }

    function parse_param_index(string params) internal returns (DirEntry[] contents) {
        (string[] lines, ) = params.split("\n");
        for (string s: lines)
            contents.push(parse_param(s));
    }

    function read_dir_data(bytes dir_data) internal returns (DirEntry[] contents, int16 status) {
        string sd = string(dir_data);
        (string[] lines, ) = sd.split("\n");
        for (string s: lines)
            contents.push(parse_entry(s));
        status = int16(contents.length);
    }

    function read_dir_verbose(bytes dir_data) internal returns (DirEntry[] contents, int16 status, string out) {
        string sd = string(dir_data);
        (string[] lines, ) = sd.split("\n");
        for (string s: lines) {
            if (s.empty())
                out.append("Empty dir entry line\n");
            else {
                (string shead, string stail) = s.csplit("\t");
                if (shead.empty())
                    out.append("Empty file type and name: " + s + "\n");
                else if (stail.empty())
                    out.append("Empty inode reference: " + s + "\n");
                else {
                    uint h_len = shead.byteLength();
                    if (h_len < 2)
                        out.append("File type and name too short: " + shead + "\n");
                    else {
                        DirEntry de = DirEntry(libstat.file_type(shead.substr(0, 1)), shead.substr(1), str.toi(stail));
                        contents.push(de);
                        out.append(print(de));
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
        if (!libstat.is_dir(ino.mode))
            status = -err.ENOTDIR;
        else
            return read_dir_data(data);
    }

    function get_symlink_target(Inode ino, bytes node_data) internal returns (DirEntry target) {
        if (!libstat.is_symlink(ino.mode))
            target.index = err.ENOSYS;
        else
            return parse_entry(node_data);
    }

    function dir_entry_line(uint16 index, string file_name, uint8 file_type) internal returns (string) {
        return format("{}{}\t{}\n", libstat.file_type_sign(file_type), file_name, index);
    }

}
