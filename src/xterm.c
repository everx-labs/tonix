#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned const NO_ACTION        = 0;
unsigned const PRINT_STATUS     = 1;
unsigned const FILE_OP          = 2;
unsigned const WRITE_FILES      = 4;
unsigned const UPDATE_NODES     = 8;
unsigned const PROCESS_COMMAND  = 16;
unsigned const FORMAT_TEXT      = 32;
unsigned const PRINT_ERRORS     = 64;
unsigned const IO_EVENT         = 128;
unsigned const READ_INDEX       = 256;
unsigned const CHECK_STATUS     = 512;
unsigned const OPEN_DIR         = 2048;
unsigned const CHANGE_DIR       = 4096;
unsigned const PIPE_OUT_TO_FILE = 8192;
unsigned const MOUNT_FS         = 16384;
unsigned const OPEN_FILE        = 32768;

unsigned const EXT_NO_ACTION    = 0;
unsigned const EXT_READ_IN      = 1;
unsigned const EXT_WRITE_IN     = 2;
unsigned const EXT_MAP_FILE     = 4;
unsigned const EXT_OPEN_FILE    = 8;
unsigned const EXT_READ_DIR     = 16;
unsigned const EXT_PIPE_TO      = 32;
unsigned const EXT_OPEN_DIR     = 64;
unsigned const EXT_READ_TREE    = 128;
unsigned const EXT_OPEN_TREE    = 256;
unsigned const EXT_WRITE_FILES  = 512;
unsigned const EXT_ACCOUNT      = 2048;
unsigned const EXT_CHANGE_DIR   = 4096;
unsigned const EXT_MOUNT_FS     = 8192;
unsigned const EXT_SPAWN        = 16384;

char *login;
char *cwd;

void a2h(char* input, char* output) {
    int loop = 0, i = 0;

    while(input[loop] != '\0') {
        sprintf((char*)(output + i),"%02X", input[loop]);
        loop += 1;
        i += 2;
    }
    output[i++] = '\0';
}

int _prompt(char *s) {
/**********************************************************
    Read line from stdin
**********************************************************/
    if (strchr(s, '\n')) {
        int lf_i = strchr(s, '\n') - s;
        s[lf_i] = '\0';
    }

    char *s2 = strdup(s);
/**********************************************************
    Break it into space-separated tokens
**********************************************************/
    char *t = strtok(s, " ");
    char *cmds = strdup(t);
    int x = 0;
    char *args[10];
    t = strtok(NULL, " ");
    while(t) {
        args[x++] = strdup(t);
        t = strtok(NULL, " ");
    }

    if (!(strcmp(cmds, "quit"))) {
        printf("Bye.\n");
        exit(0);
    }
    if (!(strcmp(cmds, "x"))) {
        char *c, *o;
        if (x > 0) {
            c = args[0];
            if (!(strcmp(c, "db")))
                system("make d_BlockDevice");
            if (!(strcmp(c, "dc")))
                system("make d_CommandProcessor");
        }
        return 0;
    }
    if (!(strcmp(cmds, "sh"))) {
        char buffer[200];
        sprintf(buffer, "%s", &s2[strlen(cmds) + 1]);
        system(buffer);
        return 0;
    }

    char mega[30000];
    char *pm = mega;

    FILE *fp = fopen("std/s_input", "wt");
    fwrite(s2, 1, strlen(s2), fp);
    fclose(fp);

    unsigned action = 0, ext_action = 0, action2 = 0, action3 = 0;
    system("make ru g=parse");

    fp = fopen("vfs/proc/2/action", "rt");
    fscanf(fp, "%u", &action);
    fclose(fp);
    fp = fopen("vfs/proc/2/ext_action", "rt");
    fscanf(fp, "%u", &ext_action);
    fclose(fp);

    if (action & PRINT_ERRORS) {
        system("make ru g=print_error_message");
        return 0;
    }

    if (action & READ_INDEX) {
        system("make ru g=read_indices");
        system("make ru g=format_text");
    }

    if (ext_action & EXT_OPEN_FILE) {
        system("make copy_in");
        system("make vfs/proc/2/op_table");
        system("make ru g=process_file_list");
        system("make ru g=_proc");
        system("make ca g=update_nodes");
    }

    if (ext_action & EXT_ACCOUNT)
        system("make account_data");

    /*if (action & MOUNT_FS) {
        system("jq -r '.addresses[]' < std/parse.out >std/addresses");
        system("jq 'del(.std,.action,.input,.redirect)' < std/parse.out > std/request_mount.args");
        system("make std/request_mount");
    }
    if (action & OPEN_DIR) {
        system("rm -f std/dirs_to_open std/files_to_open");
        system("make std/dirs_to_open");
        system("make std/files_to_open");
        system("make std/carr");
        system("make std/mount_el");
    }*/

    if (action & PRINT_STATUS) {
        system("make ru g=fstat");
        fp = fopen("vfs/proc/2/action", "rt");
        fscanf(fp, "%u", &action2);
        fclose(fp);
        if (action2 & PRINT_ERRORS)
            system("make ru g=print_error_message");
    }

    if (action & PROCESS_COMMAND)
        system("make ru g=process_command");
    else if (action & FILE_OP) {
        system("make ru g=file_op");
        fp = fopen("vfs/proc/2/action", "rt");
        fscanf(fp, "%u", &action3);
        fclose(fp);
    }

    if (action3 & PRINT_ERRORS)
        system("make ru g=print_error_message");

    if (action & PIPE_OUT_TO_FILE) {
        system("make std/text_in");
        system("make ca g=write_to_file");
    }

    if (ext_action & EXT_WRITE_FILES) {
        system("make write_all");
    }

    if (action3 & UPDATE_NODES)
        system("make ca g=update_nodes");

    // !!! jq '.u | del(.std) | .[] | select (length > 0)' < get.out !!!
    return 0;
}

int main(int argc, char **argv) {

    size_t lsize = 32;
    login = (char *)malloc(lsize);
    FILE *fp = fopen("std/login", "rt");
    if (!fp) {
        printf("login: ");
        getline(&login, &lsize, stdin);
        int len = strlen(login);
        fp = fopen("std/login", "wt");
        fwrite(login, 1, len, fp);
        fclose(fp);
    } else {
        fscanf(fp, "%s", login);
        fclose(fp);
    }

    printf("Logged in as: %s\n", login);

    /*size_t cwdsize = 32;
    cwd = (char *)malloc(cwdsize);
    FILE *cfp = fopen("vfs/proc/2/cwd", "rt");
    if (!cfp) {
        cfp = fopen("vfs/proc/2/cwd", "wt");
        fwrite("/", 1, 1, cfp);
        fclose(cfp);
    } else {
        fscanf(cfp, "%s", cwd);
        fclose(cfp);
    }

    printf("Working dir: %s\n", cwd);*/

    setbuf(stdout, NULL);
    system("cat etc/motd");
    while (1) {

        printf("$ ");
        size_t size = 20000;
        char *s = (char *)malloc(size);
        getline(&s, &size, stdin);
        int ret = _prompt(s);

        if (ret > 0) {
            printf("??? Session failed?\n");
            exit(0);
        }
    }
}
