#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char* argv[])
{
    int p[2];
    if (pipe(p) < 0)
    {
        fprintf(2, "pingpong: pipe failed\n");
        exit(1);
    }
    int pid = fork();
    if (pid == 0) // the child
    {
        char c;
        read(p[0], &c, 1);
        close(p[0]);
        fprintf(1, "%d: received ping\n", getpid(), c);
        write(p[1], "y", 1);
        close(p[1]);
        exit(0);
    }
    else // the parent
    {
        char c;
        write(p[1], "x", 1);
        close(p[1]);
        wait(0);
        read(p[0], &c, 1);
        close(p[0]);
        fprintf(1, "%d: received pong\n", getpid(), c);
        exit(0);
    }
}