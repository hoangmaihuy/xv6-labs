# Lab 7: Lock 实习报告

> **姓名**：枚辉煌
>
> **学号**：1800094810
>
> **日期**：2021/05/01

- [Lab 7: Lock 实习报告](#lab-7-lock-实习报告)
  - [1. 实验总结](#1-实验总结)
    - [Exercise 1: Memory allocator](#exercise-1-memory-allocator)
    - [Exercise 2: Buffer cache](#exercise-2-buffer-cache)
  - [2. 遇到的困难以及收获](#2-遇到的困难以及收获)
  - [3. 对课程或Lab的意见和建议](#3-对课程或lab的意见和建议)
  - [4. 参考文献](#4-参考文献)

## 1. 实验总结

### Exercise 1: Memory allocator

To implement per-CPU freelists, we firstly modify `kmem` to an array, each element is a freelist with a lock corresponding to a CPU. We add a new field `size` to maintain the length of freelist.

```c
// kernel/kalloc.c:21
struct {
  struct spinlock lock;
  struct run *freelist;
  int size; // number of free page in freelist
} kmem[NCPU];
```

In `kinit`, we initialize all `kmem` locks and freelists then gives all free memory to current CPU running `kinit`.

```c
// kernel/kalloc.c:28
void
kinit()
{
  char kmem_name[20];
  for (int i = 0; i < NCPU; i++)
  {
    snprintf(kmem_name, sizeof kmem_name, "kmem_%d", i);
    initlock(&kmem[i].lock, kmem_name);
    kmem[i].size = 0;
    kmem[i].freelist = 0;
  }
  freerange(end, (void*)PHYSTOP);
}
```

Now we just need to rewrite `kalloc`. 

- Firstly, we need to get current core number, but it's only safe to call `cpuid()` and use its result when interrupts are turned off, so we use `push_off()` and `pop_off()` to do the job. 
- Secondly, if current freelist is empty we need to steal pages from other CPUs. This can be done easily by iterating through `kmem` array and check the `size` field of each element. We steal half of the size of other process's freelist then get the first element of current CPU freelist as allocated page.

```c
// kernel/kalloc.c:79
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;
  push_off();
  int id = cpuid();
  pop_off();

  acquire(&kmem[id].lock);
  if (!kmem[id].size)
  {
    for (int i = 0; i < NCPU; i++)
    {
      if (i == id) continue;
      acquire(&kmem[i].lock);
      if (!kmem[i].size)
      {
        release(&kmem[i].lock);
        continue;
      }
      int steal_size = (kmem[i].size + 1) / 2;
      while (steal_size--)
      {
        r = kmem[i].freelist;
        kmem[i].freelist = r->next;
        kmem[i].size--;

        r->next = kmem[id].freelist;
        kmem[id].freelist = r;
        kmem[id].size++;
      }
      release(&kmem[i].lock);
      break;
    }
  }

  r = kmem[id].freelist;

  if(r)
  {
    kmem[id].freelist = r->next;
    kmem[id].size--;
  }

  release(&kmem[id].lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
```

### Exercise 2: Buffer cache

Follow the hints on MIT website, we look up block numbers in the cache with a hash table that has a lock per hash bucket. To implement this idea, we firsly modify `bcache` to an array, in which each element is a hash bucket.

```c
// kernel/param.h:14
#define NBUCKET      13  // number of bucket for hash table in bcache

// kernel/bio.c:34
struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf head;
} bcache[NBUCKET];
```

We continue to modify `binit` function, in which `bcache` is initialized. All statements are similar to unmodified version of xv6 except now we iterate through `bcache` array and initlialize each element independently.

```c
// kernel/bio.c:36
void
binit(void)
{
  struct buf *b;
  char lockname[20];

  for (int i = 0; i < NBUCKET; i++)
  {
    snprintf(lockname, sizeof(lockname), "bcache_%d", i);
    initlock(&bcache[i].lock, lockname);

    // Create linked list of buffers
    bcache[i].head.prev = &bcache[i].head;
    bcache[i].head.next = &bcache[i].head;
    for(b = bcache[i].buf; b < bcache[i].buf+NBUF; b++){
      b->next = bcache[i].head.next;
      b->prev = &bcache[i].head;
      initsleeplock(&b->lock, lockname);
      bcache[i].head.next->prev = b;
      bcache[i].head.next = b;
    }
  }
}
```

Now we check all references of `bcache` and add corresponding index of block number, which is `blockno % NBUCKET`. Those include `bget`, `brelse`, `bpin` and `bunpin`

```c
// kernel/bio.c:64
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;
  uint i = blockno % NBUCKET;

  acquire(&bcache[i].lock);

  // Is the block already cached?
  for(b = bcache[i].head.next; b != &bcache[i].head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache[i].lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  for(b = bcache[i].head.prev; b != &bcache[i].head; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache[i].lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
}

// kernel/bio.c:123
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);
  uint i = b->blockno % NBUCKET;
  acquire(&bcache[i].lock);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache[i].head.next;
    b->prev = &bcache[i].head;
    bcache[i].head.next->prev = b;
    bcache[i].head.next = b;
  }
  
  release(&bcache[i].lock);
}

// kernel/bio.c:145
void
bpin(struct buf *b) {
  uint i = b->blockno % NBUCKET;
  acquire(&bcache[i].lock);
  b->refcnt++;
  release(&bcache[i].lock);
}

// kernel/bio.c:154
void
bunpin(struct buf *b) {
  uint i = b->blockno % NBUCKET;
  acquire(&bcache[i].lock);
  b->refcnt--;
  release(&bcache[i].lock);
}
```

Besides, because each `bcache` has its own spinlock so we need to increase the maximum number of lock `NLOCK` in `kernel/spinlock.c`. Below is `make grade` output

![make_grade.png](./images/make_grade.png)

## 2. 遇到的困难以及收获

- Implementing this lab is not hard. 
- The hard part of this lab is how to come with a new design of lock to reduce contention. This lab introduce two ways to solve this problem: per-CPU lock and per-hash-bucket lock. Both ideas are interesting and can be applied in real world.

## 3. 对课程或Lab的意见和建议

无

## 4. 参考文献

- [lock lab hints on MIT website](https://pdos.csail.mit.edu/6.828/2020/labs/lock.html)
- Chapter 6 and 8 of xv6 book.