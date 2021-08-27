#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned const NO_ACTION        = 0;
unsigned const PRINT_STATUS     = 1;
unsigned const PROCESS_COMMAND  = 2;
unsigned const ADD_NODES        = 4;
unsigned const UPDATE_NODES     = 8;
unsigned const IO_EVENT         = 128;
unsigned const CHECK_STATUS     = 512;
unsigned const OPEN_DIR         = 2048;
unsigned const CHANGE_DIR       = 4096;
unsigned const PIPE_OUT_TO_FILE = 8192;
unsigned const MOUNT_FS         = 16384;
unsigned const OPEN_FILE        = 32768;

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
//    getline(&s, &size, stdin);
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

/**********************************************************
    pack our findings to the contact as metadata
**********************************************************/
    /*int len = strlen(s2);
    char hex_str[(len * 2) + 1];
    a2h(s2, hex_str);*/

    char mega[30000];
    char *pm = mega;

    pm += sprintf(pm, "{\"i_login\":\"%s\",\"i_cwd\":\"%s\",\"s_input\":\"%s\"}", login, cwd, s2);
    int mlen = strlen(mega);
    FILE *fp = fopen("std/parse.args", "wt");
    fwrite(&mega, 1, mlen, fp);
    fclose(fp);

    unsigned action = 0, action2 = 0, action3 = 0;
    system("make std/action.1");
    fp = fopen("std/action.1", "rt");
    fscanf(fp, "%u", &action);
    fclose(fp);

    if (action & CHANGE_DIR) {
        system("jq -r '.ses.cwd' <std/parse.out >std/cwd");
        fp = fopen("std/cwd", "rt");
        fscanf(fp, "%s", cwd);
        fclose(fp);
    }

    if (action & CHECK_STATUS) {
        system("jq -r '.addresses[]' < std/parse.out >std/addresses");
        system("jq -r '.names[]' < std/parse.out >std/hosts");
        system("make account_data");
        system("make std/status");
    }

    if (action & MOUNT_FS) {
        system("jq -r '.addresses[]' < std/parse.out >std/addresses");
        system("jq 'del(.std,.action,.input,.redirect)' < std/parse.out > std/request_mount.args");
        system("make std/request_mount");
    }
    if (action & OPEN_FILE) {
        system("make std/ses.temp");
        system("make std/open");
    }
    if (action & OPEN_DIR) {
        system("rm -f std/dirs_to_open std/files_to_open");
        system("make std/dirs_to_open");
        system("make std/files_to_open");
        system("make std/carr");
        system("make std/mount_el");
    }

    if (action & PRINT_STATUS) {
        system("jq -r 'del(.re,.action,.std,.ios,.ines)' < std/parse.out >std/stat.args");
        system("make std/action.2");
    }
    else if (action & PROCESS_COMMAND) {
        system("jq -r 'del(.re,.action,.std,.ios,.ines)' < std/parse.out >std/process.args");
        system("make std/action.3");
        fp = fopen("std/action.3", "rt");
        fscanf(fp, "%u", &action3);
        fclose(fp);
    }

    if (action & PIPE_OUT_TO_FILE)
        system("make std/write_to_file.res");

    /*if (action3 & ADD_NODES) {
        system("jq 'del(.std,.action,.input,.re,.ios,.redirect,.names,.addresses)' < std/parse.out > std/ses.temp");
        system("jq 'del(.std,.action)' < std/process.out > std/proc.temp");
        system("jq -s '.[0] + .[1]' std/ses.temp std/proc.temp > std/add_nodes.args");
        system("make std/add_nodes.res");
    }*/

    if (action3 & UPDATE_NODES) {
        system("jq 'del(.std,.action,.input,.re,.ios,.redirect,.names,.addresses)' < std/parse.out > std/ses.temp");
        system("jq 'del(.std,.action)' < std/process.out > std/proc.temp");
        system("jq -s '.[0] + .[1]' std/ses.temp std/proc.temp > std/update_nodes.args");
        system("make std/update_nodes.res");
    }

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

    size_t cwdsize = 32;
    cwd = (char *)malloc(cwdsize);
    FILE *cfp = fopen("std/cwd", "rt");
    if (!cfp) {
        cfp = fopen("std/cwd", "wt");
        fwrite("/", 1, 1, cfp);
        fclose(cfp);
    } else {
        fscanf(cfp, "%s", cwd);
        fclose(cfp);
    }

    printf("Working dir: %s\n", cwd);

//    int wd = argc < 2 ? 11 : atoi(argv[2]);
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
