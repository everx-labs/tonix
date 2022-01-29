pragma ton-solidity >= 0.56.0;

import "include/Base.sol";
import "lib/fmt.sol";

struct Image {
    uint16 version;
    string name;
    address addr;
    TvmCell code;
    uint32 updated_at;
}

contract Repo {

    uint32 public _counter = 10;
    bool public _live_update = true;

    Image[] public _images;

    function set_live_update(bool flag) external accept {
        _live_update = flag;
    }

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
        new Base{stateInit: si, value: 3 ton}();
    }

    function init_x(uint16 n, uint16 k) external accept {
        if (n == 1)
            _redeploy(k);
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
            _images.push(Image(0, name, addr, c, now));
            new Base{stateInit: si, value: 1 ton}();
        } else {
            Image img = _images[index - 1];
            (, , address addr, TvmCell code, ) = img.unpack();
            if (code != c) {
                img.version++;
                img.code = c;
                img.updated_at = now;
                _images[index - 1] = img;
                if (_live_update)
                    Base(addr).upgrade{value: 0.015 ton, flag: 1}(c);
            }
        }
    }

    function models() external view returns (string out) {
        Column[] columns_format = [
            Column(true, 3, fmt.ALIGN_LEFT),
            Column(true, 3, fmt.ALIGN_RIGHT),
            Column(true, 20, fmt.ALIGN_RIGHT),
            Column(true, 5, fmt.ALIGN_RIGHT),
            Column(true, 6, fmt.ALIGN_RIGHT),
            Column(true, 5, fmt.ALIGN_RIGHT),
            Column(true, 30, fmt.ALIGN_RIGHT),
            Column(true, 66, fmt.ALIGN_LEFT)];

        string[][] table = [["N", "ver", "Name", "cells", "bytes", "refs", "Updated at", "Address"]];
        for (uint i = 0; i < _images.length; i++) {
            Image img = _images[i];
            (uint16 version, string name, address addr, TvmCell code, uint32 updated_at) = img.unpack();
            (uint cells, uint bits, uint refs) = code.dataSize(1000);
            uint bytess = bits / 8;
            table.push([
                str.toa(i),
                str.toa(version),
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
            Column(true, 66, fmt.ALIGN_LEFT),
            Column(true, 20, fmt.ALIGN_LEFT)];

        string[][] table;
        for (uint i = 0; i < _images.length; i++) {
            Image img = _images[i];
            (, string name, address addr, , ) = img.unpack();
            table.push([
                format("{}", addr),
                name]);
        }
        out = fmt.format_table_ext(columns_format, table, "\t", "\n");
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
