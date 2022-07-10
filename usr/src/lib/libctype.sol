pragma ton-solidity >= 0.61.0;

library libctype {

    function isspace(byte c) internal returns (bool) {
        return c == ' ' || (c >= '\t' && c <= '\r');
    }

    function isascii(byte c) internal returns (bool) {
        return int8(c) & ~0x7f == 0;
    }

    function isupper(byte c) internal returns (bool) {
        return c >= 'A' && c <= 'Z';
    }

    function islower(byte c) internal returns (bool) {
        return c >= 'a' && c <= 'z';
    }

    function isalpha(byte c) internal returns (bool) {
        return isupper(c) || islower(c);
    }

    function isdigit(byte c) internal returns (bool) {
        return c >= '0' && c <= '9';
    }

    function isxdigit(byte c) internal returns (bool) {
        return isdigit(c) || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
    }

    function isprint(byte c) internal returns (bool) {
        return c >= ' ' && c <= '~';
    }

    function toupper(byte c) internal returns (byte) {
        uint8 v = uint8(c);
        if ((c >= 'a') && (c <= 'z'))
            return byte(v - 0x20);
        return c;
    }

    function tolower(byte c) internal returns (byte) {
        uint8 v = uint8(c);
        if (c >= 'A' && c <= 'Z')
            return byte(v + 0x20);
        return c;
//        return c + 0x20 * ((c >= 'A') && (c <= 'Z'));
    }

    function isalnum(byte c) internal returns (bool) {
        return isdigit(c) || isalpha(c);
    }
    function isblank(byte c) internal returns (bool) {
        return c == ' ' || c == '\t';
    }
//iscntrl() 	Check if character is a control character.
//isgraph() 	Check if character has graphical representation.
//ispunct() 	Check if character is a punctuation character.

}