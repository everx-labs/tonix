pragma ton-solidity >= 0.63.0;

import "sbuf_h.sol";
import  "liberr.sol";
import  "libfdt.sol";
struct __sbuf {
    uint16 base;
    uint16 size;
       bytes data;
}

struct fopencookie_thunk {
    FILE foc_cookie;
    cookie_io_functions_t foc_io;
}

struct cookie_io_functions_t {
    optional (function (TvmCell, uint16) internal returns (uint16, string)) read;
    optional (function (TvmCell, string, uint16) internal returns (uint16)) write;
    optional (function (TvmCell, uint16, uint8) internal returns (uint16)) seek;
    optional (function (TvmCell) internal returns (uint16)) close;
}

struct FILE {
    uint16 p;  // current position in (some) buffer
    uint16 r;  // read space left for getc()
    uint16 w;  // write space left for putc()
    uint16 flags; // flags, below; this FILE is free if 0
    uint8 file;  // fileno, if Unix descriptor, else -1
    __sbuf bf;   // the buffer (at least 1 byte, if !NULL)
    TvmCell cookie; // cookie passed to io functions
    function (TvmCell) internal returns (uint16) close;
    function (TvmCell, uint16) internal returns (uint16, string) read;
    function (TvmCell, uint16, uint8) internal returns (uint16) seek;
    function (TvmCell, string, uint16) internal returns (uint16) write;
    uint16 offset; // current lseek offset
//	struct pthread *_fl_owner;	// current owner
}


