# xv6 Interrupts 

- [xv6 Interrupts](#xv6-interrupts)
  - [1. Interrupts in kernel space](#1-interrupts-in-kernel-space)
    - [1.1 How does kernel install handler for interrupts in kernel space?](#11-how-does-kernel-install-handler-for-interrupts-in-kernel-space)
    - [1.2 How is an interrupt in kernel space handled?](#12-how-is-an-interrupt-in-kernel-space-handled)
  - [2. Interrupts in user space](#2-interrupts-in-user-space)
    - [2.1 How does kernel install handler for interrupts in user space?](#21-how-does-kernel-install-handler-for-interrupts-in-user-space)
    - [2.2 How is an interrupt in user space handled?](#22-how-is-an-interrupt-in-user-space-handled)
    - [2.3 Why "trampoline"?](#23-why-trampoline)

## 1. Interrupts in kernel space

### 1.1 How does kernel install handler for interrupts in kernel space?

qemu loads kernel at 0x80000000 and causes each CPU to jump there. 
`kernel.ld` [[kernel/kernel.ld](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/kernel.ld)] put 
`entry.S` [[kernel/entry.S](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/entry.S)] 
at 0x80000000 and CPU starts executing `_entry` function, which set up a stack 
for C program to run and jump to function `start()` in 
`start.c` [[kernel/start.c:21](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/start.c#L21)].

`start()` initializes a machine-mode timer interrupt in 
`timerinit()` [[kernel/start.c:57](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/start.c#L57)], 
disable paging and write `medeleg`, `mideleg` and `sie` registers to delegate all 
interrupts and exceptions to supervisor mode [[kernel/start.c:36](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/start.c#L36)]. 
It also sets up `mepc` and `mstatus.MPP` to switch to supervisor mode and jump to 
`main()` in `main.c` [[kernel/main.c:11](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/main.c#L11)].

`main()` creates kernel page table and turn on kernel paging. Kernel pagetable is created by `kvmmake()` , 
in which it maps the trampoline page for trap entry/exit to the highest virtual address 
in kernel pagetable [[kernel/vm.c:44](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/vm.c#L44)]. 
After that, it installs kernel trap vector by writing `kernelvec` address to `stvec` register 
in `trapinithart()` [[kernel/trap.c:29](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L29)].

From this point, all interrupts will trap to `kernelvec()` 
[[kernel/kernelvec.S:10](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/kernelvec.S#L10)]. 

### 1.2 How is an interrupt in kernel space handled?

When an interrupt occur in kernel mode, the following things happen:
- RISC-V hardware does some saving context works, like saving interrupt enabling status, current mode and `pc`
- `pc` is set to `stvec`, which points to `kernelvec()`
- `kernelvec` save all registers into its stack and then call `kerneltrap()`  in `trap.c` 
[[kernel/trap.c:134](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L134)]. 
- `kerneltrap` does some check on `sstatus` register then call `devintr()` to handle the interrupt. [[kernel/trap.c:146](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L146)]
- If the interrupt is a timer interrupt from machine mode, `kerneltrap` calls `yield` to give up the CPU for other processes. [[kernel/trap.c:153](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L153)]
- After `kerneltrap` returns, `kernelvec` will restores all saved register by coping data from its stack to registers, then unallocate stack [[kernel/kernelvec.S:51](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/kernelvec.S#L51)]
- Call `sret`, which tells hardware to restore context to the point before the interrupt occurs.
[[kernel/kernelvec.S:86](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/kernelvec.S#L86)]

## 2. Interrupts in user space

### 2.1 How does kernel install handler for interrupts in user space?
**Summary**:

user space asks for new process -> `fork()` -> `allocproc()` -> `forkret()` -> `usertrapret()` -> new process in user space

**Details**:

- `userinit()` [[kernel/proc.c:226](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L226)] 
sets up the first user process, which initializes the shell.
- When users want to run a program, the shell call `fork()` and `exec()` to 
allocate new process and load program code into memory.
- `fork()` calls `allocproc()` to allocate new process, in which it sets up new context to start at 
`forkret` [[kernel/proc.c:141](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L141)]. 
- `forkret` calls `usertrapret()` to let process return to user space 
[[kernel/proc.c:523](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L523)]. 
- `usertrapret` sets the `stvec` register to `uservec`. By this way all syscalls, 
interrupts and exceptions will cause `pc` jump to `uservec()` in `trampoline.S` 
[[kernel/trampoline.S:16](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#L16)].

### 2.2 How is an interrupt in user space handled?

**Summary**:

user space -> `uservec()` -> `usertrap()` -> `kerneltrap()` -> `kerneltrapret()` -> `usertrapret()` -> user space

**Details**:

- Interrupt from user space start at `uservec()` in supervisor mode but RISC-V does not switch the page table during trap, so at that time `satp` holds user page table. 
- To continue executing `satp` must be set to kernel page table, xv6 resolves this problem by mapping trampoline page to the 
same virtual address in both kernel address space  [[kernel/vm.c:42](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/vm.c#L42)] 
and user address space [[kernel/proc.c:181](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L181)]. 
- When `uservec` starts, `sscratch` holds process's trapframe, which is saved by `userret` 
[[kernel/trampoline.S:137](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#L137)]. 
It swaps `a0` and `sscratch` then use `a0` to save all other registers in process's trapframe 
[[kernel/trampoline.S:29](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#29)]. 
- `uservec` switch to kernel context by restoring kernel stack pointer and page table
[[kernel/trampoline.S:67-79](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#L67)]
- `uservec` calls `usertrap()` to handle the traps, which sends all the interrupts and exceptions to `kerneltrap()` by setting `stvec` to `kernelvec` [[kernel/trap.c:37](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L37)].
- When kernel has finished handling the traps, it calls `usertrapret()` which prepare to return to user space. 
- `usertrapret` disables interrupts and change `stvec` back to `uservec` 
[[kernel/trap.c:97](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#87)]. 
It also set up trapframe values that `uservec` will need when process next re-enters 
the kernel and restore `pc`, `sstatus` and `satp` to prepare for continuing user program execution. 
After that, it calls `userret` to return to user space.
- `userret` takes process's trapframe and pagetable as arguments. 
It first switchs to the user page table then restore all saved all registers from trapframe except `a0`. 
Finally, it swaps `a0` and `sscratch`, which restores user `a0` and save trapframe 
to `sscratch` for later use in `uservec`, then call `sret` to continue from user `pc` in user mode.

### 2.3 Why "trampoline"?
- The page is called "trampoline" because it "bounces" between kernel and user space.