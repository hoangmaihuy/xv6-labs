# Lab 2: Pagetable 实习报告

- [Lab 2: Pagetable 实习报告](#lab-2-pagetable-实习报告)
  - [1. 实验总结](#1-实验总结)
    - [Exercise 1: Print a page table](#exercise-1-print-a-page-table)
    - [Exercise 2: A kernel page table per process](#exercise-2-a-kernel-page-table-per-process)
    - [Exercise 3: Simplify `copyin/copyinstr`](#exercise-3-simplify-copyincopyinstr)
  - [2. 遇到的困难以及收获](#2-遇到的困难以及收获)
  - [3. 对课程或Lab的意见和建议](#3-对课程或lab的意见和建议)
  - [4. 参考文献](#4-参考文献)

## 1. 实验总结

### Exercise 1: Print a page table

Firstly we add `vmprint` in `exec.c`

```c
// kernel/exec.c:122
int 
exec(char *path, char** argv)
{
  ...
  // print first process page table at startup
  if (p->pid == 1)
    vmprint(p->pagetable)
  return argc; // this ends up in a0, the first argument to main(argc, argv)
  ...
}
```

Then we recursively iterate through page table. Each page table will have `2^9 = 512` entry, after going through 3 level we print the leaf

```c
// print page table in format
void
ptprint(pagetable_t pagetable, int indent)
{
  // walk through 2^9 = 512 PTE
  for (int i = 0; i < 512; i++)
  {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) // pte is valid
    {
      pagetable_t child = (pagetable_t)PTE2PA(pte);
      printf("..");
      for (int j = 1; j < indent; j++) printf(" ..");
      printf("%d: pte %p pa %p\n", i, pte, child);

      if (indent < 3)
        ptprint(child, indent+1);
    }
  }
}

void
vmprint(pagetable_t pagetable)
{
  printf("page table %p\n", pagetable);
  ptprint(pagetable, 1);
}
```

After booting xv6, it will print out first user process page table like this

```
page table 0x0000000087f64000
..0: pte 0x0000000021fd8001 pa 0x0000000087f60000
.. ..0: pte 0x0000000021fd7c01 pa 0x0000000087f5f000
.. .. ..0: pte 0x0000000021fd841f pa 0x0000000087f61000
.. .. ..1: pte 0x0000000021fd780f pa 0x0000000087f5e000
.. .. ..2: pte 0x0000000021fd741f pa 0x0000000087f5d000
..255: pte 0x0000000021fd8c01 pa 0x0000000087f63000
.. ..511: pte 0x0000000021fd8801 pa 0x0000000087f62000
.. .. ..510: pte 0x0000000021fed807 pa 0x0000000087fb6000
.. .. ..511: pte 0x0000000020001c0b pa 0x0000000080007000
```

According to Figure 3.4 in xv6 books, page 0 is process's text and data an have read/write/execute permission. Page 1 is a guard page, so `PTE_U = 0` and user can't access this page. Page 2 is process's stack. `exec.c` maps these two pages in line 67

```c
// kernel/exec.c:67
  // Allocate two pages at the next page boundary.
  // Use the second as the user stack.
  sz = PGROUNDUP(sz);
  uint64 sz1;
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
  sz = sz1;
  uvmclear(pagetable, sz-2*PGSIZE);
  sp = sz;
  stackbase = sp - PGSIZE;
```

The highest two pages, page 510 is process's trapframe and 511 is trampoline page, which is mapped in `proc_pagetable` at `kernel/proc.c:181`

### Exercise 2: A kernel page table per process

The main purpose of this exercise is a preparation for exercise 3. Each time kernel want to read user space address, it has to translate it to physical address and manipulate on it. By giving each process its own copy of kernel page table, when user process switch from user mode to kernel mode, kernel will continue using user copy of kernel pagetable instead of switching to global kernel page table.  This allow kernel deference pointer from user space.

At first, we add a new field `kpagetable` in process's struct.

```c
// kernel/proc.h:101
struct proc {
  ...
  pagetable_t kpagetable;      // Kernel page table
  ...
}
```

To initialize user's `pagetable`, we implement `proc_kpagetable`, which is just a copy of `kvminit` with addition of process's trapframe.

```c
// kernel/proc.c
// Create a copy of global kernel page table for given process
pagetable_t
proc_kpagetable(struct proc *p)
{
  pagetable_t kpagetable = (pagetable_t) kalloc();
  if (kpagetable == 0)
    return 0;

  memset(kpagetable, 0, PGSIZE);

  // uart registers
  ukvmmap(kpagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  ukvmmap(kpagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  ukvmmap(kpagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  ukvmmap(kpagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  ukvmmap(kpagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  ukvmmap(kpagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // map trapframe
  ukvmmap(kpagetable, TRAPFRAME, (uint64)(p->trapframe), PGSIZE, PTE_R | PTE_W);

  return kpagetable;
}
```

And to free user's kpagetable we implement `proc_freekpagetable`, which is similar to `proc_freepagetable` except it does not free physical memory belongs to kernel

```c
// kernel/proc.c
// Free a process's kernel page table
// without freeing physical memory
void
proc_freekpagetable(pagetable_t kpagetable)
{
  for (int i = 0; i < 512; i++)
  {
    pte_t pte = kpagetable[i];
    if ((pte & PTE_V) && ((pte & (PTE_R | PTE_W | PTE_X)) == 0))
    {
      pagetable_t child = (pagetable_t)PTE2PA(pte);
      proc_freekpagetable(child);
    }
  }
  kfree((void*)kpagetable);
}
```

We need to modify `allocproc` and `freeproc` to use initialize and free user's kernel pagetable. These modification is similar to process's page table, but in unmodified version of xv6 each process's kernel stack is in kernel memory space and setu up in `procinit`. Now each process has its independent copy of kernel page table, so it's more reasonable to move kernel stack here.

```c
// kernel/vm.c
// add a mapping to given process's kernel page table.
void
ukvmmap(pagetable_t kpagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpagetable, va, sz, pa, perm) != 0)
    panic("ukvmmap");
}

// kernel/proc.c
static struct proc*
allocproc(void)
{
  ...
  // Create process's kernel page table
  p->kpagetable = proc_kpagetable(p);
  if (p->kpagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }
    
  // Allocate a page for the process's kernel stack.
  // Map it high in memory, followed by an invalid
  // guard page.
  char *pa = kalloc();
  if(pa == 0)
    panic("kalloc");
  uint64 va = KSTACK((int) (p - proc));
  ukvmmap(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  p->kstack = va;
  ...
}
```

And in `freeproc`, we free this kernel stack and process's kernel page table.

```c
// kernel/proc.c
static void
freeproc(struct proc *p)
{
  ...
  // Free kernel stack
  pte_t *pte = walk(p->kpagetable, p->kstack, 0);
  if (pte == 0)
    panic("freeproc: free kernel stack");
  kfree((void*)PTE2PA(*pte));
  p->kstack = 0;
  ...
  if (p->kpagetable)
  proc_freekpagetable(p->kpagetable);
  ...
}
```

We also need to modify scheduler to switch to process's kernel page table when switching context. Scheduler should use global kernel pagetable when no process is running

```c
// kernel/vm.c
// Switch kernel page table when scheduling
void
switch_kpagetable(pagetable_t kpagetable)
{
  w_satp(MAKE_SATP(kpagetable));
  sfence_vma();
}

// kernel/proc.c
void
scheduler(void)
{
  ...
    int found = 0;
    for(p = proc; p < &proc[NPROC]; p++) {
        ...
        // Switch to process's kernel pagetable
        switch_kpagetable(p->kpagetable);
        ...
    }
    ...
    if(found == 0) {
      // Use global kernel pagetable when no process is running
      switch_kpagetable(kernel_pagetable);
	  ...
    }
  ...
}
```

Finally, we modify `kvmpa` to use process's kernel page table when translating kernel stack address to physical address

```c
// kernel/vm.c
uint64
kvmpa(uint64 va)
{
  ...
  pte = walk(myproc()->kpagetable, va, 0);
  ...
}
```

All `usertests` should pass now.

![make_grade.png](./images/make_grade.png)

### Exercise 3: Simplify `copyin/copyinstr`

We implement `ukvmcopy` function to copy process's address space to its own kernel page table. This function will be used if there is any changes in user address space, such as when `fork()`, `exec()` or `sbrk()`. We turn off `PTE_U` flag to prevent process from accessing kernel data.

```c
// kernel/vm.c
// Copy process's user address space to its kernel page table
void
ukvmcopy(pagetable_t pagetable, pagetable_t kpagetable, uint64 old_sz, uint64 new_sz)
{
  if (old_sz >= new_sz)
    return;

  uint64 va, pa, flags;
  pte_t *src, *dst;
  for (va = PGROUNDUP(old_sz); va < new_sz; va += PGSIZE)
  {
    if ((src = walk(pagetable, va, 0)) == 0)
      panic("ukvmcopy: src pte not found");
    if ((dst = walk(kpagetable, va, 1)) == 0)
      panic("ukvmcopy: dst pte alloc failed");

    pa = PTE2PA(*src);
    // Not allow accessing this page in user mode by turn off PTE_U flag
    flags = PTE_FLAGS(*src) & (~PTE_U);
    *dst = PA2PTE(pa) | flags;
  }
}
```

At each point where the kernel changes a process's user mappings, we change the process's kernel page table in the same way. 

```c
// kernel/exec.c:79
int
exec(char *path, char **argv)
{
  ...
  // copy user address space to kernel page table
  ukvmcopy(pagetable, p->kpagetable, 0, sz);
  ...
}

// kernel/proc.c:359
int
fork(void)
{
  ...
  // copy user address space to kernel page table
  ukvmcopy(np->pagetable, np->kpagetable, 0, np->sz)
  ...
}

// kernel/proc.c:333
int
growproc(int n)
{
  ...
  if(n > 0){
    // Additional check to ensure heap space does not overwrite PLIC segment
    if (PGROUNDUP(sz + n) >= PLIC)
      return -1;
  ...
  // copy user address space to kernel page table
  ukvmcopy(p->pagetable, p->kpagetable, p->sz, sz);
  p->sz = sz;
  return 0;
}
```

After replace `copyin()` with a call to `copyin_new` and `copyinstr()` with a call to `copyinstr_new`, all `usertests` should pass now.

The third test  `srcva + len < srcva` is necessary in `copyin_new()` because both `srcva` and `len` is passed by user process and can be harmful. Both `srcva` and `len` are `uint64`, so if `srcva + len` overflows `uint64`, it will become `(srcva + len) % 2^64`. For example, if `p->sz = 10, srcva = 1, len = 2^64-1`, the first two tests fail because `srcva < p->sz` and `srcva+len=0 < p->sz`, but the third test is true because `srcva+len < srcva`.

## 2. 遇到的困难以及收获

- It takes me times to really understand the concept of kernel page table per process.
- The hardest part of this lab is exercise 2, although the code is not hard because mostly steal from other parts of xv6 but there are many places need to modify. After modifying and rerunning usertests, other tests fails and new problem appears, it's kind of annoying.
- Kernel page table per process is interesting because it reduces the cost of switching page table when transiting between user and kernel space. 
- I watched MIT video about Meltdown attack which is related to this mechanism and I found it amazing that the authors can exploit the advantages of it.

## 3. 对课程或Lab的意见和建议

无

## 4. 参考文献

- [page tables lab hints on MIT website](https://pdos.csail.mit.edu/6.828/2020/labs/pgtbl.html)
- Chapter 3 of xv6 books
- [Meltdown lecture on MIT website](https://www.youtube.com/watch?v=WpKVr3p5rjE)
- 