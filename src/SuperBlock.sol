pragma ton-solidity >= 0.48.0;

import "Base.sol";
import "ISync.sol";
import "SyncFS.sol";
import "IBlockDevice.sol";
import "INode.sol";

contract SuperBlock is Base, SyncFS {

    uint16 constant DEF_TEXT_BLOCK_SIZE = 1024;
    uint16 constant DEF_BIN_BLOCK_SIZE = 4096;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 128;
    uint16 constant MAX_BLOCKS = 10000;
    uint16 constant MAX_INODES = 10000;

    bool _file_system_state = true; // clean
    bool _errors_behavior = true; // Continue
    string _file_system_OS_type = "Tonix";
    uint16 _inode_count;
    uint16 _block_count;
    uint16 _reserved_block_count;
    uint16 _free_inodes;
    uint16 _free_blocks;
    uint16 _block_size;
    uint32 _created_at;
    uint32 _last_mount_time;
    uint32 _last_write_time;
    uint16 _mount_count;
    uint16 _max_mount_count;
    uint32 _last_checked;
    uint32 _lifetime_writes;
    uint16 _first_inode;
    uint16 _inode_size;

    address _cmd_proc;
    address _fstat;

    struct BlockS {
        bytes data;
    }
    mapping (uint16 => BlockS) public _blocks;

    struct DeviceInfo {
        uint8 device_type;
        uint16 id;
        string name;
        uint16 blk_size;
        uint16 n_blocks;
    }
    mapping (uint16 => DeviceInfo) public _dev;
    mapping (uint16 => string[]) public _cdata;

    struct Device {
        uint16 next_free;
        uint16 next_len;
        uint16 total_free;
    }
    mapping (uint16 => Device) public _dev_stat;
    Device[] public _char_dev;

    function _write_text(uint16 id, string text) private returns (uint16[] blocks) {
        DeviceInfo dev = _dev[id];
        Device cdev = _char_dev[id];
        uint16 blk_size = dev.blk_size;
        uint32 len = uint32(text.byteLength());
        uint16 n_blocks = uint16(len / blk_size);
        uint16 start = cdev.next_free;
        for (uint16 i = 0; i < n_blocks; i++)
            _cdata[id].push(text.substr(i * blk_size, blk_size));
        _cdata[id].push(text.substr(n_blocks * blk_size, len - n_blocks * blk_size));
        cdev.next_free += n_blocks + 1;
        cdev.total_free -= n_blocks + 1;
        cdev.next_len -= n_blocks + 1;
        _char_dev[id] = cdev;
        for (uint16 i = start; i < start + n_blocks + 1; i++)
            blocks.push(i);
    }

    function _setup_users() private {
        _ugroups[ROOT_USER_GROUP] = UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, "root");
        _ugroups[REG_USER_GROUP] = UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, "boris");
        _ugroups[GUEST_USER_GROUP] = UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, "guest");
    }
    function _mkdir(uint16 owner, uint16 gid, uint16 pino, string file_name, string full_path) private returns (uint16 ino) {
        ino = ++_ino_counter;
        _inodes[ino] = INodeS(DEF_DIR_MODE, owner, gid, 1024, 2, file_name, full_path);
        _the_time_is_now(ino);
        _inodes[pino].n_links++;
    }

    function _init_etc2(uint16 pino, INodeS[] inodes) private view {
        /*for (INode inode: inodes) {
            pino = e.iid;
            inodes.push(INode(d ? DEF_DIR_MODE : DEF_FILE_MODE, uid, gid, uint32(e.text.byteLength()), d ? 2 : 1, e.path, e.text));
        }*/
        SyncFS(_bdev).import_text_inodes{value: 1 ton}(pino, inodes);
    }

    function _make_fs() private {
        uint16 ino = ++_ino_counter;
        uint16 root_dir = ino;
        _inodes[ino] = INodeS(DEF_DIR_MODE, SUPER_USER, ROOT_USER_GROUP, 1024, 1, "", "");
        _the_time_is_now(ino);

        _users[SUPER_USER] = User(ROOT_USER_GROUP, "root", root_dir);
        INodeS[] sys = _sub("", ["bin", "dev", "etc", "home", "mnt", "opt", "root", "usr", "var"]);

        uint16 counter = _ino_counter + 1;
        uint16 home_dir = counter;
//        uint16 etc_dir = counter + 1;
//        uint16 usr_dir = counter + 2;

        (DeviceInfo dev_info0, Device dev0) = _add_device(1, 1, "Dev0", 256, 400);
        _dev[0] = dev_info0;
        _char_dev.push(dev0);

        for (uint16 i = 0; i < uint16(sys.length); i++)
            _expand_inode_dir(root_dir, counter + i, sys[i]);

        INodeS[] home = _sub("/home", ["boris", "guest"]);
        for (uint16 i = 0; i < uint16(home.length); i++)
            _expand_inode_dir(home_dir, counter + 3 + i, home[i]);

        _users[REG_USER] = User(REG_USER_GROUP, "boris", home_dir);
    }

    function init3() external accept view {
        INodeS[] etc_files = _files(["exports", "fstab", "group", "hostname", "hosts", "magic", "motd", "passwd", "shadow"],
        ["/etc\n", "rootfs\t/\text4\t\t0\t1\n", "root\t0\nboris\t1000\n", format("{}\n", address(this)), "0:2f6e387ac062b790697109194e98617e7237c5edb436e09e6339089de80c7234\tCommandProcessor\n0:d6b7400b6aa477d01be6e4cd9ef0f86bc438f2cdb8446539096f65b9bda0364c\tStat\n0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume\n0:68c00d417291837826ed9e7aa451d40629dde6d7cf8bcc4fec63cc0978d08205\tSuperBlock\n0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice\n0:ae0333bad53398ec089f0505b8b99fcdc12b25a96d8aa475eda0d8988640ff6f\tInputParser\n0:6e14e41808289276817c94383b5943c25fc3c813e281dca00af152ebd94fdf61\tOptions\n",
        "11\n", "Welcome to Tonix.\nType \"help\" to get a list of commands.\n\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.\nSome options for certain commands work as well.\nFeel free to navigate a pre-made file system using intuitive commands.\nPath resolution does not work yet, one step at a time please.\nYour feedback is highly appreciated!\nHave fun :)\n",
        "root\t0\t0\troot\t/root\nboris\t1000\t1000\t/home/boris", ""]);
        _init_etc2(13, etc_files);
    }
    function _add_device(uint8 device_type, uint16 id, string name, uint16 blk_size, uint16 n_blocks) private pure returns (DeviceInfo dev_info, Device dev) {
        dev_info = DeviceInfo(device_type, id, name, blk_size, n_blocks);
        dev = Device(0, n_blocks, n_blocks);
    }

    function _init_sb() private {
        _file_system_state = true; // clean
        _errors_behavior = true; // Continue
        _file_system_OS_type = "Tonix";
        _inode_count = 0;
        _block_count = 0;
        _reserved_block_count = 0;
        _free_inodes = MAX_INODES;
        _free_blocks = MAX_BLOCKS;
        _block_size = DEF_TEXT_BLOCK_SIZE;
        _created_at = now;
        _last_mount_time = now;
        _last_write_time = now;
        _mount_count = 0;
        _max_mount_count = 0;
        _last_checked = now;
        _lifetime_writes = 0;
        _first_inode = 0;
        _inode_size = DEF_INODE_SIZE;

        _cmd_proc = address.makeAddrStd(0, 0x2f6e387ac062b790697109194e98617e7237c5edb436e09e6339089de80c7234);
        _fstat = address.makeAddrStd(0, 0xd6b7400b6aa477d01be6e4cd9ef0f86bc438f2cdb8446539096f65b9bda0364c);
        _bdev = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
    }

    function init2() external accept {
        _setup_users();
        _make_fs();
        this.init3();
    }
    function init() external override accept {
        _init_sb();
        this.init2();
//        _init_etc();
//        _init_commands();
//        _init_command_info();
//        _init_command_options();
    }

}
