pragma ton-solidity >= 0.66.0;

import "libstr.sol";
import "libflags.sol";
import "libvmem.sol";
import "libufs.sol";
contract xeen {
    TvmCell _rom;
    uint32 _version;
    mapping (uint32 => TvmCell) _ram;

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
    function read_ufs_disk() internal view returns (uufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a))
            return abi.decode(_ram[a], uufsd);
    }
    function _dump(string arg, mapping (uint8 => string) flags, mapping (uint32 => TvmCell) m) internal view returns (string out) {
        (bool fa, bool fb, bool fc, bool fd) = libflags.flags_set(flags, "abcd");
//        fsb f = ud.d_fsb;
        mapping (uint32 => TvmCell) m0 = libvmem.mmap(_ram, 0, 4);
        TvmCell c = _ram[0];
        out.append(libvmem.dump_mem(m0));
        out.append(_dev_info());
    }

    function _label(string arg, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out, string err, TvmCell c) {}
    function _gpart(uint8 cmd, string[] args, mapping (uint8 => string) flags, uufsd ud, mapping (uint32 => TvmCell) m) internal view returns (string out, string err, TvmCell c) {}
    function _mkfs(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, TvmCell c) {}    
    function _boot(string arg, mapping (uint8 => string) flags, uufsd ud) internal view returns (string out, string err, TvmCell c) {}
    function complete(string b) external pure returns (string cmd) {
        for (cmd_info ci: CI)
            if (ci.hotkey == b)
                return "read -p \"" + ci.name + " \" input; run rpw s \"" + ci.name + " $input\"";
        for (action_info ai: CA)
            if (ai.hotkey == b)
                return ai.body;
        return "echo ?" + b + "? press 0 for menu";
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

    function rpw(string s) external view returns (string cmd, string out, string err, TvmCell c) {
        (uint8 pec, uint8 ncmd, string scmd, string[] args, mapping (uint8 => string) flags) = _rl3(s);
        if (pec == 0)
            (out, err, c) = exec(ncmd, args, flags);
        else {
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
        cmd = aug(out, err);
        TvmCell empty;
        if (c != empty)
            cmd.append("jq -r .c qr >cell;");
    }

    function exec(uint8 ncmd, string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err, TvmCell c) {
        uint len = args.length;
        string arg0 = len > 0 ? args[0] : "";
        uufsd ud = read_ufs_disk();
//        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, ud.d_fsb.cblkno, 20);
        mapping (uint32 => TvmCell) m = libvmem.mmap(_ram, 0, 20);
        if (ncmd == CMD_HELP) (out, err) = _help(args, flags);
        else if (ncmd == CMD_DUMP) out = _dump(arg0, flags, m);
        else if (ncmd == CMD_LABEL) (out, err, c) = _label(arg0, flags, ud, m);
        else if (ncmd == CMD_GPART) (out, err, c) = _gpart(ncmd, args, flags, ud, m);
        else if (ncmd == CMD_NEWFS) (out, err, c) = _mkfs(args, flags);
        else if (ncmd == CMD_BOOT) (out, err, c) = _boot(arg0, flags, ud);
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
    uint8 constant CMD_BOOT     = CMD_FIRST + 5;
    uint8 constant CMD_LAST     = CMD_BOOT;

    cmd_info[CMD_LAST] constant CI = [
cmd_info("", "", "", "", "commands: help dump mount image newfs stat access examine read write fetch store boot", "", [""]),
cmd_info("h", "help",   "[-dms] [pattern ...]", "dms", "Display information about builtin commands",
    "Displays brief summaries of builtin commands.", [
        "d\t\toutput short description for each topic",
        "m\t\tdisplay usage in pseudo-manpage format",
        "s\t\toutput only a short usage synopsis for each topic matching PATTERN"]),
cmd_info("d", "dump",   "<arg> [-abcdefgh]", "abcdefghi:j:k:l:m:n:",
"Dump an internal structures specified by <arg>, or memory contents if none",
"\n    ud\t\tUFS disk"
"\n    label\tdisk label"
"\n    disk\tdisk data"
"\n    part\tpartition table"
"\n    sb\t\tsuperblock"
"\n    cg\t\tcylinder groups"
"\n    inodes\tindex nodes"
, [""]),
cmd_info("l", "label",  "[-weR] [-n] disk | -f file", "enwARf:", "read and write BSD label",
    "installs, examines or modifies the BSD label on a disk partition", [
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
"\n    add\t\tAdd a new partition"
"\n    backup\tDump a partition table to standard output in a special format used by the restore action"
"\n    commit\tCommit any pending changes"
"\n    create\tCreate a new partitioning scheme"
"\n    delete\tDelete a partition identified by the -i index option"
"\n    modify\tModify a partition identified by the -i index option"
"\n    recover\tRecover a corrupt partition's scheme metadata"
"\n    resize\tResize a partition identified by the -i index option"
"\n    restore\tRestore the partition table from a backup previously created by the backup action"
"\n    set\t\tSet the named attribute on the partition entry"
"\n    show\tShow current partition information, or all if none are specified"
"\n    undo\tRevert any pending changes"
"\n    unset\tClear the named attribute on the partition entry", [
    "a attrib\tSpecifies the attribute to set/clear",
    "b start\tThe logical block address where the partition will begin",
    "f flags\tAdditional operational flags",
    "i index\tThe index in the partition table at which the new partition is to be placed",
    "n entries The number of entries in the partition table",
    "s size\tCreate a partition of size size",
    "t type\tCreate a partition of type type"
]),
cmd_info("n", "newfs",  "[-jnqvDFSV] device", "acjnqvDFSVb:C:i:I:J:G:N:d:m:o:g:L:M:O:p:r:E:t:T:U:e:z:", "Make a Tonix filesystem",
    "Initialize and clear file systems before first use. Builds a file system on the specified special file.", [
        "n\t\tdisplay what it would do if it were to create a filesystem",
        "p partition\tThe partition name to use(a..h)"]),
cmd_info("b", "boot",  "<filename>", "qv", "system bootstrapping procedures", "", [
    "q\tbe quiet, do not write anything to the console unless automatic boot fails or is disabled",
    "v\tbe verbose during device probing (and later)."])
    ];

    action_info[6] constant CA = [
action_info("", "", "", "", "actions: 1) help 2) compile 3) update 4) quit", "", ""),
action_info("1", "help", "", "help", "", "", "run rpw s help"),
action_info("0", "menu", "", "menu", "", "", "printf \"Quick commands:\n1) help\n2) menu\n3) compile\n4) update\n5) quit\n\""),
action_info("3", "compile", "", "compile", "", "", "make cc"),
action_info("4", "update", "", "update", "", "", "make uc"),
action_info("5", "quit", "", "quit", "", "", "echo Bye! && exit 0")
    ];
    struct action_info {
        string hotkey;
        string name;
        string synopsis;
        string optstring;
        string short_desc;
        string long_desc;
        string body;
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

    uint8 constant EXECUTE_SUCCESS  = 0;
    uint8 constant EXECUTE_FAILURE  = 1;
    uint8 constant EX_BADUSAGE      = 2; // Usage messages by builtins result in a return status of 2
    uint8 constant EX_BINARY_FILE	= 126;
    uint8 constant EX_NOEXEC	= 126;
    uint8 constant EX_NOINPUT	= 126;
    uint8 constant EX_NOTFOUND	= 127;
    uint8 constant EX_BADSYNTAX = 1;    // shell syntax error
    uint8 constant EX_USAGE     = 2;    // syntax error in usage // Command line syntax errors (invalid keyword, unknown option)
    uint8 constant EX_REDIRFAIL	= 3;    // redirection failed
    uint8 constant EX_BADASSIGN	= 4;    // variable assignment error
    uint8 constant EX_EXPFAIL	= 5;    // word expansion failed
    uint8 constant EX_DISKFALLBACK = 6;	// fall back to disk command from builtin
    function _rl3(bytes bb) internal view returns (uint8 ec, uint8 cmd, string scmd, string[] args, mapping (uint8 => string) flags) {
        uint q = libstr.strchr(bb, 0x20);
        scmd = q > 0 ? bb[ : q - 1] : bb;
        for (uint i = 1; i < CI.length; i++) {
            if (CI[i].name == scmd) {
                cmd = uint8(i);
                if (q > 0)
                    (ec, args, flags) = _rl2(bb[q : ], CI[i].optstring);
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