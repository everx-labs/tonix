pragma ton-solidity >= 0.49.0;

import "SyncFS.sol";
import "ICache.sol";
import "SharedCommandInfo.sol";

interface IPages {
    function init() external;
}

/* Base contract for the devices exporting command manuals */
contract ManualPages is SyncFS, IImport, SharedCommandInfo {

    DeviceInfo public _dev;

    uint16 constant CMD_INDEX_START = 30;

    function add_page(string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) external accept {
        _add_page(command, purpose, synopsis, description, option_list, min_args, max_args, option_descriptions);
    }

    function _add_page(string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) internal {
        Inode cmd_inode = _get_any_node(FT_REG_FILE, SUPER_USER, SUPER_USER_GROUP, command,
                [command, purpose, synopsis, description, option_list, _join_fields(option_descriptions, "\t"), format("{}\t{}", min_args, max_args)]);
        uint16 dir_idx = _dir_index(command, ROOT_DIR + 1);
        uint16 idx = dir_idx > 0 ? _fetch_file_index(command, ROOT_DIR + 1) : _fs.ic++;
        _fs.inodes[idx] = cmd_inode;
        string s_de = _dir_entry_line(idx, command, FT_REG_FILE);
        if (dir_idx > 0)
            _fs.inodes[ROOT_DIR + 1].text_data[dir_idx - 1] = s_de;
        else
            _fs.inodes[ROOT_DIR + 1].text_data.push(s_de);
        uint8 cmd_idx = _command_index(command);
        if (cmd_idx > 0) {
            bytes opts = bytes(option_list);
            uint flags;
            for (uint i = 0; i < opts.length; i++)
                flags |= uint(1) << uint8(opts[i]);
            _command_info[cmd_idx] = CmdInfoS(min_args, max_args, flags);
        }
    }

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _fs);
    }

    function _init() internal override accept {
        _fs = _get_fs(1, "sysfs", ["bin", "etc"]);
        _dev = DeviceInfo(FT_BLKDEV, 1, "ManualPages", 512, 200, address(this));
        address data_volume = address.makeAddrStd(0, 0x439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb);
        IExportFS(data_volume).query_export_node("/etc", "command_list");
//        this.init2();
    }

    function update_node(Inode inode) external override accept {
        string file_name = inode.file_name;
        uint16 dir_idx = _dir_index(file_name, ROOT_DIR + 2);
        uint16 idx = dir_idx > 0 ? _fetch_file_index(file_name, ROOT_DIR + 2) : _fs.ic++;
        _fs.inodes[idx] = inode;
        string s_de = _dir_entry_line(idx, file_name, FT_REG_FILE);
        if (dir_idx > 0)
            _fs.inodes[ROOT_DIR + 2].text_data[dir_idx - 1] = s_de;
        else
            _fs.inodes[ROOT_DIR + 2].text_data.push(s_de);
        if (file_name == "command_list") {
            _command_names = inode.text_data;
            this.init2();
        }
    }

    function init2() external pure accept {
        uint[5] u_addrs = [
            0x9bc7fdbdadc754e31918f29c22af4a949787e22e84052d94c05e23e9d6e74099,
            0x5838d84e0998f90b98c6a8fa7e6727b9dc7fb7a1f686631bf929206d33a4fd30,
            0x379d5fffd72aa80b00e3f3dd73f0f748eeac311b5992de9b3cd3115b97cbb525,
            0x9fb67eacdcb4ef94f9c5c67787778a413328904fe7a3513fd921ee9881114632,
            0x694d24fe1aa0464859d21ce58a62875b80e16f6c36595f363e8b86b603bde7d4];
        for (uint u_addr: u_addrs)
            IPages(address.makeAddrStd(0, u_addr)).init{value: 0.1 ton}();
    }

    function read_page(InputS input) external view returns (string out) {
        (uint8 c, string[] args, ) = input.unpack();

        /* informational commands */
        if (c == help) out = _help(args);
        if (c == man) out = _man(args);
        if (c == whatis) out = _whatis(args);
    }

    /* Informational commands */
    function _help(string[] args) private view returns (string out) {
        if (args.empty())
            return "Commands: " + _join_fields(_get_file_contents("/etc/command_list"), " ") + "\n";

        for (string s: args) {
            if (!_is_command_info_available(s)) {
                out.append("help: no help topics match" + _quote(s) + "\nTry" + _quote("help help") + "or" + _quote("man -k " + s) + "or" + _quote("info " + s) + "\n");
                break;
            }
            out.append(_get_help_text(s));
        }
    }

    function _man(string[] args) private view returns (string out) {
        for (string s: args)
            out.append(_is_command_info_available(s) ? _get_man_text(s) : "No manual entry for " + s + "\n");
    }

    function _whatis(string[] args) private view returns (string out) {
        if (args.empty())
            return "whatis what?\n";

        for (string s: args) {
            if (_is_command_info_available(s)) {
                (string name, string purpose, , , , ) = _get_command_info(s);
                out.append(name + " (1)\t\t\t - " + purpose + "\n");
            } else
                out.append(s + ": nothing appropriate.\n");
        }
    }

    /* Imports helpers */
    function _get_imported_file_contents(string path, string file_name) internal view returns (string[] text) {
        uint16 dir_index = _resolve_absolute_path(path);
        (uint16 file_index, uint8 ft) = _fetch_dir_entry(file_name, dir_index);
        if (ft > FT_UNKNOWN)
            return _fs.inodes[file_index].text_data;
        return ["Failed to read file " + file_name + " at path " + path + "\n"];
    }

    function _fetch_element(uint16 index, string path, string file_name) internal view returns (string) {
        if (index > 0) {
            string[] text = _get_imported_file_contents(path, file_name);
            return text.length > 1 ? text[index - 1] : _element_at(1, index, text, "\t");
        }
    }

    /* Informational commands helpers */
    function _get_man_text(string s) private view returns (string) {
        (string name, string purpose, string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(s);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options;
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("\t" + "-" + option_names.substr(i, 1) + "\t" + option_descriptions[i] + "\n");
        options.append("\t" + "--help\tdisplay this help and exit\n\t--version\n\t\toutput version information and exit\n");

        return name + "(1)\t\t\t\t\tUser Commands\n\nNAME\n\t" + name + " - " + purpose + "\n\nSYNOPSIS\n" + usage +
            "\nDESCRIPTION\n\t" + description + "\n\n" + options;
    }

    function _get_help_text(string command) private view returns (string) {
        (string name, , string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_info(command);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options = "\n";
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_names.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + usage + description + options;
    }

    function _is_command_info_available(string command_name) private view returns (bool) {
        uint16 bin_dir_index = _get_file_index("/bin");
        (uint16 command_index, uint8 ft) = _fetch_dir_entry(command_name, bin_dir_index);
        return ft > FT_UNKNOWN && _fs.inodes.exists(command_index);
    }

    function _get_command_info(string command) private view returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        string[] command_info = _get_imported_file_contents("/bin", command);
        return (command_info[0], command_info[1], _join_fields(_get_tsv(command_info[3]), "\n"),
            _get_tsv(command_info[2]), command_info[4], _get_tsv(command_info[5]));
    }
}
