pragma ton-solidity >= 0.48.0;

import "INode.sol";
import "IMount.sol";

struct ExportDirS {
    string path;
    uint16 n_files;
    uint16 n_batches;
    uint16 batch_size;
    INodeS[][] batches;
}

abstract contract ExportFS is INode {

    ExportDirS[] public _exports;
    uint16 _counter;

    function _get_export(string path) private view returns (ExportDirS) {
        for (uint16 i = 0; i < uint16(_exports.length); i++)
            if (_exports[i].path == path)
                return _exports[i];
    }

    function export_all(string path, uint16 mount_point) external view {
        ExportDirS d = _get_export(path);
        if (d.n_files > 0) {
            for (uint16 i = 0; i < d.n_batches; i++)
                IMount(msg.sender).mount_dir{value: 0.1 ton}(mount_point, d.batches[i]);
        }
    }
}
