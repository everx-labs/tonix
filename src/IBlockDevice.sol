pragma ton-solidity >= 0.48.0;

interface IBlockDevice {
    function write_text_file(uint16 id, uint8 mode, string text) external;
    function query_fs_cache() external;
}
