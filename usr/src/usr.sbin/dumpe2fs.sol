pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "../lib/vfs.sol";

contract dumpe2fs is Utility {

    /*function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, uint[] nodes, bytes[] blocks) {
        err = "";
        ( , , string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        (bool sb_only, bool image_fs, , , , , , ) = arg.flag_values("hi", flags);*/
    function main(svm sv_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        s_vmem[] vmms = sv.vmem;
        uma_zone[] zones = sv.sz;
//        string[] params = p.params();
        (bool sb_only, bool image_fs, , ) = p.flags_set("hi");

        SuperBlock sblk = sb.get_sb(inodes, data);
        if (sb_only)
            p.puts(sb.display_sb(sblk));

        uint16 flags;
        if (image_fs) {
            /*string s1 = _dump_e2fs(2, inodes, data);
            string s2 = _dump_e2fs(2, vfs.read_inode_table(data), data);
            out = s1 + "\n========================\n" + s2;*/
            (uint[] nodes, bytes[] blocks) = _compact(inodes, data);
            uint nnodes = nodes.length;
            s_vmem v = vmms[0];
            (uint8 e, uint32 addr) = v.vmem_alloc(32, flags);
            p.puts(format("Allocated virtual memory: {} , exit code {}", addr, e));
            uint16 zidx;// = zones.uma_zone_index("INODES");
            uma_zone z = zones[zidx - 1];
//            z.uma_zone_reserve(uint16(nnodes));
            for (uint i = 0; i < nnodes; i++) {
                uint node = nodes[i];
                string ss;
                ss = ss + bytes32(node);
                uint32 bb2;// = z.uma_zalloc_arg(bytes(ss));
                p.puts(format("Allocated inode address: {}", bb2));
                v.vm_pages.push(blocks[i]);
            }
            sv.vmem[0] = v;
            sv.sz[zidx - 1] = z;
        } else
            p.puts(_dump_e2fs(2, inodes, data));
        sv.cur_proc = p;
    }

    function _dump_e2fs(uint8 level, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        SuperBlock sblk = sb.get_sb(inodes, data);
        out = sb.display_sb(sblk);

        for ((uint16 i, Inode ino): inodes) {
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
            out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
            if (level > 0 && (ft.is_dir(mode) || ft.is_symlink(mode) || level > 1)) {
                out.append(data[i]);
                out.append("\n");
            }
        }
    }

    function _attr(Inode ino, uint16 bs, uint16 i) internal pure returns (uint) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
        return (uint(device_id) << 224) + (uint(i) << 208) + (uint(mode) << 192) + (uint(n_links) << 176) + (uint(owner_id) << 160) + (uint(group_id) << 144) +
            (uint(file_size) << 96) + (uint(bs) << 80) + (uint(n_blocks) << 64) + (uint(modified_at) << 32) + last_modified;
    }

    function _compact(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (uint[] nodes, bytes[] blocks) {
        bytes empty;
        uint16 ic = sb.get_inode_count(inodes);
        uint16 bs = sb.get_block_size(inodes);
        for (uint16 i = 0; i < ic; i++) {
            nodes.push(inodes.exists(i) ? _attr(inodes[i], bs, i) : 0);
            blocks.push(data.exists(i) ? data[i] : empty);
        }
    }

    function parse_fs(string text) external pure returns (string out, mapping (uint16 => Inode) inodes) {
        return vfs.parsefs(text);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"dumpe2fs",
"[ -bfghixV ] device",
"dump ext2/ext3/ext4 filesystem information",
"Prints the super block and blocks group information for the filesystem present on device.",
"-h     only display the superblock information and not any of the block group descriptor detail information\n\
-i      display the filesystem data from an image file created by e2image, using device as the pathname to the image file",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
