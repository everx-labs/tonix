# **Tonix**

* A set of standalone utilities implementing basic file system functionality
* Everscale intrinsic lateral interactive shell with a Unix-style command line interface
* A set of libraries with assorted helper functions for smart-contract development

## Pre-requisites

    make: GNU make 4.2.1 or newer
    TON Solidity compiler and tools: solc, stdlib_sol.tvm, tvm_linker, tonos-cli 0.54 or newer
    jq 1.6 or newer
    wget (for "tools" target)

## Installation steps

    make tools: downloads binaries for Ubuntu Linux into ~/bin directory
    make install: configures the local environment
    make hosts: updates the contract addresses registry
    make tty: launches the command terminal

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

## Smart-contract addresses in the famous 'RFLD' test network

    primary repository: 0:b2250a9c6c04b8817493da726e201183c756f160472a88b11d84101c40a4a30f

    alias       0:b02b3e2d2ad22513e1a2eba9f7945ba19288f8242372774e1adba9034d4b3350
    builtin     0:958a53ab79222ec3648e1295148097e236c513ddfbdbd040e0e08285f316d026
    cd          0:d62467d6217756a71fae47a7f7d409524e3f5cdd3c87f8431800447754ce1883
    command     0:ea1b273f6673a21a0e2e6d86992e6ad13496dcdd1e76e92ea3316e161f108882
    compgen     0:b0502ad655be9abf5cdff4412b15c1a61e234dfd58b0f0328d8cd97179e989f3
    complete    0:0d8f04ab128f58e362b8061af2202e86f66fa0dfa7cf91115820120425681cb8
    declare     0:6e4442915fc40db8d9f5af924104172f4945d4da53082cc289c579171bc46c39
    dirs        0:ebc0cee43cb4386228a083ac2fbea0c1b4430bf6808d538ae5bfba4a1051db50
    echo        0:93cf41a4706f6e9ecee7293900d99756004769576c58ed8f381718eac1fb2edf
    eilish      0:a9ab7a4b2146298fbed9a9790a2c164e8ca7f1e84f7e6b0684ac7c12b37e6ad7
    enable      0:5621730e7b68146bc3be70d9958d78a39e562e989e89440d1cbfb8d7b1c91860
    exec        0:90584d621efc58f105faf711b1e178f81f3e8b456f59e21dca1ddd8318355cfc
    export      0:766aee6cc40bc5f560ce57eb62d6b9bbbee32178cc44be14c5d242721f4e448e
    getopts     0:02b85c5cf5adacd9ca666d253aaa2414415cdd9f16555a87c29966cc14831f10
    hash        0:a1f8105485c704f2b645169fce1d643dce646cb4c9894bcc1129b6a2da5000c7
    help        0:f5f4f0d4304753a1f56f25f92d99e4802696fa6dcb12cf8f435b6a44a9ba73c0
    jobs        0:4fe1881335e06cef5b04e35448693eda907cdf9810bdbd890e227e516a8e6a62
    mapfile     0:1ea8b5a1b4a0ba3ef82fefc190552014a56459575b4d61fd2071c84932281a63
    popd        0:4bc9312dee6664e9656bfbb43ef161463c924cf287c56ec2e082a5252978bd44
    pushd       0:38828ce8a08f4ba2413fa226fce7df029b3436d1be8665d05e24885cab94bf1c
    pwd         0:17af77084e29e044ebf33d5f9eec96947ce067241e211d5d3b58b79746fb8adf
    read        0:afc1283f57f6d9c4039552174f80ef67f7cd738bc0b12236f17b2210a063d8c3
    readonly    0:e49816dc558ce0c9d4db61b1d3515704ff4f0047af5690372fe0b82c21a3dfd7
    set         0:26d02b4f0ee11b9322c0636adab2a57a42fc396c193e5c587fb68732f0578608
    shift       0:8eb7298d3ca941a42e5c61b60823a89414086c74a39d07d23ece1a868adc875e
    shopt       0:b771dffbf39d7debf1e46a6fc8a7db57069c6d4bc4575a6b8d672882fa08ce2e
    source      0:4dae8a1505553e75c84c8585bde43c2384d45ec31ca757520e71bcb7a6b78fc4
    test        0:bfa61396214bdfc38016398fcec8e6013b05672d9d0d12de58046fed81d31f80
    type        0:39995de0c8268aeb1e1657d27419045ec78d24a0a0a03e27ab6ba3f06244d916
    ulimit      0:c614f737b28bfb482c924a46685acc79df5589c1b809b2284117d39c9affa1de
    unalias     0:9ba0ee5650ee4f3dd17e326028d9d53c627991c4f0860e6e6d97d953ac267e90
    unset       0:2945ae2b6b3bd40cc11851ec1be23baa597bdc96221f96f734ba889233fe2287
    basename    0:2689e7171339793c5d2f56cb6f15fcfb64071bf72ff0bd38a1ece98555deb556
    cat         0:5b6931d8aa2908cbba0970d16f75c468f87988304c9e87689c271f2ad9dad63a
    colrm       0:03d902e8fba86634ef05161066a089f1b645639dfdd15af5976004176a4b7842
    column      0:130368f0fdf0307b726cc48f58dc6e5b83a5dae99a470d786eb9beff048bee89
    cp          0:33048e1af4c5ac3d7dd45d17e53f54e283886df7b21defff9e1df39fdc818f64
    cut         0:bb610f38d601ae79f2c9fdb75aa168a3c1e23022c34f5f810d739c1fa81b65d1
    df          0:6241dc024977af1b30366dcbcbaf20ead8ae9645864e2f8fc87c1602a335bc0f
    dirname     0:5dc777cd22ab3eeca7735af5084d4a52a264cec5fb5cafe0b19844c1239303a7
    du          0:779eb3ffd9c96d8e57b8edb2fbbbf140074aaf36919744a6fb04aab536e7bf19
    dumpe2fs    0:f5c66a03c611902e1adc8ee3b81136106f4ec6336d0828fded832db05c6d7841
    env         0:e8190b1af71944aeebfe72d67fb243613be70012cdaf601326b44483445bbed6
    expand      0:a96d5c498558925937a0137658d2b1c38441c3b1059048ab81588203f3bcd753
    file        0:981fbc2bbfbea55add2b3b27d202331a4fcbd1106d2d4a3280ac7364a1c0a7b8
    findmnt     0:1f596bfedbd82bd479af609a8010f009bca3d1a904e4a375fd98fa08ad3478eb
    finger      0:85ec07f73e10032ed3845e4f636fca51c0918e561a05ae469001817e98cbe7be
    fsck        0:43675a694427bdcde8d345e96b8527d529b13dfdf37bb5e501a5748cc5ce4ff5
    fuser       0:4e4f3a14378499d7bf3a5e320986f45dde3ed2880a1ca187cc95c233a0ed818a
    getent      0:b1a9553f40d875d1bf34c94d87eea5bd83a91b7b1315185a28f3d1327cddc11a
    grep        0:42228c95dc89e9bacbeaa548620ad8560c40b55a881ac16bef8335e371e6e699
    groupadd    0:3e6617a4fa42072511a74eb5954eff2ab5650faa313cfa1cf427c221887a756c
    groupdel    0:08aa3c59cb50b653cf3d3d099b52194b475952951cbe41911042e332de500533
    groupmod    0:4188e5ab683211b64131f1bbac74025c70ea810afaa388d3d54ce6ff477b591d
    groups      0:db6bae76705e46acfa03499a5079687c9a4d56485a3254c2db2fba64d64d9bcf
    head        0:0f5b9263cbb6f1d5eb67a6e29a948c83e055b07b26e3071600de49bdaedad09b
    hostname    0:12606441fedd4cac78e71c87e497effe3306348d149417a623704ac9483d545b
    id          0:2ebe4cc1a9990258cb74979add63425ca644da83704f4b9667e047b53e9e8d2e
    install     0:99fb8203a0c5246cc4ea10c1b5603dbd614a878836af30da5e872d1cff364207
    last        0:aad31aed7bd5877dbf788fd6778048130890c99b3e24e5956bb8271d52fa54be
    ln          0:526f83309a7c7b38a84eb03915ff47e6473e5da26661d37c98ee0ce8a0830177
    look        0:d0334a9e455439e8c8e794d974d8a0b794ede5ff676a0ec5c39effed80fb0294
    losetup     0:d256b338430dd8f2be83338cd3d8179071930f1522741a02a047150b35bef07b
    ls          0:755c8f500455b03f9d65db0453668aec631f5ebdc05d90b65f06258fa42f6f01
    lslogins    0:43ab43ca68b96e22570594b2187b3dd911ab79e56a0980da67696fbda7dc46f4
    man         0:48a487218394c2f6cc6f9f8e99368d6934a3af201b0b1092636722c409dc68e8
    mkdir       0:4d089df81d23cc64e921aed49208159492e649ca1331f3be79817b3881459021
    mke2fs      0:5a566482ceb97c8e14d3515ed704be72824eee10ec995f06dae0bf04b358f7a4
    mkfs        0:c4ffc092ed2f97ff6c23346bd47f15e1b3e98e14df87e55066cf827e06b4cf1d
    mknod       0:78923a9e9dc1093fe2116c3380514f9e03216cf30dbce61cebe98fda72fb9ca7
    mount       0:965dba356eff39ec60ea49aa9d74b66ac3d23cca45c484927622088ef0285ca7
    mountpoint  0:1a3893b6c429470cd91b565a88c19fd0c39096f827efa99466d6c6aacf8ff0dd
    mv          0:6260ee3ef2351c5ed628edba43cd16128cd5cc5bb9320162aee8b75357fe742d
    namei       0:3b6e676e9c62031b5870dde4de01441d3b0ca7792e02527967b05d979f38afc5
    newgrp      0:67b8f4c106366f1394ffe195c53f957773c506820bab94c689f69680f6b4ba0a
    paste       0:48a0689eba6fb103e1dff30075e7da72d9af82821963636747332c1fa206f058
    pathchk     0:eefa3ca58ed45f071e5f3e3cbcec1c64c0bc162ac284b6e5c22522305bfb66d1
    printenv    0:31395f73b8724c32e259ca3aabd36bed47024d678a5a5aa6d7b081e43b946d8f
    ps          0:094415c0e0156b08c9077000b8c3a8f9796923bbc9108b8939ab77787a53a743
    readlink    0:2d07751b67e3b0b1ef9dd65324ba9ed49fb21fb678c1577ecff9cf09433de982
    realpath    0:9057954e5ef8ef424547515d08f0f1f90b2dc6b3627b0292adf1fce8f3326749
    rev         0:956d86ffd02ed55aba24ebb136e6b24dfe7689839e028de31356b41a97f4f335
    rm          0:2ad27c29b2085e5783d5055c70fde218528a8000ece340c9808144bb88858584
    rmdir       0:f87446dcd69914e09f41891abf4490f63e6949d05a328cf529daf67cec769daa
    stat        0:75a69996f764924ee1411cfd4df23ab86492442b721922845c0f0553a14882bd
    tail        0:6de0aa6dca2f98368fea1be27682e3bbce86bb6d1db4f534d89c2aa0d399b5a3
    tfs         0:7910bbfd57f2d6b8b7068eac1724d279123b3a98591c5f0230e681809234f902
    tmpfs       0:19b9e8f083b31ed1ade2eb426bc7a09b78be3affac909520a88a85dc9b3103cc
    touch       0:6c080b5a327bc9e27bd3dc8bba9108d7ac12ef9f7d5bb14f01be13fc4590c38b
    tr          0:f4104942a68c26e2a72698152b6f742e84a6c58f3bd76ee6d5494ba22791d266
    udevadm     0:130cca914e520d2b45d9f939eb10becf66e5e2bcedd17b077a446ba0f4ddb28a
    umount      0:e488ddd812ae51f5be624172518ac5fcf08db3708c520eb8cd6c895b14526461
    uname       0:ce074f8a5276d02c72a6ddc7fec1d0589b3cd9bba355b9e096099206ed1880eb
    unexpand    0:f1100fce387214abf80cca3617cafca667581a5899955d6ccc24686b0f501a66
    useradd     0:a79d30d811df46898b1e10596480b8586528223a92ad5647a587ea189e005439
    userdel     0:0837304bfae13cdd2cf399ca6bb42bff587ef211823a10cea1a9d0190af976b7
    usermod     0:e50022644a36c0fbca7dc43136679bd232d5363cb61523dace5b3833f85d8191
    utmpdump    0:39b0cc9cef74f031a39f7849a7c2233e368209a98e7f21f013122db3a9402009
    wc          0:d78970598204411880b79285c10075a3e163d9ffa2dbf08d8a9afcf63ac51637
    whatis      0:068b252363304d0bc0804a887f9279b4a2907a7e95df559d71a7b3f63f3865df
    who         0:ab7dd7722a3c88550224decd281c2c6910ecf17574c00263a37ff2dcb559a97a
    whoami      0:1f56d5172feef9d39c15172beceadf897b995dae745d874abd7becc2e7d58a5d
    lsblk       0:49bcbf4ec8bda12e16506eea9de1b23a808600c7ea0d21fbbbde634411d07c27
    login       0:bae7c5e06bc42846560a025f39abbfdbc678a5f793402c799a70b4c552cd2201