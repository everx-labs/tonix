pragma ton-solidity >= 0.67.0;
import "libflags.sol";
import "common.h";
contract help is common {
    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err) {
        return _help(args, flags);
    }
    function _help(string[] args, mapping (uint8 => string) flags) internal view returns (string out, string err) {
        if (args.empty()) {
            for (cmd_helpfile ci: CI) {
                (string name, string synopsis, , , ) = ci.unpack();
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
            if (c2 == UNKNOWN)
                return (out, "-gash: help: no help topics match `" + s + "'.  Try `help help' or `man -k " + s + "' or `info " + s + "'.");
            cmd_helpfile ci;
            if (c2 <= CMD_LAST && c2 > 0)
                ci = CI[c2];
            (string name, string synopsis, string short_desc, string long_desc, string[] optlist) = ci.unpack();
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
    uint8 constant UNKNOWN    = 0;
    uint8 constant HELP       = 1;
    uint8 constant MKFS_FIRST = HELP + 1;
    uint8 constant DUMP       = MKFS_FIRST;
    uint8 constant MOUNT      = MKFS_FIRST + 1;
    uint8 constant IMAGE      = MKFS_FIRST + 2;
    uint8 constant LABEL      = MKFS_FIRST + 3;
    uint8 constant GPART      = MKFS_FIRST + 4;
    uint8 constant NEWFS      = MKFS_FIRST + 5;
    uint8 constant MKFS_LAST  = NEWFS;
    uint8 constant STAT_FIRST = MKFS_LAST + 1;
    uint8 constant CS_STAT    = STAT_FIRST;
    uint8 constant CS_ACCESS  = STAT_FIRST + 1;
    uint8 constant STAT_LAST  = CS_ACCESS;
    uint8 constant IO_FIRST   = STAT_LAST + 1;
    uint8 constant IO_EXAMINE = IO_FIRST;
    uint8 constant IO_READ    = IO_FIRST + 1;
    uint8 constant IO_WRITE   = IO_FIRST + 2;
    uint8 constant IO_FETCH   = IO_FIRST + 3;
    uint8 constant IO_STORE   = IO_FIRST + 4;
    uint8 constant IO_LAST    = IO_STORE;
    uint8 constant BOOT       = IO_LAST + 1;
    uint8 constant UFS        = BOOT + 1;
    uint8 constant CMD_LAST   = UFS;
    struct cmd_helpfile {
        string name;
        string synopsis;
        string short_desc;
        string long_desc;
        string[] optlist;
    }
    cmd_helpfile[CMD_LAST] constant CI = [
cmd_helpfile("", "", "commands: help dump mount image newfs stat access examine read write fetch store boot", "", [""]),
cmd_helpfile("help",   "[-dms] [pattern ...]", "Display information about builtin commands",
    "Displays brief summaries of builtin commands.", [
        "d\toutput short description for each topic",
        "m\tdisplay usage in pseudo-manpage format",
        "s\toutput only a short usage synopsis for each topic matching PATTERN"]),
cmd_helpfile("dump", "<arg> [-abcdefgh]", "Dump an internal structures specified by <arg>, or memory contents if none",
"\n    ud\t\tUFS disk"
"\n    label\tdisk label"
"\n    disk\tdisk data"
"\n    part\tpartition table"
"\n    sb\t\tsuperblock"
"\n    cg\t\tcylinder groups"
"\n    inodes\tindex nodes", [""]),
cmd_helpfile("mount",  "[-fnrsvw] device dir", "Mount a filesystem",
    "The mount utility calls the nmount(2) system call to prepare and graft a special device or the remote node (rhost:path) on to the file system tree at the point node.", [
        "f\tdry run; skip the mount(2) syscall"]),
cmd_helpfile("image",  "-ra [ -cfnp ] device image-file", "Save critical filesystem metadata to a file", "", ["r\traw format"]),
cmd_helpfile("label",  "[-weR] [-n] disk | -f file", "read and write BSD label",
    "installs, examines or modifies the BSD label on a disk partition", [
        "A\tenables processing of the historical parts",
        "n\tdisplays the result instead of writing it",
        "f\toperate on a file instead of a disk partition",
        " \texamine the label on a disk drive",
        "w\twrite a standard label",
        "e\tedit an existing disk label",
        "R\trestore a disk label from a file"]),
cmd_helpfile("gpart",  "<action> [ flags ]",
    "control utility for the disk partitioning",
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
    "t type\tCreate a partition of type type"]),
cmd_helpfile("newfs",  "[-jnqvDFSV] device", "Make a Tonix filesystem",
    "Initialize and clear file systems before first use. Builds a file system on the specified special file.", [
        "n\t\tdisplay what it would do if it were to create a filesystem",
        "p partition\tThe partition name to use(a..h)"]),
cmd_helpfile("stat",   "[OPTION]... FILE...", "Print file status",
    "The stat() system call obtains information about the file pointed to by path.", [
        "f\tdisplay file system status instead of file status"]),
cmd_helpfile("access", "<address>", "Access file path", "", [""]),
cmd_helpfile("examine", "<address>", "Examine memory address", "", [""]),
cmd_helpfile("read",   "<address>", "Read memory address", "", [""]),
cmd_helpfile("write",  "<address> <value>", "Write memory at address", "", [""]),
cmd_helpfile("fetch",  "<address>", "Fetch memory contents", "", [""]),
cmd_helpfile("store",  "<address> <value>", "Store unsigned value at address", "", [""]),
cmd_helpfile("boot",  "<filename>", "system bootstrapping procedures", "", [
    "q\tbe quiet, do not write anything to the console unless automatic boot fails or is disabled",
    "v\tbe verbose during device probing (and later)."]),
cmd_helpfile("ufs",  "<command> <arg>", "operate on UFS file systems from userland",
"access a UFS file system at a low level from userland", [""])];
}
