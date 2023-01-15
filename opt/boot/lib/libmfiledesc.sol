pragma ton-solidity >= 0.66.0;
import "fs.h";
import "libfattr.sol";
struct mfiledesc {
	uint8 fdt_nfiles;   // number of open files allocated
	uint8 fd_freefile;	// approx. next free file
	uint32 fd_map;		// bitmap of free fds
    uint8 ec;
    uint8 cur;
    uint8 fdup;
    ofile fb;
    TvmCell cb;
    string sb;
	ofile[] fdt_ofiles;  // open files
}
struct ofile {
    uint8 fdtype;   // cwd/rtd/txt/mem/NOFD/
	uint8 ftype;	// REG/DIR/FIFO/CHR/a_inode/unix/unknown
    uint8 fd;
    uint16 mode;    // r/w/u u: a_inode/unix
    uint16 dev;
	uint16 inode;	// NULL or applicable vnode
	uint16 szoff;   // DFLAG_SEEKABLE specific fields
    string name;
}
struct mproc {
    uint16 pid;
    uint16 uid;
    string cmd;
    ofile cwd;
    ofile rtd;
    ofile txt;
    ofile[] mem;
    mfiledesc mf;
}
library libfdt {
    using libfdt for mfiledesc;
    uint16 constant UID_ROOT	= 0;
    uint16 constant UID_BORIS	= 10;
    uint16 constant GID_WHEEL	= 0;
    uint8 constant FD_TYPE_UNK = 0; // ???
    uint8 constant FD_TYPE_CWD = 1; // cwd
    uint8 constant FD_TYPE_RTD = 2; // rtd
    uint8 constant FD_TYPE_TXT = 3; // txt
    uint8 constant FD_TYPE_MEM = 4; // mem
    uint8 constant FD_TYPE_NFD = 5; // NOFD
    uint8 constant FD_TYPE_FDN = 6; // FD number
    string[6] constant FDTS = [ "unk", "cwd", "rtd", "txt", "mem", "NOFD", ""];
    string[15] constant DT = [ "not yet initialized", "file", "communications endpoint", "pipe", "fifo (named pipe)",
    "event queue", "crypto", "posix message queue", "swap-backed shared memory", "posix semaphore",
    "pseudo teletype master device", "Device specific fd type", "process descriptor", "eventfd", "emulation timerfd type" ];
    function add_open(mfiledesc mf, ofile f) internal {
        uint8 pos = mf.fdt_nfiles++;
        mf.fd_freefile++;
        mf.fd_map |= uint32(1) << pos;
        mf.fdt_ofiles.push(f);
    }
    function dup(mfiledesc mf, uint8 fd) internal returns (uint8 ret) {
        mf.fget(fd);
        if (mf.ec == 0) {
            mf.fdup = ret = mf.fd_freefile++;
            mf.fdt_ofiles.push(mf.fb);
            mf.fdt_nfiles++;
            mf.fd_map |= uint32(1) << ret;
        }
    }
    function fget(mfiledesc mf, uint8 fd) internal {
        if (fd < mf.fdt_nfiles) {
            if (fd != mf.cur) {
                mf.fb = mf.fdt_ofiles[fd];
                mf.cur = fd;
            }
        } else
            mf.ec = EBADF;
    }
    function write(mfiledesc mf, uint8 fd, TvmSlice buf, uint16 nbytes) internal returns (uint16 cnt) {
        mf.fget(fd);
        if (mf.ec == 0) {
            TvmBuilder b;
            if (mf.fb.szoff > 0)
                b.store(mf.cb.toSlice());
            b.store(buf);
            mf.cb = b.toCell();
            cnt = nbytes;
            mf.fb.szoff += nbytes;
        }
    }
    function read(mfiledesc mf, uint8 fd, uint16 nbytes) internal returns (TvmSlice buf) {
        mf.fget(fd);
        if (mf.ec == 0) {
            mf.fb.szoff += nbytes;
            buf = mf.cb.toSlice();
        }
    }
    function dup2(mfiledesc mf, uint8 oldd, uint8 newd) internal returns (uint8 ec, uint8 ret) {
        uint8 pos = mf.fdt_nfiles;
        if (oldd >= pos || newd < pos || oldd == newd)
            return (EBADF, 0);
        if (oldd < pos && newd >= pos) {
            uint8 gap = newd - pos;
            ofile f;
            repeat (gap) {
                mf.fdt_nfiles++;
                mf.fd_map |= uint32(1) << pos++;
                mf.fdt_ofiles.push(f);
            }
            mf.fdt_ofiles.push(mf.fdt_ofiles[oldd]);
            mf.fdt_nfiles++;
            mf.fd_map |= uint32(1) << pos;
            ret = pos;
        }
    }
    function proc_lsof(mproc mp) internal returns (string out) {
        (uint16 pid, uint16 uid, string cmd, ofile cwd, ofile rtd, ofile txt, ofile[] mem, mfiledesc mf) = mp.unpack();
        string suid = uid == UID_ROOT ? "root" : uid == UID_BORIS ? "boris" : "?";
        string prefix = cmd + format("\t{:3}   ", pid) + suid + "\t";
        out.append(prefix + print_ofile_lsof(cwd));
        out.append(prefix + print_ofile_lsof(rtd));
        out.append(prefix + print_ofile_lsof(txt));
        for (ofile f: mem)
            out.append(prefix + print_ofile_lsof(f));
        for (ofile f: mf.fdt_ofiles)
            out.append(prefix + print_ofile_lsof(f));
    }
    function print_dino_lsof(dinode di) internal returns (string out) {
//        (uint16 di_mode, uint8 di_ino, uint8 di_nlink, uint16 di_size, uint32 di_mtime, uint32 di_ctime, uint32 di_btime, uint16 di_db1, uint16 di_db2, uint16 di_flags, uint8 di_blocks, uint8 di_gen, uint16 di_uid, uint16 di_gid, ) = di.unpack();
        (uint16 di_mode, uint8 di_ino, , uint16 di_size, , , , , , , , , uint16 di_uid, , ) = di.unpack();
        string suid = di_uid == UID_ROOT ? "root" : di_uid == UID_BORIS ? "boris" : "?";
        uint8 fi = uint8(((di_mode & libfattr.S_IFMT) >> 12 & 0x0F) >> 1);
        return format("{}\t{}\t{}\t{}\n", suid, libfattr.FTS[libfattr.MTT[fi]], di_size, di_ino);
//        return format("M {} I {} N {} S {} M {} C {} B {} 1 {} 2 {} F {} B {} G {} U {} G {}\n",
//            di_mode, di_ino, di_nlink, di_size, di_mtime, di_ctime, di_btime, di_db1, di_db2, di_flags, di_blocks, di_gen, di_uid, di_gid);
    }
    function print_ofile_lsof(ofile f) internal returns (string out) {
        (uint8 fdtype, uint8 ftype, uint8 fd, uint16 mode, uint16 dev, uint16 inode, uint16 szoff, string name) = f.unpack();
        string sfdtype = FDTS[fdtype];
        string smode;
        string sdev = format("{},{}", dev >> 8 & 0xFF, dev & 0xFF);
        if (fdtype == FD_TYPE_FDN) {
            uint rwf = mode & 0x03;
            smode = rwf == 0x03 ? "u" : rwf == 0x02 ? "w" : rwf == 0x01 ? "r" : "";
            sfdtype = format("{}", fd);
        }
        string sszoff = ftype == libfattr.FT_CHR ? "0t0" : format("{}", szoff);
        out.append(format("{:3}{}\t{}\t{:6}\t{}\t{}\t{}\n",
            sfdtype, smode, libfattr.FTS[ftype], sdev, sszoff, inode, name));
    }
    function print_ofile(ofile fp) internal returns (string out) {
        (uint8 fdtype, uint8 ftype, uint8 fd, uint16 mode, uint16 dev, uint16 inode, uint16 szoff, string name) = fp.unpack();
        out.append(format("fdtype: {} ftype: {} fd: {} mode: {} dev: {} inode: {} szoff: {} name: {}\n", fdtype, ftype, fd, mode, dev, inode, szoff, name));
    }
    function print_file(file fp) internal returns (string out) {
        (uint8 flag, uint8 count, uint8 data, uint8 vnode, uint8 ftype, uint16 offset) = fp.unpack();
        out.append(format("flag: {} count: {} data: {} vnode: {} ftype: {} offset: {}\n",
            flag, count, data, vnode, DT[ftype], offset));
    }
    using libfdt for fdescenttbl;
    uint8 constant FREAD	= 0x01;
    uint8 constant FWRITE	= 0x02;
    uint8 constant FRW      = FREAD + FWRITE;
    uint8 constant FEXEC	= 0x04;	// Open for execute only
    uint8 constant EBADF    = 9;  // Bad file descriptor
    function fget_unlocked(fdescenttbl fdt, uint8 fd) internal returns (uint8 error, file fpp) {
    	if (fd >= fdt.fdt_nfiles)
    		error = EBADF;
        else
            fpp = fdt.fdt_ofiles[fd];
    }
    function fget_write(fdescenttbl fdt, uint8 fd) internal returns (uint8 error, file fpp) {
    	return fdt._fget(fd, FWRITE);
    }
    function fget_read(fdescenttbl fdt, uint8 fd) internal returns (uint8 error, file fpp) {
    	return fdt._fget(fd, FREAD);
    }
    function _fget(fdescenttbl fdt, uint8 fd, uint8 flags) internal returns (uint8 error, file fpp) {
    	file fp;
    	(error, fp) = fdt.fget_unlocked(fd);
    	if (error != 0)
    		return (error, fpp);
    	if (flags == FREAD || flags == FWRITE) {
    		if ((fp.f_flag & flags) == 0)
    			error = EBADF;
        } else if (flags == FEXEC) {
    		if (//fp.f_ops != &path_fileops &&
    		    ((fp.f_flag & (FREAD | FEXEC)) == 0 ||
    		    (fp.f_flag & FWRITE) != 0))
    			error = EBADF;
        }
    	if (error != 0) {
    		return (error, fpp);
    	}
    	fpp = fp;
    }
}