pragma ton-solidity >= 0.48.0;

import "IBlockDevice.sol";
import "IData.sol";
import "FSCache.sol";
import "IMount.sol";
import "ExportFS.sol";
import "Map.sol";
import "INode.sol";

contract BlockDevice is FSCache, IBlockDevice, IMount, Map {

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
    Device[] public _char_dev;
    ISync[4] _readers;

    function mount_dir(uint16 pino, INodeS[] inodes) external override accept {
        _add_reg_files(pino, inodes);
    }

    function _add_device(uint8 device_type, uint16 id, string name, uint16 blk_size, uint16 n_blocks) private pure returns (DeviceInfo dev_info, Device dev) {
        dev_info = DeviceInfo(device_type, id, name, blk_size, n_blocks);
        dev = Device(0, n_blocks, n_blocks);
    }

    function _write_text(uint16 id, string text) internal returns (uint16[] blocks) {
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

    function _make_fs() private returns (uint16 etc_dir, uint16 man_dir, uint16 help_dir, uint16 options_dir) {
        INodeTimeS nts = _the_time_is_now();

        (DeviceInfo dev_info0, Device dev0) = _add_device(1, 1, "Dev0", 1024, 100);
        (DeviceInfo dev_info1, Device dev1) = _add_device(1, 2, "Dev1", 127, 1000);
        (DeviceInfo dev_info2, Device dev2) = _add_device(1, 3, "Dev2", 4096, 50);
        _dev[0] = dev_info0;
        _dev[1] = dev_info1;
        _dev[2] = dev_info2;
        _char_dev.push(dev0);
        _char_dev.push(dev1);
        _char_dev.push(dev2);

        (_inodes[ROOT_DIR], ) = _get_dir_node(ROOT_DIR, ROOT_DIR, SUPER_USER, SUPER_USER_GROUP, "");
        _ino_counter = ROOT_DIR + 1;
        uint16 counter = _ino_counter;

        _ugroups[SUPER_USER_GROUP] = UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, "root");
        _ugroups[REG_USER_GROUP] = UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, "boris");
        _ugroups[GUEST_USER_GROUP] = UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, "guest");
        _users[SUPER_USER] = User(SUPER_USER_GROUP, "root", ROOT_DIR);
        _users[REG_USER_GROUP] = User(REG_USER_GROUP, "boris", counter + 7);
        _users[GUEST_USER_GROUP] = User(GUEST_USER_GROUP, "guest", counter + 8);

        _create_subdirs(ROOT_DIR, ["etc", "home", "usr"]);
        _create_subdirs(counter + 2, ["share"]);
        _create_subdirs(counter + 3, ["help", "man", "options"]);
        _create_subdirs(counter + 1, ["boris", "guest"]);

        etc_dir = counter;
        help_dir = counter + 4;
        man_dir = counter + 5;
        options_dir = counter + 6;

        for (uint16 i = ROOT_DIR; i < _ino_counter; i++)
            _ino_ts[i] = nts;
    }

    function _create_subdirs(uint16 pino, string[] files) private {
        uint16 len = uint16(files.length);
        uint16 counter = _ino_counter;
        INodeS dir = _inodes[pino];
        string text = dir.text_data;
        string dirent;
        for (uint16 i = 0; i < len; i++) {
            (_inodes[counter + i], dirent) = _get_dir_node(counter + i, pino, SUPER_USER, SUPER_USER_GROUP, files[i]);
            text.append(dirent);
        }
        dir.text_data = text;
        dir.file_size = uint32(text.byteLength());
        dir.n_links += len;
        _inodes[pino] = dir;
        _ino_counter += len;
    }

    function init() external override accept {
        (uint16 etc_dir, uint16 man_dir, uint16 help_dir, uint16 options_dir) = _make_fs();
        _init_commands();
        this.init1{value: 0.1 ton}(etc_dir);
        this.init2{value: 0.1 ton}(man_dir, help_dir, options_dir);
    }

    function init1(uint16 etc_dir) external accept {
        INodeS[] etc_files = _files(
            ["exports", "fstab", "group", "hostname", "hosts", "magic", "motd", "passwd", "shadow"], [
            "/etc\n",
            "rootfs\t/\text4\t\t0\t1\n",
            "root\t0\nboris\t1000\nguest\t10000\n",
            format("{}\n", address(this)),
            "0:47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40\tCommandProcessor\n0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9\tStat\n0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume\n0:68c00d417291837826ed9e7aa451d40629dde6d7cf8bcc4fec63cc0978d08205\tSuperBlock\n0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice\n0:4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d\tInputParser\n0:46b494f9e5c5ecfd9a48ddffbe6a85af564445ab58ed1241fd0fb6a666ec369e\tOptions\n",
            "11\n",
            "Welcome to Tonix.\nType \"help\" to get a list of commands.\n\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.\nSome options for certain commands work as well.\nFeel free to navigate a pre-made file system using intuitive commands.\nPath resolution does not work yet, one step at a time please.\nYour feedback is highly appreciated!\nHave fun :)\n",
            "root\t0\t0\troot\t/root\nboris\t1000\t1000\t/home/boris",
            ""]);
        _add_reg_files(etc_dir, etc_files);
    }

    function init2(uint16 man_dir, uint16 help_dir, uint16 options_dir) external pure accept {
        address data_volume = address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb);
        ExportFS(data_volume).export_all{value: 0.9 ton}("/usr/share/man", man_dir);
        ExportFS(data_volume).export_all{value: 0.9 ton}("/usr/share/help", help_dir);
        address command_options_source = address.makeAddrStd(0, 0x46b494f9e5c5ecfd9a48ddffbe6a85af564445ab58ed1241fd0fb6a666ec369e);
        ExportFS(command_options_source).export_all{value: 0.95 ton}("/usr/share/options", options_dir);
        this.init3{value: 0.1 ton}();
    }

    /*function _lookup_address(string name) internal view returns (address) {
        uint16 ihosts = _lookup_inode_in_dir("hosts", _get_etc_dir());
        string s_addr = _lookup_value(name, _inodes[ihosts].text_data);
        string s_hex = "0x" + s_addr.substr(2, s_addr.byteLength() - 2);
        (uint u_addr, ) = stoi(s_hex);
        return address.makeAddrStd(0, u_addr);
    }*/

    function init3() external accept {
        address command_processor = address.makeAddrStd(0, 0x47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40);
        address file_status_reader = address.makeAddrStd(0, 0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9);
        address input_parser = address.makeAddrStd(0, 0x4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d);
        _readers = [ISync(address(this)), ISync(command_processor), ISync(file_status_reader), ISync(input_parser)/*, ISync(_file_reader)*/];
        Base(command_processor).init{value: 0.2 ton}();
        Base(file_status_reader).init{value: 0.2 ton}();
        Base(input_parser).init{value: 0.2 ton}();
    }


    function iread(uint16 id) external view returns (string out) {
        out = _inodes[id].text_data;
    }

    function read(ReadEventS[] re) external view returns (string[] outs) {
        for (ReadEventS e: re) {
            if (e.read_type == READ_ANY) {
                INodeS inode = _inodes[e.iid];
                if (!inode.text_data.empty())
                    outs.push(inode.text_data);
                else {
                    uint16[] blocks = _dc[e.iid];
                    string out;
                    for (uint16 b: blocks)
                        out.append(_cdata[1][b]);
                    outs.push(out);
                }
            }
            if (e.read_type == READ_INODE)
                outs.push(_inodes[e.iid].text_data);
            if (e.read_type == READ_TEXT) {
                uint16[] blocks = _dc[e.iid];
                for (uint16 b: blocks)
                    outs.push(_cdata[1][b]);
            }
            if (e.read_type == READ_MERGE) {
                uint16[] blocks = _dc[e.iid];
                string out;
                for (uint16 b: blocks)
                    out.append(_cdata[1][b]);
                outs.push(out);
            }
        }
    }

    function nread(uint16[] ids) external view returns (INodeS[] inodes) {
        for (uint16 id: ids)
            inodes.push(_inodes[id]);
    }

    function write_to_file(SessionS ses, string path, string text) external accept {
        (uint16 uid, uint16 gid, uint16 wd) = (ses.uid, ses.gid, ses.wd);
        INodeS[] inodes;
        uint16 pino_add;
        pino_add = wd;
        inodes.push(_get_file_node(uid, gid, path, text));
        _write_text(0, text);
        for (address addr: _readers)
            ISync(addr).add{value: 0.1 ton}(pino_add, inodes);
    }

    function put(SessionS ses, INodeEventS[] ines, IOEventS[] ios) external accept {
        (uint16 uid, uint16 gid) = (ses.uid, ses.gid);
        uint16 pino_add;
        uint16 pino_update;
        uint16 pino_rem;
        uint16[] ino_chattr;

        INodeS[] inodes;
        uint16[] dirents_rem;
        INodeTimeS[] ino_ts;

        for (IOEventS e: ios) {
            if (e.iotype == IO_WR_APPEND) {
                _append_text_to_file(uid, e.iid, e.text);
                pino_add = e.iid;
                inodes.push(_inodes[e.iid]);
            }
            if (e.iotype == IO_WR_OVERWRITE) {
                _clear_text_file_contents(uid, e.iid);
                _append_text_to_file(uid, e.iid, e.text);
                pino_add = e.iid;
                inodes.push(_inodes[e.iid]);
            }
            if (e.iotype == IO_MKFILE) {
                pino_add = e.iid;
                inodes.push(_get_file_node(uid, gid, e.path, e.text));
                _write_text(0, e.text);
            }
            if (e.iotype == IO_MKDIR) {
                pino_add = e.iid;
                inodes.push(_get_dir_node_bare(uid, gid, e.path));
            }
            if (e.iotype == IO_HARDLINK) {
                pino_update = e.iid;
                inodes.push(_add_dir_entry(_inodes[e.iid], e.iid, e.path, FT_REG_FILE));
            }
            if (e.iotype == IO_SYMLINK) {
                pino_add = e.iid;
                inodes.push(_get_symlink_node(uid, gid, e.path, e.text));
            }
            if (e.iotype == IO_UNLINK) {
                pino_rem = e.iid;
                uint16 dei = e.val;
                uint16[] chi = _dc[pino_rem];
                for (uint i = 0; i < chi.length; i++) {
                    if (chi[i] == dei) {
                        dirents_rem.push(dei);
                        break;
                    }
                }
            }

        }
        for (INodeEventS e: ines) {
            if (e.intype == INO_CHATTR) {
                if (e.val > 0)
                    _inodes[e.iid].owner_id = e.val;
                if (e.val2 > 0)
                    _inodes[e.iid].group_id = e.val2;
                ino_chattr.push(e.iid);
                inodes.push(_inodes[e.iid]);
                ino_ts.push(_the_time_is_now());
            }
            if (e.intype == INO_ACCESS) {
                _ino_ts[e.iid].accessed_at = e.attr;
                ino_chattr.push(e.iid);
                inodes.push(_inodes[e.iid]);
                ino_ts.push(_ino_ts[e.iid]);
            }
            if (e.intype == INO_PERMISSION) {
                _inodes[e.iid].mode = e.val;
                ino_chattr.push(e.iid);
                inodes.push(_inodes[e.iid]);
                ino_ts.push(_ino_ts[e.iid]);
            }
            if (e.intype == INO_UPDATE_TIME) {
                ino_chattr.push(e.iid);
                ino_ts.push(INodeTimeS(e.attr, e.attr, e.attr));
            }
        }

        if (pino_add > 0)
            for (address addr: _readers)
                ISync(addr).add{value: 0.1 ton}(pino_add, inodes);
        if (pino_update > 0)
            for (address addr: _readers)
                ISync(addr).update{value: 0.1 ton}(pino_update, inodes);
        if (pino_rem > 0)
            for (address addr: _readers)
                ISync(addr).rem_dirents{value: 0.1 ton}(pino_rem, dirents_rem);
        if (ino_chattr.length > 0)
            for (address addr: _readers)
                ISync(addr).change_attrs{value: 0.1 ton}(ino_chattr, inodes);
        if (ino_ts.length > 0)
            for (address addr: _readers)
                ISync(addr).update_time{value: 0.1 ton}(ino_chattr, ino_ts);
    }

    function write_text_file(uint16 id, uint8 mode, string text) external override accept {
        if (mode == IO_WR_OVERWRITE)
            _inodes[id].text_data = text;
        if (mode == IO_WR_APPEND)
            _inodes[id].text_data.append(text);
        _ino_ts[id] = _the_time_is_now();
    }

    function _generic_version_file(uint8 command) private view returns (string) {
        return _command_names[command];
    }

    function _clear_text_file_contents(uint16 uid, uint16 tf) private {
        if (uid == _inodes[tf].owner_id) {
            _inodes[tf].text_data = "";
            _inodes[tf].file_size = 0;
            _ino_ts[tf] = _the_time_is_now();
        }
    }

    function _append_text_to_file(uint16 uid, uint16 tf, string text) private {
        if (uid >= 0) {
            _inodes[tf].text_data += text;
            _inodes[tf].file_size += uint32(text.byteLength());
            _ino_ts[tf] = _the_time_is_now();
        }
    }

    function query_fs_cache() external override accept {
        ISync(msg.sender).update_users{value: 0.1 ton}(_ugroups, _users, _ino_counter);

        uint16 chunk_size = 70;
        uint16 chunks = _ino_counter / chunk_size;
        for (uint16 i = 0; i < chunks; i++)
            this.update_inodes_chunk{value: 0.1 ton}(msg.sender, i * chunk_size, chunk_size);
        this.update_inodes_chunk{value: 0.1 ton}(msg.sender, chunks * chunk_size, _ino_counter - chunks * chunk_size);
    }

    function update_inodes_chunk(address addr, uint16 start, uint16 count) external view accept {
        mapping (uint16 => INodeS) inn;
        mapping (uint16 => INodeTimeS) inn_t;

        for (uint16 i = start; i < start + count; i++) {
            if (_inodes.exists(i)) {
                inn[i] = _inodes[i];
                inn_t[i] = _ino_ts[i];
            }
        }
        ISync(addr).update_inodes{value: 1 ton}(inn, inn_t);
    }

    function call_update_children(address addr) external view accept {
        ISync(addr).update_children{value: 0.2 ton}(_dc);
    }
}
