pragma ton-solidity >= 0.49.0;

import "Pages.sol";

/* File operations command manual */
contract PagesCommands is Pages {

    function _init1() internal override view accept {
        _add_page("chgrp", "change group ownership", "[OPTION]...",
            "Change the group of each FILE to GROUP.",
            "cfvRHLP", 2, M, [
            "like verbose but report only when a change is made",
            "suppress most error messages",
            "output a diagnostic for every file processed",
            "operate on files and directories recursively",
            "if a command line argument is a symbolic link to a directory, traverse it",
            "traverse every symbolic link to a directory encountered",
            "do not traverse any symbolic links (default)"]);
        _add_page("chmod", "change file mode bits", "[OPTION]... MODE FILE...",
            "Changes the file mode bits of each given file according to mode.",
            "cfvR", 2, M, [
            "like verbose but report only when a change is made",
            "suppress most error messages",
            "output a diagnostic for every file processed",
            "change files and directories recursively"]);
        _add_page("chown", "change file owner and group", "[OPTION]... [OWNER] FILE...",
            "Changes the user and/or group ownership of each given file. If only an owner (a user name or numeric user ID) is given, that user is made the owner of each given file, and the files' group is not changed.",
            "cfvRHLP", 2, M, [
            "like verbose but report only when a change is made",
            "suppress most error messages",
            "output a diagnostic for every file processed",
            "operate on files and directories recursively",
            "if a command line argument is a symbolic link to a directory, traverse it",
            "traverse every symbolic link to a directory encountered",
            "do not traverse any symbolic links (default)"]);
    }

    function init2() external override view accept {
        _add_page("cp", "copy files and directories", "[OPTION]... [-T] SOURCE DEST\t[OPTION]... SOURCE... DIRECTORY\t[OPTION]... -t DIRECTORY SOURCE...",
            "Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY. The backup suffix is '~'. As a special case, cp makes a backup of SOURCE when the force and backup options are given and SOURCE and DEST are the same name for an existing, regular file.",
            "abdfHlLnPprRstTuvx", 2, M, [
            "same as -dR -p",
            "make a backup of each existing destination file",
            "same as -P, preserve links",
            "if an existing destination file cannot be opened, remove it and try again",
            "follow command-line symbolic links in SOURCE",
            "hard link files instead of copying",
            "always follow symbolic links in SOURCE",
            "do not overwrite an existing file",
            "never follow symbolic links in SOURCE",
            "preserve mode, ownership, timestamps",
            "",
            "copy directories recursively",
            "make symbolic links instead of copying",
            "copy all SOURCE arguments into DIRECTORY",
            "treat DEST as a normal file",
            "copy only when the SOURCE file is newer than the destination file or when the destination file is missing",
            "explain what is being done",
            "stay on this file system"]);
        _add_page("dd", "convert and copy a file", "[OPERAND]...",
            "Copy a file, converting and formatting according to the operands.",
            "", 0, M, [""]);
        _add_page("fallocate", "preallocate or deallocate space to a file", "[-z] -l length [-n] filename\t-d [-l length] filename\t-x -l length filename",
            "Manipulate the allocated disk space for a file, either to deallocate or preallocate it.",
            "dlnvxz", 1, 1, [
            "detect zeroes and replace with holes",
            "length for range operations, in bytes",
            "maintain the apparent size of the file",
            "verbose mode",
            "use posix_fallocate(3) instead of fallocate(2)",
            "zero and ensure allocation of a range"]);
        _add_page("ln", "make links between files", "[OPTION]... [-T] TARGET LINK_NAME\t[OPTION]... TARGET\t[OPTION]... TARGET... DIRECTORY\t[OPTION]... -t DIRECTORY TARGET...",
            "In the 1st form, create a link to TARGET with the name LINK_NAME.\tIn the 2nd form, create a link to TARGET in the current directory.\tIn the 3rd and 4th forms, create links to each TARGET in DIRECTORY. Create hard links by default, symbolic links with -s. By default, each destination (name of new link) should not already exist. When creating hard links, each TARGET must exist. Symbolic links can hold arbitrary text; if later resolved, a relative link is interpreted in relation to its parent directory.",
            "bfLnPrstTv", 2, M, [
            "make a backup of each existing destination file",
            "remove existing destination files",
            "dereference TARGETs that are symbolic links",
            "treat LINK_NAME as a normal file if it is a symbolic link to a directory",
            "make hard links directly to symbolic links",
            "create symbolic links relative to link location",
            "make symbolic links instead of hard links",
            "specify the DIRECTORY in which to create the links",
            "treat LINK_NAME as a normal file always",
            "print name of each linked file"]);
        _add_page("mkdir", "make directories", "[OPTION]... DIRECTORY...",
            "Create the DIRECTORY(ies), if they do not already exist.",
            "mpv", 1, M, [
            "set file mode (as in chmod), not a=rwx - umask",
            "no error if existing, make parent directories as needed",
            "print a message for each created directory"]);
    }

    function init3() external override view accept {
        _add_page("mv", "move (rename) files", "[OPTION]... [-T] SOURCE DEST\t[OPTION]... SOURCE... DIRECTORY\t[OPTION]... -t DIRECTORY SOURCE...",
            "Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.",
            "bfntTuv", 2, M, [
            "make a backup of each existing destination file",
            "do not prompt before overwriting",
            "do not overwrite an existing file",
            "move all SOURCE arguments into DIRECTORY",
            "treat DEST as a normal file",
            "move only when the SOURCE file is newer than the destination file or when the destination file is missing",
            "explain what is being done"]);
        _add_page("rm", "remove files or directories", "[OPTION]... [FILE]...",
            "Remove each specified file. By default, it does not remove directories. Use -r option to remove each listed directory, too, along with all of its contents.",
            "frRdv", 1, M, [
            "ignore nonexistent files and arguments, never prompt",
            "",
            "remove directories and their contents recursively",
            "remove empty directories",
            "explain what is being done"]);
        _add_page("rmdir", "remove empty directories", "[OPTION]... DIRECTORY...",
            "Remove the DIRECTORY(ies), if they are empty.",
            "pv", 1, M, [
            "remove DIRECTORY and its ancestors; e.g., 'rmdir -p a/b/c' is similar to 'rmdir a/b/c a/b a'",
            "output a diagnostic for every directory processed"]);
       _add_page("rename", "rename files", "from to file...",
            "Rename the specified files by replacing the first occurrence of from in their name by to.",
            "v0nfdm", 1, M, [
            "print names of files successfully renamed",
            "use \\0 as record separator",
            "no action: print names of files to be renamed, but don't rename",
            "over write: allow existing files to be over-written",
            "do not rename directory: only rename filename component of path",
            "manual: print manual page"]);
        _add_page("tar", "an archiving utility", "{A|c|d|r|t|u|x}[GnSkUWOmpsMBiajJzZhPlRvwo] [ARG...]",
            "An archiving program designed to store multiple files in a single file (an archive), and to manipulate such archives.",
            "AcdrtuxkUWOmpRvo", 1, M, [
            "append tar files to an archive",
            "create a new archive",
            "find differences between archive and file system",
            "append files to the end of an archive",
            "list the contents of an archive",
            "only append files newer than copy in archive",
            "extract files from an archive",
            "don't replace existing files when extracting, treat them as errors",
            "remove each file prior to extracting over it",
            "attempt to verify the archive after writing it",
            "extract files to standard output",
            "don't extract file modified time",
            "extract information about file permissions (default for superuser)",
            "show block number within archive with each message",
            "verbosely list files processed",
            "when creating, same as --old-archive; when extracting, same as --no-same-owner"]);
        _add_page("touch", "change file timestamps", "[OPTION]... FILE...",
            "Update the modification time of each FILE to the current time. A FILE argument that does not exist is created empty, unless -c is supplied.",
            "cm", 1, M, [
            "do not create any files",
            "change only the modification time"]);
        _add_page("truncate", "shrink or extend the size of a file to the specified size", "OPTION... FILE...",
            "Shrink or extend the size of each FILE to the specified size\tA FILE argument that does not exist is created.",
            "cors", 1, M, [
            "do not create any files",
            "treat SIZE as number of IO blocks instead of bytes",
            "base size on RFILE",
            "set or adjust the file size by SIZE bytes"]);
    }
}
