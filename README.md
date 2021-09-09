Tonix provides basic file system functionality, as well as an interactive shell with a Unix-style command line interface.

installation steps:

make tools: downloads binaries for Ubuntu Linux into ~/bin directory
make install: configures the local environment
make tty: launches the command terminal

The following categories of operations are supported:
    query file tree and file system status
    manage user session
    operate on files
    change file attributes
    process and format text
    access reference manuals

File tree and file system status operations

    df - report file system disk space usage
    du - estimate disk usage
    file - determine file type
    findmnt - find a filesystem
    ls - list directory contents
    lsblk - list block devices
    namei - follow a pathname until a terminal point is found
    ps - report a snapshot of the current processes
    stat - display file or file system status

Session operations

    cd - Change the shell working directory
    hostname - show or set the system's host name
    id - print real and effective user and group IDs
    pwd - print name of the working directory
    whoami - print effective userid

File operations

    cmp - compare two files byte by byte
    cp - copy files and directories
    fallocate - preallocate or deallocate space to a file
    ln - make links between files
    mkdir - make directories
    mv - move (rename) files
    rm - remove files or directories
    rmdir - remove empty directories
    truncate - shrink or extend the size of a file to the specified size

File attributes operations

    chgrp - change group ownership
    chmod - change file mode bits
    chown - change file owner and group
    touch - change file timestamps

Text processing

    cat - concatenate files and print on the standard output
    column - columnate lists
    cut - remove sections from each line of files
    grep - print lines that match patterns
    head - output the first part of files
    tail - output the last part of files
    paste - merge lines of files
    wc - print newline, word, and byte counts for each file

Utility operations

    account - print account information
    basename - strip directory and suffix from filenames
    dirname - strip last component from file name
    echo - display a line of text
    help - information about builtin commands
    lslogins - display information about known users in the system
    man - an interface to the system reference manuals
    readlink - print resolved symbolic links or canonical file names
    realpath - print the resolved path
    uname - print system information
    whatis - display one-line manual page descriptions

Smart-contract addresses in the famous 'fld' testnet:

0:47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40	FileManager
0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9	StatusReader
0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb	DataVolume
0:68c00d417291837826ed9e7aa451d40629dde6d7cf8bcc4fec63cc0978d08205	SuperBlock
0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5	BlockDevice
0:4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d	SessionManager
0:46b494f9e5c5ecfd9a48ddffbe6a85af564445ab58ed1241fd0fb6a666ec369e	Options
0:4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981	ManualCommands
0:41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420	ManualStatus
0:465a0d61deccbf34e1e153b880463e941e5b7bfdf55031eb80afd5352241a50b	TestFS
0:48a04e9fc99be89ddfe4eb1f7303ee417ebae174514b5e11c072834259250eec	PrintFormatted
0:41e37889496dce38efdeb5764cf088287171d72c523c370b37bb6b3621d1f93e	ManualSession
0:4e5561b275d060ff0d0919ccc7e485d08c8e1fe9abd92af6cdf19ebfb2dd5421	ManualUtility
