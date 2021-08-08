pragma ton-solidity >= 0.48.0;

import "ISource.sol";
import "Errors.sol";
import "INode.sol";
import "ExportFS.sol";

contract DataVolume is Errors, ISource, ExportFS {

    function query_command_names() external view override accept {
        Commands(msg.sender).update_command_names{value: 0.1 ton}(_command_names);
    }

    function query_errors() external view override accept {
        Errors(msg.sender).update_errors{value: 0.1 ton}(_error_text);
    }

    function _insert(string name, string purpose, string[] uses, string description) private {
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");

        string m = name + "\t\tUser Commands\nNAME\n\t" + name + " - " + purpose + "\nSYNOPSIS\n" + usage + "DESCRIPTION\n\t" + description + "\n";
        string h = "Usage: " + usage + "\n" + description + "\n";

        _exports[0].files.push(_get_reg_file_node(name + "_man", m));
        _exports[1].files.push(_get_reg_file_node(name + "_help", h));
    }

    function init1() external accept {
        _insert("", "", [""], "");
        _insert("basename", "strip directory and suffix from filenames", ["NAME"], "Print NAME with any leading directory components removed.");
        _insert("cat", "concatenate files and print on the standard output", ["[OPTION]... [FILE]..."], "Concatenate FILE(s) to standard output.");
        _insert("cd", "Change the shell working directory", ["[-L|[-P [-e]]] [dir]"], "Change the current directory to DIR.  The default DIR is the value of the HOME shell variable.");
        _insert("chgrp", "change group ownership", ["[OPTION]... GROUP FILE..."], "Change the group of each FILE to GROUP.");
        _insert("chmod", "change file mode bits", ["[OPTION]... MODE FILE..."], "chmod changes the file mode bits of each given file according to mode");
        _insert("chown", "change file owner and group", ["[OPTION]... [OWNER] FILE..."], "chown changes the user and/or group ownership of each given file.");
        _insert("cksum", "checksum and count the bytes in a file", ["[FILE]..."], "Print CRC checksum and byte counts of each FILE.");
        _insert("cmp", "compare two files byte by byte", ["[OPTION]... FILE1 [FILE2]"], "Compare two files byte by byte.");
        _insert("cp", "copy files and directories",[
            "[OPTION]... [-T] SOURCE DEST",
            "[OPTION]... SOURCE... DIRECTORY", "[OPTION]... -t DIRECTORY SOURCE..."],
            "Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.");
    }

    function init2() external accept {
        _insert("dd", "convert and copy a file", ["[OPERAND]..."], "Copy a file, converting and formatting according to the operands.");
        _insert("df", "report file system disk space usage", ["[OPTION]... [FILE]..."], "displays the amount of disk space available on the file system containing each file name argument.");
        _insert("dirname", "strip last component from file name", ["[OPTION] NAME..."], "Output NAME with its last non-slash component and trailing slashes removed; if NAME contains no /'s, output '.' (meaning the current directory).");
        _insert("du", "estimate disk usage", ["[OPTION]... [FILE]..."], "Summarize disk usage of the set of FILEs, recursively for directories.");
        _insert("echo", "display a line of text", ["[OPTION]... [STRING]..."], "Echo the STRING(s) to standard output.");
        _insert("file", "determine file type", ["[OPTION...] [FILE...]"], "Determine type of FILE");
        _insert("help", "help", [""], "");
        _insert("ln", "make links between files", ["[OPTION]... [-T] TARGET LINK_NAME"], "Create a link to TARGET with the name LINK_NAME.");
        _insert("ls", "list directory contents", ["[OPTION]... [FILE]..."], "List information about the FILE (the current directory by default).");
        _insert("man", "an interface to the system reference manuals", ["[COMMAND]"], "man is the system's manual pager.  Each page argument given to man is normally the name of a program, utility or function.");
        _insert("mkdir", "make directories", ["[OPTION]... DIRECTORY..."], "Create the DIRECTORY(ies), if they do not already exist.");
    }

    function init3() external accept {
        _insert("mv", "move (rename) files", ["[OPTION]... [-T] SOURCE DEST"], "Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.");
        _insert("paste", "merge lines of files", ["[OPTION]... [FILE]..."], "Write lines consisting of the sequentially corresponding lines from each FILE, separated by TABs, to standard output.");
        _insert("pwd", "print name of the working directory", ["[OPTION]..."], "Print the full filename of the current working directory.");
        _insert("rm", "remove files or directories", ["[OPTION]... [FILE]..."], "rm removes each specified file.  By default, it does not remove directories.");
        _insert("rmdir", "remove empty directories", ["[OPTION]... DIRECTORY..."], "Remove the DIRECTORY(ies), if they are empty.");
        _insert("stat", "display file or file system status", ["[OPTION]... FILE..."], "Display file or file system status.");
        _insert("touch", "change file timestamps", ["[OPTION]... FILE..."], "Update the access and modification times of each FILE to the current time.");
        _insert("uname", "print system information", ["[OPTION]..."], "Print certain system information.  With no OPTION, same as -s.");
        _insert("wc", "print newline, word, and byte counts for each file", ["[OPTION]... [FILE]..."], "Print newline, word, and byte counts for each FILE, and a total line if more than one FILE is specified. A word is a non-zero-length sequence of characters delimited by white space.");
        _insert("whoami", "print effective userid", ["[OPTION]..."], "Print the user name associated with the current effective user ID.");
        _insert("mount", "mount a filesystem", ["[-l|-h|-V]", "-a [-fFnrsvw]"], "attach the filesystem found on some device to the file tree");
        _insert("ping", "send ICMP ECHO_REQUEST to network hosts", ["[-dDfhLnqUv] {destination}"], "Elicit a response from a host or gateway.");
        _insert("account", "print account information", ["[OPTIONS] <ADDRESS>"], "Obtains and prints account information.");
    }

    function init() external override accept {
        INodeS[] empty;
        _exports.push(ExportDirS("/usr/share/man", empty));
        _exports.push(ExportDirS("/usr/share/help", empty));
        _init_commands();
        _error_text = ["", "missing operand", "cannot remove", "cannot stat", "cannot access", "cannot create directory",
            "cannot open", "invalid option", "extra operand", "failed to remove", "missing operand after",
            "missing file operand", "missing destination file operand after", "invalid group", "missing filename", "invalid mode",
            "invalid owner", "cannot touch", "cannot create regular file", "too many arguments", "too many operands",
            "Try '--help' for more information", "failed to access", "-r not specified; omitting directory", "cannot overwrite directory with non-directory", "options -l and -s are incompatible",
            "No such file or directory", "File exists", "Not a directory", "Is a directory", "Permission denied",
            "direntry not found", "inode not found", "parent direntry not found", "child direntry not found", "invalid user id",
            "invalid working directory"];
        this.init1();
        this.init2();
        this.init3();
    }

}
