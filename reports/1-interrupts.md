# xv6 Interrupts 

## Trap in kernel mode

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
`kernelvec` save all registers into its stack and then call `kerneltrap()`  in `trap.c` 
[[kernel/trap.c:134](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L134)]. 
`kerneltrap` does some check on `sstatus` register then call `devintr()` to handle the interrupt. 
If it's a timer interrupt, `kerneltrap` calls `yield` to give up the CPU for other processes.

After `kerneltrap` returns, `kernelvec` will restores all saved register and 
call `sret` to return to the point before the interrupt occurs.

## Trap in user mode

`userinit()` [[kernel/proc.c:226](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L226)] 
sets up the first user process, which initializes the shell.
When users want to run a program, the shell call `fork()` and `exec()` to 
allocate new process and load program code into memory.

`fork()` calls `allocproc()` to allocate new process, in which it sets up new context to start at 
`forkret` [[kernel/proc.c:141](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L141)]. 
`forkret` calls `usertrapret()` to let process return to user space 
[[kernel/proc.c:523](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L523)]. 
`usertrapret` sets the `stvec` register to `uservec`, by this way all syscalls, 
interrupts and exceptions will cause `pc` jump to `uservec()` in `trampoline.S` 
[[kernel/trampoline.S:16](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#L16)].

Traps from user space start at `uservec()` in supervisor mode but RISC-V does not switch the page table 
during trap so at that time `satp` holds user page table. To continue executing `satp` must be 
set to kernel page table, xv6 resolves this problem by mapping trampoline page to the 
same virtual address in both kernel address space  [[kernel/vm.c:42](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/vm.c#L42)] 
and user address space [[kernel/proc.c:181](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.c#L181)]. 
The page is called "trampoline" because it "bounces" between kernel and user space.

When `uservec` starts, `sscratch` holds process's trapframe, which is saved by `userret` 
[[kernel/trampoline.S:137](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#L137)]. 
It swaps `a0` and `sscratch` then use `a0` to save all other registers in process's trapframe 
[[kernel/trampoline.S:29](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trampoline.S#29)]. 
After fully switching to kernel mode, it calls `usertrap()` to handle the traps 
[[kernel/trap.c:37](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#L37)], 
which sends the interrupts and exceptions to `kerneltrap()` by setting `stvec` to `kernelvec`. 
When kernel finish handling the traps, it calls `usertrapret()` which prepare to return to user space. 

`usertrapret` disables interrupts and change `stvec` back to `uservec` 
[[kernel/trap.c:97](https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/trap.c#87)]. 
It also set up trapframe values that `uservec` will need when process next re-enters 
the kernel and restore `pc`, `sstatus` and `satp` to prepare for continuing user program execution. 
Finally, it calls `userret` to return to user space.

`userret` parameters are process's trapframe and pagetable. 
It first switchs to the user page table then restore all saved all registers from trapframe except `a0`. 
Finally, it swaps `a0` and `sscratch`, which restores user `a0` and save trapframe 
to `sscratch` for later use in `uservec`, then call `sret` to return to continue from user `pc` in user mode.