pragma ton-solidity >= 0.49.0;

import "Manual.sol";

/* Utility commands manual */
contract ManualUtility is Manual {

    function _init1() internal override accept {
        _add_page("basename", "strip directory and suffix from filenames", "NAME",
            "Print NAME with any leading directory components removed.",
            "asz", 1, M, [
            "support multiple arguments and treat each as a NAME",
            "remove a trailing SUFFIX; implies -a",
            "end each output line with NUL, not newline"]);
        _add_page("cat", "concatenate files and print on the standard output", "[OPTION]... [FILE]...",
            "Concatenate FILE(s) to standard output.",
            "AbeEnstTv", 1, M, [
            "equivalent to -vET",
            "number nonempty output lines, overrides -n",
            "equivalent to -vE",
            "display $ at end of each line",
            "number all output lines",
            "suppress repeated empty output lines",
            "equivalent to -vT",
            "display TAB characters as ^I",
            "use ^ and M- notation, except for LFD and TAB"]);
        _add_page("cksum", "checksum and count the bytes in a file", "[FILE]...",
            "Print CRC checksum and byte counts of each FILE.",
            "", 1, M, [""]);
        _add_page("cmp", "compare two files byte by byte", "[OPTION]... FILE1 [FILE2]",
            "Compare two files byte by byte.",
            "bls", 2, 2, [
            "print differing bytes",
            "output byte numbers and differing byte values",
            "suppress all normal output"]);
        _add_page("colrm", "remove columns from a file", "[start [stop]]",
            "Removes selected columns from the lines of a file. A column is defined as a single character in a line. Output is written to the standard output.",
            "", 1, 3, [""]);
        _add_page("column", "columnate lists", "[-entx] [-c columns] [-s sep] [file ...]",
            "The column utility formats its input into multiple columns. Rows are filled before columns. Input is taken from file operands, or, by default, from the standard input. Empty lines are ignored unless the -e option is used.",
            "txne", 0, M, [
            "determine the number of columns the input contains and create a table. Columns are delimited with whitespace by default",
            "fill columns before filling rows",
            "disables merging multiple adjacent delimiters into a single delimiter when using the -t option",
            "do not ignore empty lines"]);
        _add_page("cut", "remove sections from each line of files", "OPTION... [FILE]...",
            "Print selected parts of lines from each FILE to standard output.",
            "fsz", 0, 1, [
            "select only these fields; also print any line that contains no delimiter character, unless the -s option is specified",
            "do not print lines not containing delimiters",
            "line delimiter is NUL, not newline empty"]);
        _add_page("dirname", "strip last component from file name", "[OPTION] NAME...",
            "Output NAME with its last non-slash component and trailing slashes removed; if NAME contains no /'s, output '.' (meaning the current directory).",
            "z", 1, M, [
            "end each output line with NUL, not newline"]);
        _add_page("echo", "display a line of text", "[OPTION]... [STRING]...",
            "Echo the STRING(s) to standard output.",
            "n", 0, M, [
            "do not output the trailing newline"]);
    }

    function init2() external override accept {
        _add_page("expand", "convert tabs to spaces", "[OPTION]... [FILE]...",
            "Convert tabs in each FILE to spaces, writing to standard output.",
            "it", 1, M, [
            "do not convert tabs after non blanks",
            "have tabs N characters apart, not 8"]);
        _add_page("file", "determine file type", "[OPTION...] [FILE...]",
            "Determine type of FILE.",
            "bELhNv0", 1, M, [
            "do not prepend filenames to output lines",
            "on filesystem errors, issue an error message and exit",
            "follow symlinks (default if POSIXLY_CORRECT is set)",
            "don't follow symlinks (default if POSIXLY_CORRECT is not set) (default)",
            "do not pad output",
            "print the version of the program and exit",
            "terminate filenames with ASCII NUL"]);
        _add_page("getent", "get entries from Name Service Switch libraries", "[option]... database key...",
            "Displays entries from databases supported by the Name Service Switch libraries, which are configured in /etc/nss‐witch.conf.  If one or more key arguments are provided, then only the entries that match the supplied keys will be displayed. Otherwise, if no key is provided, all entries will be displayed",
            "", 1, 2, [""]);
        _add_page("grep", "print lines that match patterns", "[OPTION...] PATTERNS [FILE...]",
            "Searches for PATTERNS in each FILE and prints each line that matches a pattern.",
            "vx", 2, M, [
            "invert the sense of matching, to select non-matching lines",
            "select only those matches that exactly match the whole line"]);
        _add_page("head", "output the first part of files", "[OPTION]... [FILE]...",
            "Print the first 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
            "nqvz", 1, M, [
            "print the first NUM lines instead of the first 10;  with the leading '-', print all but the last  NUM lines of each file",
            "never print headers giving file names",
            "always print headers giving file names",
            "line delimiter is NUL, not newline"]);
        _add_page("help", "display information about builtin commands", "[-dms]",
            "Displays brief summaries of builtin commands.",
            "dms", 0, M, [
            "output short description for each topic",
            "display usage in pseudo-manpage format",
            "output only a short usage synopsis for each topic"]);
        _add_page("look", "display lines beginning with a given string", "[-bdf] [-t termchar] string [file ...]",
            "Displays any lines in file which contain string as a prefix.",
            "bdft", 1, M, [
            "use a binary search on the given word list",
            "dictionary character set and order, i.e., only alphanumeric characters are compared",
            "ignore the case of alphabetic characters",
            "specify a string termination character, i.e., only the characters in string up to and including the first occurrence of termchar are compared"]);
        _add_page("man", "an interface to the system reference manuals", "[COMMAND]",
            "System's manual pager. Each page argument given to man is normally the name of a program, utility or function.",
            "a", 0, M, [
            "find all matching manual pages"]);
        _add_page("more", "file perusal filter for crt viewing", "[options] file...",
            "A file perusal filter for CRT viewing.",
            "dflcpsu", 1, M, [
            "display help instead of ringing bell",
            "count logical rather than screen lines",
            "suppress pause after form feed",
            "do not scroll, display text and clean line ends",
            "do not scroll, clean screen and display text",
            "squeeze multiple blank lines into one",
            "suppress underlining"]);
        _add_page("namei", "follow a pathname until a terminal point is found", "[options] pathname...",
            "Interprets its arguments as pathnames to any type of Unix file (symlinks, files, directories, and so forth). namei then follows each pathname until an endpoint is found (a file, a directory, a device node, etc). If it finds a symbolic link, it shows the link, and starts following it, indenting the output to show the context.",
            "xmolnv", 1, M, [
            "show mount point directories with a 'D'",
            "show the mode bits of each file",
            "show owner and group name of each file",
            "use a long listing format (-m -o -v)",
            "don't follow symlinks",
            "vertical align of modes and owners"]);
    }

    function init3() external override accept {
        _add_page("paste", "merge lines of files", "[OPTION]... [FILE]...",
            "Write lines consisting of the sequentially corresponding lines from each FILE, separated by TABs, to standard output.",
            "sz", 1, M, [
            "paste one file at a time instead of in parallel",
            "line delimiter is NUL, not newline"]);
        _add_page("readlink", "print resolved symbolic links or canonical file names", "[OPTION]... FILE...",
            "Print value of a symbolic link or canonical file name. Canonicalize by following every symlink in every component of the given name recursively.",
            "femnqvz", 1, M, [
            "all but the last component must exist",
            "all components must exist",
            "without requirements on components existence",
            "do not output the trailing delimiter",
            "suppress most error messages (on by default)",
            "report error messages",
            "end each output line with NUL, not newline"]);
        _add_page("realpath", "print the resolved path", "[OPTION]... FILE...",
            "Print the resolved absolute file name; all but the last component must exist.",
            "emLPqsz", 1, M, [
            "all components of the path must exist",
            "no path components need exist or be a directory",
            "resolve '..' components before symlinks",
            "resolve symlinks as encountered (default)",
            "suppress most error messages",
            "don't expand symlinks",
            "end each output line with NUL, not newline"]);
        _add_page("rev", "reverse lines characterwise", "[option] [file...]",
            "Copies the specified files to standard output, reversing the order of characters in every line.",
            "", 1, M, [""]);
        _add_page("tail", "output the last part of files", "[OPTION]... [FILE]...",
            "Print the last 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
            "nqvz", 1, M, [
            "output the last NUM lines, instead of the last 10;  or use -n +NUM to output starting with line NUM",
            "never output headers giving file names",
            "always output headers giving file names",
            "line delimiter is NUL, not newline"]);
        _add_page("tr", "translate or delete characters", "[OPTION]... SET1 [SET2]",
            "Translate, squeeze, and/or delete characters from standard input, writing to standard output.",
            "ds", 1, 2, [
            "delete characters in SET1, do not translate",
            "replace each sequence of a repeated character that is listed in the last specified SET, with a single occurrence of that character"]);
        _add_page("unexpand", "convert spaces to tabs", "[OPTION]... [FILE]...",
            "Convert blanks in each FILE to tabs, writing to standard output.",
            "at", 1, M, [
            "convert all blanks, instead of just initial blanks",
            "have tabs N characters apart instead of 8 (enables -a)"]);
        _add_page("wc", "print newline, word, and byte counts for each file", "[OPTION]... [FILE]...",
            "Print newline, word, and byte counts for each FILE, and a total line if more than one FILE is specified. A word is a non-zero-length sequence of characters delimited by white space.",
            "cmlLw", 1, M, [
            "print the byte counts",
            "print the character counts",
            "print the newline counts",
            "print the maximum display width",
            "print the word counts"]);
        _add_page("whatis", "display one-line manual page descriptions", "[-dlv] name ...",
            "Searches the manual page names and displays the manual page descriptions of any name matched.",
            "dlv", 0, M, [
            "emit debugging messages",
            "do not trim output to terminal width",
            "print verbose warning messages"]);
        _write_export_sb();
    }
}
