#include <stdbool.h>
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char* argv[])
{
    int p[2];
    pipe(p);
    close(0);
    close(2);
    if (fork() == 0) // seive process
    {
        loop: ;
        int x, y;
        close(p[1]);
        int pin = p[0];
        int pout = -1;

        read(pin, &x, 4);
        printf("prime %d\n", x);
        while (read(pin, &y, 4) != 0)
        {
            if (y % x != 0)
            {
                if (pout == -1)
                {
                    pipe(p);
                    pout = p[1];
                    if (fork() == 0)
                    {
                        goto loop;
                    }
                    else
                    {
                        close(p[0]);
                    }
                }
                write(pout, &y, 4);
            }
        }
        close(pin);
        if (pout != -1) close(pout);
        wait(0);
        exit(0);
    }
    else // generating process
    {
        close(p[0]);
        for (int i = 2; i <= 35; i++)
            write(p[1], &i, 4);
        close(p[1]);
        wait(0);
        exit(0);
    }
}