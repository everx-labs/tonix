pragma ton-solidity >= 0.61.0;

import "libstring.sol";
import "fmt.sol";

struct CommandHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string notes;
    string author;
    string bugs;
    string see_also;
    string version;
}

library libhelp {

    function usage(CommandHelp ch) internal returns (string) {
        (string name, string synopsis, , string description, string options, , , , , ) = ch.unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
        string husage = "Usage: " + name + " " + synopsis;
        return libstring.join_fields([husage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n");
    }

}