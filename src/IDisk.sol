pragma ton-solidity >= 0.48.0;

interface IDisk {
    function read(uint16 id, uint16 start, uint16 num) external;
    function write(uint16 id, bytes[] data) external;
}
