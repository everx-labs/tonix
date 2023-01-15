pragma ton-solidity >= 0.66.0;

import "disk.h";
import "proc.h";
import "ucred.h";
import "vmspace.h";
import "buf.h";
import "libstr.sol";
import "libflags.sol";
import "libvmem.sol";
import "libufs.sol";
import "libpart.sol";

import "kproc.sol";
struct namecache {
	uint16 nc_src;	// source vnode list // (namecache)
	uint16 nc_dst;	// destination vnode list // (namecache)
	uint16 nc_hash; // hash chain // (namecache)
	uint16 nc_dvp;  // vnode of parent of name // vnode
	uint16 nu_vp;	// vnode the name refers to // vnode
	uint8 nc_flag;	// flag bits
	uint8 nc_nlen;	// length of name
	string nc_name;	// segment name + nul
}

struct mount {
	uint8 mnt_vfs_ops;		// pending vfs ops
	uint8 mnt_kern_flag;	// kernel only flags
	uint64 mnt_flag;		// flags shared with user
	uint16 mnt_rootvnode;   // vnode
	uint16 mnt_vnodecovered;// vnode we mounted on // vnode
	uint16 mnt_op;		    // operations on fs // vfsops
	vfsconf	mnt_vfc;		// configuration info
	uint8 mnt_gen;		    // struct mount generation
	uint16 mnt_syncer;		// syncer vnode // vnode
    uint16[] mnt_nvnodelist;// list of vnodes // vnode
    uint8 mnt_nvnodelistsize;// # of vnodes
	uint8 mnt_writeopcount;	// write syscalls pending
	vfsopt[] mnt_opt;		// current mount options
	vfsopt[] mnt_optnew;	// new options passed to fs
	uint16 mnt_stat;		// cache of filesystem stats // statfs
	uint16 mnt_cred;		// credentials of mounter // ucred
	uint32 mnt_data;		// private data
	uint32 mnt_time;		// last time writte
	uint16 mnt_iosize_max;	// max size for clusters, etc
	uint16 mnt_export;	    // export list // netexport
	uint16[] mnt_lazyvnodelist;	// list of lazy vnodes
	uint8 mnt_lazyvnodelistsize;// # of lazy vnodes
	uint8 mnt_upper_pending;	// # of pending ops on mnt_uppers
	uint16[] mnt_uppers;    // upper mounts over us // mount_upper_node
	uint16[] mnt_notify;    // upper mounts for notification // mount_upper_node
}

struct vfsconf {
	uint16 vfc_version;		// ABI version number
	string vfc_name;	    // filesystem type name
	uint16 vfc_vfsops;	    // filesystem operations vector // vfsops
	uint16 vfc_vfsops_sd;	// ... signal-deferred // vfsops
	uint8 vfc_typenum;		// historic filesystem type number
	uint8 vfc_refcount;		// number mounted of this type
	uint8 vfc_flags;		// permanent flags
	uint8 vfc_prison_flag;	// prison allow.mount.* flag
	vfsopt[] vfc_opts;	    // mount options
}

struct vfsopt {
	uint16 link;
	string name;
	string value;
	uint8 len;
	uint8 pos;
	uint8 seen;
}


//union vm_map_object {
//	struct vm_object *vm_object;	/* object object */
//	struct vm_map *sub_map;		/* belongs to another map */
//}

