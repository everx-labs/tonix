pragma ton-solidity >= 0.60.0;

import "protos.sol";
import "fmt.sol";

struct model {
    uint16 alloc_type;
    uint16 major_version;
    uint16 minor_version;
    uint32 updated_at;
    TvmCell code;
}

struct bio {
    uint16 ordinal;
    uint48 serial;
    bytes10 name;
    address addr;
}

struct proto {
    uint16 version;
    string name;
    address addr;
    TvmCell code;
    uint32 updated_at;
}

contract startup {

    proto[] _images;

    modifier accept {
        tvm.accept();
        _;
    }

    function update_model_at_index(uint16 index, string name, TvmCell c) external accept {
        if (index == 0) {
            TvmCell si = tvm.buildStateInit({code: c});
            address addr = address.makeAddrStd(0, tvm.hash(si));
            _images.push(proto(0, name, addr, c, now));
            new protos{stateInit: si, value: 1 ton}();
        } else {
            proto img = _images[index - 1];
            (, , address addr, TvmCell code, ) = img.unpack();
            if (code != c) {
                img.version++;
                img.code = c;
                img.updated_at = now;
                _images[index - 1] = img;
                protos(addr).upgrade{value: 0.015 ton, flag: 1}(c);
            }
        }
    }

    function disable(uint16 index) external accept {
        _images[index - 1].name = "inactive";
    }

    function models() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, fmt.LEFT),
            Column(true, 3, fmt.CENTER),
            Column(true, 20, fmt.LEFT),
            Column(true, 5, fmt.CENTER),
            Column(true, 6, fmt.RIGHT),
            Column(true, 5, fmt.RIGHT),
            Column(true, 30, fmt.LEFT),
            Column(true, 66, fmt.LEFT)];

        string[][] table = [["N", "ver", "Name", "cells", "bytes", "refs", "Updated at", "Address"]];
        for (uint i = 0; i < _images.length; i++) {
            proto img = _images[i];
            (uint16 version, string name, address addr, TvmCell code, uint32 updated_at) = img.unpack();
            (uint cells, uint bits, uint refs) = code.dataSize(10000);
            uint bytess = bits / 8;
            table.push([
                str.toa(i + 1),
                str.toa(version + 1),
                name,
                str.toa(cells),
                str.toa(bytess),
                str.toa(refs),
                fmt.ts(updated_at),
                format("{}", addr)]);
        }
        out = fmt.format_table_ext(columns_format, table, " ", "\n");
    }

    function etc_hosts() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 66, fmt.LEFT),
            Column(true, 20, fmt.LEFT)];

        string[][] table;
        for (uint i = 0; i < _images.length; i++) {
            proto img = _images[i];
            (, string name, address addr, , ) = img.unpack();
            table.push([
                format("{}", addr),
                name]);
        }
        out = fmt.format_table_ext(columns_format, table, "\t", "\n");
    }

    function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }

    function reset_storage() external accept {
        tvm.resetStorage();
    }

}
