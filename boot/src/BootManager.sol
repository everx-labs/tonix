pragma ton-solidity >= 0.51.0;

import "../include/IBootManager.sol";
import "../lib/SharedCommandInfo.sol";
import "../include/ICache.sol";
import "../lib/SyncFS.sol";

struct DeviceRecord {
    uint8 major_version;
    uint8 minor_version;
    uint8 status;
    uint32 assembly_time;
    address location;
}

interface IDeviceManager {
    function init_devices(DeviceInfo[] devices) external;
}

interface IManualPages {
    function assign_pages(address[] pages) external pure;
}

contract BootManager is Internal, IBootManager {

    mapping (uint8 => address) public _system;
    mapping (uint8 => DeviceInfo) _multi;

    mapping (uint8 => DeviceImage) public _images;
    DeviceRecord[] public _roster;
    uint32 public _counter = 10;
    bool public _live_update = false;

    mapping (uint8 => address) public _utils;

    function get_system_data() external view returns (mapping (uint8 => address) system, mapping (uint8 => string) device_names) {
        system = _system;
        for ((uint8 i, DeviceImage dev): _images)
            device_names[i] = dev.description;
    }

    function get_system_devices() external view returns (string devices) {
        for ((, DeviceInfo dev): _multi) {
            (uint8 major_id, uint8 minor_id, string name, uint16 block_size, uint16 n_blocks, address device_address) = dev.unpack();
            devices.append(format("{}\t{}\t{}\t{}\t{}\t{}\n", major_id, minor_id, name, block_size, n_blocks, device_address));
        }
    }

    function set_counter(uint32 n) external accept {
        _counter = n;
    }

    function set_live_update(bool flag) external accept {
        _live_update = flag;
    }

    function apply_image(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external view accept {
        SyncFS(_system[BlockDevice_c]).init_fs{value: 1 ton, flag: 1}(inodes, data);
    }

    function set_manuals(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external view accept {
        SyncFS(_system[ManualPages_c]).init_fs{value: 1 ton, flag: 1}(inodes, data);
    }

    function assign_pages() external view accept {
        _assign_pages();
    }

    function boost_pages() external view accept {
        _system[PagesStatus_c].transfer(5 ton, true, 1);
        _system[PagesCommands_c].transfer(5 ton, true, 1);
        _system[PagesSession_c].transfer(5 ton, true, 1);
        _system[PagesAdmin_c].transfer(5 ton, true, 1);
        _system[PagesUtility_c].transfer(5 ton, true, 1);
    }

    function setup_repo(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external view accept {
        SyncFS(_system[SourceRepo_c]).init_fs{value: 1 ton, flag: 1}(inodes, data);
    }

    function do_act(uint8 act, uint8[] actors) external view accept {
        if (act == 3)
            for (uint8 actor: actors)
                Base(_system[actor]).upgrade{value: 0.1 ton, flag: 1}(_images[actor].model);
        if (act == 4)
            for (uint8 actor: actors)
                Base(_system[actor]).reset_storage();
    }

    function _assign_pages() internal view {
        IManualPages(_system[ManualPages_c]).assign_pages(
            [_system[PagesStatus_c], _system[PagesCommands_c], _system[PagesSession_c], _system[PagesUtility_c], _system[PagesAdmin_c]]);
    }

    function init_x(uint8 n) external accept {
        if (n == 11)
            _deploy_media();
        if (n == 4)
            _assign_pages();
        if (n == 5)
            _assemble_device(TapeArchive_c);
        if (n == 6)
            _assemble_device(SourceRepo_c);
    }

    function deploy_system() external accept {
        _assemble_device(BlockDevice_c);
        _assemble_device(DeviceManager_c);
        for (uint8 i = 5; i < 16; i++)
            _assemble_device(i);
        _assemble_device(Configure_c);
//        for (uint8 i = 22; i < 27; i++)
//            _assemble_device(i);
        _live_update = true;
    }

    function _deploy_media() internal {
        _assemble_device(MediaStore_c);
        _assemble_device(StorageNode_c);
        _assemble_device(Collesistant_c);
    }

    function _assemble_device(uint8 n) internal returns (address addr) {
        (uint8 version, uint16 construction_cost, string description, uint16 block_size, uint16 n_blocks, TvmCell c, ) = _images[n].unpack();
        uint device_uid = (uint(block_size) << 80) + (uint(n_blocks) << 64) + (uint(version) << 40) + (uint(n) << 32) + _counter++;
        TvmCell new_si = tvm.buildStateInit({code: c, pubkey: device_uid});
        addr = address.makeAddrStd(0, tvm.hash(new_si));
        DeviceInfo dev = DeviceInfo(n, version, description, block_size, n_blocks, addr);
        new Base{stateInit: new_si, value: uint64(construction_cost) * 1e9}();
        _multi[n] = dev;
        _system[n] = addr;
        _roster.push(DeviceRecord(n, version, 0, now, addr));
    }

    function init_images(mapping (uint8 => DeviceImage) images) external override accept {
        _images = images;
        _system[AssemblyLine_c] = msg.sender;
        _system[BootManager_c] = address(this);
        (uint8 al_version, , string al_description, uint16 al_block_size, uint16 al_n_blocks, , ) = _images[AssemblyLine_c].unpack();
        _multi[AssemblyLine_c] = DeviceInfo(AssemblyLine_c, al_version, al_description, al_block_size, al_n_blocks, msg.sender);
        (uint8 bm_version, , string bm_description, uint16 bm_block_size, uint16 bm_n_blocks, , ) = _images[AssemblyLine_c].unpack();
        _multi[BootManager_c] = DeviceInfo(BootManager_c, bm_version, bm_description, bm_block_size, bm_n_blocks, address(this));
    }

    function update_model(uint8 n, DeviceImage image) external override accept {
        _images[n] = image;
    }

    function upgrade_image(uint8 n, TvmCell c) external override accept {
        DeviceImage image = _images[n];
        image.model = c;
        image.version++;
        image.updated_at = now;
        _images[n] = image;
        if (_live_update) {
            Base(_system[n]).upgrade{value: 0.1 ton, flag: 1}(c);
            _multi[n].minor_id = image.version;
        }
    }

    function roster() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, ALIGN_LEFT),
            Column(true, 3, ALIGN_LEFT),
            Column(true, 6, ALIGN_LEFT),
            Column(true, 66, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT)];

        string[][] table = [["MAJ", "MIN", "ST", "Address", "Deployed at"]];
        for (DeviceRecord record: _roster) {
            (uint8 major_version, uint8 minor_version, uint8 status, uint32 assembly_time, address location) = record.unpack();
            table.push([
                format("{}", major_version),
                format("{}", minor_version),
                format("{}", status),
                format("{}", location),
                _ts(assembly_time)]);
        }
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function system() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, ALIGN_LEFT),
            Column(true, 66, ALIGN_LEFT)];

        string[][] table = [["N", "Address"]];
        for ((uint8 n, address addr): _system)
            table.push([
                format("{}", n),
                format("{}", addr)]);
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function multi() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, ALIGN_LEFT),
            Column(true, 3, ALIGN_LEFT),
            Column(true, 20, ALIGN_LEFT),
            Column(true, 5, ALIGN_LEFT),
            Column(true, 6, ALIGN_LEFT),
            Column(true, 66, ALIGN_LEFT)];

        string[][] table;
        for ((, DeviceInfo dev): _multi) {
                (uint8 major_id, uint8 minor_id, string name, uint16 block_size, uint16 n_blocks, address device_address) = dev.unpack();
                table.push([
                    format("{}", major_id),
                    format("{}", minor_id),
                    name,
                    format("{}", block_size),
                    format("{}", n_blocks),
                    format("{}", device_address)]);
        }
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function etc_hosts() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 66, ALIGN_LEFT),
            Column(true, 20, ALIGN_LEFT)];

        string[][] table;
        for ((uint8 n, address addr): _system)
            table.push([
                format("{}", addr),
                _images[n].description]);
        out = _format_table_ext(columns_format, table, "\t", "\n");
    }

    function update_code(TvmCell c) external {
        tvm.accept();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }
}
