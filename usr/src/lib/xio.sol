pragma ton-solidity >= 0.61.2;

import "str.sol";
import "io.sol";
import "sbuf.sol";
import "libfdt.sol";
import "libstat.sol";

library xio {

    using str for string;
    using sbuf for s_sbuf;
    using libfdt for  s_of[];

    uint16 constant BUFSIZ  = 1024;   // size of buffer used by setbuf
    int16 constant EOF = -1;
    uint16 constant FOPEN_MAX = 20; // must be <= OPEN_MAX <sys/syslimits.h>
    uint16 constant FILENAME_MAX = 1024; // must be <= PATH_MAX <sys/syslimits.h>
    string constant P_tmpdir = "/tmp/";
    uint16 constant L_tmpnam = 1024; // XXX must be == PATH_MAX
    uint32 constant TMP_MAX = 0xFFFFFFFF;//308915776;

    uint16 constant L_cuserid = 17;  // size for cuserid(3); MAXLOGNAME, legacy
    uint16 constant L_ctermid = 1024;// size for ctermid(3); PATH_MAX

    function aread(s_of f, uint32 nbytes) internal returns (bytes) {
        if (nbytes == 0)
            return f.buf.buf; // temporary
        uint32 offset = f.offset;
        uint32 file_len = libstat.st_size(f.attr);
        uint32 cap = nbytes > 0 ? math.min(nbytes, file_len - offset) : file_len - offset;
        f.offset += cap;
        if (f.offset >= file_len)
            f.flags |= io.SEOF;
        return string(f.buf.buf).substr(offset, cap);
    }

    function awrite(s_of f, bytes buf, uint32 nbytes) internal returns (s_of) {
        f.buf.buf.append(string(buf).substr(0, nbytes));
        return f;
    }

    function mode_to_flags(string mode) internal returns (uint16 flags) {
        if (mode == "r" || mode == "rb")
            flags |= io.O_RDONLY;
        if (mode == "w" || mode == "wb")
            flags |= io.O_WRONLY;
        if (mode == "a" || mode == "ab")
            flags |= io.O_APPEND;
        if (mode == "r+" || mode == "rb+" || mode == "r+b")
            flags |= io.O_RDWR;
        if (mode == "w+" || mode == "wb+" || mode == "w+b")
            flags |= io.O_TRUNC | io.O_CREAT; //Truncate to zero length or create file for update
        if (mode == "a+" || mode == "ab+" || mode == "a+b")
            flags |= io.O_APPEND | io.O_CREAT; // Append; open or create file for update, writing at end-of-file
    }

    function clearerr(s_of f) internal {
        f.flags &= ~io.SEOF;
        f.flags &= ~io.SERR;
    }

    function fclose(s_of f) internal {
        f.flags &= ~io.SRD;
        f.flags &= ~io.SWR;
        f.flags &= ~io.SRW;
        f.file = 0;
    }

    function feof(s_of f) internal returns (bool) {
        return (f.flags & io.SEOF) > 0;
    }

    function ferror(s_of f) internal returns (bool) {
        return (f.flags & io.SERR) > 0;
    }

    function fflush(s_of f) internal returns (bytes ret) {
        f.offset = 0;
        s_sbuf s = f.buf;
        ret = s.sbuf_data();
        s.sbuf_clear();
        f.buf = s;
    }

    function fgetc(s_of f) internal returns (bytes) {
        return aread(f, 1);
    }

    function fgetpos(s_of f) internal returns (uint32) {
        return f.offset;
    }

    function fgets(s_of f, uint32 size) internal returns (bytes) {
        return aread(f, size);
    }

    function fputc(s_of f, byte c) internal {
        s_sbuf s = f.buf;
        s.sbuf_putc(c);
        f.buf = s;
        f.offset = s.sbuf_len();
    }

    function fputs(s_of f, string str) internal {
        s_sbuf s = f.buf;
        s.sbuf_cat(str);
        s.sbuf_nl_terminate();
        f.buf = s;
        f.offset = s.sbuf_len();
    }

    function fread(s_of f, uint16 size, uint16 nmemb) internal returns (bytes) {
        return aread(f, size * nmemb);
    }

    function freopen(s_of stream, string path, string mode) internal {

    }

    function fseek(s_of stream, uint32 offset, uint8 whence) internal {
        uint32 pos;
        if (whence == io.SEEK_SET)
            pos = offset;
        else if (whence == io.SEEK_CUR)
            pos = pos + stream.offset;
        else if (whence == io.SEEK_END)
            pos = stream.offset;
    }

    function fsetpos(s_of f, uint32 pos) internal {
        f.offset = pos;
    }

    function ftell(s_of f) internal returns (uint32) {
        return f.offset;
    }

    function fwrite(s_of f, bytes ptr, uint16 size, uint16 nmemb) internal {
        awrite(f, ptr, size * nmemb);
    }

    function getc(s_of f) internal returns (bytes) {
        return aread(f, 1);
    }

    function gets_s(s_of f, uint32 size) internal returns (bytes) {
        return aread(f, size);
    }

    function rewind(s_of f) internal {
        f.offset = 0;
        clearerr(f);
    }

    function tmpfile() internal returns (s_of stream) {}

    function tmpnam() internal returns (string) {

    }

    function fileno(s_of f) internal returns (uint16) {
        return f.file;
    }

    function inono(s_of f) internal returns (uint16) {
        return uint16(f.attr >> 208 & 0xFFFF);
    }

    function pclose(s_of stream) internal returns (uint8) {
    }

    function popen(string cmd, string mode) internal returns (s_of stream) {

    }

    function getw(s_of f) internal returns (bytes) {
        return aread(f, 2);
    }

    function split(s_of f) internal returns (string[] fields, uint n_fields) {
        uint len = libstat.st_size(f.attr);
        string text = f.buf.buf;
        if (len > 0) {
            uint prev;
            uint cur;
            while (cur < len) {
                if (text.substr(cur, 1) == "\n") {
                    fields.push(text.substr(prev, cur - prev));
                    prev = cur + 1;
                }
                cur++;
            }
            string stail = text.substr(prev);
            if (!stail.empty() && stail != "\n")
                fields.push(stail);
            n_fields = fields.length;
        }
    }

    function getline(s_of f) internal returns (string) {
        uint pos = f.offset;
        string buf = f.buf.buf;
        string tail = buf.substr(pos);
        uint p = tail.strchr("\n");

        uint32 file_len = libstat.st_size(f.attr);

        if (p > 0) {
            f.offset += uint32(p);
            if (f.offset >= file_len)
                f.flags |= io.SEOF;
            return tail.substr(0, p - 1);
        }
        f.flags |= io.SEOF;
        f.offset = file_len;
        return tail;
    }

    function ctermid_r(string) internal returns (uint16) {}
    function fcloseall() internal {}
    function fdclose(s_of stream, uint16) internal returns (int) {}

    function fgetln(s_of f) internal returns (string) {
        uint pos = f.offset;
        string buf = f.buf.buf;
        string tail = buf.substr(pos);
        uint p = tail.strchr("\n");
        uint32 file_len = libstat.st_size(f.attr);

        if (p > 0) {
            f.offset += uint32(p);
            if (f.offset >= file_len)
                f.flags |= io.SEOF;
            return tail.substr(0, p);
        }
        f.flags |= io.SEOF;
        f.offset = file_len;
        return tail;
    }

    function print_file(s_of f) internal returns (string) {
        (uint attr, uint16 flags, uint16 file, string path, uint32 offset, s_sbuf buf) = f.unpack();
        return format("A {} flags {} fd {} path {} off {} buf {}", attr, flags, file, path, offset, buf.buf);
    }
}