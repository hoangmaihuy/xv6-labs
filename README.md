# Lab 6: Multithreading 实习报告

| 姓名 | 学号 | 日期 |
| --- | --- | --- |
| 枚辉煌 | 1800094810 | 2021/03/31 |

- [Lab 6: Multithreading 实习报告](#lab-6-multithreading-实习报告)
  - [1. 实验总结](#1-实验总结)
    - [Exercise 1: Uthread](#exercise-1-uthread)
    - [Exercise 2: Using thread](#exercise-2-using-thread)
    - [Exercise 3: Barrier](#exercise-3-barrier)
  - [Result](#result)
  - [2. 遇到的困难以及收获](#2-遇到的困难以及收获)
  - [3. 对课程或Lab的意见和建议](#3-对课程或lab的意见和建议)
  - [4. 参考文献](#4-参考文献)

## 1. 实验总结

### Exercise 1: Uthread
- First we declare `struct thread_context` to save thread context between thread switching. `thread_context`'s content is identical with process's `struct context`, only saves return address, stack pointer and callee-saved registers. Caller-saved registers are saved in caller's stack frame and will be restored by caller function when callee function returns, so we don't have to save them.
```c
// user/uthread.c
struct thread_context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

struct thread {
  char                  stack[STACK_SIZE]; /* the thread's stack */
  int                   state;             /* FREE, RUNNING, RUNNABLE */
  struct thread_context context;
};
```

- In `thread_create`, we initialize thread's context to let it start execute at given `func` address. Because stack grows downward, so stack pointer should point to `t->stack + STACK_SIZE`
```c
// user/uthread.c
void 
thread_create(void (*func)())
{
  ...
  memset(&t->context, 0, sizeof(t->context));
  t->context.ra = (uint64)func;
  t->context.sp = (uint64)t->stack + STACK_SIZE;
}
```

- `thread_switch` is similar to process's context switching in `swtch.S`. It takes address of two `struct thread_context`: old context and new context, saves current context in the first struct by using store instruction `sd`, copies new context to registers by using load instruction `ld`.
```c
// user/uthread.c
extern void thread_switch(struct thread_context* old, struct thread_context* new);

// user/uthread_switch.S
	.globl thread_switch
thread_switch:
    sd ra, 0(a0)
    sd sp, 8(a0)
    sd s0, 16(a0)
    sd s1, 24(a0)
    sd s2, 32(a0)
    sd s3, 40(a0)
    sd s4, 48(a0)
    sd s5, 56(a0)
    sd s6, 64(a0)
    sd s7, 72(a0)
    sd s8, 80(a0)
    sd s9, 88(a0)
    sd s10, 96(a0)
    sd s11, 104(a0)

    ld ra, 0(a1)
    ld sp, 8(a1)
    ld s0, 16(a1)
    ld s1, 24(a1)
    ld s2, 32(a1)
    ld s3, 40(a1)
    ld s4, 48(a1)
    ld s5, 56(a1)
    ld s6, 64(a1)
    ld s7, 72(a1)
    ld s8, 80(a1)
    ld s9, 88(a1)
    ld s10, 96(a1)
    ld s11, 104(a1)
	ret    /* return to ra */
```
- In `thread_schedule`, calls `thread_switch` to switch contexts between current thread and next thread.
```c
// user/uthread.c
void 
thread_schedule(void)
{
  ...
  if (current_thread != next_thread) {         
    next_thread->state = RUNNING;
    t = current_thread;
    current_thread = next_thread;
    thread_switch(&t->context, &next_thread->context);
  } else
    next_thread = 0;
}
```

### Exercise 2: Using thread
Q: Why are there missing keys with 2 threads, but not with 1 thread? Identify a sequence of events with 2 threads that can lead to a key being missing. Submit your sequence with a short explanation in answers-thread.txt

A: Race condition: When two threads insert at the same time into a same bucket, updating table's first element `(*p = e)` can cause missing entry.

Solution: Instead of using a global lock, each bucket will have its own lock. Because operations on a bucket do not affect other buckets, using per-bucket lock may reduce the amount of time waiting for lock to release.

- Declare `NBUCKET` mutexes
```c
// notxv6/ph.c:19
pthread_mutex_t lock[NBUCKET];
```

- Initialize mutexes
```c
// notxv6/ph.c
int
main(int argc, char *argv[])
{
  ...
  for (int i = 0; i < NBUCKET; i++) {
    pthread_mutex_init(&lock[i], NULL);
  }
  ...
}

```
- Add mutex protection when accessing a bucket data in `put` and `get`
```c
// notxv6/ph.c
static 
void put(int key, int value)
{
  int i = key % NBUCKET;

  // is the key already present?
  struct entry *e = 0;
  pthread_mutex_lock(&lock[i]);
  for (e = table[i]; e != 0; e = e->next) {
    if (e->key == key)
      break;
  }
  if(e){
    // update the existing key.
    e->value = value;
  } else {
    // the new is new.
    insert(key, value, &table[i], table[i]);
  }
  pthread_mutex_unlock(&lock[i]);
}

static struct entry*
get(int key)
{
  int i = key % NBUCKET;

  pthread_mutex_lock(&lock[i]);
  struct entry *e = 0;
  for (e = table[i]; e != 0; e = e->next) {
    if (e->key == key) break;
  }
  pthread_mutex_unlock(&lock[i]);
  return e;
}
```

### Exercise 3: Barrier

Solution: We use a mutex `barrier_mutex` to protect barrier data `nthread` and `round`. When a thread reaches the barrier, it waits for mutex to unlock then increase `nthread`. To prevent the thread from racing around the loop and reaching the barrier again, we put the thread into sleep by making it wait for conditional variable `barrier_cond`. When the last thread reaches barrier, it will broadcast other threads to continue their execution.

```c
// notxv6/barrier.c
static void 
barrier()
{
  pthread_mutex_lock(&bstate.barrier_mutex);
  ++bstate.nthread;
  if (bstate.nthread < nthread)
    pthread_cond_wait(&bstate.barrier_cond, &bstate.barrier_mutex);
  else
  {
    bstate.round++;
    bstate.nthread = 0;
    pthread_cond_broadcast(&bstate.barrier_cond);
  }
  pthread_mutex_unlock(&bstate.barrier_mutex);
}
```

## Result
- `make grade` output

![make_grade](images/make_grade.png)

## 2. 遇到的困难以及收获
- This lab is easy overall. I had a bug in uthread exercise, in which I set stack pointer to `p->stack` instead of `p->stack + STACK_SIZE` and it causes segment fault.
- This lab helps me revise multithread programming learned from ICS.
## 3. 对课程或Lab的意见和建议
None
## 4. 参考文献
- [thread lab hints on MIT website](https://pdos.csail.mit.edu/6.828/2020/labs/thread.html)