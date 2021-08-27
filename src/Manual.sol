pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "Device.sol";

abstract contract Manual is Device {

    uint8 constant M = 255;

    function _insert(string command, uint8 min_args, uint8 max_args, string purpose, string synopsis,
                        string description, string option_list, string[] option_descriptions) internal pure returns (string) {
        return command + "\n" + purpose + "\n" + synopsis + "\n" + description +"\n" +
            option_list + "\n" + _join_fields(option_descriptions) + format("\n{}\t{}\n", min_args, max_args);
    }

    function _insert_whole(string command_combined, uint8 min_args, uint8 max_args, string[] option_descriptions) internal pure returns (string) {
        return command_combined + _join_fields(option_descriptions) + format("\n{}\t{}\n", min_args, max_args);
    }

    function _init1() internal virtual;
    function init2() external virtual;
    function init3() external virtual;

    function _make_fs() internal {
        _create_fs("ManualFS", 1, ["commands"]);
        _add_primary_device("sdb", 1024, 100);
    }

    function _init() internal override {
        _make_fs();
        _sb_exports.push(_get_export_sb(_ic, 0));
        _init1();
        this.init2();
        this.init3();
    }
}