contract stdio {

// Stdio function-access interface.
	    //(function (FILE, string, uint16) internal returns (uint16)),
	    //function (FILE, string, uint16) internal returns (uint16),
	    //function (FILE, uint16, uint8) internal returns (uint16),
	    //function (FILE) internal returns (uint16)) internal returns (FILE) {}
//#define	fropen(cookie, fn) funopen(cookie, fn, 0, 0, 0)
//#define	fwopen(cookie, fn) funopen(cookie, 0, fn, 0, 0)

    FILE stdin;
    FILE stdout;
    FILE stderr;
    uint8 errno;

    uint16 constant SIZE_MAX = 0xFFFF;
    uint16 constant EOF = 0xFFFF;
    uint16 constant OFF_MAX = 0xFFFF;

    uint8 constant SEEK_SET	= 0; // set file offset to offset
    uint8 constant SEEK_CUR	= 1; // set file offset to current plus offset
    uint8 constant SEEK_END	= 2; // set file offset to EOF plus offset



    function __sflush(FILE fp) internal pure returns (uint16, bytes res) {
    	uint16 p;
    	uint16 t = fp.flags;
//        __sbuf b; // XXX
    	if ((t & libfdt.__SWR) == 0)
    		return (0, res);
    	if ((p = fp.bf.base) == 0)
    		return (0, res);
    	uint16 n = fp.p - p; // write this much
    	// Set these immediately to avoid problems with longjmp and to allow exchange buffering (via setvbuf) in user write function.
//    	uint16 old_p = fp.p;
    	fp.p = p;
//    	uint16 old_w = fp.w;
    	fp.w = (t & (libfdt.__SLBF | libfdt.__SNBF)) > 0 ? 0 : fp.bf.size;
    	for (; n > 0; n -= t) {
            p += t;
//    		t = _swrite(fp, p, n);
//    		t = _swrite(fp, b.data, n);
            res.append(fp.bf.data);
    		if (t <= 0) {
    			// Reset _p and _w.
    			if (p > fp.p) { // Some was written.
//    				memmove(fp->_p, p, n);
//                    fp._bf._data
    				fp.p += n;
    				if ((fp.flags & (libfdt.__SLBF | libfdt.__SNBF)) == 0)
    					fp.w -= n;
    			}// else if (p == fp.p) { // cond. to handle setvbuf
//    				fp.p = old_p;
//    				fp.w = old_w;
//    			}
    			fp.flags |= libfdt.__SERR;
    			return (EOF, res);
    		}
    	}
    }

    function _fopencookie_read(TvmCell, uint16) internal returns (uint16, string) {

    }

    function _fopencookie_write(TvmCell, string, uint16) internal returns (uint16) {

    }

    function _fopencookie_seek(TvmCell, uint16, uint8) internal returns (uint16) {

    }

    function _fopencookie_close(TvmCell) internal returns (uint16) {

    }


    function fopencookie(FILE cookie, string mode, cookie_io_functions_t io_funcs) internal returns (FILE fp) {
	    optional (function (TvmCell, uint16) internal returns (uint16, string)) readfn;
	    optional (function (TvmCell, string, uint16) internal returns (uint16)) writefn;
//	    optional (function (TvmCell, uint16, uint8) internal returns (uint16)) seekfn;
//	    optional (function (TvmCell) internal returns (uint16)) closefn;
        fopencookie_thunk thunk;
        (uint16 flags, uint32 oflags) = libfdt.__sflags(mode);
	    if (flags == 0)
	    	return fp;
	    //thunk = malloc(sizeof(*thunk));
	    //if (thunk == NULL)
	    //	return (NULL);
	    thunk.foc_cookie = cookie;
	    thunk.foc_io = io_funcs;
	    readfn.set(_fopencookie_read);
	    writefn = _fopencookie_write;
	    if (flags == libfdt.__SWR)
	    	readfn = null;
	    else if (flags == libfdt.__SRD)
	    	writefn = null;
	    fp = funopen(thunk);
//	    fp = funopen(thunk, readfn, writefn, _fopencookie_seek, _fopencookie_close);
	    //if (fp == NULL) {
	    //	free(thunk);
	    //	return (NULL);
	    //}
	    if ((oflags & libfdt.O_APPEND) != 0)
	    	fp.flags |= libfdt.__SAPP;
    }
//    function funopen(FILE fp, cookie_io_functions_t io_funcs) internal returns (FILE) {
    function funopen(fopencookie_thunk thunk) internal returns (FILE fp) {
        (FILE foc_cookie, cookie_io_functions_t io_funcs) = thunk.unpack();
        fp = foc_cookie;
	    optional (function (TvmCell, uint16) internal returns (uint16, string)) readfn;// = io_funcs.read;
	    optional (function (TvmCell, string, uint16) internal returns (uint16)) writefn;
//        writefn.set(io_funcs.write);
	    optional (function (TvmCell, uint16, uint8) internal returns (uint16)) seekfn;// = io_funcs.seek;
	    optional (function (TvmCell) internal returns (uint16)) closefn;// = (io_funcs.close).get();
    	uint16 flags;
    	if (!io_funcs.read.hasValue()) {
    		if (!io_funcs.write.hasValue()) {		// illegal
    			errno = err.EINVAL;
    			return fp;
    		} else
    			flags = libfdt.__SWR;		// write only
    	} else {
    		if (!io_funcs.write.hasValue())
    			flags = libfdt.__SRD;		// read only
    		else
    			flags = libfdt.__SRW;		// read-write
    	}
//    	if ((fp = __sfp()) == NULL)
//    		return (NULL);
    	fp.flags = flags;
    	fp.file = 0;
//        TvmBuilder b;
//    	fp._cookie = b.encode(fp).toCell();
    	fp.read = readfn.get();
    	fp.write = writefn.get();
    	fp.seek = seekfn.get();
    	fp.close = closefn.get();
    }

    // Refill a stdio buffer. Return EOF on eof or error, 0 otherwise.
    function __srefill(FILE fp) internal returns (uint16 ret) {
    	// make sure stdio is set up
//    	if (!__sdidinit)
//    		__sinit();
    	fp.r = 0;		// largely a convenience for callers
    	// SysV does not make this test; take it out for compatibility
    	if ((fp.flags & libfdt.__SEOF) > 0)
    		return EOF;
    	// if not already reading, have to be reading and writing
    	if ((fp.flags & libfdt.__SRD) == 0) {
    		if ((fp.flags & libfdt.__SRW) == 0) {
    			errno = err.EBADF;
    			fp.flags |= libfdt.__SERR;
    			return EOF;
    		}
    		// switch to reading
    		if ((fp.flags & libfdt.__SWR) > 0) {
                (ret, ) = __sflush(fp);
    			if (ret > 0)
    				return EOF;
    			fp.flags &= ~libfdt.__SWR;
    			fp.w = 0;
    		}
    		fp.flags |= libfdt.__SRD;
    	} else {
    		// We were reading.  If there is an ungetc buffer, we must have been reading from that.  Drop it,
    		// restoring the previous buffer (if any).  If there is anything in that buffer, return.
    	}
//    	if (fp._bf._base == NULL)
//    		__smakebuf(fp);
    	// Before reading from a line buffered or unbuffered file, flush all line buffered output files, per the ANSI C  standard.
    	if ((fp.flags & (libfdt.__SLBF | libfdt.__SNBF)) > 0) {
    		// Ignore this file in _fwalk to avoid potential deadlock.
    		fp.flags |= libfdt.__SIGN;
//    		_fwalk(lflush);
    		fp.flags &= ~libfdt.__SIGN;
    		// Now flush this file without locking it.
    		if ((fp.flags & (libfdt.__SLBF | libfdt.__SWR)) == (libfdt.__SLBF | libfdt.__SWR))
    			__sflush(fp);
    	}
    	fp.p = fp.bf.base;
//    	fp._r = _sread(fp, fp._p, fp._bf._size);
    	(fp.r, fp.bf.data) = _sread(fp, fp.bf.size);
    	fp.flags &= ~libfdt.__SMOD;	// buffer contents are again pristine
    	if (fp.r <= 0) {
    		if (fp.r == 0)
    			fp.flags |= libfdt.__SEOF;
    		else {
    			fp.r = 0;
    			fp.flags |= libfdt.__SERR;
    		}
    		return EOF;
    	}
    }

    function __fread(FILE fp, bytes buf, uint16 size, uint16 count) internal returns (uint16) {
    	uint16 p;
    	uint16 r;
    	// ANSI and SUSv2 require a return value of 0 if size or count are 0.
    	if (count == 0 || size == 0)
    		return 0;
    	// Check for integer overflow.  As an optimization, first check that at least one of {count, size} is at least 2^16, since if both
    	// values are less than that, their product can't possible overflow (size_t is always at least 32 bits on FreeBSD).
    	if (((count | size) > 0xFFFF) && (count > SIZE_MAX / size)) {
    		errno = err.EINVAL;
    		fp.flags |= libfdt.__SERR;
    		return 0;
    	}
    	// Compute the (now required to not overflow) number of bytes to read and actually do the work.
    	uint16 resid = count * size;
    	if (fp.r < 0)
    		fp.r = 0;
    	uint16 total = resid;
//    	p = buf;
        fp.bf.data = buf;
    	// If we're unbuffered we know that the buffer in fp is empty so  we can read directly into buf.  This is much faster than a series of one byte reads into fp->_nbuf.
    	if ((fp.flags & libfdt.__SNBF) > 0 && !buf.empty()) {
    		while (resid > 0) {
    			// set up the buffer
    			fp.bf.base = fp.p = p;
    			fp.bf.size = resid;

    			if (__srefill(fp) > 0) {
    				// no more input: return partial result
    				count = (total - resid) / size;
    				break;
    			}
    			p += fp.r;
    			resid -= fp.r;
    		}
    		// restore the old buffer (see __smakebuf)
    		fp.bf.base = fp.p;
    		fp.bf.size = 1;
    		fp.r = 0;
    		return count;
    	}
    	while (resid > (r = fp.r)) {
    		if (r != 0) {
//    			(void)memcpy((void *)p, (void *)fp->_p, (size_t)r);
                fp.bf.data.append(buf[fp.p : fp.p + r]);
    			fp.p += r;
    			// fp->_r = 0 ... done in __srefill
    			p += r;
    			resid -= r;
    		}
    		if (__srefill(fp) > 0) {
    			// no more input: return partial result
    			return (total - resid) / size;
    		}
    	}
//    	(void)memcpy((void *)p, (void *)fp->_p, resid);
        fp.bf.data.append(buf[fp.p : fp.p + resid]);
    	fp.r -= resid;
    	fp.p += resid;
    	return count;
    }


// Small standard I/O/seek/close functions.
    function __sread(TvmCell cookie, uint16 n) internal returns (uint16, string buf) {
    	FILE fp = cookie.toSlice().decode(FILE);
    	return fp.read(cookie, n);
    }

    function __swrite(TvmCell cookie, string buf, uint16 n) internal returns (uint16) {
    	FILE fp = cookie.toSlice().decode(FILE);
    	return fp.write(cookie, buf, n);
    }

//    function __sseek(TvmCell cookie, uint16 offset, uint8 whence) internal returns (uint16) {
//    	FILE fp = cookie.toSlice().decode(FILE);
    	//return (lseek(fp._file, offset, whence));
//    }

    function __sclose(TvmCell cookie) internal returns (uint16) {
        FILE fp = cookie.toSlice().decode(FILE);
    	return fp.close(cookie);
    }

    function _sread(FILE fp, uint16 n) internal returns (uint16 ret, bytes buf) {
    	(ret, buf) = fp.read(fp.cookie, n);
    	if (ret > 0) {
    		if ((fp.flags & libfdt.__SOFF) > 0) {
    			if (fp.offset <= OFF_MAX - ret)
    				fp.offset += ret;
    			else
    				fp.flags &= ~libfdt.__SOFF;
    		}
    	} else if (ret < 0)
    		fp.flags &= ~libfdt.__SOFF;
    }

    function _swrite(FILE fp, string buf, uint16 n) internal returns (uint16 ret) {
    	if ((fp.flags & libfdt.__SAPP) > 0) {
    		if (_sseek(fp, 0, SEEK_END) == OFF_MAX && (fp.flags & libfdt.__SOPT) > 0)
    			return 0xFFFF;
    	}
    	ret = fp.write(fp.cookie, buf, n);
    	// __SOFF removed even on success in case O_APPEND mode is set.
    	if (ret >= 0) {
    		if ((fp.flags & libfdt.__SOFF) > 0 && (fp.flags & libfdt.__S2OAP) == 0 && fp.offset <= OFF_MAX - ret)
    			fp.offset += ret;
    		else
    			fp.flags &= ~libfdt.__SOFF;

    	} else if (ret < 0)
    		fp.flags &= ~libfdt.__SOFF;
    }

    function _sseek(FILE fp, uint16 offset, uint8 whence) internal returns (uint16 ret) {
    	uint8 errret;

    	ret = fp.seek(fp.cookie, offset, whence);
    	// Disallow negative seeks per POSIX. It is needed here to help upper level caller in the cases it can't detect.
    	if (ret < 0) {
    		if (errret == 0) {
    			if (offset != 0 || whence != SEEK_CUR) {
    				fp.p = fp.bf.base;
    				fp.r = 0;
    				fp.flags &= ~libfdt.__SEOF;
    			}
    			fp.flags |= libfdt.__SERR;
    			errno = err.EINVAL;
    		} else if (errret == err.ESPIPE)
    			fp.flags &= ~libfdt.__SAPP;
    		fp.flags &= ~libfdt.__SOFF;
    		ret = OFF_MAX;
    	} else if ((fp.flags & libfdt.__SOPT) > 0) {
    		fp.flags |= libfdt.__SOFF;
    		fp.offset = ret;
    	}
    }

    function asprintf() external returns (uint8) {  // formatted output conversion

    }

    function clearerr(FILE p) internal pure returns (uint8) {  // check and reset stream status
        p.flags &= ~(libfdt.__SERR | libfdt.__SEOF);
    }

    function dprintf() external returns (uint8) {   // formatted output conversion

    }

    function fdopen(uint8 fildes, string mode) external returns (uint8) {    // stream open	functions

    }

    function feof(FILE fp) internal pure returns (bool) {   // check and reset stream status
    	return (fp.flags & libfdt.__SEOF) > 0;
    }

    function ferror(FILE fp) internal pure returns (bool) {  // check and reset stream status
    	return (fp.flags & (libfdt.__SEOF | libfdt.__SERR)) > 0;
    }

    function fflush(FILE fp) internal pure returns (uint8, bytes) {  // flush a stream
        return (0, fp.bf.data);
    }

    function fgetc(FILE	stream) internal returns (uint8) { // get next character or word from input stream

    }

    function fgetln(FILE fp) internal pure returns (string) {  // get a line from a stream
        return fp.bf.data;
    }

    function fgetpos(FILE) internal returns (uint8, uint16) {   // reposition a stream

    }
    function fgets(FILE, string, int) internal returns (uint8) {    // get a line from a stream

    }

    function fileno(FILE fp) internal pure returns (uint8) {  // check and reset stream status
        return fp.file;
    }

    function fopen(string, string) external returns (uint8) {     // stream open functions

    }

    function fprintf(FILE, string) internal returns (uint8) {   // formatted output conversion

    }

    function fpurge() external returns (uint8) {    // flush a stream

    }

    function fputc(FILE, byte) internal returns (uint8) {     // output a character or word to a stream

    }

    function fputs(FILE, string) internal returns (uint8) {     // output a line to a stream

    }

    function fread(FILE, uint16, uint16) internal returns (uint16, bytes) {     // binary stream input/output

    }

    function freopen(FILE, string, string) internal returns (FILE) {   // stream open	functions

    }
    function fropen() external returns (uint8) {    // open a stream

    }

    function fscanf(FILE) internal returns (uint8) {    // input format conversion

    }

    function fseek(FILE) internal returns (uint8) {     // reposition a stream

    }

    function fsetpos(FILE, uint16) internal returns (uint16) {   // reposition a stream

    }

    function ftell(FILE) internal returns (uint16) {   // reposition a stream

    }

    function funopen() external returns (uint8) {   // open a stream

    }

    function fwide() external returns (uint8) {   // set/get orientation of stream

    }

    function fwopen() external returns (uint8) {  // open a stream

    }

    function fwrite(bytes, uint16, uint16, FILE) internal returns (uint8) {    // binary stream input/output

    }

    function getc(FILE stream) internal returns (byte) {      // get next character or word from input stream

    }

    function getchar() external returns (byte) {   // get next character or word from input stream
        return getc(stdin);
    }

    function gets_s(string, uint16) internal returns (string) {}

    function getdelim() external returns (uint8) {  // get a line from a stream

    }

    function getline() external returns (uint8) {   // get a line from a stream

    }

    function getw(FILE stream) internal returns (uint8) {      // get	next character or word from input stream

    }

    function mkdtemp() external returns (uint8) { // create unique temporary directory

    }

    function mkstemp() external returns (uint8) { // create unique temporary file

    }

    function mktemp() external returns (uint8) {  // create unique temporary file

    }

    function perror(string) external returns (uint8) {  // system error messages

    }

    function printf(string) external returns (uint8) {  // formatted output conversion

    }

    function putc(FILE, byte) internal returns (uint8) {      // output a character or word to a stream

    }
    function putchar(byte) external returns (uint8) {   // output a character or word to a stream

    }

    function puts(string) external returns (uint8) {      // output a line to a stream

    }

    function putw() external returns (uint8) {      // output a character or word to a stream

    }

    function remove(string) external returns (uint8) {    // remove directory entry

    }

    function rewind(FILE) internal returns (uint8) {    // reposition a stream

    }
    function rename(string, string) internal returns (int8) {}

    function scanf(string) external returns (uint8) {   // input format conversion

    }

    function setbuf(FILE, string) internal returns (uint8) {   // stream buffering operations

    }

    function setbuffer() external returns (uint8) { // stream buffering operations

    }

    function setlinebuf() external returns (uint8) {// stream buffering operations

    }

    function setvbuf(FILE, string, int, uint16) internal returns (uint8) {   // stream buffering operations

    }

    function snprintf() external returns (uint8) {  // formatted output conversion

    }

    function sprintf(string, string) external returns (uint8) {   // formatted output conversion

    }

    function sscanf(string, string) external returns (uint8) {    // input format conversion

    }

    function strerror() external returns (uint8) {  // system error messages

    }

    function sys_errlist() external returns (uint8) { // system error messages

    }

    function sys_nerr() external returns (uint8) {  // system error messages

    }

    function tempnam() external returns (uint8) { // temporary file routines

    }

    function tmpfile() internal returns (FILE) {  // temporary file routines

    }
    function tmpnam(string) external returns (string) {    // temporary file routines

    }

    function ungetc() external returns (uint8) {    // un-get character from input stream

    }

    function vasprintf() external returns (uint8) { // formatted output conversion

    }

    function vdprintf() external returns (uint8) {  // formatted output conversion

    }

    function vfprintf(FILE, string) internal returns (uint8) {  // formatted output conversion

    }

    function vfscanf() external returns (uint8) {  // input format conversion

    }

    function vprintf(string) external returns (uint8) {   // formatted output conversion

    }

    function vscanf() external returns (uint8) {    // input format conversion

    }

    function vsnprintf() external returns (uint8) { // formatted output conversion

    }

    function vsprintf(string, string) external returns (uint8) {  // formatted output conversion

    }

    function vsscanf() external returns (uint8) {  // input format conversion

    }

//    function ungetc(int, FILE *) internal returns (int) {}

    function __fflush(FILE fp) internal pure returns (uint16 retval, bytes res) {
//    	if (fp == 0)
//    		return (_fwalk(sflush_locked));
    	if ((fp.flags & (libfdt.__SWR | libfdt.__SRW)) == 0)
    		retval = 0;
    	else
    		(retval, res) = __sflush(fp);
    }

    function cleanfile(FILE fp, bool c) internal returns (uint16 r) {
    	(r, ) = (fp.flags & libfdt.__SWR) > 0 ? __sflush(fp) : (0, "");
    	if (c) {
    		if (fp.close(fp.cookie) < 0)
    			r = EOF;
    	}
    	if ((fp.flags & libfdt.__SMBF) > 0)
    		delete fp.bf.base;
    	fp.file = 0;
    	fp.r = fp.w = 0;	// Mess up if reaccessed
    	fp.flags = 0;		// Release this FILE for reuse
    }

    function fdclose(FILE fp, uint8 fdp) internal returns (uint16 r) {
    	uint8 e;
//    	if (fdp != 0)
//    		fdp = -1;
    	if (fp.flags == 0) {	// not open!
    		errno = err.EBADF;
    		return EOF;
    	}
    	r = 0;
    	if (fp.close != __sclose) {
    		r = EOF;
    		errno = err.EOPNOTSUPP;
    	} else if (fp.file < 0) {
    		r = EOF;
    		errno = err.EBADF;
    	}
    	if (r == EOF) {
    		e = errno;
    		cleanfile(fp, true);
    		errno = e;
    	} else {
    		if (fdp != 0)
    			fdp = fp.file;
    		r = cleanfile(fp, false);
    	}
    }

    function fclose(FILE fp) internal returns (uint16 r) {
    	if (fp.flags == 0) {	// not open!
    		errno = err.EBADF;
    		return EOF;
    	}
    	r = cleanfile(fp, true);
    }

    // Return the (stdio) flags for a given mode.  Store the flags to be passed to an _open() syscall through *optr. Return 0 on error.
    /*function __sflags(string mode) internal returns (uint16 ret, uint32 optr) {
        uint32 m;
        uint32 o;
        uint8 known;

        for (byte b: mode) {
            if (b == 'r') { // open for reading
    		    ret = __SRD;
    		    m = O_RDONLY;
    		    o = 0;
                break;
    	    } else if (b == 'w') { // open for writing
    	    	ret = __SWR;
    	    	m = O_WRONLY;
    	    	o = O_CREAT | O_TRUNC;
                break;
    	    } else if (b == 'a') {	// open for appending
    		    ret = __SWR;
    		    m = O_WRONLY;
    		    o = O_CREAT | O_APPEND;
                break;
            } else { // illegal mode
    		    errno = err.EINVAL;
    		    return (0, 0);
            }
    	}

        for (byte b: mode) {
    		known = 1;
    		if (b == 'b') // 'b' (binary) is ignored
    			break;
    		else if (b == '+') { // [rwa][b]\+ means read and write
    			ret = __SRW;
    			m = O_RDWR;
    			break;
    		} else if (b == 'x') { // 'x' means exclusive (fail if the file exists)
    			o |= O_EXCL;
    			break;
    		} else if (b == 'e') { // set close-on-exec
    			o |= O_CLOEXEC;
    			break;
    		} else if (b == 'v') { // verify
    			o |= O_VERIFY;
    			break;
    		} else {
    			known = 0;
    			break;
    		}
        }

    	if ((o & O_EXCL) != 0 && m == O_RDONLY) {
    		errno = err.EINVAL;
    		return (0, 0);
    	}
    	optr = m | o;
    }*/

}