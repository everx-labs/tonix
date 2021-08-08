pragma ton-solidity >= 0.48.0;

import "IDisk.sol";

contract Disk is IDisk {

    struct BlockS {
        bytes[] data;
    }
    mapping (uint16 => BlockS) public _blocks;
    uint16 public _blkc;

    struct FileIn {
        uint16 ord;
        string filename;
        uint16 nblk;
        uint32 fsize;
    }
    struct FileDes {
        uint16 mode;
        uint16 inode;
        string filename;
        uint16 nblk_in;
        uint16 nblk_act;
        uint32 fsize_in;
        uint32 fsize_act;
    }
    mapping (uint16 => FileDes) public _fdes;
    uint16 public _fdc;

    struct FileInfo {
        uint8 filetype;
        string filename;
        uint16 inode;
        uint16 nBlocks;
        uint32 filesize;
        uint32 created_at;
        uint32 modified_at;
    }
    mapping (uint16 => FileInfo) public _fi;
    uint16 public _inc = 10;

    mapping (uint16 => bytes[]) public _storage;

    constructor() public {
        tvm.accept();
    }

    function creat(uint8 filetype, string filename, uint16 nBlocks, uint32 filesize) external returns (uint16 fd) {
//        uint16 inode = _inc++;
//        _fi[inode] = FileInfo(filetype, filename, inode, nBlocks, filesize, now, now);
         tvm.accept();
       fd = _fdc++;
        _fdes[fd] = FileDes(filetype, fd, filename, nBlocks, 0, filesize, 0);
            for (uint16 j = 0; j < nBlocks; j++)
                _storage[fd].push("");
    }

    function open_all(uint8 filetype, FileIn[] fins) external returns (mapping (uint16 => uint16) fds) {
        tvm.accept();
        uint16 len = uint16(fins.length);
        uint16 fdc = _fdc;
        for (uint16 i = 0; i < len; i++) {
            FileIn fin = fins[i];
            _fdes[fdc] = FileDes(filetype, fdc, fin.filename, fin.nblk, 0, fin.fsize, 0);
            for (uint16 j = 0; j < fin.nblk; j++)
                _storage[fdc].push("");
            fds[fin.ord] = fdc;
//            _fi[inc + i] = FileInfo(filetype, fin.filename, inc + i, fin.nblk, fin.fsize, now, now);
            fdc++;
        }
        _fdc += len;
    }

    function read(uint16 id, uint16 start, uint16 num) external override {
        tvm.accept();
        bytes[] bts;
        for (uint16 i = start; i < start + num; i++)
            bts.push(_storage[id][i]);
        IDisk(msg.sender).write(id, bts);
    }

    function write(uint16 id, bytes[] data) external override {
        tvm.accept();
        for (bytes d: data)
            _storage[id].push(d);
    }

    function write_fd(uint16 fd, uint16 part, bytes data) external {
        tvm.accept();
        FileDes fds = _fdes[fd];
        _storage[fds.inode][part] = data;
        fds.nblk_act++;
        fds.fsize_act += uint32(data.length);
        if (fds.nblk_act == fds.nblk_in && fds.fsize_act == fds.fsize_in)
            fds.mode += 64;
        _fdes[fd] = fds;
    }

    function upgrade(TvmCell c) external {
        tvm.accept();
        TvmCell newcode = c.toSlice().loadRef();
        tvm.commit();
        tvm.setcode(newcode);
        tvm.setCurrentCode(newcode);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
        tvm.resetStorage();
        _cmd_proc = address.makeAddrStd(0, 0x8a2536f36663a597386f751f8095cfecd8c2b5134630c40cd03e7cff08faecd1);
        _bdev = address.makeAddrStd(0, 0x8924bcd820717eb57945888d3adddd6a99a227745f422092af768940fd1be69c);
    }

    function setEnv(address[] addrs) external {
        tvm.accept();
        _env = addrs;
    }

    function setPeer(address addr) external {
        tvm.accept();
        _peer = addr;
    }

    address[] public _env;
    address _peer;
    address _cmd_proc;
    address _bdev;
}
