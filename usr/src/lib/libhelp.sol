pragma ton-solidity >= 0.61.0;

import "libstring.sol";
import "fmt.sol";
import "utilhelp_h.sol";
library libhelp {

    function usage(CommandHelp ch) internal returns (string) {
        (string name, string synopsis, , string description, string options, , , , , ) = ch.unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
        string husage = "Usage: " + name + " " + synopsis;
        return libstring.join_fields([husage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
    }

}