pragma ton-solidity >= 0.48.0;

interface ISource {
    function query_command_names() external view;
    function query_errors() external view;
}
