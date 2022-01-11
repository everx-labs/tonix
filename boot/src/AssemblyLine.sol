pragma ton-solidity >= 0.52.0;

//import "../../include/Base.sol";
//import "../include/Common.sol";
//import "../include/IBootManager.sol";
//import "../lib/Format.sol";

struct DeviceRecord {
    uint8 major_version;
    uint8 minor_version;
    uint8 status;
    uint32 assembly_time;
    address location;
}

contract AssemblyLine is Common, Format {

    uint16 constant DEFAULT_TOLL = 5;
    uint32 public _counter;

    mapping (uint16 => address) public _system;

    mapping (uint8 => DeviceImage) public _images;
    DeviceRecord[] public _roster;

    address public _boot_manager;
    bool public _sync_boot_manager;

    function deploy_boot_manager() external accept {
        _boot_manager = _assemble_standard_device(BootManager_c);
        _init_boot_manager();
    }

    function init_boot_manager() external accept {
        _init_boot_manager();
    }

    function _init_boot_manager() internal {
        _sync_boot_manager = true;
        IBootManager(_boot_manager).init_images{value: 1 ton,flag: 1}(_images);
    }

    function assemble_standard_device(uint8 n) external accept {
        _assemble_standard_device(n);
    }

    function _assemble_standard_device(uint8 n) internal returns (address addr) {
        (uint8 version, uint16 construction_cost, , uint16 block_size, uint16 n_blocks, TvmCell si, ) = _images[n].unpack();
        addr = _assemble_device(n, version, construction_cost, block_size, n_blocks, si);
        _system[n] = addr;
    }

    function assemble_custom_device(uint8 n, uint16 block_size, uint16 n_blocks) external accept {
        (uint8 version, uint16 construction_cost, , , , TvmCell si, ) = _images[n].unpack();
        _assemble_device(n, version, construction_cost, block_size, n_blocks, si);
    }

    function _assemble_device(uint8 n, uint8 version, uint16 construction_cost, uint16 block_size, uint16 n_blocks, TvmCell si) internal returns (address addr) {
        uint device_uid = (uint(block_size) << 80) + (uint(n_blocks) << 64) + (uint(version) << 40) + (uint(n) << 32) + _counter++;
//        TvmCell new_si = tvm.insertPubkey(si, device_uid);
        TvmCell new_si = tvm.buildStateInit({code: si, pubkey: device_uid});
        addr = address.makeAddrStd(0, tvm.hash(new_si));
        new Base{flag: 1, stateInit: new_si, value: uint64(construction_cost) * 1e9}();
        _roster.push(DeviceRecord(n, version, 0, now, addr));
    }

    function update_model(uint8 n, uint16 construction_cost, string description, uint16 block_size, uint16 n_blocks, TvmCell c) external accept {
        uint8 version = _images.exists(n) ? _images[n].version : 0;
        DeviceImage image = DeviceImage(version++, construction_cost, description, block_size, n_blocks, c, now);
        _images[n] = image;
        if (_sync_boot_manager)
            IBootManager(_boot_manager).update_model{value: 0.1 ton,flag: 1}(n, image);
    }

    function upgrade_image(uint8 n, TvmCell c) external accept {
        DeviceImage image = _images[n];
        image.model = c;
        image.version++;
        image.updated_at = now;
        if (_sync_boot_manager)
            IBootManager(_boot_manager).upgrade_image{value: 0.1 ton,flag: 1}(n, c);
        _images[n] = image;
    }

    function models() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, ALIGN_LEFT),
            Column(true, 3, ALIGN_LEFT),
            Column(true, 3, ALIGN_LEFT),
            Column(true, 20, ALIGN_LEFT),
            Column(true, 5, ALIGN_LEFT),
            Column(true, 6, ALIGN_LEFT),
            Column(true, 4, ALIGN_LEFT),
            Column(true, 15, ALIGN_LEFT),
            Column(true, 4, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT)];

        string[][] table = [["N", "ver", "C$", "Device model", "BSIZE", "BLOCKS", "CELL", "BYTES", "REFS", "Updated at"]];
        for ((uint8 n, DeviceImage image): _images) {
            (uint8 version, uint16 construction_cost, string name, uint16 block_size, uint16 n_blocks, TvmCell si, uint32 ts) = image.unpack();
            (uint cells, uint bits, uint refs) = si.dataSize(1000);
            uint bytess = bits / 8;
            table.push([
                format("{}", n),
                format("{}", version),
                format("{}", construction_cost),
                name,
                format("{}", block_size),
                format("{}", n_blocks),
                format("{}", cells),
                format("{}", bytess),
                format("{}", refs),
                _ts(ts)]);
        }
        out = _format_table_ext(columns_format, table, " ", "\n");
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
        for ((uint16 n, address addr): _system)
            table.push([
                format("{}", n),
                format("{}", addr)]);
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function etc_boot() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 66, ALIGN_LEFT),
            Column(true, 20, ALIGN_LEFT)];

        string[][] table;
        for ((uint16 n, address addr): _system)
            table.push([
                format("{}", addr),
                _images[uint8(n)].description]);
        out = _format_table_ext(columns_format, table, "\t", "\n");
    }

    function update_code(TvmCell c) external {
        tvm.accept();
//        TvmCell newcode = c.toSlice().loadRef();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

    function reset_storage() external accept {
        tvm.resetStorage();
    }

}
