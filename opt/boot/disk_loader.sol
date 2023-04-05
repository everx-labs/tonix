pragma ton-solidity >= 0.67.0;
import "libpart.sol";
import "common.h";
import "libflags.sol";
contract disk_loader is common {
    uint8 constant UUDISK_LOC = 5;
    function read_ufs_disk() internal view returns (uufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a))
            return abi.decode(_ram[a], uufsd);
    }
    function read_disk() internal view returns (s_disk d, disklabel l, part_table pt) {
        uint32 a = libpart.LABELOFFSET;
        if (_ram.exists(a)) {
            d = abi.decode(_ram[a], s_disk);
            a = libpart.LABELSECTOR;
            if (_ram.exists(a)) {
                l = abi.decode(_ram[a], disklabel);
                a++;
                if (_ram.exists(a))
                    pt = abi.decode(_ram[a], part_table);
            }
        }
    }
}