contract loader {
//#define LINKER_FILE_LINKED	0x1	/* file has been fully linked */
//#define LINKER_FILE_MODULES	0x2	/* file has >0 modules at preload */
    TvmCell _rom;
    uint32 _version;
    mapping (uint32 => TvmCell) _ram;
    using libvmem for mapping (uint32 => TvmCell);

    uint16 constant PID_MAX = 		63999;
    uint16 constant NO_PID = 		64000;
    uint16 constant THREAD0_TID = 	NO_PID;

    uint32 constant P_MAGIC		= 0xbeefface;
    uint32 constant TDF_INMEM	= 0x00000004; /* Thread's stack is in memory. */
    uint32 constant TDP_KTHREAD	= 0x00200000; /* This is an official kernel thread */
    function proc0_init() internal {
        session session0;
        uint16 s0a;
        pgrp pgrp0;
        uint16 p0a;
        proc proc0;
        thread thread0;
        vmspace vmspace0;
        uint16 vms0a;
        proc initproc;
        uint16[] allproc;
        thread curthread;
        uint32 osreldate;

    	ucred newcred;
    	loginclass tmplc;
    	uint32 pageablemem;
    	int i;
    	proc p = proc0;
        uint16 a; // proc0 address
    	thread td = thread0;
    	p.p_magic = P_MAGIC;
    	p.p_osrel = osreldate;
    	procinit();	    // set up proc zone
    	threadinit();   // set up UMA zones
    	allproc.push(a);
    	p.p_pgrp = p0a;//pgrp0;
    	pgrp0.pg_members.push(a);
    	pgrp0.pg_session = s0a;//session0;
    	session0.s_count = 1;
    	session0.s_leader = a;
//    	p.p_flag = P_SYSTEM | P_INMEM | P_KPROC;
    	p.p_state = p_states.PRS_NORMAL;
    	p.p_nice = 0;
    	td.td_tid = THREAD0_TID;
    	td.td_state = td_states.TDS_RUNNING;
    	td.td_flags = TDF_INMEM;
    	td.td_pflags = TDP_KTHREAD;
    	p.p_leader = a;
    	p.p_comm = "kernel";
    	td.td_name = "swapper";
    	newcred = crget();
    	newcred.cr_ngroups = 1;
    	curthread.td_ucred = 1;//newcred;
    	newcred.cr_loginclass = 1;//tmplc;
    	proc_set_cred_init(p, newcred);
    	p.p_sigacts = sigacts_alloc();
    	siginit(proc0);
    	p.p_pd = pdinit(0, false);
    	p.p_fd = fdinit();
    	p.p_vmspace = vms0a; //vmspace0;
//    	pmap_pinit0(vmspace_pmap(vmspace0));
//    	vm_map_init(vmspace0.vm_map, vmspace_pmap(vmspace0), p.p_sysent.sv_minuser, p.p_sysent.sv_maxuser);
    	//p.process_init();
    	//td.thread_init();
    	//p.process_ctor();
    	//td.thread_ctor();
    }
    function pdinit(uint16, bool) internal returns (uint16) {}
    function proc_set_cred_init(proc p, ucred uc) internal {}
    function siginit(proc p) internal {}
    function cpuset_thread0() internal {}
    function fdinit() internal returns (uint16) {}
    function crget() internal returns (ucred) {}
    function pstats_alloc() internal {}
    function sigacts_alloc() internal returns (uint16) {}
    function procinit() internal {}
    function threadinit() internal {}
    function process_init() internal {}
    function thread_init() internal {}
    function process_ctor() internal {}
    function thread_ctor() internal {}
    function vmspace_pmap(vmspace vms) internal returns (uint32) {}
    function _dev_info() internal view returns (string out) {
        out.append(format("version: {}\n", _version));
    }
    function _help(string[] args, mapping (uint8 => string) flags) internal view returns (string out) {
        if (args.empty()) {
            for (cmd_info ci: CI) {
                (, string name, string synopsis, , , , ) = ci.unpack();
                out.append(name + " " +  synopsis + "\n");
            }
        }
        (bool fd, bool fm, bool ffs, ) = libflags.flags_set(flags, "dms");
        for (string s: args) {
            uint8 c2;
            for (uint i = 1; i < CI.length; i++) {
                if (CI[i].name == s) {
                    c2 = uint8(i);
                    break;
                }
            }
            if (c2 == CMD_UNKNOWN)
                return "-gash: help: no help topics match `" + s + "'.  Try `help help' or `man -k " + s + "' or `info " + s + "'.";
            cmd_info ci;
            if (c2 <= CMD_LAST && c2 > 0)
                ci = CI[c2];
            (, string name, string synopsis, , string short_desc, string long_desc, string[] optlist) = ci.unpack();
            if (fd)
                out.append(name + " - " + short_desc + "\n");
            else if (ffs)
                out.append(name + ": " + name + " " + synopsis + "\n");
            else {
                if (fm)
                    out.append("NAME\n    " + name + " - " + short_desc + "\n\nSYNOPSIS\n    " + name + " " + synopsis + "\n\nDESCRIPTION");
                else
                    out.append(name + ": " + name + " " + synopsis);
                out.append("\n    " + short_desc + "\n\n    " + long_desc + "\n\n    Options:");
                for (string o: optlist)
                    out.append("\n      -" + o);
            }
        }
    }
    uint8 constant UUDISK_LOC = 5;
    function read_disk() internal view returns (s_disk d, disklabel l, part_table pt) {
        uint32 a = libpart.LABELOFFSET;
        if (_ram.exists(a)) {
            d = abi.decode(_ram[a], s_disk);
            a = libpart.LABELSECTOR;
            if (_ram.exists(a)) {
                l = abi.decode(_ram[a], disklabel);
                a++;
                if (_ram.exists(a))
                    pt = abi.decode(_ram[a], part_table);
            }
        }
    }

    function read_ufs_disk() internal view returns (uufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a))
            return abi.decode(_ram[a], uufsd);
    }
    function tou(string s) internal pure returns (uint val) {
        optional (int) p = stoi(s);
        if (p.hasValue())
            return uint(p.get());
    }

    function complete(string b) external pure returns (string cmd) {
        for (cmd_info ci: CI)
            if (ci.hotkey == b)
                return "read -p \"" + ci.name + " \" input; run rpw s \"" + ci.name + " $input\"";
        for (action_info ai: CA)
            if (ai.hotkey == b)
                return ai.body;
        return "echo press '0' for menu";
    }

    function ck(uint32 a, TvmCell c) external view returns (string out) {
        out.append(format("0x{:X}:\n", a));
        out.append(libvmem.dump_slice(_ram[a].toSlice()) + " =>\n");
        out.append(libvmem.dump_slice(c.toSlice()));
        out.append("\n" + libvmem.dump_cell(_ram[a]));
        out.append(" => " + libvmem.dump_cell(c) + "\n");
    }

    function immap(mapping (uint32 => TvmCell) m) external accept {
        for ((uint32 a, TvmCell c): m)
            if (_ram[a] != c)
                _ram[a] = c;
    }
    function st(uint32 a, TvmCell c) external accept {
        _ram[a] = c;
    }
    function ld(uint32 a) external view returns (TvmCell c) {
        c = _ram[a];
    }

    function uc(TvmCell c) external accept {
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }

    function flash(TvmCell c) internal {
        _rom = c;
    }
    function onCodeUpgrade() internal {
        _version++;
    }

    modifier accept {
        tvm.accept();
        _;
    }

    function exec(uint8 ncmd, string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        uint len = args.length;
        string arg0 = len > 0 ? args[0] : "";
        string arg1 = len > 1 ? args[1] : "";
        string arg2 = len > 2 ? args[2] : "";
        if (ncmd == CMD_BOOT) (out, err, a, c) = _boot(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_ECHO) out = _echo(args, flags);
        else if (ncmd == CMD_HELP) out = _help(args, flags);
        else if (ncmd == CMD_INCLUDE) (out, err, a, c) = _include(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_KLOAD) (out, err, a, c) = _kload(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_LS) (out, err, a, c) = _ls(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_LSDEV) (out, err, a, c) = _lsdev(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_LSMOD) (out, err, a, c) = _lsmod(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_MORE) (out, err, a, c) = _more(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_READ) (out, err, a, c) = _read(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_REBOOT) (out, err, a, c) = _reboot(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_SET) (out, err, a, c) = _set(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_SHOW) (out, err, a, c) = _show(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_UNSET) (out, err, a, c) = _unset(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_QM) out = _qm();
    }
    function makedev(uint major, uint minor) internal pure returns (uint16) {
        return uint16((major << 8) + minor);
    }

    function _boot(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        mproc mp1;
        mp1.pid = 1;
        mp1.uid = libfdt.UID_ROOT;
        mp1.cmd = "init";
        mp1.cwd = ofile(libfdt.FD_TYPE_CWD, libfattr.FT_DIR, 0, 0, makedev(8, 32), 2, 30, "/");
        mp1.rtd = ofile(libfdt.FD_TYPE_RTD, libfattr.FT_DIR, 0, 0, makedev(8, 32), 2, 30, "/");
        mp1.txt = ofile(libfdt.FD_TYPE_TXT, libfattr.FT_REG, 0, 0, makedev(0, 20), 60000, 50000, "/init");

        mp1.mf.fdt_ofiles = [
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_CHR,  0, libfdt.FRW,    makedev(1, 3),  14338, 0, "/dev/null"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_CHR,  1, libfdt.FRW,    makedev(1, 3),  14338, 0, "/dev/null"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_CHR,  2, libfdt.FRW,    makedev(1, 3),  14338, 0, "/dev/null"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_CHR,  3, libfdt.FWRITE, makedev(1, 11), 14343, 0, "/dev/kmsg"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_REG,  4, libfdt.FREAD,  makedev(0, 4),  40006, 0, "/mnt"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_REG,  5, libfdt.FREAD,  makedev(0, 4),  40090, 0, "/mnt"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_DIR,  6, libfdt.FRW,    makedev(8, 32),    2, 30, "/"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_SOCK, 7, libfdt.FRW,    makedev(0, 8),  18645, 0, "protocol: AF_VSOCK"),
ofile(libfdt.FD_TYPE_FDN, libfattr.FT_LINK, 8, libfdt.FRW,    makedev(0, 12), 13802, 0, "[eventpoll]")];
        mp1.mf.fdt_nfiles = 9;

        out.append("\n===\n");
        out.append("COMMAND  PID   USER\tFD\tTYPE   DEVICE SIZE/OFF  NODE   NAME\n");
        out.append(libfdt.proc_lsof(mp1));
    }
    function _echo(string[] args, mapping (uint8 => string) flags) internal pure returns (string out) {
        for (string s: args)
            out.append((out.empty() ? "" : " ") + s);
        if (!libflags.set(flags, "n"))
            out.append("\n");
    }
    function _include(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _kload(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _ls(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _lsdev(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _lsmod(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _more(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _read(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _reboot(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _set(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _show(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}
    function _unset(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {}

    function _qm() internal pure returns (string out) {
        out.append("Commands:");
        for (cmd_info ci: CI)
            out.append(" " + ci.name);
    }

    function _errmsg(uint8 pec, string scmd) internal pure returns (string err) {
        if (pec == EX_NOTFOUND)
            err.append(scmd + ": command not found\n");
        else {
            err.append("gash: " + scmd + ": ");
            if (pec == EX_BADUSAGE)
                err.append("invalid option\n");
            else
                err.append(format("EC: {}\n", pec));
        }
    }
    function rpw(string s) external view returns (string cmd, string out, string err, uint32 a, TvmCell c) {
        (uint8 pec, uint8 ncmd, string scmd, string[] args, mapping (uint8 => string) flags) = _rl3(s, CI);
        if (pec == 0)
            (out, err, a, c) = exec(ncmd, args, flags);
        else
            err = _errmsg(pec, scmd);
        cmd = aug(out, err);
        TvmCell empty;
        if (c != empty)
            cmd.append("cp qr lst.args;");
    }

    function aug(string out, string err) internal pure returns (string cmd) {
        if (!err.empty())
            cmd.append("printf \"`tput setaf 1` `jq -r .err qr` `tput sgr0`\n\";");
        if (!out.empty())
            cmd.append("jq -r .out qr;");
    }

    struct cmd_info {
        string hotkey;
        string name;
        string synopsis;
        string optstring;
        string short_desc;
        string long_desc;
        string[] optlist;
    }
    uint8 constant CMD_UNKNOWN  = 0;
    uint8 constant CMD_FIRST    = 1;
    uint8 constant CMD_BOOT    = CMD_FIRST;
    uint8 constant CMD_ECHO    = CMD_FIRST + 1;
    uint8 constant CMD_HELP    = CMD_FIRST + 2;
    uint8 constant CMD_INCLUDE = CMD_FIRST + 3;
    uint8 constant CMD_KLOAD   = CMD_FIRST + 4;
    uint8 constant CMD_LS      = CMD_FIRST + 5;
    uint8 constant CMD_LSDEV   = CMD_FIRST + 6;
    uint8 constant CMD_LSMOD   = CMD_FIRST + 7;
    uint8 constant CMD_MORE    = CMD_FIRST + 8;
    uint8 constant CMD_READ    = CMD_FIRST + 9;
    uint8 constant CMD_REBOOT  = CMD_FIRST + 10;
    uint8 constant CMD_SET     = CMD_FIRST + 11;
    uint8 constant CMD_SHOW    = CMD_FIRST + 12;
    uint8 constant CMD_UNSET   = CMD_FIRST + 13;
    uint8 constant CMD_QM      = CMD_FIRST + 14;
    uint8 constant CMD_LAST    = CMD_QM;

    cmd_info[CMD_LAST + 1] constant CI = [
cmd_info("a", "autoboot", "[seconds [prompt]]", "", "Proceeds to bootstrap the system",
    "after a number of	seconds, if not interrupted by the user. The kernel will be loaded first if necessary.", [""]),
cmd_info("b", "boot", "[-flag] kernelname [...]", "", "Immediately proceeds to bootstrap the system, loading the kernel if necessary.", "Any flags or arguments are passed to the kernel, but they must precede the kernel name, if a kernel name is provided.", [""]),
cmd_info("e", "echo", "[-n] [<message>]", "n", "Displays text on the screen.", "", ["n\tdo not append newline"]),
cmd_info("h", "help", "[topic [subtopic]]", "", "Shows help	messages read from /boot/loader.help.", "The special topic index will list the topics available.", [""]),
cmd_info("i", "include", "file [file ...]", "", "Process script files", "Each file, in turn, is completely read into memory, and then each of its lines is passed to the command line interpreter.	If any error is	returned by the interpreter", [""]),
cmd_info("k", "kload", "[-t type] file ...", "t:", "Loads a kernel", "kernel loadable module (kld), disk image, or file of opaque contents	tagged as being	of the type type.", [""]),
cmd_info("l", "ls",	"[-l] [path]", "l", "Displays a listing of files in the directory path", "the root directory if path is not specified.",  ["l\tshow file sizes"]),
cmd_info("d", "lsdev", "[-v]", "v", "Lists all of the devices", "from which it may be possible to load modules", ["v\tmore details are printed"]),
cmd_info("m", "lsmod", "[-v]", "v", "Displays loaded modules.", "", ["v\tmore details are shown."]),
cmd_info("o", "more", "file [file ...]", "", "Display the files specified", "pause at each LINES displayed", [""]),
cmd_info("r", "read", "[-t seconds] [-p prompt] [variable]", "t:p:", "Reads a line of input from the terminal", "storing it in variable if specified.", ["t timeout", "p prompt"]),
cmd_info("r", "reboot", "", "", "Immediately reboots the system.", "", [""]),
cmd_info("s", "set", "variable=value", "", "Set loader's environment variables.", "", [""]),
cmd_info("v", "vshow", "[variable]", "", "Displays the specified variable's value", "or all variables and their values if variable is not specified.", [""]),
cmd_info("u", "unset", "variable", "", "Removes variable from the environment.", "", [""]),
cmd_info("?", "", "", "", "Lists available commands.", "", [""])
    ];

    uint8 constant ACTION_LAST = 7;
    struct action_info {
        string hotkey;
        string name;
        string synopsis;
        string optstring;
        string short_desc;
        string long_desc;
        string body;
    }
    action_info[ACTION_LAST + 1] constant CA = [
action_info("0", "menu", "", "menu", "", "",
    "printf \"Quick commands:\n1) help\n2) compile\n3) update\n4) view\n5) apply\n6) discard\n7) quit\n\""),
action_info("1", "help", "", "help", "", "", "run rpw s help"),
action_info("2", "compile", "", "compile", "", "", "make cc"),
action_info("3", "update", "", "update", "", "", "make uc"),
action_info("4", "view", "", "view changes", "", "", "[ -s st.args ] && tonos-cli -c etc/xeen.conf runx -m ck st.args | jq -r .out"),
action_info("5", "apply", "", "apply changes", "", "", "[ -s st.args ] && tonos-cli -c etc/xeen.conf callx -m st st.args"),
action_info("6", "discard", "", "discard changes", "", "", "rm -f st.args;"),
action_info("7", "quit", "", "quit", "", "", "echo Bye! && exit 0")
    ];

    struct boot_info {
        uint8 index;
        uint32 loc;
        uint8 off;
        uint8 blen;
        uint16 nbits;
        uint8 nrefs;
        uint32 magic;
        string name;
        string short_desc;
        string long_desc;
    }
    uint8 constant BI_PROPS = 9;
    string[BI_PROPS + 1] constant BIPS = ["N/A", "index", "location", "offset", "block size", "bit size", "ref count", "magic", "unknown"];

    uint8 constant BI_STEPS = 8;
    uint16 constant CG_MAGIC    = 0x4347;
    uint16 constant CGFS_MAGIC  = 0x4346;
    uint16 constant BSD_MAGIC   = 0x8256; // The disk magic number

    boot_info[BI_STEPS + 1] constant BI = [
boot_info(0, 0,  0,  0, 0, 0, 0, "na", "n/a", ""),
boot_info(1, 0,  0,  1, 178, 4, 3, "disk", "disk info", ""),
boot_info(2, 1,  0,  1, 432, 0, BSD_MAGIC, "label", "disk label", ""),
boot_info(3, 2,  0,  1,  65, 1, 8, "part", "partition table", ""),
boot_info(4, 3,  0,  1, 248, 0, CGFS_MAGIC, "sb", "superblock", ""),
boot_info(5, 5,  0,  1,   1, 2, 1, "ufs", "UFS disk", ""),
boot_info(6, 6,  0, 12,   8, 0, CG_MAGIC, "cgs", "cylinder groups summary", ""),
boot_info(7, 19, 0,  8,   2, 0, 0, "inot", "inode table", ""),
boot_info(8, 21, 0,  8,   2, 0, 0, "data", "data blocks", "")
    ];

    function _status2(uint list, uint ) internal view returns (string, string err, uint res) {
        uint i;
        while (list > 0 && i <= BI_STEPS) {
            uint mask = uint(1) << i;
            if ((list & mask) == mask) {
                (uint8 ec, uint expected, uint actual) = _schk(i + 1);
                if (ec > 0)
                    err.append(format("{}) {}: error {}: {} mismatch; {} expected, {} actual\n",
                        i, BI[i].name, ec, BIPS[ec < BI_PROPS ? ec : BI_PROPS], expected, actual));
                else
                    res |= mask;
                list -= mask;
            }
            i++;
        }
    }
    function _schk(uint i) internal view returns (uint8 ec, uint expected, uint actual) {
        if (i > BI_STEPS || i == 0)
            return (1, BI_STEPS, i);
        (uint8 index, uint32 loc, uint8 nblk, uint8 off, uint16 nbits, uint8 nrefs, uint32 magic, , , ) = BI[i].unpack();
        if (i != index)
            return (1, index, i + 1);
        if (!_ram.exists(loc))
            return (2, loc, 0);
        for (uint32 j = 0; j < nblk; j++) {
            if (!_ram.exists(j + loc))
                return (3, nblk, j);
            TvmSlice s = _ram[loc + j].toSlice();
            (uint16 nb, uint8 nr) = s.size();
            if (nb < off)
                return (4, off, nb);
            nb -= off;
            if (off > 0)
                s.skip(off);
            if (nb != nbits)
                return (5, nbits, nb);
            if (nr != nrefs)
                return (6, nrefs, nr);
            uint32 val = _actual_magic(s, i);
            if (val != magic)
                return (7, magic, val);
        }
    }
    function _actual_magic(TvmSlice s, uint i) internal pure returns (uint32) {
        if (i == 1) return s.decode(s_disk).d_hba_vendor;
        else if (i == 2) return s.decode(disklabel).d_magic;
        else if (i == 3) return s.decode(part_table).d_npartitions;
//        else if (i == 4) return s.decode(stat).st_dev;
        else if (i == 4) return s.decode(fsb).magic;
        else if (i == 5) return s.decode(uufsd).d_ufs;
        else if (i == 6) return s.decode(cg).cg_magic;
    }

    uint8 constant EXECUTE_SUCCESS  = 0;
    uint8 constant EXECUTE_FAILURE  = 1;
    uint8 constant EX_BADUSAGE      = 2; // Usage messages by builtins result in a return status of 2
    uint8 constant EX_BINARY_FILE	= 126;
    uint8 constant EX_NOEXEC	    = 126;
    uint8 constant EX_NOINPUT	    = 126;
    uint8 constant EX_NOTFOUND	    = 127;
    uint8 constant EX_BADSYNTAX     = 1;    // shell syntax error
    uint8 constant EX_USAGE         = 2;    // syntax error in usage // Command line syntax errors (invalid keyword, unknown option)
    function _rl3(bytes bb, cmd_info[] cis) internal pure returns (uint8 ec, uint8 cmd, string scmd, string[] args, mapping (uint8 => string) flags) {
        uint q = libstr.strchr(bb, 0x20);
        scmd = q > 0 ? bb[ : q - 1] : bb;
        for (uint i = 1; i < cis.length; i++) {
            if (cis[i].name == scmd) {
                cmd = uint8(i);
                if (q > 0)
                    (ec, args, flags) = _rl2(bb[q : ], cis[i].optstring);
                break;
            }
        }
        if (cmd == CMD_UNKNOWN)
            ec = EX_NOTFOUND;
    }
    function rl2(string s, bytes optstring) external pure returns (uint8 ec, string[] args, mapping (uint8 => string) flags) {
        return _rl2(s, optstring);
    }
    function _rl2(bytes s, bytes optstring) internal pure returns (uint8 ec, string[] args, mapping (uint8 => string) flags) {
        uint8 opt_name;
        uint olen = optstring.length;
        uint[] tp = libstr.strtok(s, 0x20);
        uint pos;
        for (uint te: tp) {
            bytes w = pos > 0 ? s[pos + 1 : te] : s[ : te];
            pos = te;
            uint wl = w.length;
            if (wl == 0)
                continue;
            if (w[0] == '-' && wl > 1) {
                byte b = w[1];
                uint8 v = uint8(b);
                uint q = libstr.strchr(optstring, b);
                if (q == 0) {
                    ec = EX_BADUSAGE;
                    break;
                }
                if (q < olen && optstring[q] == ":")
                    opt_name = v;
                else
                    flags[v] = "";
            } else {
                if (opt_name > 0) {
                    flags[opt_name] = w;
                    opt_name = 0;
                } else
                    args.push(w);
            }
        }
    }
}