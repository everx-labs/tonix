pragma ton-solidity >= 0.67.0;
import "libflags.sol";
import "libpart.sol";
import "common.h";
contract label_loader is common {

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
