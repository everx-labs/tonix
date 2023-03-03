pragma ever-solidity >= 0.66.0;

#define BUFFER_SIZE 1024

contract test {
    function f() external pure returns (uint n) {
        n = BUFFER_SIZE;
    }
}
