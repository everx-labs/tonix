
pragma ton-solidity >= 0.66.0;

library libstr {
    function strchr(bytes s, byte c) internal returns (uint) {
        uint i;
        for (byte b: s) {
            if (b == c)
                return i + 1;
            i++;
        }
    }
    function strrchr(bytes s, byte c) internal returns (uint) {
        for (uint i = s.length; i > 0; i--)
            if (s[i - 1] == c)
                return i;
    }
    function strtok(bytes s, byte c) internal returns (uint[] pp) {
        uint i;
        for (byte b: s) {
            if (b == c)
                pp.push(i);
            i++;
        }
        pp.push(i);
    }
}