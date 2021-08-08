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
    pm += sprintf(pm, "{\"s_input\":\"%s\",\"sin\":{\"uid\":2000,\"gid\":1000,\"wd\":%d}}", s2, wd);
    int mlen = strlen(mega);
    FILE *fp;

    fp = fopen("std/parse.args", "wt");
    fwrite(&mega, 1, mlen, fp);
    fclose(fp);

    if (system("make std/parse.out"))
        return wd;

    unsigned action = 0, action2 = 0, action3 = 0;
    system("jq -r '.action' < std/parse.out >std/action");
    fp = fopen("std/action", "rt");
    fscanf(fp, "%u", &action);
    fclose(fp);

    if (action & PRINT_OUT)
        system("jq -r '.std.out' < std/parse.out");
    if (action & PRINT_ERROR)
        system("jq -r '.std.err' < std/parse.out");
    if (action & READ_EVENT) {
        system("jq 'del(.std,.input)' < std/parse.out >std/read.args");
        system("make std/read.out");
        system("jq -r '.outs[]' < std/read.out");
    }
    fflush(stdout);

    if (action < PRINT_STAT)
        return wd;

    if (action & PRINT_STAT) {
        system("{ echo -n '{\"ses\":'; cat std/session; echo -n ',\"input\":'; jq '.input' <std/parse.out; echo -n '}'; } >std/stat.args");
        system("make std/stat.out");
        fp = fopen("std/action2", "rt");
        fscanf(fp, "%u", &action2);
        fclose(fp);
    }
    else if (action & PROCESS_COMMAND) {
        system("{ echo -n '{\"ses\":'; cat std/session; echo -n ',\"input\":'; jq '.input' <std/parse.out; echo -n '}'; } >std/process.args");
        system("make std/process.out");
        fp = fopen("std/action3", "rt");
        fscanf(fp, "%u", &action3);
        fclose(fp);
    }

    if (action2 & PRINT_OUT)
        system("jq -r '.std.out' < std/stat.out");
    if (action2 & PRINT_ERROR)
        system("jq -r '.std.err' < std/stat.out");
    if (action3 & PRINT_OUT) {
        system("jq -r '.std.out' < std/process.out");
        fp = fopen("std/wd", "rt");
        fscanf(fp, "%d", &wd);
        fclose(fp);
    }
    if (action3 & PRINT_ERROR)
        system("jq -r '.std.err' < std/process.out");

    if (action2 + action3 & WRITE_EVENT) {
        if (action2 & IO_EVENT)
            system("jq 'del(.std,.action)' < std/stat.out > std/write.args");
        else if (action3 & WRITE_EVENT)
            system("jq 'del(.std,.action)' < std/process.out > std/write.args");
        system("make std/write.res");
    }

    // !!! jq '.u | del(.std) | .[] | select (length > 0)' < get.out !!!
    return wd;
}

int main(int argc, char **argv) {
    int wd = argc < 2 ? 1 : atoi(argv[2]);
    setbuf(stdout, NULL);
    system("cat etc/motd");
    while (1) {
        printf("$ ");
        int ret = _prompt(wd);

        if (ret == 0)
            printf("??? Session failed?\n");
        else
            wd = ret;
    }
}
