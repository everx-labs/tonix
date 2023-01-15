pragma ton-solidity >= 0.65.0;
import "ged.sol";
import "libctl.sol";
import "libdis.sol";
import "libdis2.sol";

contract cbutch is ged {
    uint32 _flags;

    uint8 constant M_UNDEF = 0;
    uint8 constant M_RAW   = 1;
    uint8 constant M_SI    = 2;
    uint8 constant M_CODE  = 3;
    uint8 constant M_RDATA = 4;
    uint8 constant M_RREF  = 5;

    uint8 constant M_BINARY = 10;
M_FUNC
M_DICT
M_ISEL
M_MINT
M_MEXT
M_ESEL
M_PSEL
M_ISEL
M_C47
M_C74
M_C47_IS
M_CTR
M_C4_UOT
M_UP
M_OCUP

    uint8 constant M_TEMP  = 6;


    uint8 constant M_META  = 8;


    constructor(device_t pdev) public ged(pdev) {
        tvm.accept();
    }

    function conf(uint32 val) external {
        tvm.accept();
        _flags = val;
    }

    function 
}