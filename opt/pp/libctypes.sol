pragma ton-solidity >= 0.67.0;

library libctype {

    function isspace(bytes1 c) internal returns (bool) {
        return c == ' ' || (c >= '\t' && c <= '\r');
    }

//    function isascii(byte c) internal returns (bool) {
//        return int8(c) & ~0x7f == 0;
//    }

    function isupper(bytes1 c) internal returns (bool) {
        return c >= 'A' && c <= 'Z';
    }

    function islower(bytes1 c) internal returns (bool) {
        return c >= 'a' && c <= 'z';
    }

    function isalpha(bytes1 c) internal returns (bool) {
        return isupper(c) || islower(c);
    }

    function isdigit(bytes1 c) internal returns (bool) {
        return c >= '0' && c <= '9';
    }

    function isxdigit(bytes1 c) internal returns (bool) {
        return isdigit(c) || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
    }

    function isprint(bytes1 c) internal returns (bool) {
        return c >= ' ' && c <= '~';
    }

    function toupper(bytes1 c) internal returns (bytes1) {
        uint8 v = uint8(c);
        if ((c >= 'a') && (c <= 'z'))
            return bytes1(v - 0x20);
        return c;
    }

    function tolower(bytes1 c) internal returns (bytes1) {
        uint8 v = uint8(c);
        if (c >= 'A' && c <= 'Z')
            return bytes1(v + 0x20);
        return c;
//        return c + 0x20 * ((c >= 'A') && (c <= 'Z'));
    }

    function isalnum(bytes1 c) internal returns (bool) {
        return isdigit(c) || isalpha(c);
    }
    function isident(bytes1 c) internal returns (bool) {
        return isalnum(c) || c == '_';
    }
    function isblank(bytes1 c) internal returns (bool) {
        return c == ' ' || c == '\t';
    }
//iscntrl() 	Check if character is a control character.
//isgraph() 	Check if character has graphical representation.
//ispunct() 	Check if character is a punctuation character.

}