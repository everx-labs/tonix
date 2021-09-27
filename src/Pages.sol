pragma ton-solidity >= 0.49.0;

import "Commands.sol";

interface IPager {
    function add_page(string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) external;
}

abstract contract Pages is Commands {

    address _man_pager;

    function init() external accept {
        _init();
    }

    function _init() internal override {
        _man_pager = address.makeAddrStd(0, 0xcc59225a037b56f2cc325c9ced611994e160c4485537fe01ab3787e5d92ddac3);

        _init1();
        this.init2();
        this.init3();
    }

    function _init1() internal view virtual;
    function init2() external view virtual;
    function init3() external view virtual;

    function _add_page(string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) internal view {
        IPager(_man_pager).add_page{value: 0.1 ton, flag: 1}(command, purpose, synopsis, description,
                                    option_list, min_args, max_args, option_descriptions);
    }

}
