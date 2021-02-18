#include <stdbool.h>
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/param.h"
#include "user/user.h"

#define BUF_SIZE 512

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        fprintf(2, "Usage: xargs command [argument...]\n");
        exit(1);
    }

    char cmd[BUF_SIZE];
    char arg[BUF_SIZE];
    strcpy(cmd, argv[1]);

    int cmd_argc = argc-1;
    char* cmd_argv[MAXARG];
    memcpy(cmd_argv, argv+1, sizeof(char*) * cmd_argc);
    cmd_argv[cmd_argc] = 0;

    char* p;
    bool eoa = true; // end of argument

    char buf[BUF_SIZE];
    while (read(0, buf, sizeof(buf)) != 0)
    {
        int len = strlen(buf);
        for (int i = 0; i < len; i++)
        {
            char ch = buf[i];
            if (ch == '\n' || ch == ' ') // commit new argument
            {
                if (!eoa)
                {
                    *p = 0;
                    cmd_argv[cmd_argc-1] = malloc(sizeof(arg));
                    strcpy(cmd_argv[cmd_argc-1], arg);
                }
                eoa = true;
                if (ch == '\n') // run new process
                {
                    if (fork() == 0)
                    {
                        exec(cmd, cmd_argv);
                    }
                    else
                    {
                        wait(0);
                        // reset argument
                        cmd_argc = argc-1;
                        memcpy(cmd_argv, argv+1, sizeof(char*) * cmd_argc);
                        cmd_argv[cmd_argc] = 0;
                    }
                }
            }
            else
            {
                if (eoa) // create new argument
                {
                    p = arg;
                    cmd_argv[++cmd_argc] = 0;
                }
                *p = ch; // copy this character
                p++;
                eoa = false;
            }
        }
    }
    exit(0);
}
