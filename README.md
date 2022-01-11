# **Tonix**

* A set of standalone utilities implementing basic file system functionality
* Everscale intrinsic lateral interactive shell with a Unix-style command line interface

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

    0:42201794475b6b64c984ca9397314e004430987146b3df195ebf65de5457be4a  help
    0:4daf17b36bc477e468823308900f5811a8f179cd431f82d04fa78c5ef3b565c7  type
    0:37ac4f19adf167945520b05738b16bf698557528478698b413544aa5885aa620  exec
    0:ee9754c7f266f5b3d8ded62240ea7ca11ae351bf8b76544454023c946de93aaf  declare
    0:83522b611e74d2f9f01ff91cdb9d003fb16224af8cbfd70536260b5eadd44045  pwd
    0:3c2038aa2cfc1352cc1dc0b1c25dbbadfbe790156381d582332bb06fdc1b3855  read
    0:cabd5cf0b7443902a342bbee095f4214b59b9a5934e18f1f8bd96dbcd0b1ecaf  hash
    0:9561f15b3e77b91e3a6fe2f089e4399281405580c5f6d4c446a6d4e49d0a6883  command
    0:3486c913fb9c246b4f435e7de33421421a28225005e054545d1a5d1e7e85c386  export
    0:06c96d0c333ba6341efd304978eb02ae8616cc6de536fc7aa4d6002fae6ee6c6  alias
    0:b8b03e28fb6261ef158de3243bbf5c7add77f84ab4d1b45abac6b340b8e3784e  unalias
    0:48e40dd69926fbb1affa8aaa704eb4bdd68699d7a38cf5240c80a0ff2ae847bd  unset
    0:78686b9aac083948a05b02c0d92a8d252e85c0a233acef5b52836b1d1c75b757  enable
    0:9b78676f5e480e7280b28f1904d938d25f105a7f90ac2db6c21e4f66b1815d4f  test
    0:5e665b12a6a214d7b9a62a001fe1f55f71f63836bd62d190bf12cae95fbaecf8  cd
    0:27fa3f9c882c10869702886bdbfc802aeb60ddea5d8b654c5a15a0731c534722  dirs
    0:9834948869cd1c452cae438e7db4b5245e573e6c1d45870cf5c0814536aae75c  echo
    0:5675f8bd7d3b8b4f546a4f8376524418f4f70538a0bb7a154ae64b3adb572293  ulimit
    0:6d9b513360c963b030795f9b6b9e2cb69faa611c35b4ffef48e2b477732bb2e9  shopt
    0:d2f78f87e1816b423e0b6ed1bde6343e977dcb9836a70379801cbab425f80f25  source
    0:74778a5b53aebbed35a39713d4415d7274573e166bd04329cf1da626d912a804  mapfile
    0:efdd305771281495268271d0c3e05ee8296f557a9e5cd4158d313b34f7a882de  tosh
    0:13e9c4da685eac46c17b7e0f46135c5709c263ed7e41ac1f6c4d3f669f271373  builtin
    0:254c8c97678ff5557cf41078f5a80ae1fe7b1311d8620f814ad03a0f8c5ca496  readonly
    0:13e82106c6b8d5e96c7d78a87819e11224e8a385a384c7dec319d7143c397fbb  complete
    0:9a986eca33927a4e6b73ed5aac488a4416e7c6bbcc0eada3acc6892c7a99ea07  compgen
    0:cbb0cae61a26b5ef00d938a27a118cabfb1aeaaa0ebcc38ba47852ada982f6e9  pushd
    0:c9e770807c7ee73d13bbfc46afb32e7d29df882d8af31fa0392299bccb4699b6  popd
    0:377875eac9a5ada1611f285e214e8043150a807bf77ab07cd8f581e89153fa7c  jobs
    0:93b697cb48d9b1ae4d3c9b06dd8bf5e123b457e4d905748fe64c7d05f087362b  basename
    0:7421ecc59c3274d0d1b6c62076612f3985469ad914715d2648776927851a6ce6  ls
    0:ecd0fd0aac9e1ca6accf0184cf21fc22c800fc21fa731f7acff4a6a908ba9fa8  du
    0:624500fefd39c5f90992b96e431df491981ff61e0277501a7d500b03539d1f2a  file
    0:9e120e0a7f0133a8dca4774b9fd2d7a6875bcef78d833ccc2d42154bbaa1fe9b  stat
    0:78ece1c60b26d67bf8e90ef0d6c0c23b222d909397866ea708bea5b226025b22  namei
    0:7fa396e349861e41c908faf4946a1d7fe59b5f5e541c88b404506c66338c71e5  cat
    0:1134fb15d1c6e3d8a46ecfbb70d7ea0f516aa75722295ff3f50a75071beca92e  colrm
    0:c0fe2a1890c9b281912a987de021d62893cb5103956e1a6efe798f894e5ada05  column
    0:044f0af6f6b5615105a251059ccb4700ed1e57266fa9c942c3bcfa1d39ffbf25  cut
    0:b5ff21f516f5fcb39704f32673ef8d336bd59dacaca192f362266adef8754001  expand
    0:b323d6deabf69f67e042561415ee13e9145edd1021b9862639e40e070136eb16  grep
    0:50b0a744c1afbc102ab1dedb1f97c69de67fecc78654be0004837411dbbe027b  head
    0:ddf98499df92aff0ee03f2c83e5798406cd3252f5a5988f37d5cdd7fa743fbd8  look
    0:195cd6c7e8a63f79cb9dd6fa70ebfd027cd61a9d2b911a1d4d73c36f42544ef6  rev
    0:1ea7c9676286b1cad4dd90cb706d425a90e608c05e132a58e149265c9bae514a  tail
    0:0e2beb623c05c72068d2fd0a606a57d3c1dcc4a9984b62ba517607f33e65e9c7  tr
    0:2b6dc8ba19c11b0360cd83964810e40ca2b95d30ee5f7dda0349e768897b5b72  unexpand
    0:45e6e202a7945ccb0ce7903ccd39f385b0335a61ee14a96775c8d009928694b6  paste
    0:60279dbd3b52141607caab4d642cc87dd145247c38bb284c06bd86d3f4b1c7c0  wc
    0:2cbf9fe3d2a44c5db565cd556437b74e12a17d1855f47c55a1be128a774454e5  readlink
    0:cb837dc2ece79ed3c84ae5b4787e6175f4e7a2f614d61fb4a1929fbce8cd19a9  realpath
    0:70c892b4866744435b839981509cc384f27cc6e2014b4487799fcc99a82f2b23  env
    0:dbc61aa2e3bdefebf962432f92125321579f4e014c8077ba3cff26d072298d20  man
    0:7ef2ad683b9f6a1b4a658051583b7ec878861eba4b34bc743e7b51c43712d5f8  whatis
    0:08b9d9a50438a5213144361d9bc5f6c2abc69ad3812091b32b8ea2d2421e9efb  mkfs
    0:39cae04bbc2e2784651b9008735217ba43408eaab404443c64f7175d3a1c83ac  mke2fs
    0:b2525fb399c4f2ab19bf7c21b06e3e7ac6d7a0103272defd18b243b777e59c10  dumpe2fs
    0:c87ff808e3b1693ae614161ad209e298209a512e64fe0058e262f1c1e72035a6  fsck
    0:b90d14226ccf37cb0c37395d14a4664deed5028687c0b2d8037ac02a78755950  mount
    0:8e0f4a277b3b500883bc5c7f16127aa16710e695bb0d7901bb486cf468f3e4ae  umount
    0:ad3622d6c8cc9073280751035fe1694365faeb58fbfb28feb91881a08940de63  losetup
    0:1a43d95f7c8fbce5218aba5cfbf3e32394630761b4e8cc2f083e0fb92aff71c0  udevadm
    0:cc5096e74ebb4116527041bc3f738a218f38012992533fc4aab9b526f26e9fb7  df
    0:c6a38403031efcb00f9a8dea9a2a52cc6eb6c11afce89ff6512c42bcc427c7f5  findmnt
    0:1a78e415030e10a57fbcb5e9e66c70f0ea37690298f9a7c2b1fb124e13ea5190  mountpoint
    0:1f463234db34ef556d08ba3e4ef67f82bc73c53d44b710341f47c1d89c9fbf80  touch
    0:d7f2259f9ca0cd873202eefca7fed2cd484f8dac5990b37109cf1c50fd05a816  cp
    0:f956e6927ebc5f40bbe9a39bd61f64628182c3e4cedb090c88cda8e31684aa31  mv
    0:b0996aec3c78c4d5e3a694fc4b4602fe6532b77a7f06b3baeb14d05ddb07af9f  rm
    0:11de927200c6fd1900420ce388e96ef7d81b0d2ec841933d8053e345f34e7a05  rmdir
    0:8d995561fa3b1c854039d06827782afcc60fc32a34232f9f1ef6598bcd767cd8  mkdir
    0:468accd45455f4b9d53f698d8c1abe37ccd80bd162f4d51091e08312c7ce70f8  ln
    0:476c698daa69233276483baa400e45ffff0b42043144988d8e8f445b8d85a2eb  install
    0:792788efff447ed0b26a7380886565731bcfb175c1098eac18751469a317e19b  groupadd
    0:780e1d64f4a67f5f2c67f259329d12b2f135b75bcf2bd38c7eaed7c12ebdcd7d  groupdel
    0:8f3d533584a4a92ed0eb3f51eb9c4aa23e410f48775a7e8324ec9b5a5e4b9ba3  groupmod
    0:2c507e067c75a189b1c881896b0457b94963370008c3b8c57081bde1658b12bd  useradd
    0:704addd3d0885add3f0a298d1ac3040780d5e675be4bdd7ac07d7ea403129d0e  userdel
    0:c8b03aa425a945d287b5b88cf716398c0592515d101651890362b1536cd6440d  usermod
    0:8075827cec4a65e35ea0d3d6da63ef7a352525f6f8a589f3ec4fcc5816312b3d  chfn
    0:3c51fcfb88b81c6056e848f70618d925c4932f5152e0285b0153cbfb06fc045c  newgrp
    0:ea81d5b86740de8635ae655eaa10ed7830016e92f61966f73535ae3c09b874e5  lslogins
    0:cdd41af6db946f3b154c38d6e2ea836921358558a639ac937593a75dc03aaf04  finger
    0:9597f2ec0d6cafe6fe811dbcf726f6697c0f0b2f280c1d4601dced2c1aff7645  who
    0:d66499f8dadd2ec8b247faae4a6013a678ceb6696fcee262c60cdb9408d65bd3  last
    0:3fddb76bfe233eb9261fea645fd52b5396a073dd5442164c53049d1b698cf112  fuser
    0:be5eb647df487ecec0d81de9519a1a2cb412d78dabcb326661fad0854c9fc6a9  utmpdump
    0:ff28ef2d96bdfde76cd0d74c0027e76d5cf82451c41e46b15752e704ca77968d  ps
    0:6156ada0a454c4ceb50abfe5b50069f32c2ff84c78bfa7f5431170a6bd8b9c7b  whoami
    0:d2df406ee201ef4151e5e82eff431604c6cbc7720c474b0c0c5d344c63975b49  id
    0:8c289959a22c30ac9a59e9b47d6247c252a61ee61dec4dc5d5e272256e770412  hostname
    0:a338efd6d952681fdde2ed88fd7538a3ed8ebf5fd781505e1643d9fc20e30aff  tfs
    0:1628393926c6d69dafddc18de7a2c515dc688ff5eed1a619c8d9691e874dddd5  tmpfs
    0:c42aca873a1d91f526581d5b02ca9734cd43b11f944b2f98852f4a810a7b9bac  set
    0:351845521191d11cbc60ea2b87cdd960e47f7ec3d0b9cdb4195878dedc12659d  shift
    0:7cfadce36d1dfe9d83bcd8747bc5b24e75ea6cd35370018364d953fbe483313e  history
    0:8536e17484e81cea8507d2bf6bde1723f267c71575edd1832583eda9dcd162e0  getopts
    0:d4ed44aa95b443d88f47d617ac367b4fb041ba05710a842bce565fd9185de6ce  printenv
    0:08df9194ed8d538c29f0bd7ef47d4e05547c7bba3a4fddf958100ffa8f3a5698  eilish
    0:6e6ff4d496420d83ee78ab8c73738eff21f5691f3edb0a4dbd1dcf6a8d6e4635  dirname
    0:b8c4b082b8d96afe44c59127233c4dfa6a6b2d27879d8fe0a929d25b0660f98f  getent
