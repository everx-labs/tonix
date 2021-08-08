#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char* cm[] = {"", "disks", "list", "read", "address", "indx", "write", "set"};
//static const int bn[] = { 1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

unsigned char disks = 1;
unsigned char list = 2;
unsigned char read = 3;
unsigned char address = 4;
unsigned char indx = 5;
unsigned char write = 6;
unsigned char set = 7;

static int  n = 4;
unsigned char parse_command(char *s) {
    for (int i = 1; i < 8; i++) {
        if (!strcmp(s, cm[i]))
            return i;
    }
//    printf("Unrecognized command: %s\n", s);
    return 0;
}

void a2h(char* input, char* output) {
    int loop = 0;
    int i = 0;

    while(input[loop] != '\0') {
        sprintf((char*)(output+i),"%02X", input[loop]);
        loop += 1;
        i += 2;
    }
    output[i++] = '\0';
}

unsigned short _prompt(unsigned short wd) {
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
    if (!(strcmp(cmds, "quit"))) {
        printf("Bye.\n");
        exit(0);
    }
    if (!(strcmp(cmds, "sh"))) {
        char buffer[200];
        sprintf(buffer, "%s", &s2[strlen(cmds) + 1]);
        system(buffer);
        return 0;
    }
    if (!(strcmp(cmds, "disks"))) {
        system("make system/Repo/_disks.out");
        system("jq -r '._disks | keys ' <system/Repo/_disks.out");
    }

    int x = 0;
    char *args[10];
    t = strtok(NULL, " ");
    while(t) {
        args[x++] = strdup(t);
        t = strtok(NULL, " ");
    }

    char buffer[200];

    if (!(strcmp(cmds, "new"))) {
        sprintf(buffer, "make n=%d fs/%d", n, n);
        system(buffer);
    }
    if (!(strcmp(cmds, "creat"))) {
        sprintf(buffer, "make n=%d creat", n);
        system(buffer);
    }

    if (!(strcmp(cmds, "oargs"))) {
        sprintf(buffer, "make n=%d oargs", n);
        system(buffer);
    }

    if (!(strcmp(cmds, "openall"))) {
        sprintf(buffer, "make n=%d openall", n);
        system(buffer);
    }
    if (!(strcmp(cmds, "check"))) {
        sprintf(buffer, "make n=%d check", n);
        system(buffer);
    }
    if (!(strcmp(cmds, "write"))) {
        sprintf(buffer, "make n=%d args_fd", n);
        system(buffer);
        sprintf(buffer, "make n=%d write_fd.%d", n, n);
        system(buffer);
    }

    if (!(strcmp(cmds, "get"))) {
        sprintf(buffer, "make n=%d get", n);
        system(buffer);
    }

    if (!(strcmp(cmds, "list"))) {
        system("make lfn");
    }

/**********************************************************
    parse command from first argument into cmd
    process terminal commands
**********************************************************/
    unsigned char cmd = parse_command(cmds);
    if (!cmd) {
//        printf("%s: command not found\n", cmds);
//        return 1;
    }

    if (!(strcmp(cmds, "set"))) {
        int nn = atoi(args[0]);
//        printf("set %s %d\n", args[0], nn);
        n = nn;
    }

    if (cmd == address) {
        char buffer[2000];
        sprintf(buffer, "%s%s%s", "jq -r '._disks[\"", args[0], "\"]' <system/Repo/_disks.out");
        printf("%s\n", buffer);
        system(buffer);
    }

    return wd;
}

int main(int argc, char **argv) {
    unsigned short wd = argc < 2 ? 1 : atoi(argv[2]);
    printf("\n");
    while (1) {
//        printf("wd: %d\n", wd);
        printf("$ ");
        unsigned short ret = _prompt(wd);

        if (ret == 0) {
            printf("??? Session failed?\n");
        } else {
//            printf("Session completed, old wd: %d new wd:%d\n", wd, ret);
            wd = ret;
        }
    }
}
