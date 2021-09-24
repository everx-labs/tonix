pragma ton-solidity >= 0.49.0;

import "ExportFS.sol";

/* Base contract for the devices exporting command manuals */
abstract contract Manual is ExportFS {

    function _add_page(string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) internal {
        uint16 counter = _export_fs.ic++;
        _export_fs.inodes[counter] = _get_any_node(FT_REG_FILE, SUPER_USER, SUPER_USER_GROUP, command, [command, purpose, synopsis, description,
                                    option_list, _join_fields(option_descriptions, "\t"), format("{}\t{}", min_args, max_args)]);
    }

    function _init1() internal virtual;
    function init2() external virtual;
    function init3() external virtual;

    function _init() internal override {
        _export_fs = _get_fs(1, "exportfs", ["commands"]);

        _init1();
        this.init2();
        this.init3();
    }

    function _write_export_sb() internal {
        _sb_exports.push(_get_export_sb(ROOT_DIR + 2, _export_fs.ic - ROOT_DIR - 2, "Manual"));
    }
}
