pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract diff is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        if (params.length < 2) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            p.puts(libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n"));
            return p;
        }
        s_of f1 = p.fopen(params[0], "r");
        s_of f2 = p.fopen(params[1], "r");
        if (!f1.ferror()) {
            while (!f1.feof() && !f2.feof()) {
                string line1 = f1.fgetln();
                string line2 = f2.fgetln();
                if (line1 != line2) {
                    p.puts("< " + line1);
                    p.puts("---");
                    p.puts("> " + line2);
                }
            }
        } else
            p.perror("cannot open");
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"diff",
"[-aBbdipTtw] [-c | -e	| -f | -n | -q | -u | -y] file1 file2",
"differential file and directory comparator",
"Compares the contents of file1 and file2 and writes to the standard output the list of changes necessary to convert one file into the other.  No output is produced if the files are identical.",
"",
"",
"Written by Boris",
"",
"cmp(1), comm(1), diff3(1),	ed(1), patch(1), pr(1),	sdiff(1)",
"0.01");
    }
}
