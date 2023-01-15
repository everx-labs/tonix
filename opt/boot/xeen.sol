pragma ton-solidity >= 0.66.0;

import "disk.h";
import "libstr.sol";
import "libflags.sol";
import "libvmem.sol";
import "libufs.sol";
import "libpart.sol";
contract xeen {
    TvmCell _rom;
    uint32 _version;
    mapping (uint32 => TvmCell) _ram;
    using libvmem for mapping (uint32 => TvmCell);

    function _help(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err) {
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
                return (out, "-gash: help: no help topics match `" + s + "'.  Try `help help' or `man -k " + s + "' or `info " + s + "'.");
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

    function _dev_info() internal view returns (string out) {
        out.append(format("version: {}\n", _version));
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
    function _dump(string arg, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out) {
        flags;
        fsb f = ud.d_fsb;
        mapping (uint32 => TvmCell) m0 = libvmem.mmap(_ram, 0, 4);
        out.append(libvmem.dump_mem(m0));
        out.append(_dev_info());
        out.append(libvmem.dump_mem(m));
        (s_disk d, disklabel l, part_table pt) = read_disk();
        if (arg == "ufs") out.append(libufs.print_disk(ud));
        else if (arg == "ud") out.append(libufs.print_disk_header(ud));
        else if (arg == "label") out.append(libpart.print_label(l));
        else if (arg == "disk") out.append(libpart.print_disk(d));
        else if (arg == "part") out.append(libpart.print_part_table(pt));
        else if (arg == "sb") out.append(libsb.print_sb(f));
        else if (arg == "cg") {
            uint16 i;
            repeat (f.ncg) {
                cg g = libufs.fetch_cg(f, m, i);
                out.append(libsb.print_cg(f, g));
                i++;
            }
        } else if (arg == "inodes") {
            vector(TvmSlice) vino = libvmem.vuload(m[f.iblkno].toSlice());
            out.append("USER\tTYPE   DEVICE SIZE/OFF  NODE\n");
            while (!vino.empty()) {
                TvmSlice s = vino.pop();
                if (s.bits() >= 248) {
                    dinode dd = s.decode(dinode);
    //                out.append(libsb.print_dino(dd));
                    out.append(libfdt.print_dino_lsof(dd));
                } else
                    out.append("Thin ino\n");
            }
        }
    }

    function _label(string arg, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out, string err, uint32 a, TvmCell c) {
        err;
        ud;
        m;
        (bool fe, , bool fw, ) = libflags.flags_set(flags, "enwR");
        (bool fA, , , ) = libflags.flags_set(flags, "A");
        (s_disk d, disklabel l, part_table pt) = read_disk();
        if (fA)
            out.append(libpart.print_label(l));
        if (fe) {
            d = libpart.read_disk_label(l);
            out.append(libpart.print_disk(d));
            out.append(libpart.print_label(l));
            a = 0;
            c = abi.encode(d);
        }
        if (fw) {
            uint8 scheme = libpart.SCHEME_VTOC;
            d = libpart.create_disk(arg, scheme, 0);
            disklabel l1 = libpart.read_standard_label(d);
            out.append(libpart.print_label(l1));
            a = libpart.LABELOFFSET;
            c = abi.encode(l1);
        }
        if (arg.empty())
            out.append(libpart.print_part_table(pt));

    }
    function _gpart(string arg0, string arg1, string arg2, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out, string err, uint32 a, TvmCell c) {
        uint v1 = tou(arg1);
        arg2;
        (bool fa, bool fb, bool ff, bool fi) = libflags.flags_set(flags, "abfi");
        (bool fn, bool ffs, bool ft, ) = libflags.flags_set(flags, "nst");
        (string sattr, string sflags, string ssch, string stype) = libflags.option_values(flags, "afst");
        (uint ustart, uint uindex, uint unentries, uint usize) = libflags.option_values_uint(flags, "bins");
        if (fa) sattr;
        if (ff) sflags;
        if (fb) ustart;
        v1;
        usize;
        if (ft) {
            if (stype == "boot") {}
            else if (stype == "swap") {}
            else if (stype == "ufs") {}
        }
        ud;
        m;
        uint8 scheme;
        if (ffs) {
            scheme = libpart.parse_part_scheme(ssch);
        }
//        part_table pt = read_part_table((uint32(15) << 8) + scheme);
        (s_disk d, disklabel l, part_table pt) = read_disk();
        l;
        uint8 ui = uint8(uindex);
//        (disklabel l, part_table pt) = read_label();
        uint8 i;
        partition p;
        if (fi) {
            (i, p) = libpart.get_part(pt, ui, arg1);
            if (i == 0)
                err.append("partition " + arg1 + " not found");
            else
                out.append(libpart.print_partition(i - 1, p));
        }
        if (arg0 == "add") {
        } else if (arg0 == "backup") {

        } else if (arg0 == "commit") {
        } else if (arg0 == "create") {
            unentries;
//            uint8 nen = (unentries > 0 && unentries <= libpart.MAXPARTITIONS) ? uint8(unentries) : libpart.MAXPARTITIONS;
            d = libpart.create_disk(arg1, scheme, 0);
            part_table pt0 = libpart.create_part_table(scheme);
            if (!fn) {
                out.append(libpart.print_part_table(pt0));
                out.append(libpart.print_disk(d));
            }
            a = 2;
            c = abi.encode(pt0);
        } else if (arg0 == "delete") {
        } else if (arg0 == "modify") {
            out.append("modify type: " + stype);
            if (stype == "boot") {}
            else if (stype == "swap") {
                p.p_fstype = libpart.FS_SWAP;
                pt.d_partitions[i - 1] = p;
                out.append(libpart.print_part_table(pt));
                a = 2;
                c = abi.encode(pt);
            }
            else if (stype == "ufs") {}
        } else if (arg0 == "recover") {
        } else if (arg0 == "resize") {
        } else if (arg0 == "restore") {
        } else if (arg0 == "set") {
        } else if (arg0 == "show") {
            if (!fi)
                out.append(libpart.print_part_table(pt));
        } else if (arg0 == "undo") {
        } else if (arg0 == "unset") {
        }
    }
    function tou(string s) internal pure returns (uint val) {
        optional (int) p = stoi(s);
        if (p.hasValue())
            return uint(p.get());
    }

    function _newfs(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        uint len = args.length;
//        (bool fa, bool fb, bool fc, ) = libflags.flags_set(flags, "abcp");
//        (uint ubsize, uint ubpcg, uint umaxbpg, uint ufsize) = option_values_uint(flags, "bcef");
//        (string svolname, string sdisktype, string sfstype, string spart) = option_values(flags, "LTOp");
        (string spart, , , ) = libflags.option_values(flags, "p");

        (s_disk d, disklabel l, part_table pt) = read_disk();
        l;
        uint8 npart;// = 1;
        string arg0 = len > 0 ? args[0] : "";
        string arg1 = len > 1 ? args[1] : "";
        arg0;
        arg1;
        (uint8 i, partition p) = libpart.get_part(pt, npart, spart);
        if (i == 0)
            (i, p) = libpart.get_part(pt, 1, "");
        if (i == 0)
            err.append("partition " + spart + " not found");
        else {
            out.append(libpart.print_partition(i - 1, p));
            if (p.p_fstype == 0) {
	            uint32 p_size = p.p_size;
	            uint32 p_offset = p.p_offset;
	            uint8 p_fsize = uint8(d.d_sectorsize);
	            uint8 p_fstype = libpart.FS_TOFS;
	            uint8 p_frag = p_fsize * uint8(d.d_fwsectors);
	            uint8 p_cpg = uint8(d.d_fwheads / p_fsize);
                p = partition(p_size, p_offset, p_fsize, p_fstype, p_frag, p_cpg);
                out.append(libpart.print_partition(i - 1, p));
                pt.d_partitions[i - 1] = p;
                out.append(libpart.print_part_table(pt));
                a = 2;
                c = abi.encode(pt);
            }
        }
    }

    function _io(string arg0, string arg1, string arg2, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        (bool ff, , , ) = libflags.flags_set(flags, "f");
        ff;
        err;
        uufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, ud.d_fsb.cblkno, 20);
        uint v0 = tou(arg1);
        out.append(libvmem._conva(v0));
        uint val = tou(arg2);
        if (arg0 == "examine") {
            out.append(libvmem.faccess(m, v0) + "\n");
//            dinode di = libufs.getinode(ud, m, uint16(v0));
        //    out.append(libufs.checkinode(ud, uint16(v0)));
//            out.append(libsb.print_dino(di));
        } else if (arg0 == "read") {
//            out.append(libvmem.faccess(m, v0) + "\n");
//            out.append(libvmem.fread(m, v0) + "\n");
//            dinode di = ud.getinode(m, uint16(v0));
//            out.append(libsb.print_dino(di));
//            out.append(libvmem.fread(m, ud.d_dp) + "\n");
        } else if (arg0 == "fetch") {
            out.append(libvmem.faccess(m, v0) + "\n");
            out.append(libvmem.fread(m, v0) + "\n");
        } else if (arg0 == "store") {
            m.suword(uint8(v0), uint248(val));
            out.append(format("store {} {}\n", v0, val));
            out.append(libvmem.fread(m, v0 * 4) + "\n");
            a;
            c;
        }  else if (arg0 == "write") {
//            uint val = tou(arg1);
            m.suword(uint8(v0), uint248(val));
            out.append(libvmem.fread(m, v0 * 4) + "\n");
        }
        out.append(libvmem.dump_bin(m));
    }

    function _boot(string arg, mapping (uint8 => string) flags, uufsd ud) internal view returns (string out, string err, uint32 a, TvmCell c) {
//        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, 0, 4);
//        out.append(libvmem.dump_mem(m));
        uint res;
//        (out, err, res) = _status();
        (out, err, res) = _status2(255, 0);
//        (string out2, string err2, uint res2) = _inspect(res);
//        out.append(out2);
//        err.append(err2);
        c;
        a;
        flags;
        if (arg == "?") {
	     //Give a short listing of the files in the root directory of	the default boot device, as a hint about available boot files.
        }
//        string filename = arg.empty() ? "/boot/kernel/kernel" : arg;
//        out.append(libufs.print_disk(ud));
//        out.append("> boot " + filename + "\n");
        out.append(">>	Tonix/TON BOOT\nDefault: 0:ad(0,a)/boot/loader\nboot:");
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
            cmd.append("cp qr st.args;");
    }

    function exec(uint8 ncmd, string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, uint32 a, TvmCell c) {
        uint len = args.length;
        string arg0 = len > 0 ? args[0] : "";
        string arg1 = len > 1 ? args[1] : "";
        string arg2 = len > 2 ? args[2] : "";
        uufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, 0, 20);
        if (ncmd == CMD_HELP) (out, err) = _help(args, flags);
        else if (ncmd == CMD_IO) (out, err, a, c) = _io(arg0, arg1, arg2, flags);
        else if (ncmd == CMD_DUMP) out = _dump(arg0, flags, ud, m);
        else if (ncmd == CMD_LABEL) (out, err, a, c) = _label(arg0, flags, ud, m);
        else if (ncmd == CMD_GPART) (out, err, a, c) = _gpart(arg0, arg1, arg2, flags, ud, m);
        else if (ncmd == CMD_NEWFS) (out, err, a, c) = _newfs(args, flags);
        else if (ncmd == CMD_BOOT) (out, err, a, c) = _boot(arg0, flags, ud);
    }
    function aug(string out, string err) internal pure returns (string cmd) {
        if (!err.empty())
            cmd.append("printf \"`tput setaf 1` `jq -r .err qr` `tput sgr0`\n\";");
        if (!out.empty())
            cmd.append("jq -r .out qr;");
    }

    uint8 constant CMD_UNKNOWN  = 0;
    uint8 constant CMD_FIRST    = 1;
    uint8 constant CMD_HELP     = CMD_FIRST;
    uint8 constant CMD_DUMP     = CMD_FIRST + 1;
    uint8 constant CMD_LABEL    = CMD_FIRST + 2;
    uint8 constant CMD_GPART    = CMD_FIRST + 3;
    uint8 constant CMD_NEWFS    = CMD_FIRST + 4;
    uint8 constant CMD_IO       = CMD_FIRST + 5;
    uint8 constant CMD_BOOT     = CMD_FIRST + 6;
    uint8 constant CMD_LAST     = CMD_BOOT;

    struct cmd_info {
        string hotkey;
        string name;
        string synopsis;
        string optstring;
        string short_desc;
        string long_desc;
        string[] optlist;
    }

    cmd_info[CMD_LAST] constant CI = [
cmd_info("", "", "", "", "commands: help dump mount image newfs stat access examine read write fetch store boot", "", [""]),
cmd_info("h", "help",   "[-dms] [pattern ...]", "dms", "Display information about builtin commands",
    "Displays brief summaries of builtin commands.", [
        "d\toutput short description for each topic",
        "m\tdisplay usage in pseudo-manpage format",
        "s\toutput only a short usage synopsis for each topic matching PATTERN"]),
cmd_info("d", "dump", "<arg> [-r]", "r",
"Dump an internal structures specified by <arg>, or memory contents if none. Available types:",
"\n      ud\t\tUFS disk"
"\n      label\tdisk label"
"\n      disk\tdisk data"
"\n      part\tpartition table"
"\n      sb\t\tsuperblock"
"\n      cg\t\tcylinder groups"
"\n      inodes\tindex nodes", [
"r\traw memory format"]),
cmd_info("l", "label",  "[-weR] [-n] disk | -f file", "enwARf:", "read and write Tonix label",
    "installs, examines or modifies the Tonix label on a disk partition", [
        "A\tenables processing of the historical parts",
        "n\tdisplays the result instead of writing it",
        "f\toperate	on a file instead of a disk partition",
        " \texamine the label on a disk drive",
        "w\twrite a	standard label",
        "e\tedit an	existing disk label",
        "R\trestore	a disk label from a file"
        ]),
cmd_info("g", "gpart",  "<action> [ flags ]",
    "lprFNa:b:f:i:n:s:t:", "control utility for the disk partitioning",
"Partition disks. The first argument is the action to be taken:\n"
"\n      add\tAdd a new partition"
"\n      backup\tDump a partition table to standard output in a special format used by the restore action"
"\n      commit\tCommit any pending changes"
"\n      create\tCreate a new partitioning scheme"
"\n      delete\tDelete a partition identified by the -i <index> option"
"\n      modify\tModify a partition identified by the -i <index> option"
"\n      recover\tRecover a corrupt partition's scheme metadata"
"\n      resize\tResize a partition identified by the -i <index> option"
"\n      restore\tRestore the partition table from a backup previously created by the backup action"
"\n      set\tSet the named attribute on the partition entry"
"\n      show\tShow current partition information, or all if none are specified"
"\n      undo\tRevert any pending changes"
"\n      unset\tClear the named attribute on the partition entry", [
    "a attrib\tSpecifies the attribute to set or clear",
    "b start\tThe logical block address where the partition will begin",
    "f flags\tAdditional operational flags",
    "i index\tThe index in the partition table at which the new partition is to be placed",
    "n entries The number of entries in the partition table",
    "s size\tCreate a partition of size <size>",
    "t type\tCreate a partition of type <type>"
]),
cmd_info("n", "newfs",  "[-jnqvDFSV] device", "acjnqvDFSVb:C:i:I:J:G:N:d:m:o:g:L:M:O:p:r:E:t:T:U:e:z:", "Make a Tonix filesystem",
    "Initialize and clear file systems before first use. Builds a file system on the specified special file.", [
        "n\t\tdisplay what it would do if it were to create a filesystem",
        "p partition\tThe partition name to use (a..h)"]),
cmd_info("i", "io", "<command> <address> [arg]", "r", "Memory access",
"\n      examine <addr>\tExamine memory at address <addr>"
"\n      read <addr>\t\tRead memory at address <addr>"
"\n      write <addr> <val>\tWrite <val> to memory at address <addr>"
"\n      fetch <addr>\t\tFetch memory contents from address <addr>"
"\n      store <addr> <val>\tStore unsigned value <val> at address <addr>",
["r\traw memory access"]),
cmd_info("b", "boot",  "<filename>", "qv", "system bootstrapping procedures", "", [
    "q\tbe quiet, do not write anything to the console unless automatic boot fails or is disabled",
    "v\tbe verbose during device probing (and later)."])
    ];

    uint8 constant LCMD_BOOT    = CMD_FIRST;
    uint8 constant LCMD_ECHO    = CMD_FIRST + 1;
    uint8 constant LCMD_HELP    = CMD_FIRST + 2;
    uint8 constant LCMD_INCLUDE = CMD_FIRST + 3;
    uint8 constant LCMD_KLOAD   = CMD_FIRST + 4;
    uint8 constant LCMD_LS      = CMD_FIRST + 5;
    uint8 constant LCMD_LSDEV   = CMD_FIRST + 6;
    uint8 constant LCMD_LSMOD   = CMD_FIRST + 7;
    uint8 constant LCMD_MORE    = CMD_FIRST + 8;
    uint8 constant LCMD_READ    = CMD_FIRST + 9;
    uint8 constant LCMD_REBOOT  = CMD_FIRST + 10;
    uint8 constant LCMD_SET     = CMD_FIRST + 11;
    uint8 constant LCMD_SHOW    = CMD_FIRST + 12;
    uint8 constant LCMD_UNSET   = CMD_FIRST + 13;
    uint8 constant LCMD_QM      = CMD_FIRST + 14;
    uint8 constant LCMD_LAST    = LCMD_QM;

    cmd_info[LCMD_LAST + 1] constant LI = [
cmd_info("a", "autoboot", "[seconds [prompt]]", "", "Proceeds to bootstrap the system",
    "after a number of	seconds, if not interrupted by the user. The kernel will be loaded first if necessary.", [""]),
cmd_info("b", "boot", "[-flag] kernelname [...]", "", "Immediately proceeds to bootstrap the system, loading the kernel if necessary.", "Any	flags or arguments are passed to the kernel, but they must precede the kernel name, if a kernel	name is	provided.", [""]),
cmd_info("e", "echo", "[-n] [<message>]", "n", "Displays text on the screen.", "A new line will be printed unless -n	is specified.", [""]),
cmd_info("h", "help", "[topic [subtopic]]", "", "Shows help	messages read from /boot/loader.help.", "The special topic index will list the topics available.", [""]),
cmd_info("i", "include", "file [file ...]", "", "Process script files", "Each file, in turn, is completely read into memory, and then each	of its lines is	passed to the command line interpreter.	If any error is	returned by the	interpreter", [""]),
cmd_info("k", "kload", "[-t type] file ...", "t:", "Loads a kernel", "kernel loadable module (kld), disk image, or file of opaque contents	tagged as being	of the type type.", [""]),
cmd_info("l", "ls",	"[-l] [path]", "l", "Displays a listing	of files", "in the	directory path,	or the root directory if path is not specified.",  ["l is specified, file sizes will	be shown too."]),
cmd_info("d", "lsdev", "[-v]", "v", "Lists all of the devices", "from which it may	be possible to load modules v more details are printed", [""]),
cmd_info("m", "lsmod", "[-v]", "v", "Displays loaded modules.", "", ["v\tmore details	are shown."]),
cmd_info("o", "more", "file [file ...]", "", "Display the files specified, with a pause at each LINES displayed", "", [""]),
cmd_info("r", "read", "[-t seconds] [-p prompt] [variable]", "t:p:", "Reads a line of input from the terminal", "storing it in variable if	specified. t timeout. p prompt", [""]),
cmd_info("r", "reboot", "", "", "Immediately reboots the system.", "", [""]),
cmd_info("s", "set", "variable=value", "", "Set loader's environment variables.", "", [""]),
cmd_info("h", "show", "[variable]", "", "Displays the specified variable's value", "or all variables and their values if variable is not specified.", [""]),
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
//    function _rl3(bytes bb) internal view returns (uint8 ec, uint8 cmd, string scmd, string[] args, mapping (uint8 => string) flags) {
        uint q = libstr.strchr(bb, 0x20);
        scmd = q > 0 ? bb[ : q - 1] : bb;
        for (uint i = 1; i < cis.length; i++) {
            if (cis[i].name == scmd) {
//        for (uint i = 1; i < CI.length; i++) {
//            if (CI[i].name == scmd) {
                cmd = uint8(i);
                if (q > 0)
//                    (ec, args, flags) = _rl2(bb[q : ], CI[i].optstring);
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
                if (optstring[q] == ":")
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