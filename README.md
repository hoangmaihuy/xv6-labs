# Lab 6: Lazy Allocation 实习报告

> **姓名**：枚辉煌
>
> **学号**：1800094810
>
> **日期**：2021/04/12

- [Lab 6: Lazy Allocation 实习报告](#lab-6-lazy-allocation-实习报告)
  - [1. 实验总结](#1-实验总结)
    - [Exercise 1: Eliminate allocation from sbrk()](#exercise-1-eliminate-allocation-from-sbrk)
    - [Exercise 2 & 3: Lazy allocation](#exercise-2--3-lazy-allocation)
    - [Result](#result)
  - [2. 遇到的困难以及收获](#2-遇到的困难以及收获)
  - [3. 对课程或Lab的意见和建议](#3-对课程或lab的意见和建议)
  - [4. 参考文献](#4-参考文献)


## 1. 实验总结

### Exercise 1: Eliminate allocation from sbrk()

`sys_sbrk()` calls `growproc(n)` to change the process's memory size by `n` bytes. To implement lazy allocation, we can delete `growproc()` and adjust current process's `sz` field when increasing memory size (`n > 0`) but leave `growproc()` normal when decreasing memory size.

```c
uint64
sys_sbrk(void)
{
  int addr;
  int n;
  struct proc* p = myproc();

  if(argint(0, &n) < 0)
    return -1;
  addr = p->sz;
  if (n > 0)
  {
    // Lazy allocation
    p->sz = p->sz + n;
  }
  else if (growproc(n) < 0)
  {
    return -1;
  }
  return addr;
}
```

After making above modification, xv6 should boot normally. But if we type `echo hi` to the shell, it will display an error:

```
init: starting sh
$ echo hi
usertrap(): unexpected scause 0x000000000000000f pid=3
            sepc=0x00000000000012ac stval=0x0000000000004008
va=0x0000000000004000 pte=0x0000000000000000
panic: uvmunmap: not mapped
```

If we print out the name of process, we will know that `sh` process causes this error. So what is happening here?  We can see that `scause = 0xf = 15`, so it means that there is a store fault here at instruction address `0x12ac`, fauting address is `0x4008`.  In `sh.asm`, instruction `12ac` is 

```assembly
hp->s.size = nu;
    12ac:	01652423          	sw	s6,8(a0)
```

And it's in function `morecore(uint nu)` in `user/umalloc.c:58`,right after the `sbrk()` call. `morecore` is called by `malloc`, so we can guess that `sh.c` called `malloc` somewhere when running command `echo`. Searching in `sh.c`, we found that `execcmd` called `malloc`, after tracing calling sequence we can see that before running `echo`, `sh` called `parsecmd (line 168) -> parseline (line 334) -> parsepipe(line 349) -> parseexec (line 366) -> execcmd (line 426) -> malloc (line 200) -> morecore`. Below is `morecore` implementation:

```c
static Header*
morecore(uint nu)
{
  char *p;
  Header *hp;

  if(nu < 4096)
    nu = 4096;
  p = sbrk(nu * sizeof(Header));
  if(p == (char*)-1)
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
  free((void*)(hp + 1));
  return freep;
}
```

In line 9, we see that it called `sbrk` to allocate more memory but `sbrk` did not really allocate phyical memory, then in line 13 when it tries to write to `hp->s.size` which is new memory page, it causes a write page fault. 

### Exercise 2 & 3: Lazy allocation

Firstly, we make `usertrap` handle read/write page fault causing by lazy allocation. Note that `scause = 13` means load page fault, `scause = 15` is store page fault and we kill process if it's an invalid memory reference.

```c
// kernel/trap.c
void
usertrap(void)
{
  ...
  } else if (r_scause() == 13 || r_scause() == 15) {
    // page fault
    uint64 va = r_stval(); // virtual address that cause page fault
    if (lazyalloc(va) == 0)
      p->killed = 1;
  }
}
```

Secondly, we implement `lazyalloc()`, which allocate a physical page for virtual address `va`. `lazyalloc` does some check to ensure that `va` is in heap space, calls `kalloc` to allocate a physical page and map it in user page table. `kalloc` returns physical address of new page or 0 if failed. 

```c
// Lazy allocation a page in user memory
// return physical address or 0 if failed
int lazyalloc(uint64 va)
{
  struct proc* p = myproc();
  // va should be in heap space, not stack
  if (va >= p->sz || va < p->trapframe->sp)
    return 0;

  va = PGROUNDDOWN(va); // round down to page boundary
  uint64 pa = (uint64)kalloc();
  if (pa == 0)
    return 0;
  else
  {
    if (mappages(p->pagetable, va, PGSIZE, pa, PTE_R|PTE_W|PTE_U) != 0)
    {
      kfree((void*)pa);
      return 0;
    }
  }
  return pa;
}
```

After this point, `uvmcopy()` will panic because when we create new process by calling `fork`, it calls `uvmcopy()` to copy page table from parent process to child process. `uvmunmap()` will also panic because lazy pages may not have been allocated before child process exit. All we have to do is ignoring these.

```c
// kernel/vm.c
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  ...
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
    {
      continue;
      // panic("uvmcopy: pte should exist");
    }
    if((*pte & PTE_V) == 0)
    {
      continue;
      // panic("uvmcopy: page not present");
    }
    ...
}
    
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  ...
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
    {
      continue; // page has not been allocated
      // panic("uvmunmap: walk");
    }
    if((*pte & PTE_V) == 0)
    {
      continue;
      // panic("uvmunmap: not mapped");
    }  
  ...
}
```

Til this point, we see that `freewalk` panic `freewalk: leaf`. Because after `uvmunmap` free all physical pages, `uvmfree` calls `freewalk` to recursively free user page tables and some leaves have not been allocated, so page table entry would be invalid. We can just ignore this panic and continue the loop.

```c
void
freewalk(pagetable_t pagetable)
{
  ...
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  ...
}
```

There is a case in which a process passes a valid address from sbrk() to a system call such as read or write, but the memory for that address has not yet been allocated. `usertrap` can't handle this case because it happens when kernel copies data from kernel space to user space by using `copyin` and `copyout` functions. We can fix this problem by allocation pages when translating virtual address to physical address in `walkaddr` function

```c
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  ...
  if(pte == 0 || (*pte & PTE_V) == 0)
  {
    if (lazyalloc(va) == 0)
      return 0;
    pte = walk(pagetable, va, 0);
  }
  ...
}
```

All lazytests and usertests should pass now.

### Result

![make_grade.png](./images/make_grade.png)

## 2. 遇到的困难以及收获

**Lessons**:

- Lazy allocation is amazing! 
- More understanding about virtual memory translation
- More understanding about virtual memory management in processes.

**Difficulties**:

- It takes times to investigate what causes page fault in first exercise `echo hi`
- There are many cases to handle when implementing lazy allocation. Without the hints on MIT website,  I think that it would take me a day to complete this lab.

## 3. 对课程或Lab的意见和建议

无

## 4. 参考文献

- [lazy lab hints on MIT website](https://pdos.csail.mit.edu/6.828/2020/labs/lazy.html)
- Chapter 4.6 in xv6 book.