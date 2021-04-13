# Lab 9: mmap 实习报告

> **姓名**：枚辉煌
>
> **学号**：1800094810
>
> **日期**：2021/06/01
- [Lab 9: mmap 实习报告](#lab-9-mmap-实习报告)
  - [1. 实验总结](#1-实验总结)
    - [Result](#result)
  - [2. 遇到的困难以及收获](#2-遇到的困难以及收获)
  - [3. 对课程或Lab的意见和建议](#3-对课程或lab的意见和建议)
  - [4. 参考文献](#4-参考文献)
## 1. 实验总结

We first add prototype of `mmap` and `munmap` system calls.

```c
// kernel/defs.h:108-109
...
uint64          mmap(uint64, int, int, int, int, int);
int             munmap(uint64, int);

// kernel/syscall.h:23
...
#define SYS_mmap   22
#define SYS_munmap 23
    
// user/user.h:26-27
void* mmap(void*, int, int, int, int, int);
int munmap(void*, int);
    
// user/usys.pl:39-40
entry("mmap");
entry("munmap");

// kernel/syscall.c:110
static uint64 (*syscalls[])(void) = {
...
[SYS_mmap]    sys_mmap,
[SYS_munmap]  sys_munmap,
};
```

Then we implement `sys_mmap` and `sys_munmap`, which simply reads arguments from registers and pass them to the kernel version of `mmap` and `munmap`, we will implement these two functions later.

```c
// kernel/sysproc.c:99
uint64
sys_mmap(void)
{
  uint64 addr;
  int length, offset, prot, flags, fd;

  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 ||
      argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    return -1;
  return mmap(addr, length, prot, flags, fd, offset);
}

uint64
sys_munmap(void)
{
  uint64 addr;
  int length;

  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    return -1;
  return munmap(addr, length);
}
```

To implement `mmap`, we first have to keep track of what `mmap` has mapped for each process and find an empty memory region in heap space to map the file. Therefore, we defined `vmarea` structure to keep trach of each process's virtual memory area

```c
// kernel/proc.h:85
struct vmarea
{
  uint64 addr;
  int length;
  int perm; // PTE_R, PTE_W
  int type; // MAP_SHARED, MAP_PRIVATE
  int offset; // addr map to offset from file
  struct file* f; // backed file
};
```

We modify `struct proc` to add `vmarea` to user process. Since the xv6 kernel doesn't have a memory allocator in the kernel, we declare a fixed-array of `vmarea` with length of `MAXVMA = 16`. Besides, we need a spinlock to protect this array and a base address of new `vmarea`. All `vma_start` are initialized with the value of `VMAREA = (MAXVA / 2)`

```c
// kernel/proc.h:117
struct proc {
  // virtual memory area, needed for implementing mmap and munmap
  struct spinlock vma_lock;
  uint64 vma_start;
  struct vmarea vma[MAXVMA]; // sorted by begin address
}
```

We have two main operations on `vma`: 

- Find an empty slot for newly allocated `vmarea`
- Given a virtual address `va`, find the `vmarea` that contains `va`.

Because both operations need to scan through `vma` array, we can combine these into a function `find_vma`. A `vmarea` is considered empty if its length is 0. If a non-empty `vmarea` contains `va`, it should satisfy `addr <= va < addr + length`.

```c
// kernel/vm.c:442
// if va == 0 return empty vma
// else return vma that contains va
struct vmarea*
find_vma(struct proc* p, uint64 va)
{
  struct vmarea* vma = 0;
  acquire(&p->vma_lock);
  for (int i = 0; i < MAXVMA; i++)
  {
    if (!va)
    {
      if (p->vma[i].length == 0)
      {
        vma = &p->vma[i];
        goto ret_vma;
      }
    }
    else
    {
      if (p->vma[i].length && va >= p->vma[i].addr && va < p->vma[i].addr + p->vma[i].length)
      {
        vma = &p->vma[i];
        goto ret_vma;
      }
    }
  }
  ret_vma:
  release(&p->vma_lock);
  return vma;
}
```

Now we can implement `mmap`. `mmap` does some check on arguments such as `addr`, `length` and ensure that given file is opened and check its properties. If everything is fine, it calls `find_vma` to find an empty `vmarea` in `vma` array and modifies the struct according to given `prot` and `flags`.

```c
// kernel/vm.c:473
uint64
mmap(uint64 addr, int length, int prot, int flags, int fd, int offset)
{
  if (addr != 0)
  {
    printf("mmap: addr must be 0\n");
    return -1;
  }
  if (length <= 0)
  {
    printf("mmap: length must be greater than 0\n");
    return -1;
  }

  struct proc *p = myproc();

  if (p->ofile[fd] == 0)
  {
    printf("mmap: file not open");
    return -1;
  }

  struct file* f = p->ofile[fd];
  // doesn't allow read/write mapping of a
  // file opened read-only on MAP_SHARED
  if ((flags & MAP_SHARED) && f->readable && (!f->writable)
      && (prot & PROT_READ) && (prot & PROT_WRITE))
    return -1;

  struct vmarea* vma = find_vma(p, 0);

  if (vma == 0)
  {
    printf("mmap: out of vma\n");
    return -1;
  }

  vma->addr = PGROUNDUP(p->vma_start);
  p->vma_start += length;
  vma->length = length;
  vma->f = filedup(f);
  vma->type = flags;
  vma->offset = offset;
  vma->perm = PTE_U;

  if (prot & PROT_READ)
    vma->perm |= PTE_R;
  if (prot & PROT_WRITE)
    vma->perm |= PTE_W;

  return vma->addr;
}
```

To this point, `mmap` call should successfully return, but any data references on mapped memory region will cause a page fault. Handling these page faults is similar to lazy allocation, we allocate a new physical page and read relevant data from backed file to this page then map it to user address space. All these details are in one function `handle_pgfault` in `vm.c`. `handle_pgfault`  does the following things:

- Checks on the fault address to ensure that it's in mmap area
- Calls `find_vma` to get information about the address such as permission, map type,...
- Does more checks about the permission of virtual address to make sure that the page fault is valid
- Calls `kalloc` to get a new physical page
- Use `mappages` to map virtual page to physical page
- Read data from backed file to physical page by calling `readi`

```c
// kernel/trap.c
void
usertrap(void) {
  ...
  } else if (r_scause() == 13 || r_scause() == 15) {
    uint64 va = r_stval();
    int is_write = (r_scause() == 15 ? 1 : 0);
    if (handle_pgfault(va, is_write) == -1)
      p->killed = 1;
  }
  ...
}

// kernel/vm.c:584
int
handle_pgfault(uint64 va, int is_write)
{
  // printf("pagefault: va=%p, is_write=%d\n", va, is_write);
  struct proc* p = myproc();
  if (va < VMAREA || va >= p->vma_start)
  {
    printf("pgfault: not mmap address\n");
    return -1;
  }

  struct vmarea* vma = find_vma(p, va);

  if (vma == 0)
  {
    printf("pgfault: mmap address not found\n");
    return -1;
  }

  if ((is_write && !(vma->perm & PTE_W)) || (!is_write && !(vma->perm & PTE_R)))
  {
    printf("pgfault: permission denied\n");
    return -1;
  }

  va = PGROUNDDOWN(va);
  uint64 pa = (uint64)kalloc();
  if (pa == 0)
  {
    printf("pgfault: out of memory\n");
    return -1;
  }

  memset((void*)pa, 0, PGSIZE);

  if (mappages(p->pagetable, va, PGSIZE, pa, vma->perm) != 0)
  {
    kfree((void*)pa);
    printf("pgfault: mappages failed\n");
    return -1;
  }

  uint offset = vma->offset + (va - vma->addr);
  //printf("readi: inode ref=%p, va=%p, offset=%d\n", vma->f->ip->ref, va, offset);
  begin_op();
  ilock(vma->f->ip);
  int read_res = readi(vma->f->ip, 1, va, offset, PGSIZE);
  iunlock(vma->f->ip);
  end_op();

  if (read_res < 0)
  {
    printf("pgfault: read inode failed\n");
    return -1;
  }
  return 0;
}
```

All the mmap test should pass now and we can move to implement `munmap`.  `munmap` does the following things:

- Find the VMA for the address range and call `uvmunmap` to unmap the specified pages.
- If an unmapped page has been modified and the file is mapped `MAP_SHARED`, write the page back to the file by calling `writeback`
- If `munmap` removes all pages of a previous `mmap`, it calls `fileclose` to decrement the reference count of the corresponding file.

```c
// kernel/vm.c:526
// write n bytes back to file, start from off
// ignore writei error because page may not be allocated
// inspired from filewrite
void
writeback(struct file* f, int off, uint64 addr, int n)
{
  int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
  int i = 0;
  while (i < n){
    int n1 = n - i;
    if(n1 > max)
      n1 = max;

    begin_op();
    ilock(f->ip);
    writei(f->ip, 1, addr + i, off, n1);
    off += n1;
    iunlock(f->ip);
    end_op();

    i += n1;
  }
}

int
munmap(uint64 va, int length)
{
  struct proc* p = myproc();
  if (va % PGSIZE)
  {
    printf("munmap: va not aligned\n");
    return -1;
  }
  struct vmarea* vma = find_vma(p, va);
  if (vma == 0)
  {
    printf("munmap: vma not found\n");
    return -1;
  }

  if (vma->type & MAP_SHARED)
    writeback(vma->f, vma->offset, va, length);

  uvmunmap(p->pagetable, va, length / PGSIZE, 1);
  vma->length -= length;

  if (va == vma->addr)
  {
    vma->addr += length;
    vma->offset += length;
  }

  if (!vma->length)
    fileclose(vma->f);

  return 0;
}
```

Finally, we modify `exit` unmap the process's mapped regions as if `munmap` had been called. We also modify `fork` to ensure that the child has the same mapped regions as the parent. We allocate a new physical page for child process instead of sharing a page with the parent to reduce implementation work.

```c
// kernel/vm.c:283
int
fork(void)
{
  ...
  // Copy vmarea from parent to child
  np->vma_start = p->vma_start;
  for (i = 0; i < MAXVMA; i++)
  {
    np->vma[i] = p->vma[i];
    if (np->vma[i].length)
      np->vma[i].f = filedup(np->vma[i].f);
  }
  ...
}

// kernel/vm.c:370
void
exit(int status)
{
  ...
  // unmap remain vmarea
  for (int i = 0; i < MAXVMA; i++)
    if (p->vma[i].length)
      munmap(p->vma[i].addr, p->vma[i].length);
  ...
}
```

Now all `mmaptest` should pass, including `mmap_test` and `fork_test`

### Result

![make_grade.png](./images/make_grade.png)

## 2. 遇到的困难以及收获

- Implement work for this lab is really huge
- `mmaptest` test many cases that I didn't expect, for example "mmap doesn't allow read/write mapping of a file opened read-only."
- Read from backed file when handling page fault and write back when `unmap` are tricky.
- `mmaptest` only `unmap` at the beginning or end of a mapped region, if it tries to `unmap` in the middle of region, there will be more cases to consider.

## 3. 对课程或Lab的意见和建议

无

## 4. 参考文献

- [mmap lab hints on MIT website](https://pdos.csail.mit.edu/6.828/2020/labs/mmap.html)

