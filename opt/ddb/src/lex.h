pragma ton-solidity >= 0.64.0;
contract lex_const {
    modifier accept {
        tvm.accept();
        _;
    }
    byte constant tEOF              = 0xFF;
    byte constant t0                = 0x00;
    byte constant tEOL              = 0x01;
    byte constant tNUMBER           = 0x02;
    byte constant tIDENT            = 0x03;
    byte constant tPLUS             = 0x04;
    byte constant tMINUS            = 0x05;
    byte constant tDOT              = 0x06;
    byte constant tSTAR             = 0x07;
    byte constant tSLASH            = 0x08;
    byte constant tEQ               = 0x09;
    byte constant tLPAREN           = 0x0A;
    byte constant tRPAREN           = 0x0B;
    byte constant tPCT              = 0x0C;
    byte constant tHASH             = 0x0D;
    byte constant tCOMMA            = 0x0E;
    byte constant tDITTO            = 0x0F;
    byte constant tDOLLAR           = 0x10;
    byte constant tEXCL             = 0x11;
    byte constant tSHIFT_L          = 0x12;
    byte constant tSHIFT_R          = 0x13;
    byte constant tDOTDOT           = 0x14;
    byte constant tSEMI             = 0x15;
    byte constant tLOG_EQ           = 0x16;
    byte constant tLOG_NOT_EQ       = 0x17;
    byte constant tLESS             = 0x18;
    byte constant tLESS_EQ          = 0x19;
    byte constant tGREATER          = 0x1A;
    byte constant tGREATER_EQ       = 0x1B;
    byte constant tBIT_AND          = 0x1C;
    byte constant tBIT_OR           = 0x1D;
    byte constant tLOG_AND          = 0x1E;
    byte constant tLOG_OR           = 0x1F;
    byte constant tSTRING           = 0x20;
    byte constant tQUESTION         = 0x21;
    byte constant tBIT_NOT          = 0x22;
    byte constant tWSPACE           = 0x23;
    byte constant tCOLON            = 0x24;
    byte constant tCOLONCOLON       = 0x25;
}