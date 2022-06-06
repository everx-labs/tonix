pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "../lib/vfs.sol";

contract mkfs is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
//        string[] params = p.params();
        string fstype = p.opt_value("t");
        if (fstype == "procfs") {
            string[][2] w = [
            ["cmdline", p.p_args.ar_misc.argv],
            ["exe", p.p_comm],
            ["cwd", p.p_pd.pwd_cdir.path],
            ["root", p.p_pd.pwd_rdir.path]];
            for (string[2] s: w) {
                p.puts("./procfsd " + s[0] + " " + s[1]);
            }
        }
    }

    function get_device_fs(string devices) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return vfs.get_device_fs(devices);
    }

    function get_arr_fs(uint[] nodes, bytes[] blocks) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        uint len = nodes.length;
        for (uint16 i = 0; i < len; i++) {
            uint val = nodes[i];
            if (val > 0) {
                (uint16 st_dev, , uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, , uint32 st_size, ,
                    uint16 st_blocks, uint32 st_mtim, uint32 st_ctim) = (uint16(val >> 224 & 0xFFFF), uint16(val >> 208 & 0xFFFF), uint16(val >> 192 & 0xFFFF),
                    uint16(val >> 176 & 0xFFFF), uint16(val >> 160 & 0xFFFF), uint16(val >> 144 & 0xFFFF), uint16(val >> 128 & 0xFFFF), uint32(val >> 96 & 0xFFFFFFFF),
                    uint16(val >> 80 & 0xFFFF), uint16(val >> 64 & 0xFFFF), uint32(val >> 32 & 0xFFFFFFFF), uint32(val & 0xFFFFFFFF));
                inodes[i] = Inode(st_mode, st_uid, st_gid, st_nlink, st_dev, st_blocks, st_size, st_mtim, st_ctim, "");
                data[i] = blocks[i];
            }
        }
    }

    function arr_to_cell(uint[] nodes, bytes[] blocks) external pure returns (TvmCell[] cells) {
        uint len = nodes.length;
        for (uint16 i = 0; i < len; i++) {
            uint val = nodes[i];
            if (val > 0) {
                TvmBuilder b;
                b.store(val);
                b.store(blocks[i]);
                cells.push(b.toCell());
            }
        }
    }

    function cell_to_arr(TvmCell[] cells) external pure returns (uint[] nodes, bytes[] blocks) {
        uint len = cells.length;
        for (uint16 i = 0; i < len; i++) {
            TvmSlice s = cells[i].toSlice();
            (uint node, bytes blk) = s.decode(uint, bytes);
            nodes.push(node);
            blocks.push(blk);
        }
    }

    function _attr(Inode ino, uint16 bs, uint16 i) internal pure returns (uint) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
        return (uint(device_id) << 224) + (uint(i) << 208) + (uint(mode) << 192) + (uint(n_links) << 176) + (uint(owner_id) << 160) + (uint(group_id) << 144) +
            (uint(file_size) << 96) + (uint(bs) << 80) + (uint(n_blocks) << 64) + (uint(modified_at) << 32) + last_modified;
    }

    function to_arr_fs(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint[] nodes, bytes[] blocks) {
        bytes empty;
        uint16 ic = sb.get_inode_count(inodes);
        uint16 bs = sb.get_block_size(inodes);
        for (uint16 i = 0; i < ic; i++) {
            nodes.push(inodes.exists(i) ? _attr(inodes[i], bs, i) : 0);
            blocks.push(data.exists(i) ? data[i] : empty);
        }
    }

    function t_mkfs(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell /*c*/, string /*out*/) {
        (inodes, data) = vfs.get_system_init(config);
    }

    function t_mkfs_2(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
        return vfs.get_system_init_2(config);
    }

    function parse_fs(string text) external pure returns (string out, mapping (uint16 => Inode) inodes) {
        return vfs.parsefs(text);
    }

    function process_system_init(uint16 mode, string config) external pure returns (string out) {
        uint16 level = mode & 0xFF;
        uint16 form = (mode >> 8) & 0xFF;
        (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) = vfs.get_system_init(config);
        return inode.dumpfs(level, form, inodes, data);
    }

    function get_system_init(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return vfs.get_system_init(config);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mkfs",
"[options] [fs-options] device [size]",
"build a Tonix filesystem",
"Used to build a Tonix filesystem on a device. The device argument is either the device name, or a regular file that shall contain the filesystem. The size argument is the number of blocks to be used for the filesystem.",
"-V     produce verbose output, including all filesystem-specific commands that are executed",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
