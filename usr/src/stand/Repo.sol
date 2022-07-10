pragma ton-solidity >= 0.61.0;

import "Base.sol";
import "fmt.sol";

struct Image {
    uint16 version;
    string name;
    address addr;
    TvmCell code;
    uint32 updated_at;
}

contract Repo {

    uint32 public _counter = 10;

    Image[] public _images;

    modifier accept {
        tvm.accept();
        _;
    }

    function _redeploy(uint16 index) internal {
        Image img = _images[index - 1];
        TvmCell si = tvm.buildStateInit({code: img.code});
        img.addr = address.makeAddrStd(0, tvm.hash(si));
        img.version++;
        img.updated_at = now;
        _images[index - 1] = img;
        new Base{stateInit: si, value: 1 ton}();
    }

    function init_x(uint16 n, uint16 k) external accept {
        if (n == 1)
            _redeploy(k);
    }

    function add_model(string name, TvmCell c) external accept {
        _add_model(name, c);
    }

    function _add_model(string name, TvmCell c) internal {
        TvmCell si = tvm.buildStateInit({code: c});
        _images.push(Image(0, name, address.makeAddrStd(0, tvm.hash(si)), c, now));
        new Base{stateInit: si, value: 1 ton}();
    }
    function update_model_at_index(uint16 index, TvmCell c) external {
        Image img = _images[index - 1];
        (, , address addr, TvmCell code, ) = img.unpack();
        require(code != c, 222);
        tvm.accept();
        img.version++;
        img.code = c;
        img.updated_at = now;
        _images[index - 1] = img;
        Base(addr).upgrade{value: 0.015 ton, flag: 1}(c);
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
            Image img = _images[i];
            (uint16 version, string name, address addr, TvmCell code, uint32 updated_at) = img.unpack();
            (uint cells, uint bits, uint refs) = code.dataSize(1000);
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
        Column[] columns_format = [Column(true, 66, fmt.LEFT), Column(true, 20, fmt.LEFT)];

        string[][] table;
        for (uint i = 0; i < _images.length; i++) {
            Image img = _images[i];
            (, string name, address addr, , ) = img.unpack();
            table.push([format("{}", addr), name]);
        }
        out = fmt.format_table_ext(columns_format, table, "\t", "\n");
    }

    function erase() external accept() {
        _images.pop();
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
