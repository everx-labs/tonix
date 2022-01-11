pragma ton-solidity >= 0.51.0;

import "../include/Base.sol";
import "../include/Common.sol";
import "../lib/Format.sol";

struct BuiltinImage {
    uint8 version;
    string name;
    address addr;
    TvmCell code;
    uint32 updated_at;
}

contract CommandInterpreter is Format {

    uint32 public _counter = 10;
    bool public _live_update = true;

    BuiltinImage[] public _images;

    function set_live_update(bool flag) external accept {
        _live_update = flag;
    }

    modifier accept {
        tvm.accept();
        _;
    }

//    function _redeploy(string name) internal {
//        uint index = _get_image_index(name);
    function _redeploy(uint8 index) internal {
        BuiltinImage img = _images[index - 1];
        TvmCell si = tvm.buildStateInit({code: img.code});
        img.addr = address.makeAddrStd(0, tvm.hash(si));
        img.version++;
        img.updated_at = now;
        _images[index - 1] = img;
        new Base{stateInit: si, value: 3 ton}();
    }

    function init_x(uint8 n, uint8 k) external accept {
        if (n == 1)
            _redeploy(k);
/*        if (n == 1)
            _deploy_media();
        if (n == 4)
            _assign_pages();
        if (n == 5)
            _assemble_device(TapeArchive_c);
        if (n == 6)
            _assemble_device(SourceRepo_c);*/
    }

    function _get_image_index(string name) internal view returns (uint) {
        for (uint i = 0; i < _images.length; i++)
            if (_images[i].name == name)
                return i + 1;
    }

    function update_model(string name, TvmCell c) external accept {
        uint index = _get_image_index(name);
        if (index == 0) {
            TvmCell si = tvm.buildStateInit({code: c});
            address addr = address.makeAddrStd(0, tvm.hash(si));
            _images.push(BuiltinImage(0, name, addr, c, now));
            new Base{stateInit: si, value: 3 ton}();
        } else {
            BuiltinImage img = _images[index - 1];
            (, , address addr, TvmCell code, ) = img.unpack();
            if (code != c) {
                img.version++;
                img.code = c;
                img.updated_at = now;
                _images[index - 1] = img;
                if (_live_update)
                    Base(addr).upgrade{value: 0.1 ton, flag: 1}(c);
            }
        }
    }

    function models() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, ALIGN_LEFT),
            Column(true, 3, ALIGN_LEFT),
            Column(true, 20, ALIGN_LEFT),
            Column(true, 5, ALIGN_LEFT),
            Column(true, 6, ALIGN_LEFT),
            Column(true, 5, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT),
            Column(true, 66, ALIGN_LEFT)];

        string[][] table = [["N", "ver", "Name", "cells", "bytes", "refs", "Updated at", "Address"]];
        for (uint i = 0; i < _images.length; i++) {
            BuiltinImage img = _images[i];
            (uint8 version, string name, address addr, TvmCell code, uint32 updated_at) = img.unpack();
            (uint cells, uint bits, uint refs) = code.dataSize(1000);
            uint bytess = bits / 8;
            table.push([
                format("{}", i),
                format("{}", version),
                name,
                format("{}", cells),
                format("{}", bytess),
                format("{}", refs),
                _ts(updated_at),
                format("{}", addr)]);
        }
        out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function etc_hosts() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 66, ALIGN_LEFT),
            Column(true, 20, ALIGN_LEFT)];

        string[][] table;
        for (uint i = 0; i < _images.length; i++) {
            BuiltinImage img = _images[i];
            (, string name, address addr, , ) = img.unpack();
            table.push([
                format("{}", addr),
                name]);
        }
        out = _format_table_ext(columns_format, table, "\t", "\n");
    }

    function upgrade_code(TvmCell c) external {
        tvm.accept();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

    function reset_storage() external accept {
        tvm.resetStorage();
    }

    /*onBounce(TvmSlice slice) external {
        uint32 functionId = slice.decode(uint32);
//        _roster.push(DeviceRecord(0, 0, 0, functionId, msg.sender));
	}*/
}
