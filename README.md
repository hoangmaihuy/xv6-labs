# Lab 8: File system 实习报告

> **姓名**：枚辉煌
>
> **学号**：1800094810
>
> **日期**：2021/05/08
- [Lab 8: File system 实习报告](#lab-8-file-system-实习报告)
  - [1. 实验总结](#1-实验总结)
    - [Exercise 1: Large files](#exercise-1-large-files)
    - [Exercise 2: Symbolic links](#exercise-2-symbolic-links)
  - [2. 遇到的困难以及收获](#2-遇到的困难以及收获)
  - [3. 对课程或Lab的意见和建议](#3-对课程或lab的意见和建议)
  - [4. 参考文献](#4-参考文献)
## 1. 实验总结

### Exercise 1: Large files

To implement a doubly-indirect block, we have to reduce number of direct blocks `NDIRECT` from 12 to 11 to make room for new double-indirect block. We modify `struct inode` and `struct dinode` to add new double-indirect address

```c
// kernel/file.h:29
// in-memory copy of an inode
struct inode {
  ...
  uint addrs[NDIRECT+2];
};

// kernel/fs.h
...
#define NDIRECT 11
#define NINDIRECT (BSIZE / sizeof(uint)) // singly-indirect
#define NDOUBLYINDIRECT (NINDIRECT * NINDIRECT) // doubly-indirect
#define MAXFILE (NDIRECT + NINDIRECT + NDOUBLYINDIRECT)
struct dinode {
  ...
  uint addrs[NDIRECT+2];   // Data block addresses
};
```

Now we need to add loading double-indirect block and it's similar to load singly-indirect block code in `bmap`. After decreasing blocker number `bn` by the number of direct and singly-indirect blocks, we can calculate the address of first indirect level `i = bn / INDIRECT`. We read data in this block and allocate if necessary and move to this block. To this point, our needed data should be at block `i = bn % NINDIRECT` and we continue above steps to get the data.

```c
// kernel/fs.c
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
  // Code of iterating through direct and singly-direct blocks
  ...
  bn -= NINDIRECT;

  if (bn < NDOUBLYINDIRECT)
  {
    // Load doubly-indirect block, allocating if necessary
    if((addr = ip->addrs[NDIRECT+1]) == 0)
      ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);

    bp = bread(ip->dev, addr);
    a = (uint*)bp->data;
    // the first indirect-level
    i = bn / NINDIRECT;
    if ((addr = a[i]) == 0)
    {
      a[i] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);

    bp = bread(ip->dev, addr);
    a = (uint*)bp->data;
    // the second indirect-level
    i = bn % NINDIRECT;
    if ((addr = a[i]) == 0)
    {
      a[i] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
}
```

We need to modify `itrunc` to free all blocks of a file including double-indirect blocks. This can be done by two for loops, one for first indirect-level and another for second indirect-level. We only free contents in a first indirect-level block after freeing all of its contents in second indirect-level blocks. Finally, we free double-indirect block in inode, which is `ip->addrs[NDIRECT+1]`

```c
// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
  // Code for truncating direct and singly-indirect blocks
  ...
  if (ip->addrs[NDIRECT+1])
  {
    bp = bread(ip->dev, ip->addrs[NDIRECT+1]);
    a = (uint*)bp->data;
    for(i = 0; i < NINDIRECT; i++)
    {
      if (a[i])
      {
        bp1 = bread(ip->dev, a[i]);
        b = (uint*)bp1->data;
        for (j = 0; j < NINDIRECT; j++)
        {
          if (b[j])
            bfree(ip->dev, b[j]);
        }
        brelse(bp1);
        bfree(ip->dev, a[i]);
      }
    }
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT+1]);
    ip->addrs[NDIRECT+1] = 0;
  }
```

### Exercise 2: Symbolic links

Firstly, we create a new system call number for symlink.

```c
// user/user.h:26
...
int symlink(const char*, const char*);

// user/sys.pl:39
...
entry("symlink");

// kernel/syscall.h:23
...
#define SYS_symlink 22

// kernel/syscall.c:131
static uint64 (*syscalls[])(void) = {
...
[SYS_symlink] sys_symlink,
};
```

Secondly, we add a new file type (`T_SYMLINK`)  to represent a symbolic link.

```c
// kernel/stat.h:4
#define T_SYMLINK 4   // Symlink
```

We also add a new flag `O_NOFOLLOW` that can be used with the `open` system call

```c
// kernel/fcntl.h:6
#define O_NOFOLLOW 0x800
```

Now we're ready to implement `sys_symlink`. `sys_symlink` simply reads the arguments `target` and `path` from registers, create an `inode` with `T_SYMLINK` type and write `target` to it.

```c
// kernel/sysfile.c:519
uint64
sys_symlink(void)
{
  char target[MAXPATH], path[MAXPATH];
  memset(target, 0, sizeof(target));
  memset(path, 0, sizeof(path));

  if (argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    return -1;

  begin_op();
  struct inode* ip = create(path, T_SYMLINK, 0, 0);
  if (ip == 0)
  {
    //printf("create symlink inode failed\n");
    end_op();
    return -1;
  }

  if (writei(ip, 0, (uint64)target, 0, MAXPATH) < MAXPATH)
  {
    //printf("write symlink failed\n");
    end_op();
    return -1;
  }
  iunlockput(ip);
  end_op();
  return 0;
} 
```

Finally, we modify `sys_open` to follow symlink if required. If `O_NOFOLLOW` flag is specified in the call to `open`, `open` only open the symlink and not follow the symlink. Otherwise, it recursively follows the symbolic link. We detects if the links form a cycle by setting the maximum depths of the symbolic links as 10.

```c
uint64
sys_open(void)
{
  ...
  if ((ip->type == T_SYMLINK) && !(omode & O_NOFOLLOW))
  {
    for (int follow_cnt = 1; follow_cnt <= MAXFOLLOW; follow_cnt++)
    {
      if (follow_cnt == MAXFOLLOW)
      {
        //printf("cycle detected when following symlink\n");
        iunlockput(ip);
        end_op();
        return -1;
      }
      if (readi(ip, 0, (uint64)path, 0, MAXPATH) == 0)
      {
        //printf("read symlink target failed\n");
        iunlockput(ip);
        end_op();
        return -1;
      }
      iunlockput(ip);
      if ((ip = namei(path)) == 0)
      {
        //printf("symlink target not found\n");
        end_op();
        return -1;
      }
      ilock(ip);
      if (ip->type != T_SYMLINK)
        break;
    }
  }
  ...
}
```

### Result

![make_grade.png](./images/make_grade.png)

## 2. 遇到的困难以及收获

- This lab is pretty good overall
- I think the hard part of this lab is to be careful about concurrency, such as using `begin_op()`, `end_op()`, `ilock()`, `iunlockput()` when manipulating `inode`.

## 3. 对课程或Lab的意见和建议

无

## 4. 参考文献

- [fs lab hints on MIT website](https://pdos.csail.mit.edu/6.828/2020/labs/fs.html)
- Chapter 8 of xv6 book
- [File System lecture from MIT website](https://www.youtube.com/watch?v=ADzLv1nRtR8)