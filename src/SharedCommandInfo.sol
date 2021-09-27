pragma ton-solidity >= 0.49.0;

import "Commands.sol";

abstract contract SharedCommandInfo is Commands {

    struct CmdInfoS {
        uint8 min_args;
        uint16 max_args;
        uint options;
    }
    mapping (uint8 => CmdInfoS) public _command_info;
    string[] public _command_names;

    function query_command_info() external view accept {
        SharedCommandInfo(msg.sender).update_command_info{value: 1 ton, flag: 1}(_command_names, _command_info);
    }

    function pull_backup_command_info() external pure accept {
        SharedCommandInfo(address.makeAddrStd(0, 0xcc59225a037b56f2cc325c9ced611994e160c4485537fe01ab3787e5d92ddac3)).query_command_info{value: 0.02 ton}();
    }

    function update_command_info(string[] command_names, mapping (uint8 => CmdInfoS) command_info) external accept {
        _command_names = command_names;
        _command_info = command_info;
    }

    function _command_index(string s) internal view returns (uint8) {
        for (uint8 i = 0; i < _command_names.length; i++)
            if (_command_names[i] == s)
                return i + 1;
    }

}
