pragma ton-solidity >= 0.48.0;

import "IRepo.sol";
import "Disk.sol";

contract Repo is IRepo {

    uint8 _ver = 0;
    uint16 _counter = _ver * 10;
    uint8 _initialBalance = 5;
    TvmCell _si;
    mapping (uint8 => TvmCell) public _images;

    modifier accept {
        tvm.accept();
        _;
    }

    uint16 constant DEFAULT_LOG_LEVEL = 31;
    uint16 constant ROOT_ID     = 30;
    uint64 constant REIMBURSE   = 3e8;

    address public _deployed;
    mapping (uint16 => address) public _disks;
    uint16 public _dc;

    /* Machinery */
    function _deploy(uint8 n, TvmCell c, uint8 gr) private pure {
        uint128 val = uint128(gr) * 1e9;
        if (n == 1)
            new Disk {stateInit:c, value:val}();
    }

    function _spawn(uint8 n) private returns (address) {
        TvmCell signed = tvm.insertPubkey(_si, _counter++);
        address addr = address(tvm.hash(signed));
        _deploy(n, signed, _initialBalance);
        return addr;
    }

    function deploy() external accept {
        _deployed = _spawn(1);
    }

    function dd() external accept returns(address addr) {
        TvmCell signed = tvm.insertPubkey(_images[2], _dc);
        addr = new Disk {stateInit: signed, value: 10 ton}();
        _disks[_dc++] = addr;
    }

    function setdc(uint16 n) external accept {
        _dc = n;
    }
    function initAll() external accept {
    }
    /* Callbacks */
    function onDeploy(uint16 id) external override accept {
        if (id == id) {
            _deployed = msg.sender;
        }
    }

    function setImage(TvmCell c) external accept {
        _si = c;
    }

    function updateImage(uint8 n, TvmCell c) external accept {
        _images[n] = c;
    }

    function grant(address addr, uint128 value) external pure {
        tvm.accept();
        addr.transfer(value, false, 3);
    }

    function purgeRepo() external accept {
        delete _si;
    }

    function upgrade(TvmCell c) external {
//        require(msg.pubkey() == tvm.pubkey(), 100);
        TvmCell newcode = c.toSlice().loadRef();
        tvm.accept();
        tvm.commit();
        tvm.setcode(newcode);
        tvm.setCurrentCode(newcode);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
        tvm.resetStorage();
    }
}

