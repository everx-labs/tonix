pragma ton-solidity >= 0.62.0;

import "Utility.sol";
import "sb.sol";
import "udirent.sol";
import "fs.sol";

contract fsck is Utility {

    uint8 constant NO_ERRORS                = 0;
    uint8 constant ERRORS_CORRECTED         = 1;
    uint8 constant ERRORS_CORRECTED_REBOOT  = 2;
    uint8 constant ERRORS_UNCORRECTED       = 4;
    uint8 constant OPERATIONAL_ERROR        = 8;
    uint8 constant USAGE_OR_SYNTAX_ERROR    = 16;
    uint8 constant CANCELED_BY_USER         = 32;
    uint8 constant SHARED_LIBRARY_ERROR     = 128;

    function _print_dir_contents(uint16 start_dir_index, mapping (uint16 => bytes) data) internal pure returns (uint8 ec, string out) {
        (DirEntry[] contents, int16 status) = udirent.read_dir_data(data[start_dir_index]);
        if (status < 0) {
            out.append(format("Error: {} \n", status));
            ec = EXECUTE_FAILURE;
        } else {
            uint len = uint(status);
            for (uint16 j = 0; j < len; j++) {
                (uint8 t, string name, uint16 index) = contents[j].unpack();
                if (t == libstat.FT_UNKNOWN)
                    continue;
                out.append(udirent.dir_entry_line(index, name, t));
            }
        }
    }

    uint16 constant MISSING_INODE_DATA      = 1;
    uint16 constant FILE_SIZE_MISMATCH      = 2;
    uint16 constant LINK_COUNT_MISMATCH     = 4;
    uint16 constant EMPTY_DIRENT_NAME       = 8;
    uint16 constant UNKNOWN_DIRENT_TYPE     = 16;
    uint16 constant DIR_INDEX_ERROR         = 32;
    uint16 constant DIRENT_COUNT_MISMATCH   = 64;
    uint16 constant INODE_COUNT_MISMATCH    = 128;
    uint16 constant BLOCK_COUNT_MISMATCH    = 256;
    uint16 constant UNKNOWN_FILE_TYPE       = 512;

    struct fsck_err {
        uint16 index;
        uint16 code;
        uint16 expected;
        uint16 actual;
    }
    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        uint8 ec;
        string out;
        string err;
        string[] params = p.params();
        mapping (uint16 => Inode) inodes_out;
        mapping (uint16 => bytes) data_out;

        (bool auto_repair, bool check_all, bool no_changes, bool list_files, bool skip_root, bool dry_run, bool verbose, bool print_sb) =
            p.flag_values("pAnlRNvs");
        inodes_out = inodes;
        data_out = data;
        mapping (uint16 => fsck_err[]) es;

        string start_dir = "/";
        uint16 start = sb.ROOT_DIR;

        if (print_sb) {
            out.append(sb.display_sb(sb.read_sb(inodes, data)));
            out.append("\n======================================\n\n");
            out.append(sb.display_sb(sb.get_sb(inodes, data)));
        }

        if (!params.empty()) {
            start_dir = params[0];
            if (verbose)
                out.append("Resolving start dir index for " + start_dir + "\n");
            start = fs.resolve_absolute_path(start_dir, inodes, data);
            if (verbose)
                out.append("start dir index resolved as " + str.toa(start) + "\n");
            if (!data.exists(start)) {
                es[start].push(fsck_err(start, MISSING_INODE_DATA, 0, 0));
            }
            if (verbose)
                out.append("checking dir " + str.toa(start) + "\n");
            (string errs, string dry, Inode res, bytes res_data) = _check_dir(inodes[start], data[start]);
            if (verbose)
                out.append("dir " + str.toa(start) + " checked\n");
            (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = res.unpack();
            if (!err.empty()) {
                err.append(errs);
                ec |= ERRORS_UNCORRECTED;
            }
            if (dry_run) {
                out.append(dry);
            } else if (auto_repair && !no_changes) {
                inodes_out[start] = res;
                data_out[start] = res_data;
                ec = ERRORS_CORRECTED;
            }
            err.append(format("\nfixed inode: I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", start, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
            err.append(format("\nfixed data: {}\n", res_data));
        }

        if (!dry_run && !skip_root && start >= sb.ROOT_DIR) {
            (DirEntry[] contents, int16 status, ) = udirent.read_dir_verbose(data[start]);
            uint16 i = start;
            uint16 sn_links = inodes[i].n_links;
            if (status < 0 || uint16(status) != sn_links) {
                es[i].push(fsck_err(i, DIR_INDEX_ERROR, 0, uint16(status)));
            } else {
                for (DirEntry de: contents) {
                    (uint8 sub_ft, string sub_name, uint16 sub_index) = de.unpack();
                    if (sub_name.empty())
                        es[i].push(fsck_err(i, EMPTY_DIRENT_NAME, 0, sub_index));
                    if (sub_ft == libstat.FT_UNKNOWN)
                        es[i].push(fsck_err(i, UNKNOWN_DIRENT_TYPE, 0, sub_ft));
                    if (verbose || list_files)
                        out.append(udirent.dir_entry_line(sub_index, sub_name, sub_ft));
                }
            }
            if (!es[i].empty()) {
                uint err_len = es[i].length;
                string suffix = err_len > 1 ? "s" : "";
                err.append(format("\nInode {} consistency check failed with {} error{}:\n", i, err_len, suffix));
                (string errs, string dry, Inode res, bytes res_data) = _rebuild_dir_index(inodes[i], data[i], fsck_err(i, DIR_INDEX_ERROR, 0, uint16(status)));
                err.append(errs);
                err.append(dry);
                (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = res.unpack();
                err.append(format("\nfixed inode: I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
                err.append(format("\nfixed data: {}\n", res_data));
            }
            if (status < 0) {
                err.append(format("Error: {} \n", status));
                es[start].push(fsck_err(start, DIR_INDEX_ERROR, 0, uint16(status)));
                ec = EXECUTE_FAILURE;
            } else {
                i = start;
                uint16 n_links = inodes[i].n_links;
//                (errs, dry, res, res_data) = _rebuild_dir_index(inodes[i], data[i], fsckerr);
                if (status < 0)
                    es[i].push(fsck_err(i, DIR_INDEX_ERROR, 0, uint16(status)));
                else if (uint16(status) != n_links)
                    es[i].push(fsck_err(i, DIRENT_COUNT_MISMATCH, n_links, uint16(status)));
                else {
                    for (DirEntry de: contents) {
                        (uint8 sub_ft, string sub_name, uint16 sub_index) = de.unpack();
                        if (sub_name.empty())
                            es[i].push(fsck_err(i, EMPTY_DIRENT_NAME, 0, sub_index));
                        if (sub_ft == libstat.FT_UNKNOWN)
                            es[i].push(fsck_err(i, UNKNOWN_DIRENT_TYPE, 0, sub_ft));
                        if (verbose || list_files)
                            out.append(udirent.dir_entry_line(sub_index, sub_name, sub_ft));
                            if (es.exists(i))
                                break;
                    }
                }
                uint len = uint(status);
                for (uint16 j = 0; j < len; j++) {
                    (uint8 t, string name, uint16 index) = contents[j].unpack();
                    if (t == libstat.FT_UNKNOWN) {
                        es[start].push(fsck_err(start, UNKNOWN_DIRENT_TYPE, 0, t));
                        continue;
                    }
                    if (verbose)
                        out.append(udirent.dir_entry_line(index, name, t));
                }
            }
        }
//        uint16 block_size = 100;
        uint16 first_block = 0;
        uint total_inodes;
        uint total_blocks_reported;
        uint total_blocks_actual;

        if (check_all) {
//            SuperBlock sb = sb.read_sb(inodes, data);
            SuperBlock sblk = sb.get_sb(inodes, data);

            (, , , uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size, , , , ,
                , , uint16 first_inode, uint16 inode_size) = sblk.unpack();

            for ((uint16 i, Inode ino): inodes) {
                (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = ino.unpack();
                bytes bts = data[i];
                uint32 len = uint32(bts.length);
                if (file_size != uint32(len))
                    es[i].push(fsck_err(i, FILE_SIZE_MISMATCH, uint16(file_size), uint16(len)));
                uint16 n_data_blocks = uint16(len / block_size + 1);
                if (n_blocks != n_data_blocks) {
        //                errors.append(format("Block count mismatch: inode: {} data: {} \n", n_blocks, n_data_blocks));
                }
                total_blocks_reported += n_blocks;
                total_blocks_actual += n_data_blocks;
                total_inodes++;

                if (libstat.is_dir(mode)) {
                    out.append(format("Inode dir: {}\n", i));
                    out.append(format("I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
                    out.append(bts);
                    (DirEntry[] contents, int status) = udirent.read_dir_data(bts);
                    out.append(format("status {}\n", status));
                    if (status < 0)
                        es[i].push(fsck_err(i, DIR_INDEX_ERROR, 0, uint16(status)));
                    else if (status != n_links)
                        es[i].push(fsck_err(i, DIRENT_COUNT_MISMATCH, n_links, uint16(status)));
                    else {
                        for (DirEntry de: contents) {
                            (uint8 sub_ft, string sub_name, uint16 sub_index) = de.unpack();
                            if (sub_name.empty())
                                es[i].push(fsck_err(i, EMPTY_DIRENT_NAME, 0, sub_index));
                            else if (sub_ft == libstat.FT_UNKNOWN)
                                es[i].push(fsck_err(i, UNKNOWN_DIRENT_TYPE, 0, sub_ft));
                            if (verbose || list_files)
                                out.append(udirent.dir_entry_line(sub_index, sub_name, sub_ft));
                            if (es.exists(i))
                                break;
                        }
                    }
                }
                if (verbose) {
                    if (es.exists(i)) {
                        err.append(format("\nI {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
                        err.append(bts);
                    } else
                        out.append(format("{} OK  ", i));
                }
            }

            out.append("Summary\n");
            out.append(format("Inodes SB: count: {} free: {} first: {} size: {}\n", inode_count, free_inodes, first_inode, inode_size));
            out.append(format("Inodes actual: count: {}\n", total_inodes));
            if (inode_count != total_inodes) {
                es[sb.SB].push(fsck_err(sb.SB, INODE_COUNT_MISMATCH, inode_count, uint16(total_inodes)));
            }
            out.append(format("Blocks SB: count: {} free: {} first: {} size: {}\n", block_count, free_blocks, first_block, block_size));
            out.append(format("Blocks reported: {} actual: {}\n", total_blocks_reported, total_blocks_actual));
            if (total_blocks_reported != total_blocks_actual) {
                es[sb.SB].push(fsck_err(sb.SB, BLOCK_COUNT_MISMATCH, uint16(total_blocks_reported), uint16(total_blocks_actual)));
            }
        }
        err.append("\n======================================\n\n");
        for ((uint16 i, fsck_err[] fsckers): es) {
            uint err_len = fsckers.length;
            string suffix = err_len > 1 ? "s" : "";
            err.append(format("\nInode {} consistency check failed with {} error{}:\n", i, err_len, suffix));
            for (fsck_err fsckerr: fsckers) {
                string errs;
                string dry;
                Inode res;
                bytes res_data;
                if ((fsckerr.code & EMPTY_DIRENT_NAME + UNKNOWN_DIRENT_TYPE + DIR_INDEX_ERROR + DIRENT_COUNT_MISMATCH) > 0)
                    (errs, dry, res, res_data) = _rebuild_dir_index(inodes[i], data[i], fsckerr);
                else if ((fsckerr.code & INODE_COUNT_MISMATCH + BLOCK_COUNT_MISMATCH) > 0)
                    (errs, dry, res, res_data) = _fix_sb(inodes[sb.SB], data[sb.SB], fsckerr);
//                else
//                    (errs, dry, res) = _fix_inode(inodes[i], data[i], fsckerr);
                err.append(errs);
                err.append(dry);
                (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, , , string file_name) = res.unpack();
                err.append(format("\nfixed inode: I {} {} PM {} O {} G {} NL {} DI {} NB {} SZ {}\n", i, file_name, mode, owner_id, group_id, n_links, device_id, n_blocks, file_size));
                err.append(format("\nfixed data: {}\n", res_data));
            }
        }
        err.append("\n======================================\n");
    }

    function _check_dir(Inode ino, bytes data) internal pure returns (string err, string dry, Inode res, bytes resdata) {
        res = ino;
        resdata = data;

        (uint16 smode, , , uint16 sn_links, , , , , , ) = ino.unpack();
        if (!libstat.is_dir(smode))
            err.append("Not a directory\n");
        (DirEntry[] contents, int16 status, ) = udirent.read_dir_verbose(data);
//        err.append(dbg);
        if (status < 0)
            err.append(format("Error reading dir index: {}, status {}\n", "?", status));
        if (uint16(status) != sn_links)
            err.append(format("Dir entry count mismatch, expected: {} actual: {}\n", sn_links, status));
        (string[] lines, ) = libstring.split(data, "\n");
        for (string s: lines) {
            if (s.empty())
                err.append("Empty dir entry line\n");
            else {
                (string shead, string stail) = s.csplit("\t");
                if (shead.empty())
                    err.append("Empty file type and name: " + s + "\n");
                else if (stail.empty())
                    err.append("Empty inode reference: " + s + "\n");
                else {
                    uint h_len = shead.byteLength();
                    if (h_len < 2)
                        err.append("File type and name too short: " + shead + "\n");
                    else {
                        DirEntry de = DirEntry(libstat.file_type(shead.substr(0, 1)), shead.substr(1), str.toi(stail));
                        contents.push(de);
                        dry.append(udirent.print(de));
                    }
                }
            }
        }

            /*(uint8 sub_ft, string sub_name, uint16 sub_index) = de.unpack();
            if (sub_name.empty())
                err.append(format("empty dir entry name {}\n", sub_index));
            if (sub_ft == FT_UNKNOWN)
                err.append(format("unknown dir entry type: {}, status {}\n", 0, sub_ft));
            }*/
        if (!err.empty()) {
            dry.append(format("Fixing inode dir index:\n{}", data));
            string text;
            uint new_lc;
            (lines, ) = libstring.split(data, "\n");
            for (string s: lines) {
                if (s.empty())
                    dry.append("Skipping empty dir entry line\n");
                else {
                    (string shead, string stail) = s.csplit("\t");
                    if (shead.empty())
                        dry.append("Skipping line with an empty file type and name: " + s + "\n");
                    else if (stail.empty())
                        dry.append("Skipping line with an empty inode reference: " + s + "\n");
                    else {
                        uint h_len = shead.byteLength();
                        if (h_len < 2)
                            dry.append("Skipping line with a file type and name way too short: " + shead + "\n");
                        else {
                            dry.append("Appending a valid line " + s + "\n");
                            text.append(s + "\n");
                            new_lc++;
                        }
                    }
                }
            }
            res.n_links = uint16(new_lc);
            res.file_size = text.byteLength();
            resdata = text;
        }
    }

    function _fix_inode(Inode ino, bytes /*data*/, fsck_err fsckerr) internal pure returns (string err, string dry, Inode res) {
        (uint16 index, uint16 code, uint16 expected, uint16 actual) = fsckerr.unpack();
        res = ino;
        if ((code & MISSING_INODE_DATA) > 0) {
            err.append(format("Missing data for inode: {}\n", index));
            dry.append(format("Setting inode {} file size {} to 0\n", index, ino.file_size));
            res.file_size = 0;
        }
        if ((code & FILE_SIZE_MISMATCH) > 0) {
            err.append(format("File size mismatch, expected: {} actual: {}\n", expected, actual));
            dry.append(format("Resetting inode {} file size {} to {}\n", index, ino.file_size, actual));
            res.file_size = actual;
        }
        if ((code & LINK_COUNT_MISMATCH) > 0) {
            err.append(format("Link count mismatch, expected: {} actual: {}\n", expected, actual));
            dry.append(format("Resetting inode {} file size {} to {}\n", index, ino.n_links, actual));
            res.n_links = actual;
        }

        if ((code & UNKNOWN_FILE_TYPE) > 0) {
            err.append(format("unknown file type for {}: {}\n", index, actual));
            // ???
        }
    }

    function _fix_sb(Inode ino, bytes data, fsck_err fsckerr) internal pure returns (string err, string /*dry*/, Inode res, bytes res_data) {
        (, uint16 code, uint16 expected, uint16 actual) = fsckerr.unpack();
        res = ino;
        res_data = data;
        if ((code & INODE_COUNT_MISMATCH) > 0) {
            err.append(format("Inode count mismatch   SB data: {} actual: {}\n", expected, actual));
            // reset inode count
        }
        if ((code & BLOCK_COUNT_MISMATCH) > 0) {
            err.append(format("Block count mismatch   SB data: {} actual: {}\n", expected, actual));
            // reset block count
        }
    }

    function _rebuild_dir_index(Inode ino, bytes data, fsck_err fsckerr) internal pure returns (string err, string dry, Inode res, bytes res_data) {
        (uint16 index, uint16 code, uint16 expected, uint16 actual) = fsckerr.unpack();
        res = ino;
        res_data = data;
        if ((code & EMPTY_DIRENT_NAME) > 0)
            err.append(format("empty dir entry name {}\n", index));
        if ((code & UNKNOWN_DIRENT_TYPE) > 0)
            err.append(format("unknown dir entry type: {}, status {}\n", index, actual));
        if ((code & DIR_INDEX_ERROR) > 0)
            err.append(format("Error reading dir index: {}, status {}\n", index, actual));
        if ((code & DIRENT_COUNT_MISMATCH) > 0)
            err.append(format("Dir entry count mismatch, expected: {} actual: {}\n", expected, actual));
        if ((code & EMPTY_DIRENT_NAME + UNKNOWN_DIRENT_TYPE + DIR_INDEX_ERROR + DIRENT_COUNT_MISMATCH) > 0) {
            dry.append(format("Fixing inode {} dir index:\n{}", index, data));
            string text;
            uint new_lc;
            (string[] lines, ) = libstring.split(data, "\n");
            for (string s: lines) {
                if (s.empty())
                    dry.append("Skipping empty dir entry line\n");
                else {
                    (string shead, string stail) = s.csplit("\t");
                    if (shead.empty())
                        dry.append("Skipping line with an empty file type and name: " + s + "\n");
                    else if (stail.empty())
                        dry.append("Skipping line with an empty inode reference: " + s + "\n");
                    else {
                        uint h_len = shead.byteLength();
                        if (h_len < 2)
                            dry.append("Skipping line with a file type and name way too short: " + shead + "\n");
                        else {
                            dry.append("Appending a valid line " + s + "\n");
                            text.append(s + "\n");
                            new_lc++;
                        }
                    }
                }
            }
            res.n_links = uint16(new_lc);
            res.file_size = text.byteLength();
            res_data = text;
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"fsck",
"[filesystem...]",
"check and repair a Tonix filesystem",
"Used to check and optionally repair one or more Tonix filesystems.",
"-A      check all filesystems\n\
-l      list all filenames\n\
-a      automatic repair\n\
-r      interactive repair\n\
-s      output super-block information\n\
-f      force check\n\
-v      be verbose\n\
-R      skip root filesystem\n\
-p      automatic repair (no questions)\n\
-N      don't execute, just show what would be done\n\
-n      make no changes to the filesystem",
"",
"Written by Boris",
"",
"dumpe2fs, mke2fs, (debugfs)*",
"0.02");
    }

}
