pragma ton-solidity >= 0.48.0;

import "IBlockDevice.sol";
import "IData.sol";
import "SyncFS.sol";
import "IMount.sol";
import "ExportFS.sol";

contract BlockDevice is SyncFS, IBlockDevice, IMount {

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

    function mount_dir(uint16 pino, INodeS[] inodes) external override accept {
        this.add_inodes{value: 1 ton}(pino, inodes);
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
    function _make_fs() private {
        _user_counter = USERS;
        _ino_counter = INODES;
        _de_counter = DIRENTS;
        _init_ids.push(SUPER_USER); // 0

        (uint16 root_dir, uint16 root_dir_de) = _mkroot();
        _users[SUPER_USER] = User(ROOT_USER_GROUP, "root", root_dir);
        UserGroup[] groups = _make_groups(["root", "boris", "guest"]);
        INodeS[] sys = _sub("", ["home", "etc", "usr"]);
        INodeS[] usr = _sub("/usr", ["share"]);
        INodeS[] usr_share = _sub("/usr/share", ["man", "help", "version", "options"]);
        (DeviceInfo dev_info0, Device dev0) = _add_device(1, 1, "Dev0", 1024, 100);
        (DeviceInfo dev_info1, Device dev1) = _add_device(1, 2, "Dev1", 127, 1000);
        (DeviceInfo dev_info2, Device dev2) = _add_device(1, 3, "Dev2", 4096, 50);
        _dev[0] = dev_info0;
        _dev[1] = dev_info1;
        _dev[2] = dev_info2;
        _char_dev.push(dev0);
        _char_dev.push(dev1);
        _char_dev.push(dev2);
        _ugroups[ROOT_USER_GROUP] = groups[0];
        _ugroups[REG_USER_GROUP] = groups[1];
        _ugroups[GUEST_USER_GROUP] = groups[2];

        _init_ids.push(root_dir_de);    // 1
        _init_ids.push(root_dir);   // 2
        uint16 counter = _ino_counter + 1;
        uint16 home_dir = counter;
        uint16 etc_dir = counter + 1;
        uint16 usr_dir = counter + 2;
        uint16 usr_share_dir = counter + 3;
        uint16 man_dir = counter + 4;
        uint16 help_dir = counter + 5;
        uint16 version_dir = counter + 6;
        uint16 options_dir = counter + 7;

        _init_ids.push(home_dir);  // 3 home
        for (uint16 i = 0; i < uint16(sys.length); i++)
            _expand_inode_dir(root_dir, counter + i, sys[i]);
        _expand_inode_dir(usr_dir, usr_share_dir, usr[0]);
        for (uint16 i = 0; i < uint16(usr_share.length); i++)
            _expand_inode_dir(usr_share_dir, usr_share_dir + i + 1, usr_share[i]);

        _init_ids.push(etc_dir);  // 4
        _init_ids.push(usr_dir);    // 5
        _init_ids.push(usr_share_dir);  // 6
        _init_ids.push(man_dir);  // 7
        _init_ids.push(help_dir); // 8
        _init_ids.push(version_dir);  //9
        _init_ids.push(options_dir);  //10

        _ino_counter = options_dir;
        (uint16 active_user_id, uint16 active_user_dir, uint16 active_user_de) = _create_user(REG_USER_GROUP, "boris", "/home/boris");
        (uint16 guest_user_id, , ) = _create_user(GUEST_USER_GROUP, "guest", "/home/guest");

        _init_ids.push(active_user_id);  // 11
        _init_ids.push(guest_user_id); // 12
        _init_ids.push(active_user_dir);  // 13
        _init_ids.push(active_user_de);  // 14*/
    }

/*    function init_etc() external accept view {
        INodeS[] etc_files = _files(["exports", "fstab", "group", "hostname", "hosts", "magic", "motd", "passwd", "shadow"],
        ["/etc\n", "rootfs\t/\text4\t\t0\t1\n", "root\t0\nboris\t1000\n", format("{}\n", address(this)), "0:72c71b29995fb176b187bf9c57d2750bd7b3a2ab04b355e6b46a3eb59c75cb6a\tCommandProcessor\n0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9\tStat\n0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume\n0:68c00d417291837826ed9e7aa451d40629dde6d7cf8bcc4fec63cc0978d08205\tSuperBlock\n0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice\n0:78a427fb136f940f38df2505d67632120aade8f1af9e3eb68d8d5aceda751823\tInputParser\n0:6e14e41808289276817c94383b5943c25fc3c813e281dca00af152ebd94fdf61\tOptions\n",
//        "11\n", "Welcome to Tonix.\nType \"help\" to get a list of commands.\n\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.\nSome options for certain commands work as well.\nFeel free to navigate a pre-made file system using intuitive commands.\nPath resolution does not work yet, one step at a time please.\nYour feedback is highly appreciated!\nHave fun :)\n",
        "11\n", "Welcome to Tonix.\nType \"help\" for a list of commands.\nHave fun :)\n",
        "root\t0\t0\troot\t/root\nboris\t1000\t1000\t/home/boris", ""]);
        this.import_text_inodes{value: 0.9 ton}(_init_ids[4], etc_files);
    }*/

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

     function put(SessionS o_ses, INodeEventS[] ines, IOEventS[] ios) external accept {
        (uint16 uid, uint16 gid) = (o_ses.uid, o_ses.gid);
        uint16 pino;
        uint16 pino_add;
        uint16 pino_rem;
        uint16[] ino_chattr;

        INodeS[] inodes;
        DirEntry[] dirents_add;
        uint16[] dirents_rem;
        INodeTimeS[] ino_ts;

        for (IOEventS e: ios) {
            if (e.iotype == IO_WR_APPEND) {
                _append_text_to_file(uid, e.iid, e.text);
                pino = e.iid;
                inodes.push(_inodes[e.iid]);
            }
            if (e.iotype == IO_WR_OVERWRITE) {
                _clear_text_file_contents(uid, e.iid);
                _append_text_to_file(uid, e.iid, e.text);
                pino = e.iid;
                inodes.push(_inodes[e.iid]);
            }
            if (e.iotype == IO_MKFILE || e.iotype == IO_MKDIR) {
                bool d = e.iotype == IO_MKDIR;
                pino = e.iid;
                inodes.push(INodeS(d ? DEF_DIR_MODE : DEF_FILE_MODE, uid, gid, uint32(e.text.byteLength()), d ? 2 : 1, e.path, e.text));
                if (!d) {
                    _write_text(0, e.text);
//                    _write_text(1, e.text);
//                    _write_text(2, e.text);
                }
            }
            if (e.iotype == IO_HARDLINK) {
                pino_add = e.iid;
                dirents_add.push(DirEntry(e.val, pino_add, e.path, FT_REG_FILE));
            }
            if (e.iotype == IO_SYMLINK) {
                pino = e.iid;
                INodeS i = INodeS(DEF_SYMLINK_MODE, uid, gid, uint32(e.text.byteLength()), 1, e.path, e.text);
                inodes.push(i);
                pino_add = e.val;
                dirents_add.push(DirEntry(e.val, e.val, e.path, _is_reg(e.val) ? FT_REG_FILE : FT_DIR));
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
                _the_time_is_now(e.iid);
                ino_chattr.push(e.iid);
                inodes.push(_inodes[e.iid]);
                ino_ts.push(_ino_ts[e.iid]);
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
                _ino_ts[e.iid] = INodeTimeS(e.attr, e.attr, e.attr);
                ino_chattr.push(e.iid);
                ino_ts.push(_ino_ts[e.iid]);
            }
        }

//        if (pino > 0 && inodes.length > 0) {
        if (pino > 0) {
            ISync(this).add_inodes{value: 0.1 ton}(pino, inodes);
            ISync(_cmd_proc).add_inodes{value: 0.1 ton}(pino, inodes);
            ISync(_fstat).add_inodes{value: 0.1 ton}(pino, inodes);
        }
//        if (pino_add > 0 && dirents_add.length > 0) {
        if (pino_add > 0) {
            ISync(this).add_dirents{value: 0.1 ton}(pino_add, dirents_add);
            ISync(_cmd_proc).add_dirents{value: 0.1 ton}(pino_add, dirents_add);
            ISync(_fstat).add_dirents{value: 0.1 ton}(pino_add, dirents_add);
        }
//        if (pino_rem > 0 && dirents_rem.length > 0) {
        if (pino_rem > 0) {
            ISync(this).rem_dirents{value: 0.1 ton}(pino_rem, dirents_rem);
            ISync(_cmd_proc).rem_dirents{value: 0.1 ton}(pino_rem, dirents_rem);
            ISync(_fstat).rem_dirents{value: 0.1 ton}(pino_rem, dirents_rem);
        }
        if (ino_chattr.length > 0) {
            ISync(this).change_attrs{value: 0.1 ton}(ino_chattr, inodes);
            ISync(_cmd_proc).change_attrs{value: 0.1 ton}(ino_chattr, inodes);
            ISync(_fstat).change_attrs{value: 0.1 ton}(ino_chattr, inodes);
        }
        if (ino_ts.length > 0) {
            ISync(this).update_time{value: 0.1 ton}(ino_chattr, ino_ts);
            ISync(_cmd_proc).update_time{value: 0.1 ton}(ino_chattr, ino_ts);
            ISync(_fstat).update_time{value: 0.1 ton}(ino_chattr, ino_ts);
        }
    }

    function write_text_file(uint16 id, uint8 mode, string text) external override accept {
        if (mode == IO_WR_OVERWRITE)
            _inodes[id].text_data = text;
        if (mode == IO_WR_APPEND)
            _inodes[id].text_data.append(text);
        _the_time_is_now(id);
    }

    function _create_user(uint16 group_id, string name, string home_dir) private returns (uint16 uid, uint16 home_dir_id, uint16 home_de) {
        uid = group_id + _user_counter++;
        (home_dir_id, home_de) = _mkdir(uid, group_id, _init_ids[3], name, home_dir);
        _users[uid] = User(group_id, name, home_dir_id);
    }

    function _make_groups(string[] groups) private pure returns (UserGroup[] ug) {
        for (string s: groups)
            ug.push(UserGroup(DEF_FILE_MODE, DEF_DIR_MODE, s));
    }

    function _get_dir(uint16 pino, INodeS i) private returns (uint16 ino, uint16 dei) {
        ino = ++_ino_counter;
        _inodes[ino] = i;
        _the_time_is_now(ino);
        dei = _de_counter;
        _de[dei] = DirEntry(ino, pino, i.file_name, FT_DIR);
        _de[dei + 1] = DirEntry(ino, ino, ".", FT_DIR);
        _de[dei + 2] = DirEntry(pino, ino, "..", FT_DIR);

        _dc[pino].push(dei);
        _dc[ino].push(dei + 1);
        _dc[ino].push(dei + 2);
        _de_counter += 3;

        _inodes[pino].n_links++;
    }
    function _mkroot() private returns (uint16 ino, uint16 dei) {
        ino = ++_ino_counter;
        _inodes[ino] = INodeS(DEF_DIR_MODE, SUPER_USER, ROOT_USER_GROUP, 1024, 1, "", "");
        _the_time_is_now(ino);
        dei = _de_counter;
        _de[dei] = DirEntry(ino, ino, ".", FT_DIR);
        _de[dei + 1] = DirEntry(ino, ino, "..", FT_DIR);
        _dc[ino].push(dei);
        _dc[ino].push(dei + 1);
        _de_counter += 2;
    }

    function _mkdir(uint16 owner, uint16 gid, uint16 pino, string filename, string fullpath) private returns (uint16 ino, uint16 dei) {
        ino = ++_ino_counter;
        _inodes[ino] = INodeS(DEF_DIR_MODE, owner, gid, 1024, 2, filename, fullpath);
        _the_time_is_now(ino);
        dei = _de_counter;
        _de[dei] = DirEntry(ino, pino, filename, FT_DIR);
        _de[dei + 1] = DirEntry(ino, ino, ".", FT_DIR);
        _de[dei + 2] = DirEntry(pino, ino, "..", FT_DIR);

        _dc[pino].push(dei);
        _dc[ino].push(dei + 1);
        _dc[ino].push(dei + 2);
        _de_counter += 3;

        _inodes[pino].n_links++;
    }

    function _mknode(uint16 owner, uint16 gid, uint16 pino, string filename, string text_data) private returns (uint16 ino, uint16 dei) {
        ino = ++_ino_counter;
        _inodes[ino] = INodeS(DEF_FILE_MODE, owner, gid, uint32(text_data.byteLength()), 1, filename, text_data);
        _the_time_is_now(ino);
        dei = ++_de_counter;
        _de[dei] = DirEntry(ino, pino, filename, FT_REG_FILE);
        _dc[pino].push(dei);
        _inodes[pino].n_links++;
    }

    function _generic_version_file(uint8 command) private view returns (string) {
        return _command_names[command];
    }

    function _clear_text_file_contents(uint16 uid, uint16 tf) private {
        if (uid == _inodes[tf].owner_id) {
            _inodes[tf].text_data = "";
            _inodes[tf].file_size = 0;
            _the_time_is_now(tf);
        }
    }

    function _append_text_to_file(uint16 uid, uint16 tf, string text) private {
        if (uid >= 0) {
            _inodes[tf].text_data += text;
            _inodes[tf].file_size += uint32(text.byteLength());
            _the_time_is_now(tf);
        }
    }

    address _cmd_proc;
    address _fstat;
    address _command_options_source;
    address _data_volume;

    function init() external override accept {
        _make_fs();
        _init_commands();
        this.init1{value: 1 ton}();
    }

    function init1() external accept {
        INodeS[] etc_files = _files(["exports", "fstab", "group", "hostname", "hosts", "magic", "motd", "passwd", "shadow"],
        ["/etc\n", "rootfs\t/\text4\t\t0\t1\n", "root\t0\nboris\t1000\n", format("{}\n", address(this)), "0:72c71b29995fb176b187bf9c57d2750bd7b3a2ab04b355e6b46a3eb59c75cb6a\tCommandProcessor\n0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9\tStat\n0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume\n0:68c00d417291837826ed9e7aa451d40629dde6d7cf8bcc4fec63cc0978d08205\tSuperBlock\n0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice\n0:78a427fb136f940f38df2505d67632120aade8f1af9e3eb68d8d5aceda751823\tInputParser\n0:6e14e41808289276817c94383b5943c25fc3c813e281dca00af152ebd94fdf61\tOptions\n",
        "11\n", "Welcome to Tonix.\nType \"help\" to get a list of commands.\n\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.\nSome options for certain commands work as well.\nFeel free to navigate a pre-made file system using intuitive commands.\nPath resolution does not work yet, one step at a time please.\nYour feedback is highly appreciated!\nHave fun :)\n",
//        "11\n", "Welcome to Tonix.\nType \"help\" for a list of commands.\nHave fun :)\n",
        "root\t0\t0\troot\t/root\nboris\t1000\t1000\t/home/boris", ""]);
        this.mount_dir{value: 1 ton}(_init_ids[4], etc_files);
        this.init2{value: 1 ton}();
    }

    function init2() external accept {
        _data_volume = address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb);
        ExportFS(_data_volume).export_all{value: 1 ton}("/usr/share/man", _init_ids[7], 3);
        ExportFS(_data_volume).export_all{value: 1 ton}("/usr/share/help", _init_ids[8], 3);
        _command_options_source = address.makeAddrStd(0, 0x6e14e41808289276817c94383b5943c25fc3c813e281dca00af152ebd94fdf61);
        ExportFS(_command_options_source).export_all{value: 1 ton}("/usr/share/options", _init_ids[10], 3);
        this.init3{value: 1 ton}();
    }
    function init3() external accept {
        _cmd_proc = address.makeAddrStd(0, 0x72c71b29995fb176b187bf9c57d2750bd7b3a2ab04b355e6b46a3eb59c75cb6a);
        _fstat = address.makeAddrStd(0, 0x44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9);
        Base(_cmd_proc).init{value: 1 ton}();
        Base(_fstat).init{value: 1 ton}();
    }

    function query_fs_cache() external override accept {
        ISync(msg.sender).update_users{value: 0.2 ton}(_init_ids, _ugroups, _users, _ino_counter, _de_counter);
        uint j = 0;
        uint16[] inn;
        for ((uint16 i, ): _inodes) {
            inn.push(i);
            j++;
            if (j > 70) {
                this.call_update_inodes{value: 1 ton}(msg.sender, inn);
                j = 0;
                delete inn;
            }
        }
        this.call_update_inodes{value: 1 ton}(msg.sender, inn);
        this.call_update_dirents{value: 1 ton}(msg.sender);
        this.call_update_children{value: 1 ton}(msg.sender);
    }

    function call_update_inodes(address addr, uint16[] inns) external view accept {
        mapping (uint16 => INodeS) inn;
        mapping (uint16 => INodeTimeS) inn_t;
        for (uint16 i: inns) {
            inn[i] = _inodes[i];
            inn_t[i] = _ino_ts[i];
        }
        ISync(addr).update_inodes{value: 1 ton}(inn, inn_t);
    }

    function call_update_dirents(address addr) external view accept {
        ISync(addr).update_dirents{value: 1 ton}(_de);
    }

    function call_update_children(address addr) external view accept {
        ISync(addr).update_children{value: 1 ton}(_dc);
    }
}
