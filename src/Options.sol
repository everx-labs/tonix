pragma ton-solidity >= 0.48.0;

import "Commands.sol";
import "INode.sol";
import "ExportFS.sol";

contract Options is Commands, ExportFS {

    function _c11() private {
        string[] empty;
        _add_command("res0", empty);
        _add_command("basename", [
            "a", "support multiple arguments and treat each as a NAME",
            "s", "remove a trailing SUFFIX; implies -a",
            "z", "end each output line with NUL, not newline"]);
        _add_command("cat", [
            "b", "number nonempty output lines, overrides -n",
            "E", "display $ at end of each line",
            "n", "number all output lines",
            "s", "suppress repeated empty output lines",
            "t", "equivalent to -vT",
            "T", "display TAB characters as ^I",
            "v", "use ^ and M- notation, except for LFD and TAB"]);
        _add_command("cd", [
            "L", "force symbolic links to be followed",
            "P", "use the physical directory structure without following symbolic links",
            "e", "if the -P option is supplied, and the current working directory cannot be determined successfully, exit with a non-zero status"]);
        _add_command("chgrp", [
            "c", "like verbose but report only when a change is made",
            "f", "suppress most error messages",
            "v", "output a diagnostic for every file processed",
            "R", "operate on files and directories recursively",
            "H", "if a command line argument is a symbolic link to a directory, traverse it",
            "L", "traverse every symbolic link to a directory encountered",
            "P", "do not traverse any symbolic links (default)"]);
        _add_command("chmod", [
            "c", "like verbose but report only when a change is made",
            "f", "suppress most error messages",
            "v", "output a diagnostic for every file processed",
            "R", "change files and directories recursively"]);
        _add_command("chown", [
            "c", "like verbose but report only when a change is made",
            "f", "suppress most error messages",
            "v", "output a diagnostic for every file processed",
            "R", "operate on files and directories recursively",
            "H", "if a command line argument is a symbolic link to a directory, traverse it",
            "L", "traverse every symbolic link to a directory encountered",
            "P", "do not traverse any symbolic links (default)"]);
        _add_command("cksum", empty);
        _add_command("cmp", [
            "s", "suppress all normal output"]);
    }
    function _c12() private {
        string[] empty;
        _add_command("cp", [
            "a", "same as -dR -p",
            "b", "make a backup of each existing destination file",
            "f", "if an existing destination file cannot be opened, remove it and try again",
            "H", "follow command-line symbolic links in SOURCE",
            "l", "hard link files instead of copying",
            "L", "always follow symbolic links in SOURCE",
            "n", "do not overwrite an existing file",
            "P", "never follow symbolic links in SOURCE",
            "R, -r", "copy directories recursively",
            "s", "make symbolic links instead of copying",
            "t", "copy all SOURCE arguments into DIRECTORY",
            "T", "treat DEST as a normal file",
            "u", "copy only when the SOURCE file is newer than the destination file or when the destination file is missing",
            "v", "explain what is being done",
            "x", "stay on this file system"]);
        _add_command("dd", empty);
        _add_command("df", empty);
        _add_command("dirname", [
            "z", "end each output line with NUL, not newline"]);
        _add_command("du", [
            "0", "end each output line with NUL, not newline",
            "a", "write counts for all files, not just directories",
            "b", "block size = 1 byte", "c", "produce a grand total",
            "D, H", "dereference only symlinks that are listed on the command line",
            "h", "print sizes in human readable format (e.g., 1K 234M 2G)",
            "k", "block size = 1K",
            "L", "dereference all symbolic links",
            "l", "count sizes many times if hard linked",
            "m", "block size = 1M",
            "P", "don't follow any symbolic links (this is the default)",
            "S", "for directories do not include size of subdirectories",
            "s", "display only a total for each argument",
            "x", "skip directories on different file systems"]);
        _add_command("echo", [
            "n", "do not output the trailing newline"]);
        _add_command("file", [
            "b", "Do not prepend filenames to output lines (brief mode)",
            "E", "On filesystem errors, issue an error message and exit",
            "N", "Don't pad filenames so that they align in the output",
            "v", "Print the version of the program and exit",
            "0", "Output a null character ‘\\0’ after the end of the filename"]);
        _add_command("help", [
            "d", "output short description for each topic",
            "m", "display usage in pseudo-manpage format"]);
        _add_command("ln", [
            "b", "make a backup of each existing destination file",
            "f", "remove existing destination files",
            "L", "dereference TARGETs that are symbolic links",
            "n", "treat LINK_NAME as a normal file if it is a symbolic link to a directory",
            "P", "make hard links directly to symbolic links",
            "r", "create symbolic links relative to link location",
            "s", "make symbolic links instead of hard links",
            "t", "specify the DIRECTORY in which to create the links",
            "T", "treat LINK_NAME as a normal file always",
            "v", "print name of each linked file"]);
    }

    function _c2() private {
        _add_command("ls", [
            "a", "do not ignore entries starting with .",
            "A", "do not list implied . and ..",
            "B", "do not list implied entries ending with ~",
            "c", "with -lt: sort by, and show, ctime; with -l: show ctime and sort by name, otherwise: sort by ctime, newest first",
            "C", "list entries by columns",
            "d", "list directories themselves, not their contents",
            "f", "do not sort, enable -aU",
            "F", "append indicator (one of */=>@|) to entries",
            "g", "like -l, but do not list owner",
            "G", "in a long listing, don't print group names",
            "h", "with -l and -s, print sizes like 1K 234M 2G etc.",
            "H", "follow symbolic links listed on the command line",
            "i", "print the index number of each file",
            "k", "default to 1024-byte blocks for disk usage; used only with -s and per directory totals",
            "L", "for a symbolic link, show information for the file the link references rather than for the link itself",
            "l", "use a long listing format",
            "m", "fill width with a comma separated list of entries",
            "n", "like -l, but list numeric user and group IDs",
            "N", "print entry names without quoting",
            "o", "like -l, but do not list group information",
            "p", "append / indicator to directories",
            "q", "print ? instead of nongraphic characters",
            "Q", "enclose entry names in double quotes",
            "r", "reverse order while sorting",
            "R", "list subdirectories recursively",
            "s", "print the allocated size of each file, in blocks",
            "S", "sort by file size, largest first",
            "t", "sort by modification time, newest first",
            "u", "with -lt: sort by, and show, access time; with -l: show access time and sort by name; otherwise: sort by access time, newest first",
            "U", "do not sort; list entries in directory order",
            "v", "natural sort of (version) numbers within text",
            "x", "list entries by lines instead of by columns",
            "X", "sort alphabetically by entry extension",
            "1", "list one file per line. Avoid \'\\n\' with -q or -b"]);
        _add_command("man", [
            "a", "find all matching manual pages"]);
        _add_command("mkdir", [
            "m", "set file mode (as in chmod), not a=rwx - umask",
            "p", "no error if existing, make parent directories as needed",
            "v", "print a message for each created directory"]);
    }

    function _c3() private {
        string[] empty;
        _add_command("mv", [
            "b", "make a backup of each existing destination file",
            "f", "do not prompt before overwriting",
            "n", "do not overwrite an existing file",
            "t", "move all SOURCE arguments into DIRECTORY",
            "T", "treat DEST as a normal file",
            "u", "move only when the SOURCE file is newer than the destination file or when the destination file is missing",
            "v", "explain what is being done"]);
        _add_command("pwd", [
            "L", "use PWD from environment, even if it contains symlinks",
            "P", "avoid all symlinks"]);
        _add_command("rm", [
            "f", "ignore nonexistent files and arguments, never prompt",
            "r, R", "remove directories and their contents recursively",
            "d", "remove empty directories",
            "v", "explain what is being done"]);
        _add_command("rmdir", [
            "p", "remove DIRECTORY and its ancestors; e.g., 'rmdir -p a/b/c' is similar to 'rmdir a/b/c a/b a'",
            "v", "output a diagnostic for every directory processed"]);
        _add_command("paste", [
            "s", "paste one file at a time instead of in parallel",
            "z", "line delimiter is NUL, not newline"]);
        _add_command("stat", [
            "L", "follow links",
            "f", "display file system status instead of file status",
            "t", "print the information in terse form"]);
        _add_command("touch", [
            "a", "change only the access time",
            "c", "do not create any files",
            "m", "change only the modification time"]);
        _add_command("uname", [
            "a", "print all information, in the following order, except omit -p and -i if unknown:",
            "s", "print the kernel name",
            "n", "print the network node hostname",
            "r", "print the kernel release",
            "v", "print the kernel version",
            "m", "print the machine hardware name",
            "p", "print the processor type (non-portable)",
            "i", "print the hardware platform (non-portable)",
            "o", "print the operating system"]);
        _add_command("wc", [
            "c", "print the byte counts",
            "m", "print the character counts",
            "l", "print the newline counts",
            "L", "print the maximum display width",
            "w", "print the word counts"]);
        _add_command("whoami", empty);
        _add_command("mount", [
            "a", "mount all filesystems mentioned in fstab",
            "c", "don't canonicalize paths",
            "f", "dry run; skip the mount(2) syscall",
            "l", "show also filesystem labels",
            "n", "don't write to /etc/mtab",
            "v", "say what is being done",
            "w", "mount the filesystem read-write (default)"]);
        _add_command("ping", [
            "D", "print timestamps",
            "n", "no dns name resolution",
            "q", "quiet output",
            "U", "print user-to-user latency",
            "v", "verbose output"]);
        _add_command("account", [
            "d", "dump account StateInit to a tvc file"]);
    }

    function _add_command(string cmd_name, string[] names) private {
        string s;
        for (uint i = 0; i < names.length / 2; i++)
            s.append("\t-" + names[i * 2] + "\t\t" + names[i * 2 + 1] + "\n");
        s.append("\t--help\t\tdisplay this help and exit\n\t--version\toutput version information and exit\n");
        INodeS inode = _get_reg_file_node(cmd_name + "_opt", s);
        _exports[0].files.push(inode);
    }

    function init12() external accept {
        _c12();
    }
    function init2() external accept {
        _c2();
    }
    function init3() external accept {
        _c3();
    }

    function init() external override accept {
        INodeS[] empty;
        _exports.push(ExportDirS("/usr/share/options", empty));
        _init_commands();
        _c11();
        this.init12();
        this.init2();
        this.init3();
    }

}


