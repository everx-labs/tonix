pragma ton-solidity >= 0.62.0;

import "filedesc_h.sol";
import "xio.sol";
import "libstat.sol";
import "liberr.sol";
import "libstring.sol";
library dirent {

    using xio for s_of;
    using str for string;
    using libstring for string;
/*struct s_dirent {
	uint16 d_fileno;
	uint8 d_type;
	string d_name;
}*/

    uint16 constant DIRBLKSIZ = 1024;

    // flags for opendir2
    uint16 constant DTF_HIDEW      = 0x0001; // hide whiteout entries
    uint16 constant DTF_NODUP      = 0x0002; // don't return duplicate names
    uint16 constant DTF_REWIND     = 0x0004; // rewind after reading union stack
    uint16 constant __DTF_READALL  = 0x0008; // everything has been read
    uint16 constant __DTF_SKIPREAD = 0x0010; // assume internal buffer is populated

    //	File types
    uint8 constant DT_UNKNOWN = 0;
    uint8 constant DT_FIFO = 1;
    uint8 constant DT_CHR  = 2;
    uint8 constant DT_DIR  = 4;
    uint8 constant DT_BLK  = 6;
    uint8 constant DT_REG  = 8;
    uint8 constant DT_LNK  = 10;
    uint8 constant DT_SOCK = 12;
    uint8 constant DT_WHT  = 14;

    function IFTODT(uint16 mode) internal returns (uint8) {
        return uint8((mode & 0xF000) >> 12);
    }
    function DTTOIF(uint8 dirtype) internal returns (uint16) {
        return uint16(dirtype) << 12;
    }
   function alphasort(s_dirent[]) internal returns (uint16, s_dirent[]) {}

	/*uint16 dd_fd;	 // file descriptor associated with directory
	uint16 dd_loc;	 // offset in current buffer
	uint16 dd_size;  // amount of data returned by getdirentries
	string dd_buf;   // data buffer
	uint16 dd_len;	 // size of data buffer
	uint16 dd_seek;  // magic cookie returned by getdirentries
	uint16 dd_flags; // flags for readdir
	uint16 dd_td;	 // telldir position recording*/

    function parse_dirents(string ss) internal returns (s_dirent[] dd) {
        (string[] lines, ) = ss.split("\n");
        for (string line: lines)
            dd.push(parse_dirent(line));
    }

    function parse_dirent(string s) internal returns (s_dirent) {
        uint p = s.strchr("\t");
        if (p > 1) {
            optional(int) index_u = stoi(s.substr(p));
            return s_dirent(index_u.hasValue() ? uint16(index_u.get()) : err.ENOENT, libstat.file_type(s.substr(0, 1)), s.substr(1, p - 2));
        }
    }

    function readdir(s_dirdesc dirp) internal returns (s_dirent) {
        uint pos = dirp.dd_td;
        string buf = dirp.dd_buf;
        string tail = buf.substr(pos);
        uint p = tail.strchr("\n");
        if (p > 0) {
            dirp.dd_td += uint16(p);
            if (dirp.dd_td >= dirp.dd_size)
                dirp.dd_flags |= __DTF_READALL;
            return parse_dirent(tail.substr(0, p - 1));
        }
        dirp.dd_flags |= __DTF_READALL;
        dirp.dd_td = dirp.dd_size;
        return parse_dirent(tail);
    }
//    function readdir_r(s_of dirp, s_dirent entry) internal returns (uint16, s_dirent[] result) {}
    function telldir(s_dirdesc dirp) internal returns (uint16) {
        return dirp.dd_td;
    }
    function seekdir(s_dirdesc dirp, uint16 loc) internal {
        dirp.dd_td = loc;
    }
    function rewinddir(s_dirdesc dirp) internal {
        dirp.dd_td = 0;
    }
    function closedir(s_dirdesc dirp) internal returns (uint16) {
        dirp.dd_fd = 0;
    }
    function fdclosedir(s_dirdesc dirp) internal returns (uint16) {
        return dirp.dd_fd;
    }
    function dirfd(s_dirdesc dirp) internal returns (uint16) {
        return dirp.dd_fd;
    }

    function print_dirdesc(s_dirdesc dirp) internal returns (string) {
	    (uint16 dd_fd, uint16 dd_loc, uint16 dd_size, , uint16 dd_len, uint16 dd_seek, uint16 dd_flags, uint16 dd_td) = dirp.unpack();
        return format("fd {} loc {} size {} len {} seek {} flags {} td {}", dd_fd, dd_loc, dd_size, dd_len, dd_seek, dd_flags,  dd_td);
    }

    function print_dirdesc_full(s_dirdesc dirp) internal returns (string) {
	    (uint16 dd_fd, uint16 dd_loc, uint16 dd_size, string dd_buf, uint16 dd_len, uint16 dd_seek, uint16 dd_flags, uint16 dd_td) = dirp.unpack();
        return format("fd {} loc {} size {} buf {} len {} seek {} flags {} td {}", dd_fd, dd_loc, dd_size, dd_buf, dd_len, dd_seek, dd_flags,  dd_td);
    }

    function print_dirent(s_dirent de) internal returns (string) {
        (uint16 d_fileno, uint8 d_type, string d_name) = de.unpack();
        return format("ino {} type {} name {}", d_fileno, d_type, d_name);
    }

}