pragma ton-solidity >= 0.49.0;

import "Pages.sol";

/* Session management commands manual */
contract PagesSession is Pages {

    function _init1() internal override view accept {
        _add_page("account", "print account information", "[OPTIONS] <ADDRESS>",
            "Obtains and prints account information.",
            "d", 0, M, [
            "dump account StateInit to a tvc file"]);
        _add_page("cd", "Change the shell working directory", "[-L|[-P [-e]]] [dir]",
            "Change the current directory to DIR. The default DIR is the value of the HOME shell variable.",
            "LPe", 1, 1, [
            "force symbolic links to be followed",
            "use the physical directory structure without following symbolic links",
            "with -P, and if the current working directory is invalid, signal error"]);
        _add_page("dd", "convert and copy a file", "[OPERAND]...",
            "Copy a file, converting and formatting according to the operands.",
            "", 0, M, [""]);
        _add_page("finger", "user information lookup program", "[-lms] [user ...]",
            "Displays information about the system users.",
            "lms", 1, M, [
            "produces a multi-line format displaying all of the information described for the -s option as well as the user's home directory",
            "prevent matching of user names",
            "displays the user's login name, write status and login time"]);
        _add_page("hostname", "show or set the system's host name", "[-afis]",
            "Display the system's hostname and address",
            "afis", 0, 0, [
            "alias names",
            "long host name (FQDN)",
            "addresses for the host name",
            "short host name"]);
        _add_page("id", "print real and effective user and group IDs", "[OPTION]... [USER]",
            "Print user and group information for the specified USER, or (when USER omitted) for the current user.",
            "agGnruz", 0, 1, [
            "ignore, for compatibility with other versions",
            "print only the effective group ID",
            "print all group IDs",
            "print a name instead of a number, for -ugG",
            "print the real ID instead of the effective ID, with -ugG",
            "print only the effective user ID",
            "delimit entries with NUL characters, not whitespace"]);
    }

    function init2() external override view accept {
        _add_page("last", "show a listing of last logged in users", "[options] [username...] [tty...]",
            "Searches back through the /var/log/wtmp file (or the file designated by the -f option) and displays a list of all users logged in (and out) since that file was created.",
            "adFiRwx", 0, M, [
            "display hostnames in the last column",
            "translate the IP number back into a hostname",
            "print full login and logout times and dates",
            "display IP numbers in numbers-and-dots notation",
            "don't display the hostname field",
            "display full user and domain names",
            "display system shutdown entries and run level changes"]);
        _add_page("login", "begin session on the system", "[-h host] [username] -r host",
            "Establish a new session with the system.",
            "fhr", 1, 1, [
            "do not perform authentication, user is preauthenticated",
            "name of the remote host for this login",
            "perform autologin protocol for rlogin"]);
        _add_page("logout", "exit a login shell", "",
            "Exits a login shell. Returns an error if not executed in a login shell.",
            "", 0, 0, [""]);
        _add_page("lslogins", "display information about known users in the system", "[options] [-s] [username]",
            "Examine the wtmp and btmp logs, /etc/shadow (if necessary) and /etc/passwd and output the desired data.",
            "cenrsuz", 0, 1, [
            "display data in a format similar to /etc/passwd",
            "display in an export-able output format",
            "display each piece of information on a new line",
            "display in raw mode",
            "display system accounts",
            "display user accounts",
            "delimit user entries with a nul character"]);
        _add_page("mapfile", "read lines from the standard input into an indexed array variable.", "[-d delim] [-n count] [-s count] [-t] [-u fd] [array]",
            "Read lines from the standard input into the indexed array variable ARRAY, or from file descriptor FD if the -u option is supplied.",
            "dnstu", 1, M, [
            "use DELIM to terminate lines, instead of newline",
            "copy at most COUNT lines. If COUNT is 0, all lines are copied",
            "discard the first COUNT lines read",
            "remove a trailing DELIM from each line read (default newline)",
            "read lines from file descriptor FD instead of the standard input"]);
    }

    function init3() external override view accept {
       _add_page("newgrp", "log in to a new group", "[-] [group]",
            "Change the current group ID during a login session.",
            "", 1, M, [""]);
        _add_page("ping", "send a request to network hosts", "[-Dnqv] {destination}",
            "Elicit a response from a host.",
            "Dnqv", 0, M, [
            "print timestamps",
            "no dns name resolution",
            "quiet output",
            "verbose output"]);
        _add_page("pwd", "print name of the working directory", "[OPTION]...",
            "Print the full filename of the current working directory.",
            "LP", 0, 0, [
            "use PWD from environment, even if it contains symlinks",
            "avoid all symlinks"]);
        _add_page("uname", "print system information", "[OPTION]...",
            "Print certain system information. With no OPTION, same as -s.",
            "asnrvmpio", 0, 0, ["print all information, in the following order, except omit -p and -i if unknown:",
            "print the kernel name",
            "print the network node hostname",
            "print the kernel release",
            "print the kernel version",
            "print the machine hardware name",
            "print the processor type (non-portable)",
            "print the hardware platform (non-portable)",
            "print the operating system"]);
        _add_page("who", "show who is logged on", "[OPTION]... [FILE]",
            "Print information about users who are currently logged in.",
            "abdHlpqstTwu", 0, 1, [
            "same as -b -d -l -p -r -t -T -u",
            "time of last system boot",
            "print dead processes",
            "print line of column headings",
            "print system login processes",
            "print active processes spawned by init",
            "all login names and number of users logged on",
            "print only name, line, and time (default)",
            "print last system clock change",
            "",
            "add user's message status as +, - or ?",
            "list users logged in"]);
        _add_page("whoami", "print effective userid", "[OPTION]...",
            "Print the user name associated with the current effective user ID. Same as id -un.",
            "", 0, 0, [""]);
    }
}
