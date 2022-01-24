pragma ton-solidity >= 0.55.0;

import "../lib/SyncFS.sol";
import "../include/ICache.sol";
import "Utility.sol";

interface IPages {
    function query_pages() external view;
}

/* Base contract for the devices exporting command manuals */
contract man is SyncFS, Utility {

    function exec(Session /*session*/, InputS input) external view returns (string out) {
        (, string[] args, ) = input.unpack();
        for (string s: args)
            out.append(_is_command_page_available(s) ? _get_man_text(s) : "No manual entry for " + s + "\n");
    }

    Page[] public _pages;
    uint16 constant CMD_INDEX_START = 30;

    function add_page(Page page) external accept {
        _pages.push(page);
    }

    function process_pages(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external accept {
        for ((uint16 idx, Inode inode): inodes)
            _inodes[idx] = inode;
        for ((uint16 idx, bytes bts): data)
            _data[idx] = bts;
    }

    function view_pages() external view returns (Page[] pages) {
        return _pages;
    }

    function transform_pages(uint8 start, uint8 count) external view returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint cap = math.min(_pages.length, start + count);
        for (uint i = start; i < cap; i++) {
            Page page = _pages[i];
            (string command, string purpose, string synopsis, string description, string option_list,
                uint8 min_args, uint16 max_args, string[] option_descriptions) = page.unpack();
            string contents = stdio.join_fields([command, purpose, synopsis, description, option_list, stdio.join_fields(option_descriptions, "\t"), format("{}\t{}", min_args, max_args)], "\n");

            (Inode cmd_inode, bytes cmd_data) = _get_any_node(FT_REG_FILE, SUPER_USER, SUPER_USER_GROUP, _device_id, uint16(contents.byteLength() / _block_size + 1),
                command, contents);

            (uint16 idx, ) = _lookup_dir(_inodes[ROOT_DIR + 1], _data[ROOT_DIR + 1], command);
            if (idx > INODES) {
                inodes[idx] = cmd_inode;
                data[idx] = cmd_data;
            }
        }
    }

    function convert_pages(Page[] pages) external view returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint n_pages = pages.length;
        uint16 usr_dir_index = _resolve_absolute_path("/usr", _inodes, _data);
        uint16 ic = _get_inode_count(_inodes);
        bytes dirents;
        uint total_blocks;
        uint total_inodes;
        Inode usr_dir_inode = _inodes[usr_dir_index];
        bytes usr_dir_data = _data[usr_dir_index];

        for (uint i = 0; i < n_pages; i++) {
            Page page = pages[i];
            (string command, string purpose, string synopsis, string description, string option_list,
                uint8 min_args, uint16 max_args, string[] option_descriptions) = page.unpack();
            string contents = _join_fields([command, purpose, synopsis, description, option_list, _join_fields(option_descriptions, "\t"), format("{}\t{}", min_args, max_args)], "\n");
            uint16 n_blocks = uint16(contents.byteLength() / _block_size + 1);

            (uint16 idx, uint8 ft) = _lookup_dir(_inodes[usr_dir_index], _data[usr_dir_index], command);
            (Inode cmd_inode, bytes cmd_data) = _get_any_node(FT_REG_FILE, SUPER_USER, SUPER_USER_GROUP, _device_id, n_blocks, command, contents);

            if (ft == FT_UNKNOWN) {
                idx = ic++;
                total_inodes++;
                dirents.append(_dir_entry_line(idx, command, FT_REG_FILE));
            }
            inodes[idx] = cmd_inode;
            data[idx] = cmd_data;
            total_blocks += n_blocks;
        }
        if (!dirents.empty()) {
            usr_dir_inode.file_size += uint32(dirents.length);
            usr_dir_inode.n_links += ic - _get_inode_count(_inodes);
            usr_dir_inode.modified_at = now;
            usr_dir_inode.last_modified = now;
            inodes[usr_dir_index] = usr_dir_inode;
            usr_dir_data.append(dirents);
            data[usr_dir_index] = usr_dir_data;
            inodes[SB_INODES] = _claim_inodes_and_blocks(_inodes[SB_INODES], uint16(total_inodes), uint16(total_blocks));
        }
    }

    function get_command_info_list() external view returns (string[] command_names, mapping (uint8 => CmdInfoS) command_info) {
        string etc_command_list = _get_file_contents_at_path("/etc/command_list", _inodes, _data);
        (string[] commands, uint n_commands) = stdio.split_line(etc_command_list, " ", "\n");
        uint16 bin_dir_index = _resolve_absolute_path("/usr", _inodes, _data);
        for (uint i = 0; i < n_commands; i++) {
            string command_name = commands[i];
            command_names.push(command_name);
            uint16 command_index = bin_dir_index + uint16(i) + 4;
            bytes command_file = _data[command_index];
            uint8 min_args;
            uint16 max_args;
            uint flags;
            (string[] command_data, uint len) = stdio.split(command_file, "\n");
            if (len > 4) {
                bytes opts = bytes(command_data[4]);
                for (uint j = 0; j < opts.length; j++)
                    flags |= uint(1) << uint8(opts[j]);
                if (len > 6) {
                    string s_n_args = command_data[6];
                    (string[] min_max_args, uint n_fields) = stdio.split(s_n_args, "\t");
                    if (n_fields > 1) {
                        min_args = uint8(stdio.atoi(min_max_args[0]));
                        max_args = stdio.atoi(min_max_args[1]);
                    }
                }
            }
            command_info[uint8(i) + 1] = CmdInfoS(min_args, max_args, flags, command_name);
        }
    }

    function get_command_info_file() external view returns (uint16 index, bytes contents) {
        string etc_command_list = _get_file_contents_at_path("/etc/command_list", _inodes, _data);
        (string[] commands, uint n_commands) = stdio.split(etc_command_list, " ");
        uint16 bin_dir_index = _resolve_absolute_path("/usr", _inodes, _data);
        index = _resolve_absolute_path("/etc/command_info", _inodes, _data);
        for (uint i = 0; i < n_commands; i++) {
            string command_name = commands[i];
            uint16 command_index = bin_dir_index + uint16(i) + 4;
            bytes command_file = _data[command_index];
            (string[] command_data, uint len) = stdio.split(command_file, "\n");
            if (len > 4) {
                bytes opts = bytes(command_data[4]);
                uint flags;
                for (uint j = 0; j < opts.length; j++)
                    flags |= uint(1) << uint8(opts[j]);
                if (len > 6) {
                    string s_n_args = command_data[6];
                    (string[] min_max_args, uint n_fields) = split(s_n_args, "\t");
                    if (n_fields > 1) {
                        uint u_min_args = stdio.atoi(min_max_args[0]);
                        uint u_max_args = stdio.atoi(min_max_args[1]);
                        contents.append(format("{}\t{}\t{}\t{}\t{}\n", i + 1, command_name, u_min_args, u_max_args, flags));
                    }
                }
            }
        }
    }

    function set_file_contents(uint16 index, bytes contents) external accept {
        _inodes[index].file_size = uint32(contents.length);
        _data[index] = contents;
    }

    /* Print an internal debugging information about the file system state */
    function dump_fs(uint8 level) external view returns (string) {
        return _dump_fs(level, _inodes, _data);
    }

    function assign_pages(address[] pages) external pure accept {
        for (address addr: pages)
            IPages(addr).query_pages();
    }

    function read_page(InputS input) external view returns (string out) {
        (, string[] args, ) = input.unpack();
        for (string s: args)
            out.append(_is_command_page_available(s) ? _get_man_text(s) : "No manual entry for " + s + "\n");
    }

    /* Imports helpers */
    function _get_imported_file_contents(string path, string file_name) internal view returns (string text) {
        uint16 dir_idx = _resolve_absolute_path(path, _inodes, _data);
        (uint16 file_index, uint8 ft) = _lookup_dir(_inodes[dir_idx], _data[dir_idx], file_name);
        if (ft > FT_UNKNOWN)
            return _data[file_index];
        return "Failed to read file " + file_name + " at path " + path + "\n";
    }
    /* Informational commands helpers */
    function _get_man_text(string s) private view returns (string) {
        (string name, string purpose, string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_page(s);
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
        (string name, , string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_page(command);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options = "\n";
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_names.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + usage + description + options;
    }

    function _is_command_page_available(string command_name) private view returns (bool) {
        uint16 usr_dir_index = _resolve_absolute_path("/usr", _inodes, _data);
        (uint16 command_index, uint8 ft) = _lookup_dir(_inodes[usr_dir_index], _data[usr_dir_index], command_name);
        return ft > FT_UNKNOWN && _inodes.exists(command_index) && _data.exists(command_index);
    }

    function _get_command_page(string command) private view returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        (string[] command_data, uint n_fields) = stdio.split(_get_file_contents_at_path("/usr/" + command, _inodes, _data), "\n");
        if (n_fields > 5)
            return (command_data[0], command_data[1], stdio.join_fields(_get_tsv(command_data[3]), "\n"),
                _get_tsv(command_data[2]), command_data[4], _get_tsv(command_data[5]));
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
            "man",
            "an interface to the system reference manuals",
            "[COMMAND]",
            "System's manual pager. Each page argument given to man is normally the name of a program, utility or function.",
            "a",
            0,
            M, [
                "find all matching manual pages"]);
    }
}
