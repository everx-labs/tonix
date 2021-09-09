pragma ton-solidity >= 0.49.0;

import "ExportFS.sol";

/* Base contract for the devices exporting command manuals */
abstract contract Manual is ExportFS {

    uint8 constant M = 255;

    function _insert_lines(string command, string purpose, string synopsis,
                        string description, string option_list, uint8 min_args, uint8 max_args, string[] option_descriptions) internal pure returns (string[]) {
        return [command, purpose, synopsis, description, option_list, _join_fields(option_descriptions, "\t"), format("{}\t{}", min_args, max_args)];
    }

    function _add_command(string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint8 max_args, string[] option_descriptions) internal pure returns (string[]) {
        return [command, purpose, synopsis, description, option_list, _join_fields(option_descriptions, "\t"), format("{}\t{}", min_args, max_args)];
    }

    function _init1() internal virtual;
    function init2() external virtual;
    function init3() external virtual;

    function _manual_name() internal pure virtual returns (string);

    function _init() internal override {
        _fs = _get_fs(1, "exportfs", ["commands"]);
        _create_device(ROOT_DIR + 1, DeviceInfo(BLK_DEVICE, _dc++, _manual_name(), 1024, 100, address(this)));
        _sb_exports.push(_get_export_sb(_fs.ic, 0, "commands"));

        _init1();
        this.init2();
        this.init3();
    }

}
