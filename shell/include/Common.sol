pragma ton-solidity >= 0.51.0;

struct DeviceInfo {
    uint8 major_id;
    uint8 minor_id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
    address device_address;
}

abstract contract Common {
    uint8 constant DataVolume_c     = 1;
    uint8 constant DeviceManager_c  = 2;
    uint8 constant AccessManager_c  = 3;
    uint8 constant StaticBackup_c   = 4;
    uint8 constant BlockDevice_c    = 5;
    uint8 constant FileManager_c    = 6;
    uint8 constant StatusReader_c   = 7;
    uint8 constant PrintFormatted_c = 8;
    uint8 constant SessionManager_c = 9;
    uint8 constant ManualPages_c    = 10;
    uint8 constant PagesStatus_c    = 11;
    uint8 constant PagesCommands_c  = 12;
    uint8 constant PagesSession_c   = 13;
    uint8 constant PagesUtility_c   = 14;
    uint8 constant PagesAdmin_c     = 15;
    uint8 constant AssemblyLine_c   = 16;
    uint8 constant BootManager_c    = 17;
    uint8 constant TextBlocks_c     = 18;
    uint8 constant BuildFileSys_c   = 19;
    uint8 constant Configure_c      = 20;
    uint8 constant TapeArchive_c    = 21;
    uint8 constant SourceRepo_c     = 22;
    uint8 constant MediaStore_c     = 23;
    uint8 constant StorageNode_c    = 24;
    uint8 constant ls_c             = 25;
    uint8 constant Collesistant_c   = 26;

    modifier accept {
        tvm.accept();
        _;
    }


}
