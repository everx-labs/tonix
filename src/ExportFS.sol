pragma ton-solidity >= 0.48.0;

import "INode.sol";
import "IMount.sol";

struct ExportDirS {
    string path;
    INodeS[] files;
}

abstract contract ExportFS is INode {

    ExportDirS[] public _exports;

    function export(string path, uint16 mount_point) external view {
        for (ExportDirS d: _exports)
            if (path == d.path)
                IMount(msg.sender).mount_dir{value: 0.2 ton}(mount_point, d.files);
    }

    function _get_export(string path) private view returns (uint16, uint16) {
        for (uint16 i = 0; i < uint16(_exports.length); i++)
            if (_exports[i].path == path)
                return (i, uint16(_exports[i].files.length));
        return (0, 0);
    }
    function export_all(string path, uint16 mount_point, uint16 chunks) external view {
        (uint16 idx, uint16 len) = _get_export(path);
        if (len > 0) {
            uint16 chunk_size = len / chunks;
            for (uint16 i = 0; i < chunks; i++)
                IMount(msg.sender).mount_dir{value: 0.2 ton}(mount_point, _get_chunk(idx, i * chunk_size, chunk_size));
            IMount(msg.sender).mount_dir{value: 0.2 ton}(mount_point, _get_chunk(idx, chunks * chunk_size, len - chunks * chunk_size));
        }
    }

    function _get_chunk(uint16 id, uint16 start, uint16 count) private view returns (INodeS[] exports) {
        if (id < uint16(_exports.length)) {
            ExportDirS d = _exports[id];
            if (start + count < uint16(d.files.length))
            for (uint16 i = start; i < start + count; i++)
                exports.push(d.files[i]);
        }
    }
}
