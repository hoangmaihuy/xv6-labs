#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

#define BUF_SIZE 512

void find(char* dirpath, char* filename)
{
    char buf[BUF_SIZE], *p;
    int fd;
    struct stat st;
    struct dirent de;

    if ((fd = open(dirpath, 0)) < 0)
    {
        fprintf(2, "find: cannot open %s\n", dirpath);
        return;
    }

    strcpy(buf, dirpath);
    p = buf + strlen(buf);
    *p++ = '/';

    // read directory
    while (read(fd, &de, sizeof(de)) == sizeof(de))
    {
        if (de.inum == 0)
            continue;
        // append name
        memmove(p, de.name, DIRSIZ);
        p[DIRSIZ] = 0;
        // get path stat
        if (stat(buf, &st) < 0)
        {
            fprintf(2, "find: cannot stat %s\n", buf);
            continue;
        }
        switch (st.type)
        {
            case T_FILE:
                if (strcmp(filename, de.name) == 0)
                    printf("%s\n", buf);
                break;

            case T_DIR:
                if (strcmp(de.name, ".") != 0 && strcmp(de.name, "..") != 0)
                    find(buf, filename);
                break;
        }
    }
}

int main(int argc, char* argv[])
{
    if (argc < 3)
    {
        fprintf(2, "Usage: find dirpath filename\n");
        exit(1);
    }
    find(argv[1], argv[2]);
    exit(0);
}