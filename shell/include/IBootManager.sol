pragma ton-solidity >= 0.50.0;

struct DeviceImage {
    uint8 version;
    uint16 construction_cost;
    string description;
    uint16 blk_size;
    uint16 n_blocks;
    TvmCell model;
    uint32 updated_at;
}

interface IBootManager {
    function init_images(mapping (uint8 => DeviceImage) images) external;
    function update_model(uint8 n, DeviceImage image) external;
    function upgrade_image(uint8 n, TvmCell c) external;
}
