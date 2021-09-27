# **Tonix**

Tonix provides basic file system functionality, as well as an interactive shell with a Unix-style command line interface.

## Pre-requisites

    make: GNU make 4.2.1 or newer
    TON Solidity compiler and tools: solc, stdlib_sol.tvm, tvm_linker, tonos-cli 0.49 or newer
    jq 1.6 or newer
    wget (for "tools" target)

## Installation steps

    make tools: downloads binaries for Ubuntu Linux into ~/bin directory
    make install: configures the local environment
    make tty: launches the command terminal

## Categories of operations

    query file tree and file system status
    manage user session
    operate on files and file attributes
    manage devices and file systems
    manage user access
    process and format text
    browse reference manuals

### File tree and file system status operations

    du - estimate disk usage
    file - determine file type
    ls - list directory contents
    namei - follow a pathname until a terminal point is found
    stat - display file or file system status

### Session operations

    cd - Change the shell working directory
    hostname - show or set the system's host name
    id - print real and effective user and group IDs
    pwd - print name of the working directory
    whoami - print effective userid

### File and file attributes operations

    chgrp - change group ownership
    chmod - change file mode bits
    chown - change file owner and group
    cmp - compare two files byte by byte
    cp - copy files and directories
    fallocate - preallocate or deallocate space to a file
    ln - make links between files
    mkdir - make directories
    mv - move (rename) files
    rm - remove files or directories
    rmdir - remove empty directories
    touch - change file timestamps
    truncate - shrink or extend the size of a file to the specified size

### Devices and file systems management

    df - report file system disk space usage
    findmnt - find a filesystem
    lsblk - list block devices
    mount - mount a filesystem
    mountpoint - see if a directory or file is a mountpoint

### User access management

    groupadd - create a new group
    groupdel - delete a group
    groupmod - modify a group definition on the system
    lslogins - display information about known users in the system
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

    account - print account information
    basename - strip directory and suffix from filenames
    dirname - strip last component from file name
    echo - display a line of text
    help - information about builtin commands
    man - an interface to the system reference manuals
    ps - report a snapshot of the current processes
    readlink - print resolved symbolic links or canonical file names
    realpath - print the resolved path
    uname - print system information
    whatis - display one-line manual page descriptions

## Smart-contract addresses in the famous 'fld' testnet

    0:47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40      FileManager
    0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9      StatusReader
    0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb      DataVolume
    0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5      BlockDevice
    0:4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d      SessionManager
    0:48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec      PrintFormatted
    0:430dd570de5398dbc2319979f5ba4aa99d5254e5382d3c344b985733d141617b      DeviceManager
    0:4a7cd37ce66473c7b383a245891502e5d05c626a69ca764165e2c7d6edd9e317      AccessManager
    0:cc59225a037b56f2cc325c9ced611994e160c4485537fe01ab3787e5d92ddac3      ManualPages
    0:9bc7fdbdadc754e31918f29c22af4a949787e22e84052d94c05e23e9d6e74099      PagesStatus
    0:5838d84e0998f90b98c6a8fa7e6727b9dc7fb7a1f686631bf929206d33a4fd30      PagesCommands
    0:9fb67eacdcb4ef94f9c5c67787778a413328904fe7a3513fd921ee9881114632      PagesSession
    0:379d5fffd72aa80b00e3f3dd73f0f748eeac311b5992de9b3cd3115b97cbb525      PagesUtility
    0:694d24fe1aa0464859d21ce58a62875b80e16f6c36595f363e8b86b603bde7d4      PagesAdmin
    0:9f1e5499529a00aad0990d2f7dd7d1bfd23e2d0939d4e739e2659dc27313819a      StaticBackup
