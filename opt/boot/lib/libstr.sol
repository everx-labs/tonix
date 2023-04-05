pragma ton-solidity >= 0.67.0;

library libstr {
    function strchr(bytes s, bytes1 c) internal returns (uint) {
        uint i;
        for (bytes1 b: s) {
            if (b == c)
                return i + 1;
            i++;
        }
    }
    function strrchr(bytes s, bytes1 c) internal returns (uint) {
        for (uint i = s.length; i > 0; i--)
            if (s[i - 1] == c)
                return i;
    }
    function strtok(bytes s, bytes1 c) internal returns (uint[] pp) {
        uint i;
        for (bytes1 b: s) {
            if (b == c)
                pp.push(i);
            i++;
        }
        pp.push(i);
    }
}
