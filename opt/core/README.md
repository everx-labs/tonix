# **Core utilities proof-of-concept **

## Categories of operations

    query file tree and file system status
    operate on files and file attributes
    manage devices and file systems
    manage user access
    process and format text
    browse reference manuals

### File tree and file system status operations

    du - estimate disk usage
    file - determine file type
    ls - list directory contents
    stat - display file or file system status

### File and file attributes operations

    chgrp - change group ownership
    chmod - change file mode bits
    chown - change file owner and group
    cmp - compare two files byte by byte
    cp - copy files and directories
    ln - make links between files
    mkdir - make directories
    mv - move (rename) files
    rm - remove files or directories
    rmdir - remove empty directories
    touch - change file timestamps

### Devices and file systems management

    df - report file system disk space usage
    findmnt - find a filesystem
    fsck - check and repair a Tonix filesystem
    lsblk - list block devices
    mkfs - build a Tonix filesystem
    mount - mount a filesystem
    mountpoint - see if a directory or file is a mountpoint

### User access management

    groupadd - create a new group
    groupdel - delete a group
    groupmod - modify a group definition on the system
    useradd - create a new user or update default new user information
    userdel - delete a user account and related files
    usermod - modify a user account

### Text processing

    cat - concatenate files and print on the standard output
    colrm - remove columns from a file
    column - columnate lists
    cut - remove sections from each line of files
    expand - convert tabs to spaces
    grep - print lines that match patterns
    head - output the first part of files
    look - display lines beginning with a given string
    paste - merge lines of files
    rev - reverse lines characterwise
    tail - output the last part of files
    tr - translate or delete characters
    unexpand - convert spaces to tabs
    wc - print newline, word, and byte counts for each file

### Utility operations

    basename - strip directory and suffix from filenames
    dirname - strip last component from file name
    env - run a program in a modified environment
    getent - get entries from Name Service Switch libraries
    groups - print the groups a user is in
    hostname - show or set the system's host name
    id - print real and effective user and group IDs
    lslogins - display information about known users in the system
    man - an interface to the system reference manuals
    namei - follow a pathname until a terminal point is found
    pathchk - check whether file names are valid or portable
    printenv  - print all or part of environment
    ps - report a snapshot of the current processes
    readlink - print resolved symbolic links or canonical file names
    realpath - print the resolved path
    uname - print system information
    whatis - display one-line manual page descriptions
    whoami - print effective userid

### Interactive shell

    alias - Define or display aliases.
    builtin - Execute shell builtins.
    cd - Change the shell working directory.
    command - Execute a simple command or display information about commands.
    compgen - Display possible completions depending on the options.
    complete - Specify how arguments are to be completed
    declare - Set variable values and attributes.
    dirs - Display directory stack.
    echo - Write arguments to the standard output.
    enable - Enable and disable shell builtins.
    exec - Replace the shell with the given command.
    export - Set export attribute for shell variables.
    hash - Remember or display program locations.
    help - Display information about builtin commands.
    jobs - Display status of jobs.
    mapfile - Read lines from the standard input into an indexed array variable.
    type - Display information about command type.
    popd - Remove directories from stack.
    pushd - Add directories to stack.
    pwd - Print the name of the current working directory.
    read - Read a line from the standard input and split it into fields.
    readonly - Mark shell variables as unchangeable.
    set - Set or unset values of shell options and positional parameters.
    shift - Shift positional parameters.
    shopt - Set and unset shell options.
    source - Execute commands from a file in the current shell.
    test - Evaluate conditional expression.
    ulimit - Modify shell resource limits.
    unalias - Remove each NAME from the list of defined aliases.
    unset - Unset values and attributes of shell variables and functions.
