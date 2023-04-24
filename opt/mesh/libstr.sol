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
    function toa(uint num) internal returns (string) {
        return format("{}", num);
    }

    function split(bytes s, bytes1 c) internal returns (bytes[] pp) {
        uint i;
        uint p;
        for (bytes1 b: s) {
            i++;
            if (b == c) {
                pp.push(s[p : i - 1]);
                p = i;
            }
        }
        pp.push(s[p : ]);
    }

    /* File size display helpers */
    uint16 constant KILO = 1024;

    function scale(uint32 n, uint32 factor) internal returns (string) {
        if (n < factor || factor == 1)
            return format("{:6}", n);
        if (factor == KILO) {
            (uint d, uint m) = math.divmod(n, factor);
            return d > 10 ? format("{:5}K", d) : format("{:3}.{:02}K", d, m / 100);
        }
        return format("Invalid scale factor: {}", factor);
    }

    function join(string[] items) internal returns (string res) {
        return join(items, " ");
    }
    function join(string[] items, string separator) internal returns (string res) {
        uint len = items.length;
        if (len > 0) {
            res = items[0];
            for (uint i = 1; i < len; i++)
                res.append(separator + items[i]);
        }
    }
}
