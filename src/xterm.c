#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned const NO_ACTION   = 0;
unsigned const PRINT_ERROR       = 1;
unsigned const PRINT_OUT         = 2;
unsigned const PRINT_IN          = 4;
unsigned const PRINT_STAT        = 8;
unsigned const PROCESS_COMMAND   = 16;
unsigned const INODE_EVENT       = 64;
unsigned const IO_EVENT          = 128;
unsigned const WRITE_EVENT       = IO_EVENT + INODE_EVENT;
unsigned const READ_EVENT       = 256;
unsigned const CHECK_STATUS     = 512;
unsigned const QUERY_BALANCE    = 1024;
unsigned const WRITE_TO_FILE    = 2048;
unsigned const CHANGE_DIR       = 4096;
unsigned const PIPE_OUT_TO_FILE = 8192;

void a2h(char* input, char* output) {
    int loop = 0, i = 0;

    while(input[loop] != '\0') {
        sprintf((char*)(output + i),"%02X", input[loop]);
        loop += 1;
        i += 2;
    }
    output[i++] = '\0';
}

int _prompt(int wd) {
    size_t size = 20000;
    char *s = (char *)malloc(size);

/**********************************************************
    Read line from stdin
**********************************************************/
    int bytes_read = getline(&s, &size, stdin);
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

    /*if (!(strcmp(cmds, "test"))) {
        system("make test");
        return wd;
    }*/

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
        return wd;
    }
    if (!(strcmp(cmds, "sh"))) {
        char buffer[200];
        sprintf(buffer, "%s", &s2[strlen(cmds) + 1]);
        system(buffer);
        return wd;
    }

/**********************************************************
    pack our findings to the contact as metadata
**********************************************************/
    int len = strlen(s2);
    char hex_str[(len * 2) + 1];
    a2h(s2, hex_str);

    char mega[30000];
    char *pm = mega;
//    pm += sprintf(pm, "{\"s_input\":\"%s\",\"sin\":{\"uid\":2000,\"gid\":1000,\"wd\":%d}}", s2, wd);
    pm += sprintf(pm, "{\"i_ses\":{\"uid\":2000,\"gid\":1000,\"wd\":%d},\"s_input\":\"%s\"}", wd, s2);
    int mlen = strlen(mega);
    FILE *fp;

    fp = fopen("std/parse.args", "wt");
    fwrite(&mega, 1, mlen, fp);
    fclose(fp);

    if (system("make std/action std/out std/err")) {
        exit(0);
//        return wd;
    }

    unsigned action = 0, action2 = 0, action3 = 0;
//    system("jq -r '.action' < std/parse.out >std/action");
    fp = fopen("std/action", "rt");
    fscanf(fp, "%u", &action);
    fclose(fp);

    if (action & READ_EVENT) {
        system("jq 'del(.std,.input)' < std/parse.out >std/read.args");
        system("make std/read.out");
        system("jq -r '.outs[]' < std/read.out");
    }

    if (action & CHANGE_DIR) {
        system("jq -r '.ses.wd' <std/parse.out >std/wd");
        fp = fopen("std/wd", "rt");
        fscanf(fp, "%d", &wd);
        fclose(fp);
    }
//    if (action < PRINT_STAT)
//        return wd;

    if (action & PRINT_STAT) {
        system("jq -r 'del(.re,.action,.std,.ios,.ines)' < std/parse.out >std/stat.args");
        system("make std/stat.out");
        fp = fopen("std/action2", "rt");
        fscanf(fp, "%u", &action2);
        fclose(fp);
    }
    else if (action & PROCESS_COMMAND) {
        system("jq -r 'del(.re,.action,.std,.ios,.ines)' < std/parse.out >std/process.args");
        system("make std/process.out");
        fp = fopen("std/action3", "rt");
        fscanf(fp, "%u", &action3);
        fclose(fp);
    }

    if (action3 & CHECK_STATUS) {
        system("make std/status");
        system("cat std/status");
    }

    if (action3 & QUERY_BALANCE) {
        system("make std/balance");
        system("cat std/balance");
    }

    if (action2 & PRINT_OUT)
        system("jq -r '.std.out' < std/stat.out >>std/out");
    if (action2 & PRINT_ERROR)
        system("jq -r '.std.err' < std/stat.out >>std/err");
    if (action3 & PRINT_OUT)
        system("jq -r '.std.out' < std/process.out >>std/out");
    if (action3 & PRINT_ERROR)
        system("jq -r '.std.err' < std/process.out >>std/err");

    system("cat std/out");
    if (action + action2 + action3 & PRINT_ERROR)
        system("cat std/err");
    fflush(stdout);

    if (action & PIPE_OUT_TO_FILE) {
        system("make std/write_to_file.res");
    }

    if (action + action2 + action3 & WRITE_EVENT) {
        if (action & IO_EVENT)
            system("jq 'del(.std,.action,.input,.re)' < std/parse.out > std/write.args");
        if (action2 & IO_EVENT) {
//            system("jq 'del(.std,.action)' < std/stat.out > std/write.args");
            system("jq 'del(.std,.action,.input,.re,.ios,.ines)' < std/parse.out > std/ses.temp");
            system("sed '7d' std/ses.temp > std/ses2.temp");
            system("echo ',' >> std/ses2.temp");
            system("jq 'del(.std,.action)' < std/stat.out > std/proc.temp");
            system("sed '1d' std/proc.temp > std/proc2.temp");
            system("cat std/ses2.temp std/proc2.temp > std/write.args");

        } else if (action3 & WRITE_EVENT) {
            system("jq 'del(.std,.action,.input,.re,.ios,.ines)' < std/parse.out > std/ses.temp");
            system("sed '7d' std/ses.temp > std/ses2.temp");
            system("echo ',' >> std/ses2.temp");
            system("jq 'del(.std,.action)' < std/process.out > std/proc.temp");
            system("sed '1d' std/proc.temp > std/proc2.temp");
            system("cat std/ses2.temp std/proc2.temp > std/write.args");

        }
        system("make std/write.res");
    }

    // !!! jq '.u | del(.std) | .[] | select (length > 0)' < get.out !!!
    return wd;
}

int main(int argc, char **argv) {
    int wd = argc < 2 ? 11 : atoi(argv[2]);
    setbuf(stdout, NULL);
    system("cat etc/motd");
    while (1) {
        printf("$ ");
        int ret = _prompt(wd);

        if (ret == 0) {
            printf("??? Session failed?\n");
            exit(0);
        }
        else
            wd = ret;
    }
}
