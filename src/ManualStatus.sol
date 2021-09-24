pragma ton-solidity >= 0.49.0;

import "Manual.sol";

/* File system status commands manual */
contract ManualStatus is Manual {

    function _init1() internal override accept {
        _add_page("df", "report file system disk space usage", "[OPTION]... [FILE]...", "displays the amount of disk space available on the file system containing each file name argument.",
            "ahHiklP", 1, M, [
            "include pseudo, duplicate, inaccessible file systems",
            "print sizes in powers of 1024 (e.g., 1023K)",
            "print sizes in powers of 1000 (e.g., 1.1K)",
            "list inode information instead of block usage",
            "block size = 1K",
            "limit listing to local file systems",
            "use the POSIX output format"]);
        _add_page("du", "estimate disk usage", "[OPTION]... [FILE]...", "Summarize disk usage of the set of FILEs, recursively for directories.",
            "abcDhkLlPSsx0", 1, M, [
            "write counts for all files, not just directories",
            "block size = 1 byte",
            "produce a grand total",
            "dereference only symlinks that are listed on the command line",
            "print sizes in human readable format (e.g., 12K 1M)",
            "block size = 1K",
            "dereference all symbolic links",
            "count sizes many times if hard linked",
            "don't follow any symbolic links (this is the default)",
            "for directories do not include size of subdirectories",
            "display only a total for each argument",
            "skip directories on different file systems",
            "end each output line with NUL, not newline"]);
        _add_page("findmnt", "find a filesystem", "[options]\t[options] device|mountpoint[options] [device...]", "list all mounted filesystems or search for a filesystem.",
            "smkAbDfnu", 0, M, [
            "search in static table of filesystems",
            "search in table of mounted filesystems",
            "search in kernel table of mounted filesystems (default)",
            "disable all built-in filters, print all filesystems",
            "print sizes in bytes rather than in human readable format",
            "imitate the output of df(1)",
            "print the first found filesystem only",
            "don't print column headings",
            "don't truncate text in columns"]);
        _add_page("fuser", "identify processes using files or sockets", "[-almsuv]", "displays the PIDs of processes using the specified files or file systems.",
            "almsuv", 0, 1, [
            "display unused files too",
            "list available signal names",
            "show all processes using the named filesystems or block device",
            "silent operation",
            "display user IDs",
            "verbose output"]);
    }

    function init2() external override accept {
        _add_page("ls", "list directory contents", "[OPTION]... [FILE]...", "List information about the FILE (the current directory by default).",
            "aABcCdfFgGhHikLlmnNopqQrRsStuUvxX1", 1, M, [
            "do not ignore entries starting with .",
            "do not list implied . and ..",
            "do not list implied entries ending with ~",
            "with -lt: sort by, and show, ctime; with -l: show ctime and sort by name, otherwise: sort by ctime, newest first",
            "list entries by columns",
            "list directories themselves, not their contents",
            "do not sort, enable -aU",
            "append indicator (one of */=>@|) to entries",
            "like -l, but do not list owner",
            "in a long listing, don't print group names",
            "with -l and -s, print sizes like 1K 234M 2G etc.",
            "follow symbolic links listed on the command line",
            "print the index number of each file",
            "default to 1024-byte blocks for disk usage; used only with -s and per directory totals",
            "for a symbolic link, show information for the file the link references rather than for the link itself",
            "use a long listing format",
            "fill width with a comma separated list of entries",
            "like -l, but list numeric user and group IDs",
            "print entry names without quoting",
            "like -l, but do not list group information",
            "append / indicator to directories",
            "print ? instead of nongraphic characters",
            "enclose entry names in double quotes",
            "reverse order while sorting",
            "list subdirectories recursively",
            "print the allocated size of each file, in blocks",
            "sort by file size, largest first",
            "sort by modification time, newest first",
            "with -lt: sort by, and show, access time; with -l: show access time and sort by name; otherwise: sort by access time, newest first",
            "do not sort; list entries in directory order",
            "natural sort of (version) numbers within text",
            "list entries by lines instead of by columns",
            "sort alphabetically by entry extension",
            "list one file per line. Avoid \'\\n\' with -q or -b"]);
    }

    function init3() external override accept {
        _add_page("lsblk", "list block devices", "[options] [device...]", "List information about all available or the specified block devices.",
            "abfmnOp", 0, M, [
            "print all devices",
            "print SIZE in bytes rather than in human readable format",
            "output info about filesystems",
            "output info about permissions",
            "don't print headings",
            "output all columns",
            "print complete device path"]);
        _add_page("lsof", "list open files", "[-lnoRst]", "",
            "lnoRst", 0, M, [
            "list UID numbers",
            "no host names",
            "list file offset",
            "list paRent PID",
            "list file size",
            "terse listing"]);
        _add_page("mountpoint", "see if a directory or file is a mountpoint", "[-d|-q] directory | file\t-x device",
            "Checks whether the given directory or file is mentioned in the /proc/self/mountinfo file.",
            "dqx", 1, 1, [
            "quiet mode - don't print anything",
            "print maj:min device number of the filesystem",
            "print maj:min device number of the block device"]);
        _add_page("ps", "report a snapshot of the current processes", "[options]", "displays information about a selection of the active processes.",
            "efF", 0, 0, [
            "select all processes",
            "do full-format listing",
            "extra full format"]);
        _add_page("stat", "display file or file system status", "[OPTION]... FILE...", "Display file or file system status.",
            "Lft", 1, M, [
            "follow links",
            "display file system status instead of file status",
            "print the information in terse form"]);
        _write_export_sb();
    }
}
