
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	ca478793          	addi	a5,a5,-860 # 80005d00 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6278793          	addi	a5,a5,-414 # 80000f08 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3ce080e7          	jalr	974(ra) # 800024f4 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	85a080e7          	jalr	-1958(ra) # 80001a28 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	05e080e7          	jalr	94(ra) # 8000223c <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	284080e7          	jalr	644(ra) # 8000249e <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ad8080e7          	jalr	-1320(ra) # 80000d0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	97c080e7          	jalr	-1668(ra) # 80000c5a <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	24e080e7          	jalr	590(ra) # 8000254a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a02080e7          	jalr	-1534(ra) # 80000d0e <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f72080e7          	jalr	-142(ra) # 800023c2 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	758080e7          	jalr	1880(ra) # 80000bca <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	650080e7          	jalr	1616(ra) # 80000c5a <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5a0080e7          	jalr	1440(ra) # 80000d0e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	436080e7          	jalr	1078(ra) # 80000bca <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3e0080e7          	jalr	992(ra) # 80000bca <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	408080e7          	jalr	1032(ra) # 80000c0e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	476080e7          	jalr	1142(ra) # 80000cae <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b0c080e7          	jalr	-1268(ra) # 800023c2 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8ec080e7          	jalr	-1812(ra) # 8000223c <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	25a080e7          	jalr	602(ra) # 80000c5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2fc080e7          	jalr	764(ra) # 80000d0e <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	306080e7          	jalr	774(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1f8080e7          	jalr	504(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	298080e7          	jalr	664(ra) # 80000d0e <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0ce080e7          	jalr	206(ra) # 80000bca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	126080e7          	jalr	294(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	1c2080e7          	jalr	450(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1fc080e7          	jalr	508(ra) # 80000d56 <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	198080e7          	jalr	408(ra) # 80000d0e <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <kcountfree>:

// Count free mem size
uint64
kcountfree(void)
{
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 freemem = 0;

  acquire(&kmem.lock);
    80000b8a:	00011497          	auipc	s1,0x11
    80000b8e:	da648493          	addi	s1,s1,-602 # 80011930 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	0c6080e7          	jalr	198(ra) # 80000c5a <acquire>
  for (r = kmem.freelist; r; r = r->next)
    80000b9c:	6c9c                	ld	a5,24(s1)
    80000b9e:	c785                	beqz	a5,80000bc6 <kcountfree+0x46>
  uint64 freemem = 0;
    80000ba0:	4481                	li	s1,0
    freemem += PGSIZE;
    80000ba2:	6705                	lui	a4,0x1
    80000ba4:	94ba                	add	s1,s1,a4
  for (r = kmem.freelist; r; r = r->next)
    80000ba6:	639c                	ld	a5,0(a5)
    80000ba8:	fff5                	bnez	a5,80000ba4 <kcountfree+0x24>
  release(&kmem.lock);
    80000baa:	00011517          	auipc	a0,0x11
    80000bae:	d8650513          	addi	a0,a0,-634 # 80011930 <kmem>
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	15c080e7          	jalr	348(ra) # 80000d0e <release>
  return freemem;
}
    80000bba:	8526                	mv	a0,s1
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  uint64 freemem = 0;
    80000bc6:	4481                	li	s1,0
    80000bc8:	b7cd                	j	80000baa <kcountfree+0x2a>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e18080e7          	jalr	-488(ra) # 80001a0c <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	de6080e7          	jalr	-538(ra) # 80001a0c <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dda080e7          	jalr	-550(ra) # 80001a0c <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dc2080e7          	jalr	-574(ra) # 80001a0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	d82080e7          	jalr	-638(ra) # 80001a0c <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a2080e7          	jalr	-1886(ra) # 80000548 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	d56080e7          	jalr	-682(ra) # 80001a0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	842080e7          	jalr	-1982(ra) # 80000548 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7fa080e7          	jalr	2042(ra) # 80000548 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ce09                	beqz	a2,80000d76 <memset+0x20>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	fff6071b          	addiw	a4,a2,-1
    80000d64:	1702                	slli	a4,a4,0x20
    80000d66:	9301                	srli	a4,a4,0x20
    80000d68:	0705                	addi	a4,a4,1
    80000d6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fee79de3          	bne	a5,a4,80000d6c <memset+0x16>
  }
  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d82:	ca05                	beqz	a2,80000db2 <memcmp+0x36>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	1682                	slli	a3,a3,0x20
    80000d8a:	9281                	srli	a3,a3,0x20
    80000d8c:	0685                	addi	a3,a3,1
    80000d8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	00e79863          	bne	a5,a4,80000da8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9c:	0505                	addi	a0,a0,1
    80000d9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da0:	fed518e3          	bne	a0,a3,80000d90 <memcmp+0x14>
  }

  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	a019                	j	80000dac <memcmp+0x30>
      return *s1 - *s2;
    80000da8:	40e7853b          	subw	a0,a5,a4
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
  return 0;
    80000db2:	4501                	li	a0,0
    80000db4:	bfe5                	j	80000dac <memcmp+0x30>

0000000080000db6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbc:	00a5f963          	bgeu	a1,a0,80000dce <memmove+0x18>
    80000dc0:	02061713          	slli	a4,a2,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	00e587b3          	add	a5,a1,a4
    80000dca:	02f56563          	bltu	a0,a5,80000df4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dce:	fff6069b          	addiw	a3,a2,-1
    80000dd2:	ce11                	beqz	a2,80000dee <memmove+0x38>
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96ae                	add	a3,a3,a1
    80000ddc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dde:	0585                	addi	a1,a1,1
    80000de0:	0785                	addi	a5,a5,1
    80000de2:	fff5c703          	lbu	a4,-1(a1)
    80000de6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dea:	fed59ae3          	bne	a1,a3,80000dde <memmove+0x28>

  return dst;
}
    80000dee:	6422                	ld	s0,8(sp)
    80000df0:	0141                	addi	sp,sp,16
    80000df2:	8082                	ret
    d += n;
    80000df4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df6:	fff6069b          	addiw	a3,a2,-1
    80000dfa:	da75                	beqz	a2,80000dee <memmove+0x38>
    80000dfc:	02069613          	slli	a2,a3,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	fff64613          	not	a2,a2
    80000e06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e08:	17fd                	addi	a5,a5,-1
    80000e0a:	177d                	addi	a4,a4,-1
    80000e0c:	0007c683          	lbu	a3,0(a5)
    80000e10:	00d70023          	sb	a3,0(a4) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e14:	fec79ae3          	bne	a5,a2,80000e08 <memmove+0x52>
    80000e18:	bfd9                	j	80000dee <memmove+0x38>

0000000080000e1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1a:	1141                	addi	sp,sp,-16
    80000e1c:	e406                	sd	ra,8(sp)
    80000e1e:	e022                	sd	s0,0(sp)
    80000e20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	f94080e7          	jalr	-108(ra) # 80000db6 <memmove>
}
    80000e2a:	60a2                	ld	ra,8(sp)
    80000e2c:	6402                	ld	s0,0(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e38:	ce11                	beqz	a2,80000e54 <strncmp+0x22>
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	cf89                	beqz	a5,80000e58 <strncmp+0x26>
    80000e40:	0005c703          	lbu	a4,0(a1)
    80000e44:	00f71a63          	bne	a4,a5,80000e58 <strncmp+0x26>
    n--, p++, q++;
    80000e48:	367d                	addiw	a2,a2,-1
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4e:	f675                	bnez	a2,80000e3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	a809                	j	80000e64 <strncmp+0x32>
    80000e54:	4501                	li	a0,0
    80000e56:	a039                	j	80000e64 <strncmp+0x32>
  if(n == 0)
    80000e58:	ca09                	beqz	a2,80000e6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5a:	00054503          	lbu	a0,0(a0)
    80000e5e:	0005c783          	lbu	a5,0(a1)
    80000e62:	9d1d                	subw	a0,a0,a5
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strncmp+0x32>

0000000080000e6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e74:	872a                	mv	a4,a0
    80000e76:	8832                	mv	a6,a2
    80000e78:	367d                	addiw	a2,a2,-1
    80000e7a:	01005963          	blez	a6,80000e8c <strncpy+0x1e>
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	fef70fa3          	sb	a5,-1(a4)
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	f7f5                	bnez	a5,80000e76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8c:	00c05d63          	blez	a2,80000ea6 <strncpy+0x38>
    80000e90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e98:	fff6c793          	not	a5,a3
    80000e9c:	9fb9                	addw	a5,a5,a4
    80000e9e:	010787bb          	addw	a5,a5,a6
    80000ea2:	fef048e3          	bgtz	a5,80000e92 <strncpy+0x24>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	addi	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addiw	a3,a2,-1
    80000eba:	1682                	slli	a3,a3,0x20
    80000ebc:	9281                	srli	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	addi	a1,a1,1
    80000ec8:	0785                	addi	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	4685                	li	a3,1
    80000ef0:	9e89                	subw	a3,a3,a0
    80000ef2:	00f6853b          	addw	a0,a3,a5
    80000ef6:	0785                	addi	a5,a5,1
    80000ef8:	fff7c703          	lbu	a4,-1(a5)
    80000efc:	fb7d                	bnez	a4,80000ef2 <strlen+0x14>
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	aec080e7          	jalr	-1300(ra) # 800019fc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	addi	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	ad0080e7          	jalr	-1328(ra) # 800019fc <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0d8080e7          	jalr	216(ra) # 8000101e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	790080e7          	jalr	1936(ra) # 800026de <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	dea080e7          	jalr	-534(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	002080e7          	jalr	2(ra) # 80001f60 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    printfinit();
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	80a080e7          	jalr	-2038(ra) # 80000778 <printfinit>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	614080e7          	jalr	1556(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f86:	00007517          	auipc	a0,0x7
    80000f8a:	11a50513          	addi	a0,a0,282 # 800080a0 <digits+0x60>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	604080e7          	jalr	1540(ra) # 80000592 <printf>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	13250513          	addi	a0,a0,306 # 800080c8 <digits+0x88>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5f4080e7          	jalr	1524(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	b3e080e7          	jalr	-1218(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	2a0080e7          	jalr	672(ra) # 8000124e <kvminit>
    kvminithart();   // turn on paging
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	068080e7          	jalr	104(ra) # 8000101e <kvminithart>
    procinit();      // process table
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	96e080e7          	jalr	-1682(ra) # 8000192c <procinit>
    trapinit();      // trap vectors
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	6f0080e7          	jalr	1776(ra) # 800026b6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	710080e7          	jalr	1808(ra) # 800026de <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	d54080e7          	jalr	-684(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	d62080e7          	jalr	-670(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80000fe6:	00002097          	auipc	ra,0x2
    80000fea:	f00080e7          	jalr	-256(ra) # 80002ee6 <binit>
    iinit();         // inode cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	590080e7          	jalr	1424(ra) # 8000357e <iinit>
    fileinit();      // file table
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	52a080e7          	jalr	1322(ra) # 80004520 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	e4a080e7          	jalr	-438(ra) # 80005e48 <virtio_disk_init>
    userinit();      // first user process
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	cec080e7          	jalr	-788(ra) # 80001cf2 <userinit>
    __sync_synchronize();
    8000100e:	0ff0000f          	fence
    started = 1;
    80001012:	4785                	li	a5,1
    80001014:	00008717          	auipc	a4,0x8
    80001018:	fef72c23          	sw	a5,-8(a4) # 8000900c <started>
    8000101c:	b789                	j	80000f5e <main+0x56>

000000008000101e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101e:	1141                	addi	sp,sp,-16
    80001020:	e422                	sd	s0,8(sp)
    80001022:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001024:	00008797          	auipc	a5,0x8
    80001028:	fec7b783          	ld	a5,-20(a5) # 80009010 <kernel_pagetable>
    8000102c:	83b1                	srli	a5,a5,0xc
    8000102e:	577d                	li	a4,-1
    80001030:	177e                	slli	a4,a4,0x3f
    80001032:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	addi	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	addi	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	addi	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	06850513          	addi	a0,a0,104 # 800080d0 <digits+0x90>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	aa4080e7          	jalr	-1372(ra) # 80000b20 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cca080e7          	jalr	-822(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srli	a5,s1,0xc
    80001098:	07aa                	slli	a5,a5,0xa
    8000109a:	0017e793          	ori	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addiw	s4,s4,-9
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	andi	s2,s2,511
    800010b0:	090e                	slli	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	andi	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srli	s1,s1,0xa
    800010c0:	04b2                	slli	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srli	a0,s3,0xc
    800010c8:	1ff57513          	andi	a0,a0,511
    800010cc:	050e                	slli	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	addi	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e8:	57fd                	li	a5,-1
    800010ea:	83e9                	srli	a5,a5,0x1a
    800010ec:	00b7f463          	bgeu	a5,a1,800010f4 <walkaddr+0xc>
    return 0;
    800010f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f2:	8082                	ret
{
    800010f4:	1141                	addi	sp,sp,-16
    800010f6:	e406                	sd	ra,8(sp)
    800010f8:	e022                	sd	s0,0(sp)
    800010fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fc:	4601                	li	a2,0
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f44080e7          	jalr	-188(ra) # 80001042 <walk>
  if(pte == 0)
    80001106:	c105                	beqz	a0,80001126 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001108:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110a:	0117f693          	andi	a3,a5,17
    8000110e:	4745                	li	a4,17
    return 0;
    80001110:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001112:	00e68663          	beq	a3,a4,8000111e <walkaddr+0x36>
}
    80001116:	60a2                	ld	ra,8(sp)
    80001118:	6402                	ld	s0,0(sp)
    8000111a:	0141                	addi	sp,sp,16
    8000111c:	8082                	ret
  pa = PTE2PA(*pte);
    8000111e:	00a7d513          	srli	a0,a5,0xa
    80001122:	0532                	slli	a0,a0,0xc
  return pa;
    80001124:	bfcd                	j	80001116 <walkaddr+0x2e>
    return 0;
    80001126:	4501                	li	a0,0
    80001128:	b7fd                	j	80001116 <walkaddr+0x2e>

000000008000112a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112a:	1101                	addi	sp,sp,-32
    8000112c:	ec06                	sd	ra,24(sp)
    8000112e:	e822                	sd	s0,16(sp)
    80001130:	e426                	sd	s1,8(sp)
    80001132:	1000                	addi	s0,sp,32
    80001134:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001136:	1552                	slli	a0,a0,0x34
    80001138:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000113c:	4601                	li	a2,0
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	ed253503          	ld	a0,-302(a0) # 80009010 <kernel_pagetable>
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	efc080e7          	jalr	-260(ra) # 80001042 <walk>
  if(pte == 0)
    8000114e:	cd09                	beqz	a0,80001168 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001150:	6108                	ld	a0,0(a0)
    80001152:	00157793          	andi	a5,a0,1
    80001156:	c38d                	beqz	a5,80001178 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001158:	8129                	srli	a0,a0,0xa
    8000115a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000115c:	9526                	add	a0,a0,s1
    8000115e:	60e2                	ld	ra,24(sp)
    80001160:	6442                	ld	s0,16(sp)
    80001162:	64a2                	ld	s1,8(sp)
    80001164:	6105                	addi	sp,sp,32
    80001166:	8082                	ret
    panic("kvmpa");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7050513          	addi	a0,a0,-144 # 800080d8 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("kvmpa");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f6050513          	addi	a0,a0,-160 # 800080d8 <digits+0x98>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080001188 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001188:	715d                	addi	sp,sp,-80
    8000118a:	e486                	sd	ra,72(sp)
    8000118c:	e0a2                	sd	s0,64(sp)
    8000118e:	fc26                	sd	s1,56(sp)
    80001190:	f84a                	sd	s2,48(sp)
    80001192:	f44e                	sd	s3,40(sp)
    80001194:	f052                	sd	s4,32(sp)
    80001196:	ec56                	sd	s5,24(sp)
    80001198:	e85a                	sd	s6,16(sp)
    8000119a:	e45e                	sd	s7,8(sp)
    8000119c:	0880                	addi	s0,sp,80
    8000119e:	8aaa                	mv	s5,a0
    800011a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a2:	777d                	lui	a4,0xfffff
    800011a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a8:	167d                	addi	a2,a2,-1
    800011aa:	00b609b3          	add	s3,a2,a1
    800011ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b2:	893e                	mv	s2,a5
    800011b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b8:	6b85                	lui	s7,0x1
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	e7e080e7          	jalr	-386(ra) # 80001042 <walk>
    800011cc:	c51d                	beqz	a0,800011fa <mappages+0x72>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	andi	a5,a5,1
    800011d2:	ef81                	bnez	a5,800011ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srli	s1,s1,0xc
    800011d6:	04aa                	slli	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	ori	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	03390863          	beq	s2,s3,80001212 <mappages+0x8a>
    a += PGSIZE;
    800011e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	bfc9                	j	800011ba <mappages+0x32>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	ef650513          	addi	a0,a0,-266 # 800080e0 <digits+0xa0>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	356080e7          	jalr	854(ra) # 80000548 <panic>
      return -1;
    800011fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011fc:	60a6                	ld	ra,72(sp)
    800011fe:	6406                	ld	s0,64(sp)
    80001200:	74e2                	ld	s1,56(sp)
    80001202:	7942                	ld	s2,48(sp)
    80001204:	79a2                	ld	s3,40(sp)
    80001206:	7a02                	ld	s4,32(sp)
    80001208:	6ae2                	ld	s5,24(sp)
    8000120a:	6b42                	ld	s6,16(sp)
    8000120c:	6ba2                	ld	s7,8(sp)
    8000120e:	6161                	addi	sp,sp,80
    80001210:	8082                	ret
  return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7e5                	j	800011fc <mappages+0x74>

0000000080001216 <kvmmap>:
{
    80001216:	1141                	addi	sp,sp,-16
    80001218:	e406                	sd	ra,8(sp)
    8000121a:	e022                	sd	s0,0(sp)
    8000121c:	0800                	addi	s0,sp,16
    8000121e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001220:	86ae                	mv	a3,a1
    80001222:	85aa                	mv	a1,a0
    80001224:	00008517          	auipc	a0,0x8
    80001228:	dec53503          	ld	a0,-532(a0) # 80009010 <kernel_pagetable>
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f5c080e7          	jalr	-164(ra) # 80001188 <mappages>
    80001234:	e509                	bnez	a0,8000123e <kvmmap+0x28>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	addi	sp,sp,16
    8000123c:	8082                	ret
    panic("kvmmap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eaa50513          	addi	a0,a0,-342 # 800080e8 <digits+0xa8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	302080e7          	jalr	770(ra) # 80000548 <panic>

000000008000124e <kvminit>:
{
    8000124e:	1101                	addi	sp,sp,-32
    80001250:	ec06                	sd	ra,24(sp)
    80001252:	e822                	sd	s0,16(sp)
    80001254:	e426                	sd	s1,8(sp)
    80001256:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	8c8080e7          	jalr	-1848(ra) # 80000b20 <kalloc>
    80001260:	00008797          	auipc	a5,0x8
    80001264:	daa7b823          	sd	a0,-592(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	aea080e7          	jalr	-1302(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	6605                	lui	a2,0x1
    80001278:	100005b7          	lui	a1,0x10000
    8000127c:	10000537          	lui	a0,0x10000
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f96080e7          	jalr	-106(ra) # 80001216 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100015b7          	lui	a1,0x10001
    80001290:	10001537          	lui	a0,0x10001
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f82080e7          	jalr	-126(ra) # 80001216 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6641                	lui	a2,0x10
    800012a0:	020005b7          	lui	a1,0x2000
    800012a4:	02000537          	lui	a0,0x2000
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f6e080e7          	jalr	-146(ra) # 80001216 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	00400637          	lui	a2,0x400
    800012b6:	0c0005b7          	lui	a1,0xc000
    800012ba:	0c000537          	lui	a0,0xc000
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f58080e7          	jalr	-168(ra) # 80001216 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c6:	00007497          	auipc	s1,0x7
    800012ca:	d3a48493          	addi	s1,s1,-710 # 80008000 <etext>
    800012ce:	46a9                	li	a3,10
    800012d0:	80007617          	auipc	a2,0x80007
    800012d4:	d3060613          	addi	a2,a2,-720 # 8000 <_entry-0x7fff8000>
    800012d8:	4585                	li	a1,1
    800012da:	05fe                	slli	a1,a1,0x1f
    800012dc:	852e                	mv	a0,a1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f38080e7          	jalr	-200(ra) # 80001216 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e6:	4699                	li	a3,6
    800012e8:	4645                	li	a2,17
    800012ea:	066e                	slli	a2,a2,0x1b
    800012ec:	8e05                	sub	a2,a2,s1
    800012ee:	85a6                	mv	a1,s1
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f24080e7          	jalr	-220(ra) # 80001216 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fa:	46a9                	li	a3,10
    800012fc:	6605                	lui	a2,0x1
    800012fe:	00006597          	auipc	a1,0x6
    80001302:	d0258593          	addi	a1,a1,-766 # 80007000 <_trampoline>
    80001306:	04000537          	lui	a0,0x4000
    8000130a:	157d                	addi	a0,a0,-1
    8000130c:	0532                	slli	a0,a0,0xc
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f08080e7          	jalr	-248(ra) # 80001216 <kvmmap>
}
    80001316:	60e2                	ld	ra,24(sp)
    80001318:	6442                	ld	s0,16(sp)
    8000131a:	64a2                	ld	s1,8(sp)
    8000131c:	6105                	addi	sp,sp,32
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	addi	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	fc26                	sd	s1,56(sp)
    80001328:	f84a                	sd	s2,48(sp)
    8000132a:	f44e                	sd	s3,40(sp)
    8000132c:	f052                	sd	s4,32(sp)
    8000132e:	ec56                	sd	s5,24(sp)
    80001330:	e85a                	sd	s6,16(sp)
    80001332:	e45e                	sd	s7,8(sp)
    80001334:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001336:	03459793          	slli	a5,a1,0x34
    8000133a:	e795                	bnez	a5,80001366 <uvmunmap+0x46>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	892e                	mv	s2,a1
    80001340:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	0632                	slli	a2,a2,0xc
    80001344:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001348:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	6b05                	lui	s6,0x1
    8000134c:	0735e863          	bltu	a1,s3,800013bc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001350:	60a6                	ld	ra,72(sp)
    80001352:	6406                	ld	s0,64(sp)
    80001354:	74e2                	ld	s1,56(sp)
    80001356:	7942                	ld	s2,48(sp)
    80001358:	79a2                	ld	s3,40(sp)
    8000135a:	7a02                	ld	s4,32(sp)
    8000135c:	6ae2                	ld	s5,24(sp)
    8000135e:	6b42                	ld	s6,16(sp)
    80001360:	6ba2                	ld	s7,8(sp)
    80001362:	6161                	addi	sp,sp,80
    80001364:	8082                	ret
    panic("uvmunmap: not aligned");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	d8a50513          	addi	a0,a0,-630 # 800080f0 <digits+0xb0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	d9250513          	addi	a0,a0,-622 # 80008108 <digits+0xc8>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	d9250513          	addi	a0,a0,-622 # 80008118 <digits+0xd8>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	d9a50513          	addi	a0,a0,-614 # 80008130 <digits+0xf0>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013a8:	0532                	slli	a0,a0,0xc
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	67a080e7          	jalr	1658(ra) # 80000a24 <kfree>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	f9397ce3          	bgeu	s2,s3,80001350 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	c80080e7          	jalr	-896(ra) # 80001042 <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d54d                	beqz	a0,80001376 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dbcd                	beqz	a5,80001386 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fb778ee3          	beq	a5,s7,80001396 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x92>
    800013e2:	b7d1                	j	800013a6 <uvmunmap+0x86>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	732080e7          	jalr	1842(ra) # 80000b20 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	958080e7          	jalr	-1704(ra) # 80000d56 <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	addi	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	6f2080e7          	jalr	1778(ra) # 80000b20 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	91a080e7          	jalr	-1766(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	d3a080e7          	jalr	-710(ra) # 80001188 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	95a080e7          	jalr	-1702(ra) # 80000db6 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	addi	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cd450513          	addi	a0,a0,-812 # 80008148 <digits+0x108>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	addi	a5,a5,-1
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	767d                	lui	a2,0xfffff
    800014a0:	8f71                	and	a4,a4,a2
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff1                	and	a5,a5,a2
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	addi	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e5e080e7          	jalr	-418(ra) # 80001320 <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	addi	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	addi	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6985                	lui	s3,0x1
    800014e8:	19fd                	addi	s3,s3,-1
    800014ea:	95ce                	add	a1,a1,s3
    800014ec:	79fd                	lui	s3,0xfffff
    800014ee:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	628080e7          	jalr	1576(ra) # 80000b20 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	84e080e7          	jalr	-1970(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	c6e080e7          	jalr	-914(ra) # 80001188 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	addi	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	4d0080e7          	jalr	1232(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	addi	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	addi	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a821                	j	800015a8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001594:	0532                	slli	a0,a0,0xc
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	fe0080e7          	jalr	-32(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    8000159e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a2:	04a1                	addi	s1,s1,8
    800015a4:	03248163          	beq	s1,s2,800015c6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015aa:	00f57793          	andi	a5,a0,15
    800015ae:	ff3782e3          	beq	a5,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b2:	8905                	andi	a0,a0,1
    800015b4:	d57d                	beqz	a0,800015a2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	bb250513          	addi	a0,a0,-1102 # 80008168 <digits+0x128>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c6:	8552                	mv	a0,s4
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	45c080e7          	jalr	1116(ra) # 80000a24 <kfree>
}
    800015d0:	70a2                	ld	ra,40(sp)
    800015d2:	7402                	ld	s0,32(sp)
    800015d4:	64e2                	ld	s1,24(sp)
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	69a2                	ld	s3,8(sp)
    800015da:	6a02                	ld	s4,0(sp)
    800015dc:	6145                	addi	sp,sp,48
    800015de:	8082                	ret

00000000800015e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e0:	1101                	addi	sp,sp,-32
    800015e2:	ec06                	sd	ra,24(sp)
    800015e4:	e822                	sd	s0,16(sp)
    800015e6:	e426                	sd	s1,8(sp)
    800015e8:	1000                	addi	s0,sp,32
    800015ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ec:	e999                	bnez	a1,80001602 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ee:	8526                	mv	a0,s1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f86080e7          	jalr	-122(ra) # 80001576 <freewalk>
}
    800015f8:	60e2                	ld	ra,24(sp)
    800015fa:	6442                	ld	s0,16(sp)
    800015fc:	64a2                	ld	s1,8(sp)
    800015fe:	6105                	addi	sp,sp,32
    80001600:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001602:	6605                	lui	a2,0x1
    80001604:	167d                	addi	a2,a2,-1
    80001606:	962e                	add	a2,a2,a1
    80001608:	4685                	li	a3,1
    8000160a:	8231                	srli	a2,a2,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d12080e7          	jalr	-750(ra) # 80001320 <uvmunmap>
    80001616:	bfe1                	j	800015ee <uvmfree+0xe>

0000000080001618 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001618:	c679                	beqz	a2,800016e6 <uvmcopy+0xce>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	0880                	addi	s0,sp,80
    80001630:	8b2a                	mv	s6,a0
    80001632:	8aae                	mv	s5,a1
    80001634:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001638:	4601                	li	a2,0
    8000163a:	85ce                	mv	a1,s3
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	a04080e7          	jalr	-1532(ra) # 80001042 <walk>
    80001646:	c531                	beqz	a0,80001692 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001648:	6118                	ld	a4,0(a0)
    8000164a:	00177793          	andi	a5,a4,1
    8000164e:	cbb1                	beqz	a5,800016a2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001650:	00a75593          	srli	a1,a4,0xa
    80001654:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001658:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	4c4080e7          	jalr	1220(ra) # 80000b20 <kalloc>
    80001664:	892a                	mv	s2,a0
    80001666:	c939                	beqz	a0,800016bc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001668:	6605                	lui	a2,0x1
    8000166a:	85de                	mv	a1,s7
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	74a080e7          	jalr	1866(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001674:	8726                	mv	a4,s1
    80001676:	86ca                	mv	a3,s2
    80001678:	6605                	lui	a2,0x1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	8556                	mv	a0,s5
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	b0a080e7          	jalr	-1270(ra) # 80001188 <mappages>
    80001686:	e515                	bnez	a0,800016b2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	6785                	lui	a5,0x1
    8000168a:	99be                	add	s3,s3,a5
    8000168c:	fb49e6e3          	bltu	s3,s4,80001638 <uvmcopy+0x20>
    80001690:	a081                	j	800016d0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	ae650513          	addi	a0,a0,-1306 # 80008178 <digits+0x138>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	af650513          	addi	a0,a0,-1290 # 80008198 <digits+0x158>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e9e080e7          	jalr	-354(ra) # 80000548 <panic>
      kfree(mem);
    800016b2:	854a                	mv	a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	370080e7          	jalr	880(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016bc:	4685                	li	a3,1
    800016be:	00c9d613          	srli	a2,s3,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	c5a080e7          	jalr	-934(ra) # 80001320 <uvmunmap>
  return -1;
    800016ce:	557d                	li	a0,-1
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
  return 0;
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret

00000000800016ea <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ea:	1141                	addi	sp,sp,-16
    800016ec:	e406                	sd	ra,8(sp)
    800016ee:	e022                	sd	s0,0(sp)
    800016f0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f2:	4601                	li	a2,0
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	94e080e7          	jalr	-1714(ra) # 80001042 <walk>
  if(pte == 0)
    800016fc:	c901                	beqz	a0,8000170c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fe:	611c                	ld	a5,0(a0)
    80001700:	9bbd                	andi	a5,a5,-17
    80001702:	e11c                	sd	a5,0(a0)
}
    80001704:	60a2                	ld	ra,8(sp)
    80001706:	6402                	ld	s0,0(sp)
    80001708:	0141                	addi	sp,sp,16
    8000170a:	8082                	ret
    panic("uvmclear");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	aac50513          	addi	a0,a0,-1364 # 800081b8 <digits+0x178>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e34080e7          	jalr	-460(ra) # 80000548 <panic>

000000008000171c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	c6bd                	beqz	a3,8000178a <copyout+0x6e>
{
    8000171e:	715d                	addi	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	addi	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8c2e                	mv	s8,a1
    8000173a:	8a32                	mv	s4,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a015                	j	80001766 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001744:	9562                	add	a0,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	85d2                	mv	a1,s4
    8000174c:	41250533          	sub	a0,a0,s2
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	666080e7          	jalr	1638(ra) # 80000db6 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	97a080e7          	jalr	-1670(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177e:	fc99f3e3          	bgeu	s3,s1,80001744 <copyout+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	b7c1                	j	80001744 <copyout+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyout+0x74>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a8:	c6bd                	beqz	a3,80001816 <copyin+0x6e>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	e062                	sd	s8,0(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8b2a                	mv	s6,a0
    800017c4:	8a2e                	mv	s4,a1
    800017c6:	8c32                	mv	s8,a2
    800017c8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6a85                	lui	s5,0x1
    800017ce:	a015                	j	800017f2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d0:	9562                	add	a0,a0,s8
    800017d2:	0004861b          	sext.w	a2,s1
    800017d6:	412505b3          	sub	a1,a0,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	fffff097          	auipc	ra,0xfffff
    800017e0:	5da080e7          	jalr	1498(ra) # 80000db6 <memmove>

    len -= n;
    800017e4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ea:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ee:	02098263          	beqz	s3,80001812 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f6:	85ca                	mv	a1,s2
    800017f8:	855a                	mv	a0,s6
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	8ee080e7          	jalr	-1810(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001802:	cd01                	beqz	a0,8000181a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001804:	418904b3          	sub	s1,s2,s8
    80001808:	94d6                	add	s1,s1,s5
    if(n > len)
    8000180a:	fc99f3e3          	bgeu	s3,s1,800017d0 <copyin+0x28>
    8000180e:	84ce                	mv	s1,s3
    80001810:	b7c1                	j	800017d0 <copyin+0x28>
  }
  return 0;
    80001812:	4501                	li	a0,0
    80001814:	a021                	j	8000181c <copyin+0x74>
    80001816:	4501                	li	a0,0
}
    80001818:	8082                	ret
      return -1;
    8000181a:	557d                	li	a0,-1
}
    8000181c:	60a6                	ld	ra,72(sp)
    8000181e:	6406                	ld	s0,64(sp)
    80001820:	74e2                	ld	s1,56(sp)
    80001822:	7942                	ld	s2,48(sp)
    80001824:	79a2                	ld	s3,40(sp)
    80001826:	7a02                	ld	s4,32(sp)
    80001828:	6ae2                	ld	s5,24(sp)
    8000182a:	6b42                	ld	s6,16(sp)
    8000182c:	6ba2                	ld	s7,8(sp)
    8000182e:	6c02                	ld	s8,0(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret

0000000080001834 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001834:	c6c5                	beqz	a3,800018dc <copyinstr+0xa8>
{
    80001836:	715d                	addi	sp,sp,-80
    80001838:	e486                	sd	ra,72(sp)
    8000183a:	e0a2                	sd	s0,64(sp)
    8000183c:	fc26                	sd	s1,56(sp)
    8000183e:	f84a                	sd	s2,48(sp)
    80001840:	f44e                	sd	s3,40(sp)
    80001842:	f052                	sd	s4,32(sp)
    80001844:	ec56                	sd	s5,24(sp)
    80001846:	e85a                	sd	s6,16(sp)
    80001848:	e45e                	sd	s7,8(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8a2a                	mv	s4,a0
    8000184e:	8b2e                	mv	s6,a1
    80001850:	8bb2                	mv	s7,a2
    80001852:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001854:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6985                	lui	s3,0x1
    80001858:	a035                	j	80001884 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000185a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001860:	0017b793          	seqz	a5,a5
    80001864:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001868:	60a6                	ld	ra,72(sp)
    8000186a:	6406                	ld	s0,64(sp)
    8000186c:	74e2                	ld	s1,56(sp)
    8000186e:	7942                	ld	s2,48(sp)
    80001870:	79a2                	ld	s3,40(sp)
    80001872:	7a02                	ld	s4,32(sp)
    80001874:	6ae2                	ld	s5,24(sp)
    80001876:	6b42                	ld	s6,16(sp)
    80001878:	6ba2                	ld	s7,8(sp)
    8000187a:	6161                	addi	sp,sp,80
    8000187c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001882:	c8a9                	beqz	s1,800018d4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001884:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001888:	85ca                	mv	a1,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	85c080e7          	jalr	-1956(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001894:	c131                	beqz	a0,800018d8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001896:	41790833          	sub	a6,s2,s7
    8000189a:	984e                	add	a6,a6,s3
    if(n > max)
    8000189c:	0104f363          	bgeu	s1,a6,800018a2 <copyinstr+0x6e>
    800018a0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a2:	955e                	add	a0,a0,s7
    800018a4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a8:	fc080be3          	beqz	a6,8000187e <copyinstr+0x4a>
    800018ac:	985a                	add	a6,a6,s6
    800018ae:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b0:	41650633          	sub	a2,a0,s6
    800018b4:	14fd                	addi	s1,s1,-1
    800018b6:	9b26                	add	s6,s6,s1
    800018b8:	00f60733          	add	a4,a2,a5
    800018bc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c0:	df49                	beqz	a4,8000185a <copyinstr+0x26>
        *dst = *p;
    800018c2:	00e78023          	sb	a4,0(a5)
      --max;
    800018c6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ca:	0785                	addi	a5,a5,1
    while(n > 0){
    800018cc:	ff0796e3          	bne	a5,a6,800018b8 <copyinstr+0x84>
      dst++;
    800018d0:	8b42                	mv	s6,a6
    800018d2:	b775                	j	8000187e <copyinstr+0x4a>
    800018d4:	4781                	li	a5,0
    800018d6:	b769                	j	80001860 <copyinstr+0x2c>
      return -1;
    800018d8:	557d                	li	a0,-1
    800018da:	b779                	j	80001868 <copyinstr+0x34>
  int got_null = 0;
    800018dc:	4781                	li	a5,0
  if(got_null){
    800018de:	0017b793          	seqz	a5,a5
    800018e2:	40f00533          	neg	a0,a5
}
    800018e6:	8082                	ret

00000000800018e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	2ec080e7          	jalr	748(ra) # 80000be0 <holding>
    800018fc:	c909                	beqz	a0,8000190e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	749c                	ld	a5,40(s1)
    80001900:	00978f63          	beq	a5,s1,8000191e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    panic("wakeup1");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	8ba50513          	addi	a0,a0,-1862 # 800081c8 <digits+0x188>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4785                	li	a5,1
    80001922:	fef711e3          	bne	a4,a5,80001904 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001926:	4789                	li	a5,2
    80001928:	cc9c                	sw	a5,24(s1)
}
    8000192a:	bfe9                	j	80001904 <wakeup1+0x1c>

000000008000192c <procinit>:
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	88e58593          	addi	a1,a1,-1906 # 800081d0 <digits+0x190>
    8000194a:	00010517          	auipc	a0,0x10
    8000194e:	00650513          	addi	a0,a0,6 # 80011950 <pid_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	278080e7          	jalr	632(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010917          	auipc	s2,0x10
    8000195e:	40e90913          	addi	s2,s2,1038 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b97          	auipc	s7,0x7
    80001966:	876b8b93          	addi	s7,s7,-1930 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000196a:	8b4a                	mv	s6,s2
    8000196c:	00006a97          	auipc	s5,0x6
    80001970:	694a8a93          	addi	s5,s5,1684 # 80008000 <etext>
    80001974:	040009b7          	lui	s3,0x4000
    80001978:	19fd                	addi	s3,s3,-1
    8000197a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00016a17          	auipc	s4,0x16
    80001980:	deca0a13          	addi	s4,s4,-532 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85de                	mv	a1,s7
    80001986:	854a                	mv	a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	242080e7          	jalr	578(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	190080e7          	jalr	400(ra) # 80000b20 <kalloc>
    80001998:	85aa                	mv	a1,a0
      if(pa == 0)
    8000199a:	c929                	beqz	a0,800019ec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199c:	416904b3          	sub	s1,s2,s6
    800019a0:	848d                	srai	s1,s1,0x3
    800019a2:	000ab783          	ld	a5,0(s5)
    800019a6:	02f484b3          	mul	s1,s1,a5
    800019aa:	2485                	addiw	s1,s1,1
    800019ac:	00d4949b          	slliw	s1,s1,0xd
    800019b0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b4:	4699                	li	a3,6
    800019b6:	6605                	lui	a2,0x1
    800019b8:	8526                	mv	a0,s1
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	85c080e7          	jalr	-1956(ra) # 80001216 <kvmmap>
      p->kstack = va;
    800019c2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	16890913          	addi	s2,s2,360
    800019ca:	fb491de3          	bne	s2,s4,80001984 <procinit+0x58>
  kvminithart();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	650080e7          	jalr	1616(ra) # 8000101e <kvminithart>
}
    800019d6:	60a6                	ld	ra,72(sp)
    800019d8:	6406                	ld	s0,64(sp)
    800019da:	74e2                	ld	s1,56(sp)
    800019dc:	7942                	ld	s2,48(sp)
    800019de:	79a2                	ld	s3,40(sp)
    800019e0:	7a02                	ld	s4,32(sp)
    800019e2:	6ae2                	ld	s5,24(sp)
    800019e4:	6b42                	ld	s6,16(sp)
    800019e6:	6ba2                	ld	s7,8(sp)
    800019e8:	6161                	addi	sp,sp,80
    800019ea:	8082                	ret
        panic("kalloc");
    800019ec:	00006517          	auipc	a0,0x6
    800019f0:	7f450513          	addi	a0,a0,2036 # 800081e0 <digits+0x1a0>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	b54080e7          	jalr	-1196(ra) # 80000548 <panic>

00000000800019fc <cpuid>:
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e422                	sd	s0,8(sp)
    80001a00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a02:	8512                	mv	a0,tp
}
    80001a04:	2501                	sext.w	a0,a0
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <mycpu>:
mycpu(void) {
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
    80001a12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a14:	2781                	sext.w	a5,a5
    80001a16:	079e                	slli	a5,a5,0x7
}
    80001a18:	00010517          	auipc	a0,0x10
    80001a1c:	f5050513          	addi	a0,a0,-176 # 80011968 <cpus>
    80001a20:	953e                	add	a0,a0,a5
    80001a22:	6422                	ld	s0,8(sp)
    80001a24:	0141                	addi	sp,sp,16
    80001a26:	8082                	ret

0000000080001a28 <myproc>:
myproc(void) {
    80001a28:	1101                	addi	sp,sp,-32
    80001a2a:	ec06                	sd	ra,24(sp)
    80001a2c:	e822                	sd	s0,16(sp)
    80001a2e:	e426                	sd	s1,8(sp)
    80001a30:	1000                	addi	s0,sp,32
  push_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	1dc080e7          	jalr	476(ra) # 80000c0e <push_off>
    80001a3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3c:	2781                	sext.w	a5,a5
    80001a3e:	079e                	slli	a5,a5,0x7
    80001a40:	00010717          	auipc	a4,0x10
    80001a44:	f1070713          	addi	a4,a4,-240 # 80011950 <pid_lock>
    80001a48:	97ba                	add	a5,a5,a4
    80001a4a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	262080e7          	jalr	610(ra) # 80000cae <pop_off>
}
    80001a54:	8526                	mv	a0,s1
    80001a56:	60e2                	ld	ra,24(sp)
    80001a58:	6442                	ld	s0,16(sp)
    80001a5a:	64a2                	ld	s1,8(sp)
    80001a5c:	6105                	addi	sp,sp,32
    80001a5e:	8082                	ret

0000000080001a60 <forkret>:
{
    80001a60:	1141                	addi	sp,sp,-16
    80001a62:	e406                	sd	ra,8(sp)
    80001a64:	e022                	sd	s0,0(sp)
    80001a66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	fc0080e7          	jalr	-64(ra) # 80001a28 <myproc>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	29e080e7          	jalr	670(ra) # 80000d0e <release>
  if (first) {
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	f287a783          	lw	a5,-216(a5) # 800089a0 <first.1667>
    80001a80:	eb89                	bnez	a5,80001a92 <forkret+0x32>
  usertrapret();
    80001a82:	00001097          	auipc	ra,0x1
    80001a86:	c74080e7          	jalr	-908(ra) # 800026f6 <usertrapret>
}
    80001a8a:	60a2                	ld	ra,8(sp)
    80001a8c:	6402                	ld	s0,0(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret
    first = 0;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	f007a723          	sw	zero,-242(a5) # 800089a0 <first.1667>
    fsinit(ROOTDEV);
    80001a9a:	4505                	li	a0,1
    80001a9c:	00002097          	auipc	ra,0x2
    80001aa0:	a62080e7          	jalr	-1438(ra) # 800034fe <fsinit>
    80001aa4:	bff9                	j	80001a82 <forkret+0x22>

0000000080001aa6 <allocpid>:
allocpid() {
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab2:	00010917          	auipc	s2,0x10
    80001ab6:	e9e90913          	addi	s2,s2,-354 # 80011950 <pid_lock>
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	19e080e7          	jalr	414(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac4:	00007797          	auipc	a5,0x7
    80001ac8:	ee078793          	addi	a5,a5,-288 # 800089a4 <nextpid>
    80001acc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ace:	0014871b          	addiw	a4,s1,1
    80001ad2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	238080e7          	jalr	568(ra) # 80000d0e <release>
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret

0000000080001aec <proc_pagetable>:
{
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	e04a                	sd	s2,0(sp)
    80001af6:	1000                	addi	s0,sp,32
    80001af8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	8ea080e7          	jalr	-1814(ra) # 800013e4 <uvmcreate>
    80001b02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b04:	c121                	beqz	a0,80001b44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b06:	4729                	li	a4,10
    80001b08:	00005697          	auipc	a3,0x5
    80001b0c:	4f868693          	addi	a3,a3,1272 # 80007000 <_trampoline>
    80001b10:	6605                	lui	a2,0x1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	66e080e7          	jalr	1646(ra) # 80001188 <mappages>
    80001b22:	02054863          	bltz	a0,80001b52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b26:	4719                	li	a4,6
    80001b28:	05893683          	ld	a3,88(s2)
    80001b2c:	6605                	lui	a2,0x1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	650080e7          	jalr	1616(ra) # 80001188 <mappages>
    80001b40:	02054163          	bltz	a0,80001b62 <proc_pagetable+0x76>
}
    80001b44:	8526                	mv	a0,s1
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6902                	ld	s2,0(sp)
    80001b4e:	6105                	addi	sp,sp,32
    80001b50:	8082                	ret
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a8a080e7          	jalr	-1398(ra) # 800015e0 <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	b7d5                	j	80001b44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	040005b7          	lui	a1,0x4000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b2                	slli	a1,a1,0xc
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	7b0080e7          	jalr	1968(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b78:	4581                	li	a1,0
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a64080e7          	jalr	-1436(ra) # 800015e0 <uvmfree>
    return 0;
    80001b84:	4481                	li	s1,0
    80001b86:	bf7d                	j	80001b44 <proc_pagetable+0x58>

0000000080001b88 <proc_freepagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	84aa                	mv	s1,a0
    80001b96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b98:	4681                	li	a3,0
    80001b9a:	4605                	li	a2,1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	77c080e7          	jalr	1916(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	020005b7          	lui	a1,0x2000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b6                	slli	a1,a1,0xd
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	766080e7          	jalr	1894(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc2:	85ca                	mv	a1,s2
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	a1a080e7          	jalr	-1510(ra) # 800015e0 <uvmfree>
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <freeproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	1000                	addi	s0,sp,32
    80001be4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be6:	6d28                	ld	a0,88(a0)
    80001be8:	c509                	beqz	a0,80001bf2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	e3a080e7          	jalr	-454(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bf2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf6:	68a8                	ld	a0,80(s1)
    80001bf8:	c511                	beqz	a0,80001c04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfa:	64ac                	ld	a1,72(s1)
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	f8c080e7          	jalr	-116(ra) # 80001b88 <proc_freepagetable>
  p->pagetable = 0;
    80001c04:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c08:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c10:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c14:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c18:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c24:	0004ac23          	sw	zero,24(s1)
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <allocproc>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3e:	00010497          	auipc	s1,0x10
    80001c42:	12a48493          	addi	s1,s1,298 # 80011d68 <proc>
    80001c46:	00016917          	auipc	s2,0x16
    80001c4a:	b2290913          	addi	s2,s2,-1246 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	00a080e7          	jalr	10(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c58:	4c9c                	lw	a5,24(s1)
    80001c5a:	cf81                	beqz	a5,80001c72 <allocproc+0x40>
      release(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	0b0080e7          	jalr	176(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	16848493          	addi	s1,s1,360
    80001c6a:	ff2492e3          	bne	s1,s2,80001c4e <allocproc+0x1c>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a0b9                	j	80001cbe <allocproc+0x8c>
  p->pid = allocpid();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e34080e7          	jalr	-460(ra) # 80001aa6 <allocpid>
    80001c7a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	ea4080e7          	jalr	-348(ra) # 80000b20 <kalloc>
    80001c84:	892a                	mv	s2,a0
    80001c86:	eca8                	sd	a0,88(s1)
    80001c88:	c131                	beqz	a0,80001ccc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e60080e7          	jalr	-416(ra) # 80001aec <proc_pagetable>
    80001c94:	892a                	mv	s2,a0
    80001c96:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c98:	c129                	beqz	a0,80001cda <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c9a:	07000613          	li	a2,112
    80001c9e:	4581                	li	a1,0
    80001ca0:	06048513          	addi	a0,s1,96
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0b2080e7          	jalr	178(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001cac:	00000797          	auipc	a5,0x0
    80001cb0:	db478793          	addi	a5,a5,-588 # 80001a60 <forkret>
    80001cb4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb6:	60bc                	ld	a5,64(s1)
    80001cb8:	6705                	lui	a4,0x1
    80001cba:	97ba                	add	a5,a5,a4
    80001cbc:	f4bc                	sd	a5,104(s1)
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret
    release(&p->lock);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	040080e7          	jalr	64(ra) # 80000d0e <release>
    return 0;
    80001cd6:	84ca                	mv	s1,s2
    80001cd8:	b7dd                	j	80001cbe <allocproc+0x8c>
    freeproc(p);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	efe080e7          	jalr	-258(ra) # 80001bda <freeproc>
    release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	028080e7          	jalr	40(ra) # 80000d0e <release>
    return 0;
    80001cee:	84ca                	mv	s1,s2
    80001cf0:	b7f9                	j	80001cbe <allocproc+0x8c>

0000000080001cf2 <userinit>:
{
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	f36080e7          	jalr	-202(ra) # 80001c32 <allocproc>
    80001d04:	84aa                	mv	s1,a0
  initproc = p;
    80001d06:	00007797          	auipc	a5,0x7
    80001d0a:	30a7b923          	sd	a0,786(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d0e:	03400613          	li	a2,52
    80001d12:	00007597          	auipc	a1,0x7
    80001d16:	c9e58593          	addi	a1,a1,-866 # 800089b0 <initcode>
    80001d1a:	6928                	ld	a0,80(a0)
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	6f6080e7          	jalr	1782(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d24:	6785                	lui	a5,0x1
    80001d26:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d28:	6cb8                	ld	a4,88(s1)
    80001d2a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d2e:	6cb8                	ld	a4,88(s1)
    80001d30:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d32:	4641                	li	a2,16
    80001d34:	00006597          	auipc	a1,0x6
    80001d38:	4b458593          	addi	a1,a1,1204 # 800081e8 <digits+0x1a8>
    80001d3c:	15848513          	addi	a0,s1,344
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	16c080e7          	jalr	364(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001d48:	00006517          	auipc	a0,0x6
    80001d4c:	4b050513          	addi	a0,a0,1200 # 800081f8 <digits+0x1b8>
    80001d50:	00002097          	auipc	ra,0x2
    80001d54:	1d6080e7          	jalr	470(ra) # 80003f26 <namei>
    80001d58:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d5c:	4789                	li	a5,2
    80001d5e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	fac080e7          	jalr	-84(ra) # 80000d0e <release>
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6105                	addi	sp,sp,32
    80001d72:	8082                	ret

0000000080001d74 <growproc>:
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	e04a                	sd	s2,0(sp)
    80001d7e:	1000                	addi	s0,sp,32
    80001d80:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	ca6080e7          	jalr	-858(ra) # 80001a28 <myproc>
    80001d8a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d8c:	652c                	ld	a1,72(a0)
    80001d8e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d92:	00904f63          	bgtz	s1,80001db0 <growproc+0x3c>
  } else if(n < 0){
    80001d96:	0204cc63          	bltz	s1,80001dce <growproc+0x5a>
  p->sz = sz;
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001da2:	4501                	li	a0,0
}
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6902                	ld	s2,0(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db0:	9e25                	addw	a2,a2,s1
    80001db2:	1602                	slli	a2,a2,0x20
    80001db4:	9201                	srli	a2,a2,0x20
    80001db6:	1582                	slli	a1,a1,0x20
    80001db8:	9181                	srli	a1,a1,0x20
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	710080e7          	jalr	1808(ra) # 800014cc <uvmalloc>
    80001dc4:	0005061b          	sext.w	a2,a0
    80001dc8:	fa69                	bnez	a2,80001d9a <growproc+0x26>
      return -1;
    80001dca:	557d                	li	a0,-1
    80001dcc:	bfe1                	j	80001da4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dce:	9e25                	addw	a2,a2,s1
    80001dd0:	1602                	slli	a2,a2,0x20
    80001dd2:	9201                	srli	a2,a2,0x20
    80001dd4:	1582                	slli	a1,a1,0x20
    80001dd6:	9181                	srli	a1,a1,0x20
    80001dd8:	6928                	ld	a0,80(a0)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	6aa080e7          	jalr	1706(ra) # 80001484 <uvmdealloc>
    80001de2:	0005061b          	sext.w	a2,a0
    80001de6:	bf55                	j	80001d9a <growproc+0x26>

0000000080001de8 <fork>:
{
    80001de8:	7179                	addi	sp,sp,-48
    80001dea:	f406                	sd	ra,40(sp)
    80001dec:	f022                	sd	s0,32(sp)
    80001dee:	ec26                	sd	s1,24(sp)
    80001df0:	e84a                	sd	s2,16(sp)
    80001df2:	e44e                	sd	s3,8(sp)
    80001df4:	e052                	sd	s4,0(sp)
    80001df6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	c30080e7          	jalr	-976(ra) # 80001a28 <myproc>
    80001e00:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	e30080e7          	jalr	-464(ra) # 80001c32 <allocproc>
    80001e0a:	c575                	beqz	a0,80001ef6 <fork+0x10e>
    80001e0c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e0e:	04893603          	ld	a2,72(s2)
    80001e12:	692c                	ld	a1,80(a0)
    80001e14:	05093503          	ld	a0,80(s2)
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	800080e7          	jalr	-2048(ra) # 80001618 <uvmcopy>
    80001e20:	04054c63          	bltz	a0,80001e78 <fork+0x90>
  np->sz = p->sz;
    80001e24:	04893783          	ld	a5,72(s2)
    80001e28:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e2c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e30:	05893683          	ld	a3,88(s2)
    80001e34:	87b6                	mv	a5,a3
    80001e36:	0589b703          	ld	a4,88(s3)
    80001e3a:	12068693          	addi	a3,a3,288
    80001e3e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e42:	6788                	ld	a0,8(a5)
    80001e44:	6b8c                	ld	a1,16(a5)
    80001e46:	6f90                	ld	a2,24(a5)
    80001e48:	01073023          	sd	a6,0(a4)
    80001e4c:	e708                	sd	a0,8(a4)
    80001e4e:	eb0c                	sd	a1,16(a4)
    80001e50:	ef10                	sd	a2,24(a4)
    80001e52:	02078793          	addi	a5,a5,32
    80001e56:	02070713          	addi	a4,a4,32
    80001e5a:	fed792e3          	bne	a5,a3,80001e3e <fork+0x56>
  np->tmask = p->tmask;
    80001e5e:	03c92783          	lw	a5,60(s2)
    80001e62:	02f9ae23          	sw	a5,60(s3)
  np->trapframe->a0 = 0;
    80001e66:	0589b783          	ld	a5,88(s3)
    80001e6a:	0607b823          	sd	zero,112(a5)
    80001e6e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e72:	15000a13          	li	s4,336
    80001e76:	a03d                	j	80001ea4 <fork+0xbc>
    freeproc(np);
    80001e78:	854e                	mv	a0,s3
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	d60080e7          	jalr	-672(ra) # 80001bda <freeproc>
    release(&np->lock);
    80001e82:	854e                	mv	a0,s3
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e8a080e7          	jalr	-374(ra) # 80000d0e <release>
    return -1;
    80001e8c:	54fd                	li	s1,-1
    80001e8e:	a899                	j	80001ee4 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e90:	00002097          	auipc	ra,0x2
    80001e94:	722080e7          	jalr	1826(ra) # 800045b2 <filedup>
    80001e98:	009987b3          	add	a5,s3,s1
    80001e9c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e9e:	04a1                	addi	s1,s1,8
    80001ea0:	01448763          	beq	s1,s4,80001eae <fork+0xc6>
    if(p->ofile[i])
    80001ea4:	009907b3          	add	a5,s2,s1
    80001ea8:	6388                	ld	a0,0(a5)
    80001eaa:	f17d                	bnez	a0,80001e90 <fork+0xa8>
    80001eac:	bfcd                	j	80001e9e <fork+0xb6>
  np->cwd = idup(p->cwd);
    80001eae:	15093503          	ld	a0,336(s2)
    80001eb2:	00002097          	auipc	ra,0x2
    80001eb6:	886080e7          	jalr	-1914(ra) # 80003738 <idup>
    80001eba:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ebe:	4641                	li	a2,16
    80001ec0:	15890593          	addi	a1,s2,344
    80001ec4:	15898513          	addi	a0,s3,344
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	fe4080e7          	jalr	-28(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80001ed0:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ed4:	4789                	li	a5,2
    80001ed6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eda:	854e                	mv	a0,s3
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	e32080e7          	jalr	-462(ra) # 80000d0e <release>
}
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	70a2                	ld	ra,40(sp)
    80001ee8:	7402                	ld	s0,32(sp)
    80001eea:	64e2                	ld	s1,24(sp)
    80001eec:	6942                	ld	s2,16(sp)
    80001eee:	69a2                	ld	s3,8(sp)
    80001ef0:	6a02                	ld	s4,0(sp)
    80001ef2:	6145                	addi	sp,sp,48
    80001ef4:	8082                	ret
    return -1;
    80001ef6:	54fd                	li	s1,-1
    80001ef8:	b7f5                	j	80001ee4 <fork+0xfc>

0000000080001efa <reparent>:
{
    80001efa:	7179                	addi	sp,sp,-48
    80001efc:	f406                	sd	ra,40(sp)
    80001efe:	f022                	sd	s0,32(sp)
    80001f00:	ec26                	sd	s1,24(sp)
    80001f02:	e84a                	sd	s2,16(sp)
    80001f04:	e44e                	sd	s3,8(sp)
    80001f06:	e052                	sd	s4,0(sp)
    80001f08:	1800                	addi	s0,sp,48
    80001f0a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f0c:	00010497          	auipc	s1,0x10
    80001f10:	e5c48493          	addi	s1,s1,-420 # 80011d68 <proc>
      pp->parent = initproc;
    80001f14:	00007a17          	auipc	s4,0x7
    80001f18:	104a0a13          	addi	s4,s4,260 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f1c:	00016997          	auipc	s3,0x16
    80001f20:	84c98993          	addi	s3,s3,-1972 # 80017768 <tickslock>
    80001f24:	a029                	j	80001f2e <reparent+0x34>
    80001f26:	16848493          	addi	s1,s1,360
    80001f2a:	03348363          	beq	s1,s3,80001f50 <reparent+0x56>
    if(pp->parent == p){
    80001f2e:	709c                	ld	a5,32(s1)
    80001f30:	ff279be3          	bne	a5,s2,80001f26 <reparent+0x2c>
      acquire(&pp->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d24080e7          	jalr	-732(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f3e:	000a3783          	ld	a5,0(s4)
    80001f42:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	dc8080e7          	jalr	-568(ra) # 80000d0e <release>
    80001f4e:	bfe1                	j	80001f26 <reparent+0x2c>
}
    80001f50:	70a2                	ld	ra,40(sp)
    80001f52:	7402                	ld	s0,32(sp)
    80001f54:	64e2                	ld	s1,24(sp)
    80001f56:	6942                	ld	s2,16(sp)
    80001f58:	69a2                	ld	s3,8(sp)
    80001f5a:	6a02                	ld	s4,0(sp)
    80001f5c:	6145                	addi	sp,sp,48
    80001f5e:	8082                	ret

0000000080001f60 <scheduler>:
{
    80001f60:	715d                	addi	sp,sp,-80
    80001f62:	e486                	sd	ra,72(sp)
    80001f64:	e0a2                	sd	s0,64(sp)
    80001f66:	fc26                	sd	s1,56(sp)
    80001f68:	f84a                	sd	s2,48(sp)
    80001f6a:	f44e                	sd	s3,40(sp)
    80001f6c:	f052                	sd	s4,32(sp)
    80001f6e:	ec56                	sd	s5,24(sp)
    80001f70:	e85a                	sd	s6,16(sp)
    80001f72:	e45e                	sd	s7,8(sp)
    80001f74:	e062                	sd	s8,0(sp)
    80001f76:	0880                	addi	s0,sp,80
    80001f78:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f7c:	00779b13          	slli	s6,a5,0x7
    80001f80:	00010717          	auipc	a4,0x10
    80001f84:	9d070713          	addi	a4,a4,-1584 # 80011950 <pid_lock>
    80001f88:	975a                	add	a4,a4,s6
    80001f8a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f8e:	00010717          	auipc	a4,0x10
    80001f92:	9e270713          	addi	a4,a4,-1566 # 80011970 <cpus+0x8>
    80001f96:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f98:	4c0d                	li	s8,3
        c->proc = p;
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	00010a17          	auipc	s4,0x10
    80001fa0:	9b4a0a13          	addi	s4,s4,-1612 # 80011950 <pid_lock>
    80001fa4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa6:	00015997          	auipc	s3,0x15
    80001faa:	7c298993          	addi	s3,s3,1986 # 80017768 <tickslock>
        found = 1;
    80001fae:	4b85                	li	s7,1
    80001fb0:	a899                	j	80002006 <scheduler+0xa6>
        p->state = RUNNING;
    80001fb2:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fb6:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fba:	06048593          	addi	a1,s1,96
    80001fbe:	855a                	mv	a0,s6
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	68c080e7          	jalr	1676(ra) # 8000264c <swtch>
        c->proc = 0;
    80001fc8:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fcc:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	d3e080e7          	jalr	-706(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd8:	16848493          	addi	s1,s1,360
    80001fdc:	01348b63          	beq	s1,s3,80001ff2 <scheduler+0x92>
      acquire(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	c78080e7          	jalr	-904(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001fea:	4c9c                	lw	a5,24(s1)
    80001fec:	ff2791e3          	bne	a5,s2,80001fce <scheduler+0x6e>
    80001ff0:	b7c9                	j	80001fb2 <scheduler+0x52>
    if(found == 0) {
    80001ff2:	000a9a63          	bnez	s5,80002006 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ffa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ffe:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002002:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002006:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002012:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002014:	00010497          	auipc	s1,0x10
    80002018:	d5448493          	addi	s1,s1,-684 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000201c:	4909                	li	s2,2
    8000201e:	b7c9                	j	80001fe0 <scheduler+0x80>

0000000080002020 <sched>:
{
    80002020:	7179                	addi	sp,sp,-48
    80002022:	f406                	sd	ra,40(sp)
    80002024:	f022                	sd	s0,32(sp)
    80002026:	ec26                	sd	s1,24(sp)
    80002028:	e84a                	sd	s2,16(sp)
    8000202a:	e44e                	sd	s3,8(sp)
    8000202c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	9fa080e7          	jalr	-1542(ra) # 80001a28 <myproc>
    80002036:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	ba8080e7          	jalr	-1112(ra) # 80000be0 <holding>
    80002040:	c93d                	beqz	a0,800020b6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002042:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002044:	2781                	sext.w	a5,a5
    80002046:	079e                	slli	a5,a5,0x7
    80002048:	00010717          	auipc	a4,0x10
    8000204c:	90870713          	addi	a4,a4,-1784 # 80011950 <pid_lock>
    80002050:	97ba                	add	a5,a5,a4
    80002052:	0907a703          	lw	a4,144(a5)
    80002056:	4785                	li	a5,1
    80002058:	06f71763          	bne	a4,a5,800020c6 <sched+0xa6>
  if(p->state == RUNNING)
    8000205c:	4c98                	lw	a4,24(s1)
    8000205e:	478d                	li	a5,3
    80002060:	06f70b63          	beq	a4,a5,800020d6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002064:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002068:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000206a:	efb5                	bnez	a5,800020e6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000206c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000206e:	00010917          	auipc	s2,0x10
    80002072:	8e290913          	addi	s2,s2,-1822 # 80011950 <pid_lock>
    80002076:	2781                	sext.w	a5,a5
    80002078:	079e                	slli	a5,a5,0x7
    8000207a:	97ca                	add	a5,a5,s2
    8000207c:	0947a983          	lw	s3,148(a5)
    80002080:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002082:	2781                	sext.w	a5,a5
    80002084:	079e                	slli	a5,a5,0x7
    80002086:	00010597          	auipc	a1,0x10
    8000208a:	8ea58593          	addi	a1,a1,-1814 # 80011970 <cpus+0x8>
    8000208e:	95be                	add	a1,a1,a5
    80002090:	06048513          	addi	a0,s1,96
    80002094:	00000097          	auipc	ra,0x0
    80002098:	5b8080e7          	jalr	1464(ra) # 8000264c <swtch>
    8000209c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000209e:	2781                	sext.w	a5,a5
    800020a0:	079e                	slli	a5,a5,0x7
    800020a2:	97ca                	add	a5,a5,s2
    800020a4:	0937aa23          	sw	s3,148(a5)
}
    800020a8:	70a2                	ld	ra,40(sp)
    800020aa:	7402                	ld	s0,32(sp)
    800020ac:	64e2                	ld	s1,24(sp)
    800020ae:	6942                	ld	s2,16(sp)
    800020b0:	69a2                	ld	s3,8(sp)
    800020b2:	6145                	addi	sp,sp,48
    800020b4:	8082                	ret
    panic("sched p->lock");
    800020b6:	00006517          	auipc	a0,0x6
    800020ba:	14a50513          	addi	a0,a0,330 # 80008200 <digits+0x1c0>
    800020be:	ffffe097          	auipc	ra,0xffffe
    800020c2:	48a080e7          	jalr	1162(ra) # 80000548 <panic>
    panic("sched locks");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	14a50513          	addi	a0,a0,330 # 80008210 <digits+0x1d0>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	47a080e7          	jalr	1146(ra) # 80000548 <panic>
    panic("sched running");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	14a50513          	addi	a0,a0,330 # 80008220 <digits+0x1e0>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	46a080e7          	jalr	1130(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020e6:	00006517          	auipc	a0,0x6
    800020ea:	14a50513          	addi	a0,a0,330 # 80008230 <digits+0x1f0>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	45a080e7          	jalr	1114(ra) # 80000548 <panic>

00000000800020f6 <exit>:
{
    800020f6:	7179                	addi	sp,sp,-48
    800020f8:	f406                	sd	ra,40(sp)
    800020fa:	f022                	sd	s0,32(sp)
    800020fc:	ec26                	sd	s1,24(sp)
    800020fe:	e84a                	sd	s2,16(sp)
    80002100:	e44e                	sd	s3,8(sp)
    80002102:	e052                	sd	s4,0(sp)
    80002104:	1800                	addi	s0,sp,48
    80002106:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	920080e7          	jalr	-1760(ra) # 80001a28 <myproc>
    80002110:	89aa                	mv	s3,a0
  if(p == initproc)
    80002112:	00007797          	auipc	a5,0x7
    80002116:	f067b783          	ld	a5,-250(a5) # 80009018 <initproc>
    8000211a:	0d050493          	addi	s1,a0,208
    8000211e:	15050913          	addi	s2,a0,336
    80002122:	02a79363          	bne	a5,a0,80002148 <exit+0x52>
    panic("init exiting");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	12250513          	addi	a0,a0,290 # 80008248 <digits+0x208>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	41a080e7          	jalr	1050(ra) # 80000548 <panic>
      fileclose(f);
    80002136:	00002097          	auipc	ra,0x2
    8000213a:	4ce080e7          	jalr	1230(ra) # 80004604 <fileclose>
      p->ofile[fd] = 0;
    8000213e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002142:	04a1                	addi	s1,s1,8
    80002144:	01248563          	beq	s1,s2,8000214e <exit+0x58>
    if(p->ofile[fd]){
    80002148:	6088                	ld	a0,0(s1)
    8000214a:	f575                	bnez	a0,80002136 <exit+0x40>
    8000214c:	bfdd                	j	80002142 <exit+0x4c>
  begin_op();
    8000214e:	00002097          	auipc	ra,0x2
    80002152:	fe4080e7          	jalr	-28(ra) # 80004132 <begin_op>
  iput(p->cwd);
    80002156:	1509b503          	ld	a0,336(s3)
    8000215a:	00001097          	auipc	ra,0x1
    8000215e:	7d6080e7          	jalr	2006(ra) # 80003930 <iput>
  end_op();
    80002162:	00002097          	auipc	ra,0x2
    80002166:	050080e7          	jalr	80(ra) # 800041b2 <end_op>
  p->cwd = 0;
    8000216a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000216e:	00007497          	auipc	s1,0x7
    80002172:	eaa48493          	addi	s1,s1,-342 # 80009018 <initproc>
    80002176:	6088                	ld	a0,0(s1)
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	ae2080e7          	jalr	-1310(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    80002180:	6088                	ld	a0,0(s1)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	766080e7          	jalr	1894(ra) # 800018e8 <wakeup1>
  release(&initproc->lock);
    8000218a:	6088                	ld	a0,0(s1)
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b82080e7          	jalr	-1150(ra) # 80000d0e <release>
  acquire(&p->lock);
    80002194:	854e                	mv	a0,s3
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	ac4080e7          	jalr	-1340(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    8000219e:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021a2:	854e                	mv	a0,s3
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	b6a080e7          	jalr	-1174(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aac080e7          	jalr	-1364(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021b6:	854e                	mv	a0,s3
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	aa2080e7          	jalr	-1374(ra) # 80000c5a <acquire>
  reparent(p);
    800021c0:	854e                	mv	a0,s3
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	d38080e7          	jalr	-712(ra) # 80001efa <reparent>
  wakeup1(original_parent);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	71c080e7          	jalr	1820(ra) # 800018e8 <wakeup1>
  p->xstate = status;
    800021d4:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021d8:	4791                	li	a5,4
    800021da:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	b2e080e7          	jalr	-1234(ra) # 80000d0e <release>
  sched();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	e38080e7          	jalr	-456(ra) # 80002020 <sched>
  panic("zombie exit");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	06850513          	addi	a0,a0,104 # 80008258 <digits+0x218>
    800021f8:	ffffe097          	auipc	ra,0xffffe
    800021fc:	350080e7          	jalr	848(ra) # 80000548 <panic>

0000000080002200 <yield>:
{
    80002200:	1101                	addi	sp,sp,-32
    80002202:	ec06                	sd	ra,24(sp)
    80002204:	e822                	sd	s0,16(sp)
    80002206:	e426                	sd	s1,8(sp)
    80002208:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	81e080e7          	jalr	-2018(ra) # 80001a28 <myproc>
    80002212:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a46080e7          	jalr	-1466(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    8000221c:	4789                	li	a5,2
    8000221e:	cc9c                	sw	a5,24(s1)
  sched();
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e00080e7          	jalr	-512(ra) # 80002020 <sched>
  release(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	ae4080e7          	jalr	-1308(ra) # 80000d0e <release>
}
    80002232:	60e2                	ld	ra,24(sp)
    80002234:	6442                	ld	s0,16(sp)
    80002236:	64a2                	ld	s1,8(sp)
    80002238:	6105                	addi	sp,sp,32
    8000223a:	8082                	ret

000000008000223c <sleep>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	89aa                	mv	s3,a0
    8000224c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	7da080e7          	jalr	2010(ra) # 80001a28 <myproc>
    80002256:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002258:	05250663          	beq	a0,s2,800022a4 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	9fe080e7          	jalr	-1538(ra) # 80000c5a <acquire>
    release(lk);
    80002264:	854a                	mv	a0,s2
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	aa8080e7          	jalr	-1368(ra) # 80000d0e <release>
  p->chan = chan;
    8000226e:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002272:	4785                	li	a5,1
    80002274:	cc9c                	sw	a5,24(s1)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	daa080e7          	jalr	-598(ra) # 80002020 <sched>
  p->chan = 0;
    8000227e:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a8a080e7          	jalr	-1398(ra) # 80000d0e <release>
    acquire(lk);
    8000228c:	854a                	mv	a0,s2
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	9cc080e7          	jalr	-1588(ra) # 80000c5a <acquire>
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6145                	addi	sp,sp,48
    800022a2:	8082                	ret
  p->chan = chan;
    800022a4:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022a8:	4785                	li	a5,1
    800022aa:	cd1c                	sw	a5,24(a0)
  sched();
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	d74080e7          	jalr	-652(ra) # 80002020 <sched>
  p->chan = 0;
    800022b4:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022b8:	bff9                	j	80002296 <sleep+0x5a>

00000000800022ba <wait>:
{
    800022ba:	715d                	addi	sp,sp,-80
    800022bc:	e486                	sd	ra,72(sp)
    800022be:	e0a2                	sd	s0,64(sp)
    800022c0:	fc26                	sd	s1,56(sp)
    800022c2:	f84a                	sd	s2,48(sp)
    800022c4:	f44e                	sd	s3,40(sp)
    800022c6:	f052                	sd	s4,32(sp)
    800022c8:	ec56                	sd	s5,24(sp)
    800022ca:	e85a                	sd	s6,16(sp)
    800022cc:	e45e                	sd	s7,8(sp)
    800022ce:	e062                	sd	s8,0(sp)
    800022d0:	0880                	addi	s0,sp,80
    800022d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	754080e7          	jalr	1876(ra) # 80001a28 <myproc>
    800022dc:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022de:	8c2a                	mv	s8,a0
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	97a080e7          	jalr	-1670(ra) # 80000c5a <acquire>
    havekids = 0;
    800022e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ea:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022ec:	00015997          	auipc	s3,0x15
    800022f0:	47c98993          	addi	s3,s3,1148 # 80017768 <tickslock>
        havekids = 1;
    800022f4:	4a85                	li	s5,1
    havekids = 0;
    800022f6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022f8:	00010497          	auipc	s1,0x10
    800022fc:	a7048493          	addi	s1,s1,-1424 # 80011d68 <proc>
    80002300:	a08d                	j	80002362 <wait+0xa8>
          pid = np->pid;
    80002302:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002306:	000b0e63          	beqz	s6,80002322 <wait+0x68>
    8000230a:	4691                	li	a3,4
    8000230c:	03448613          	addi	a2,s1,52
    80002310:	85da                	mv	a1,s6
    80002312:	05093503          	ld	a0,80(s2)
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	406080e7          	jalr	1030(ra) # 8000171c <copyout>
    8000231e:	02054263          	bltz	a0,80002342 <wait+0x88>
          freeproc(np);
    80002322:	8526                	mv	a0,s1
    80002324:	00000097          	auipc	ra,0x0
    80002328:	8b6080e7          	jalr	-1866(ra) # 80001bda <freeproc>
          release(&np->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	9e0080e7          	jalr	-1568(ra) # 80000d0e <release>
          release(&p->lock);
    80002336:	854a                	mv	a0,s2
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	9d6080e7          	jalr	-1578(ra) # 80000d0e <release>
          return pid;
    80002340:	a8a9                	j	8000239a <wait+0xe0>
            release(&np->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	9ca080e7          	jalr	-1590(ra) # 80000d0e <release>
            release(&p->lock);
    8000234c:	854a                	mv	a0,s2
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	9c0080e7          	jalr	-1600(ra) # 80000d0e <release>
            return -1;
    80002356:	59fd                	li	s3,-1
    80002358:	a089                	j	8000239a <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235a:	16848493          	addi	s1,s1,360
    8000235e:	03348463          	beq	s1,s3,80002386 <wait+0xcc>
      if(np->parent == p){
    80002362:	709c                	ld	a5,32(s1)
    80002364:	ff279be3          	bne	a5,s2,8000235a <wait+0xa0>
        acquire(&np->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	8f0080e7          	jalr	-1808(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    80002372:	4c9c                	lw	a5,24(s1)
    80002374:	f94787e3          	beq	a5,s4,80002302 <wait+0x48>
        release(&np->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	994080e7          	jalr	-1644(ra) # 80000d0e <release>
        havekids = 1;
    80002382:	8756                	mv	a4,s5
    80002384:	bfd9                	j	8000235a <wait+0xa0>
    if(!havekids || p->killed){
    80002386:	c701                	beqz	a4,8000238e <wait+0xd4>
    80002388:	03092783          	lw	a5,48(s2)
    8000238c:	c785                	beqz	a5,800023b4 <wait+0xfa>
      release(&p->lock);
    8000238e:	854a                	mv	a0,s2
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	97e080e7          	jalr	-1666(ra) # 80000d0e <release>
      return -1;
    80002398:	59fd                	li	s3,-1
}
    8000239a:	854e                	mv	a0,s3
    8000239c:	60a6                	ld	ra,72(sp)
    8000239e:	6406                	ld	s0,64(sp)
    800023a0:	74e2                	ld	s1,56(sp)
    800023a2:	7942                	ld	s2,48(sp)
    800023a4:	79a2                	ld	s3,40(sp)
    800023a6:	7a02                	ld	s4,32(sp)
    800023a8:	6ae2                	ld	s5,24(sp)
    800023aa:	6b42                	ld	s6,16(sp)
    800023ac:	6ba2                	ld	s7,8(sp)
    800023ae:	6c02                	ld	s8,0(sp)
    800023b0:	6161                	addi	sp,sp,80
    800023b2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b4:	85e2                	mv	a1,s8
    800023b6:	854a                	mv	a0,s2
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	e84080e7          	jalr	-380(ra) # 8000223c <sleep>
    havekids = 0;
    800023c0:	bf1d                	j	800022f6 <wait+0x3c>

00000000800023c2 <wakeup>:
{
    800023c2:	7139                	addi	sp,sp,-64
    800023c4:	fc06                	sd	ra,56(sp)
    800023c6:	f822                	sd	s0,48(sp)
    800023c8:	f426                	sd	s1,40(sp)
    800023ca:	f04a                	sd	s2,32(sp)
    800023cc:	ec4e                	sd	s3,24(sp)
    800023ce:	e852                	sd	s4,16(sp)
    800023d0:	e456                	sd	s5,8(sp)
    800023d2:	0080                	addi	s0,sp,64
    800023d4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d6:	00010497          	auipc	s1,0x10
    800023da:	99248493          	addi	s1,s1,-1646 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023de:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e2:	00015917          	auipc	s2,0x15
    800023e6:	38690913          	addi	s2,s2,902 # 80017768 <tickslock>
    800023ea:	a821                	j	80002402 <wakeup+0x40>
      p->state = RUNNABLE;
    800023ec:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	91c080e7          	jalr	-1764(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fa:	16848493          	addi	s1,s1,360
    800023fe:	01248e63          	beq	s1,s2,8000241a <wakeup+0x58>
    acquire(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	856080e7          	jalr	-1962(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000240c:	4c9c                	lw	a5,24(s1)
    8000240e:	ff3791e3          	bne	a5,s3,800023f0 <wakeup+0x2e>
    80002412:	749c                	ld	a5,40(s1)
    80002414:	fd479ee3          	bne	a5,s4,800023f0 <wakeup+0x2e>
    80002418:	bfd1                	j	800023ec <wakeup+0x2a>
}
    8000241a:	70e2                	ld	ra,56(sp)
    8000241c:	7442                	ld	s0,48(sp)
    8000241e:	74a2                	ld	s1,40(sp)
    80002420:	7902                	ld	s2,32(sp)
    80002422:	69e2                	ld	s3,24(sp)
    80002424:	6a42                	ld	s4,16(sp)
    80002426:	6aa2                	ld	s5,8(sp)
    80002428:	6121                	addi	sp,sp,64
    8000242a:	8082                	ret

000000008000242c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000243c:	00010497          	auipc	s1,0x10
    80002440:	92c48493          	addi	s1,s1,-1748 # 80011d68 <proc>
    80002444:	00015997          	auipc	s3,0x15
    80002448:	32498993          	addi	s3,s3,804 # 80017768 <tickslock>
    acquire(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	80c080e7          	jalr	-2036(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    80002456:	5c9c                	lw	a5,56(s1)
    80002458:	01278d63          	beq	a5,s2,80002472 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	8b0080e7          	jalr	-1872(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002466:	16848493          	addi	s1,s1,360
    8000246a:	ff3491e3          	bne	s1,s3,8000244c <kill+0x20>
  }
  return -1;
    8000246e:	557d                	li	a0,-1
    80002470:	a829                	j	8000248a <kill+0x5e>
      p->killed = 1;
    80002472:	4785                	li	a5,1
    80002474:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002476:	4c98                	lw	a4,24(s1)
    80002478:	4785                	li	a5,1
    8000247a:	00f70f63          	beq	a4,a5,80002498 <kill+0x6c>
      release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	88e080e7          	jalr	-1906(ra) # 80000d0e <release>
      return 0;
    80002488:	4501                	li	a0,0
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
        p->state = RUNNABLE;
    80002498:	4789                	li	a5,2
    8000249a:	cc9c                	sw	a5,24(s1)
    8000249c:	b7cd                	j	8000247e <kill+0x52>

000000008000249e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000249e:	7179                	addi	sp,sp,-48
    800024a0:	f406                	sd	ra,40(sp)
    800024a2:	f022                	sd	s0,32(sp)
    800024a4:	ec26                	sd	s1,24(sp)
    800024a6:	e84a                	sd	s2,16(sp)
    800024a8:	e44e                	sd	s3,8(sp)
    800024aa:	e052                	sd	s4,0(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	84aa                	mv	s1,a0
    800024b0:	892e                	mv	s2,a1
    800024b2:	89b2                	mv	s3,a2
    800024b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	572080e7          	jalr	1394(ra) # 80001a28 <myproc>
  if(user_dst){
    800024be:	c08d                	beqz	s1,800024e0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c0:	86d2                	mv	a3,s4
    800024c2:	864e                	mv	a2,s3
    800024c4:	85ca                	mv	a1,s2
    800024c6:	6928                	ld	a0,80(a0)
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	254080e7          	jalr	596(ra) # 8000171c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d0:	70a2                	ld	ra,40(sp)
    800024d2:	7402                	ld	s0,32(sp)
    800024d4:	64e2                	ld	s1,24(sp)
    800024d6:	6942                	ld	s2,16(sp)
    800024d8:	69a2                	ld	s3,8(sp)
    800024da:	6a02                	ld	s4,0(sp)
    800024dc:	6145                	addi	sp,sp,48
    800024de:	8082                	ret
    memmove((char *)dst, src, len);
    800024e0:	000a061b          	sext.w	a2,s4
    800024e4:	85ce                	mv	a1,s3
    800024e6:	854a                	mv	a0,s2
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	8ce080e7          	jalr	-1842(ra) # 80000db6 <memmove>
    return 0;
    800024f0:	8526                	mv	a0,s1
    800024f2:	bff9                	j	800024d0 <either_copyout+0x32>

00000000800024f4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	892a                	mv	s2,a0
    80002506:	84ae                	mv	s1,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	51c080e7          	jalr	1308(ra) # 80001a28 <myproc>
  if(user_src){
    80002514:	c08d                	beqz	s1,80002536 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	28a080e7          	jalr	650(ra) # 800017a8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove(dst, (char*)src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	878080e7          	jalr	-1928(ra) # 80000db6 <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyin+0x32>

000000008000254a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000254a:	715d                	addi	sp,sp,-80
    8000254c:	e486                	sd	ra,72(sp)
    8000254e:	e0a2                	sd	s0,64(sp)
    80002550:	fc26                	sd	s1,56(sp)
    80002552:	f84a                	sd	s2,48(sp)
    80002554:	f44e                	sd	s3,40(sp)
    80002556:	f052                	sd	s4,32(sp)
    80002558:	ec56                	sd	s5,24(sp)
    8000255a:	e85a                	sd	s6,16(sp)
    8000255c:	e45e                	sd	s7,8(sp)
    8000255e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002560:	00006517          	auipc	a0,0x6
    80002564:	b6850513          	addi	a0,a0,-1176 # 800080c8 <digits+0x88>
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	02a080e7          	jalr	42(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002570:	00010497          	auipc	s1,0x10
    80002574:	95048493          	addi	s1,s1,-1712 # 80011ec0 <proc+0x158>
    80002578:	00015917          	auipc	s2,0x15
    8000257c:	34890913          	addi	s2,s2,840 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002580:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002582:	00006997          	auipc	s3,0x6
    80002586:	ce698993          	addi	s3,s3,-794 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000258a:	00006a97          	auipc	s5,0x6
    8000258e:	ce6a8a93          	addi	s5,s5,-794 # 80008270 <digits+0x230>
    printf("\n");
    80002592:	00006a17          	auipc	s4,0x6
    80002596:	b36a0a13          	addi	s4,s4,-1226 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259a:	00006b97          	auipc	s7,0x6
    8000259e:	d0eb8b93          	addi	s7,s7,-754 # 800082a8 <states.1707>
    800025a2:	a00d                	j	800025c4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a4:	ee06a583          	lw	a1,-288(a3)
    800025a8:	8556                	mv	a0,s5
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	fe8080e7          	jalr	-24(ra) # 80000592 <printf>
    printf("\n");
    800025b2:	8552                	mv	a0,s4
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	fde080e7          	jalr	-34(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025bc:	16848493          	addi	s1,s1,360
    800025c0:	03248163          	beq	s1,s2,800025e2 <procdump+0x98>
    if(p->state == UNUSED)
    800025c4:	86a6                	mv	a3,s1
    800025c6:	ec04a783          	lw	a5,-320(s1)
    800025ca:	dbed                	beqz	a5,800025bc <procdump+0x72>
      state = "???";
    800025cc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ce:	fcfb6be3          	bltu	s6,a5,800025a4 <procdump+0x5a>
    800025d2:	1782                	slli	a5,a5,0x20
    800025d4:	9381                	srli	a5,a5,0x20
    800025d6:	078e                	slli	a5,a5,0x3
    800025d8:	97de                	add	a5,a5,s7
    800025da:	6390                	ld	a2,0(a5)
    800025dc:	f661                	bnez	a2,800025a4 <procdump+0x5a>
      state = "???";
    800025de:	864e                	mv	a2,s3
    800025e0:	b7d1                	j	800025a4 <procdump+0x5a>
  }
}
    800025e2:	60a6                	ld	ra,72(sp)
    800025e4:	6406                	ld	s0,64(sp)
    800025e6:	74e2                	ld	s1,56(sp)
    800025e8:	7942                	ld	s2,48(sp)
    800025ea:	79a2                	ld	s3,40(sp)
    800025ec:	7a02                	ld	s4,32(sp)
    800025ee:	6ae2                	ld	s5,24(sp)
    800025f0:	6b42                	ld	s6,16(sp)
    800025f2:	6ba2                	ld	s7,8(sp)
    800025f4:	6161                	addi	sp,sp,80
    800025f6:	8082                	ret

00000000800025f8 <countproc>:

// Count number of processes
uint64
countproc(void)
{
    800025f8:	7179                	addi	sp,sp,-48
    800025fa:	f406                	sd	ra,40(sp)
    800025fc:	f022                	sd	s0,32(sp)
    800025fe:	ec26                	sd	s1,24(sp)
    80002600:	e84a                	sd	s2,16(sp)
    80002602:	e44e                	sd	s3,8(sp)
    80002604:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 nproc = 0;
    80002606:	4901                	li	s2,0
  for (p = proc; p < &proc[NPROC]; p++)
    80002608:	0000f497          	auipc	s1,0xf
    8000260c:	76048493          	addi	s1,s1,1888 # 80011d68 <proc>
    80002610:	00015997          	auipc	s3,0x15
    80002614:	15898993          	addi	s3,s3,344 # 80017768 <tickslock>
  {
    acquire(&p->lock);
    80002618:	8526                	mv	a0,s1
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	640080e7          	jalr	1600(ra) # 80000c5a <acquire>
    if (p->state != UNUSED)
    80002622:	4c9c                	lw	a5,24(s1)
      nproc++;
    80002624:	00f037b3          	snez	a5,a5
    80002628:	993e                	add	s2,s2,a5
    release(&p->lock);
    8000262a:	8526                	mv	a0,s1
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	6e2080e7          	jalr	1762(ra) # 80000d0e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002634:	16848493          	addi	s1,s1,360
    80002638:	ff3490e3          	bne	s1,s3,80002618 <countproc+0x20>
  }
  return nproc;
}
    8000263c:	854a                	mv	a0,s2
    8000263e:	70a2                	ld	ra,40(sp)
    80002640:	7402                	ld	s0,32(sp)
    80002642:	64e2                	ld	s1,24(sp)
    80002644:	6942                	ld	s2,16(sp)
    80002646:	69a2                	ld	s3,8(sp)
    80002648:	6145                	addi	sp,sp,48
    8000264a:	8082                	ret

000000008000264c <swtch>:
    8000264c:	00153023          	sd	ra,0(a0)
    80002650:	00253423          	sd	sp,8(a0)
    80002654:	e900                	sd	s0,16(a0)
    80002656:	ed04                	sd	s1,24(a0)
    80002658:	03253023          	sd	s2,32(a0)
    8000265c:	03353423          	sd	s3,40(a0)
    80002660:	03453823          	sd	s4,48(a0)
    80002664:	03553c23          	sd	s5,56(a0)
    80002668:	05653023          	sd	s6,64(a0)
    8000266c:	05753423          	sd	s7,72(a0)
    80002670:	05853823          	sd	s8,80(a0)
    80002674:	05953c23          	sd	s9,88(a0)
    80002678:	07a53023          	sd	s10,96(a0)
    8000267c:	07b53423          	sd	s11,104(a0)
    80002680:	0005b083          	ld	ra,0(a1)
    80002684:	0085b103          	ld	sp,8(a1)
    80002688:	6980                	ld	s0,16(a1)
    8000268a:	6d84                	ld	s1,24(a1)
    8000268c:	0205b903          	ld	s2,32(a1)
    80002690:	0285b983          	ld	s3,40(a1)
    80002694:	0305ba03          	ld	s4,48(a1)
    80002698:	0385ba83          	ld	s5,56(a1)
    8000269c:	0405bb03          	ld	s6,64(a1)
    800026a0:	0485bb83          	ld	s7,72(a1)
    800026a4:	0505bc03          	ld	s8,80(a1)
    800026a8:	0585bc83          	ld	s9,88(a1)
    800026ac:	0605bd03          	ld	s10,96(a1)
    800026b0:	0685bd83          	ld	s11,104(a1)
    800026b4:	8082                	ret

00000000800026b6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026b6:	1141                	addi	sp,sp,-16
    800026b8:	e406                	sd	ra,8(sp)
    800026ba:	e022                	sd	s0,0(sp)
    800026bc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026be:	00006597          	auipc	a1,0x6
    800026c2:	c1258593          	addi	a1,a1,-1006 # 800082d0 <states.1707+0x28>
    800026c6:	00015517          	auipc	a0,0x15
    800026ca:	0a250513          	addi	a0,a0,162 # 80017768 <tickslock>
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	4fc080e7          	jalr	1276(ra) # 80000bca <initlock>
}
    800026d6:	60a2                	ld	ra,8(sp)
    800026d8:	6402                	ld	s0,0(sp)
    800026da:	0141                	addi	sp,sp,16
    800026dc:	8082                	ret

00000000800026de <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026de:	1141                	addi	sp,sp,-16
    800026e0:	e422                	sd	s0,8(sp)
    800026e2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e4:	00003797          	auipc	a5,0x3
    800026e8:	58c78793          	addi	a5,a5,1420 # 80005c70 <kernelvec>
    800026ec:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f0:	6422                	ld	s0,8(sp)
    800026f2:	0141                	addi	sp,sp,16
    800026f4:	8082                	ret

00000000800026f6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026f6:	1141                	addi	sp,sp,-16
    800026f8:	e406                	sd	ra,8(sp)
    800026fa:	e022                	sd	s0,0(sp)
    800026fc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	32a080e7          	jalr	810(ra) # 80001a28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002706:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000270a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000270c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002710:	00005617          	auipc	a2,0x5
    80002714:	8f060613          	addi	a2,a2,-1808 # 80007000 <_trampoline>
    80002718:	00005697          	auipc	a3,0x5
    8000271c:	8e868693          	addi	a3,a3,-1816 # 80007000 <_trampoline>
    80002720:	8e91                	sub	a3,a3,a2
    80002722:	040007b7          	lui	a5,0x4000
    80002726:	17fd                	addi	a5,a5,-1
    80002728:	07b2                	slli	a5,a5,0xc
    8000272a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000272c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002730:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002732:	180026f3          	csrr	a3,satp
    80002736:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002738:	6d38                	ld	a4,88(a0)
    8000273a:	6134                	ld	a3,64(a0)
    8000273c:	6585                	lui	a1,0x1
    8000273e:	96ae                	add	a3,a3,a1
    80002740:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002742:	6d38                	ld	a4,88(a0)
    80002744:	00000697          	auipc	a3,0x0
    80002748:	13868693          	addi	a3,a3,312 # 8000287c <usertrap>
    8000274c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000274e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002750:	8692                	mv	a3,tp
    80002752:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002754:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002758:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000275c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002760:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002764:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002766:	6f18                	ld	a4,24(a4)
    80002768:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000276c:	692c                	ld	a1,80(a0)
    8000276e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002770:	00005717          	auipc	a4,0x5
    80002774:	92070713          	addi	a4,a4,-1760 # 80007090 <userret>
    80002778:	8f11                	sub	a4,a4,a2
    8000277a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000277c:	577d                	li	a4,-1
    8000277e:	177e                	slli	a4,a4,0x3f
    80002780:	8dd9                	or	a1,a1,a4
    80002782:	02000537          	lui	a0,0x2000
    80002786:	157d                	addi	a0,a0,-1
    80002788:	0536                	slli	a0,a0,0xd
    8000278a:	9782                	jalr	a5
}
    8000278c:	60a2                	ld	ra,8(sp)
    8000278e:	6402                	ld	s0,0(sp)
    80002790:	0141                	addi	sp,sp,16
    80002792:	8082                	ret

0000000080002794 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002794:	1101                	addi	sp,sp,-32
    80002796:	ec06                	sd	ra,24(sp)
    80002798:	e822                	sd	s0,16(sp)
    8000279a:	e426                	sd	s1,8(sp)
    8000279c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000279e:	00015497          	auipc	s1,0x15
    800027a2:	fca48493          	addi	s1,s1,-54 # 80017768 <tickslock>
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	4b2080e7          	jalr	1202(ra) # 80000c5a <acquire>
  ticks++;
    800027b0:	00007517          	auipc	a0,0x7
    800027b4:	87050513          	addi	a0,a0,-1936 # 80009020 <ticks>
    800027b8:	411c                	lw	a5,0(a0)
    800027ba:	2785                	addiw	a5,a5,1
    800027bc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027be:	00000097          	auipc	ra,0x0
    800027c2:	c04080e7          	jalr	-1020(ra) # 800023c2 <wakeup>
  release(&tickslock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	546080e7          	jalr	1350(ra) # 80000d0e <release>
}
    800027d0:	60e2                	ld	ra,24(sp)
    800027d2:	6442                	ld	s0,16(sp)
    800027d4:	64a2                	ld	s1,8(sp)
    800027d6:	6105                	addi	sp,sp,32
    800027d8:	8082                	ret

00000000800027da <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027da:	1101                	addi	sp,sp,-32
    800027dc:	ec06                	sd	ra,24(sp)
    800027de:	e822                	sd	s0,16(sp)
    800027e0:	e426                	sd	s1,8(sp)
    800027e2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027e8:	00074d63          	bltz	a4,80002802 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ec:	57fd                	li	a5,-1
    800027ee:	17fe                	slli	a5,a5,0x3f
    800027f0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f4:	06f70363          	beq	a4,a5,8000285a <devintr+0x80>
  }
}
    800027f8:	60e2                	ld	ra,24(sp)
    800027fa:	6442                	ld	s0,16(sp)
    800027fc:	64a2                	ld	s1,8(sp)
    800027fe:	6105                	addi	sp,sp,32
    80002800:	8082                	ret
     (scause & 0xff) == 9){
    80002802:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002806:	46a5                	li	a3,9
    80002808:	fed792e3          	bne	a5,a3,800027ec <devintr+0x12>
    int irq = plic_claim();
    8000280c:	00003097          	auipc	ra,0x3
    80002810:	56c080e7          	jalr	1388(ra) # 80005d78 <plic_claim>
    80002814:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002816:	47a9                	li	a5,10
    80002818:	02f50763          	beq	a0,a5,80002846 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000281c:	4785                	li	a5,1
    8000281e:	02f50963          	beq	a0,a5,80002850 <devintr+0x76>
    return 1;
    80002822:	4505                	li	a0,1
    } else if(irq){
    80002824:	d8f1                	beqz	s1,800027f8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002826:	85a6                	mv	a1,s1
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	ab050513          	addi	a0,a0,-1360 # 800082d8 <states.1707+0x30>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	d62080e7          	jalr	-670(ra) # 80000592 <printf>
      plic_complete(irq);
    80002838:	8526                	mv	a0,s1
    8000283a:	00003097          	auipc	ra,0x3
    8000283e:	562080e7          	jalr	1378(ra) # 80005d9c <plic_complete>
    return 1;
    80002842:	4505                	li	a0,1
    80002844:	bf55                	j	800027f8 <devintr+0x1e>
      uartintr();
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	18e080e7          	jalr	398(ra) # 800009d4 <uartintr>
    8000284e:	b7ed                	j	80002838 <devintr+0x5e>
      virtio_disk_intr();
    80002850:	00004097          	auipc	ra,0x4
    80002854:	9e6080e7          	jalr	-1562(ra) # 80006236 <virtio_disk_intr>
    80002858:	b7c5                	j	80002838 <devintr+0x5e>
    if(cpuid() == 0){
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	1a2080e7          	jalr	418(ra) # 800019fc <cpuid>
    80002862:	c901                	beqz	a0,80002872 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002864:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002868:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000286a:	14479073          	csrw	sip,a5
    return 2;
    8000286e:	4509                	li	a0,2
    80002870:	b761                	j	800027f8 <devintr+0x1e>
      clockintr();
    80002872:	00000097          	auipc	ra,0x0
    80002876:	f22080e7          	jalr	-222(ra) # 80002794 <clockintr>
    8000287a:	b7ed                	j	80002864 <devintr+0x8a>

000000008000287c <usertrap>:
{
    8000287c:	1101                	addi	sp,sp,-32
    8000287e:	ec06                	sd	ra,24(sp)
    80002880:	e822                	sd	s0,16(sp)
    80002882:	e426                	sd	s1,8(sp)
    80002884:	e04a                	sd	s2,0(sp)
    80002886:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000288c:	1007f793          	andi	a5,a5,256
    80002890:	e3ad                	bnez	a5,800028f2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002892:	00003797          	auipc	a5,0x3
    80002896:	3de78793          	addi	a5,a5,990 # 80005c70 <kernelvec>
    8000289a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000289e:	fffff097          	auipc	ra,0xfffff
    800028a2:	18a080e7          	jalr	394(ra) # 80001a28 <myproc>
    800028a6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028a8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028aa:	14102773          	csrr	a4,sepc
    800028ae:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028b4:	47a1                	li	a5,8
    800028b6:	04f71c63          	bne	a4,a5,8000290e <usertrap+0x92>
    if(p->killed)
    800028ba:	591c                	lw	a5,48(a0)
    800028bc:	e3b9                	bnez	a5,80002902 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028be:	6cb8                	ld	a4,88(s1)
    800028c0:	6f1c                	ld	a5,24(a4)
    800028c2:	0791                	addi	a5,a5,4
    800028c4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ca:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ce:	10079073          	csrw	sstatus,a5
    syscall();
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	2e0080e7          	jalr	736(ra) # 80002bb2 <syscall>
  if(p->killed)
    800028da:	589c                	lw	a5,48(s1)
    800028dc:	ebc1                	bnez	a5,8000296c <usertrap+0xf0>
  usertrapret();
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	e18080e7          	jalr	-488(ra) # 800026f6 <usertrapret>
}
    800028e6:	60e2                	ld	ra,24(sp)
    800028e8:	6442                	ld	s0,16(sp)
    800028ea:	64a2                	ld	s1,8(sp)
    800028ec:	6902                	ld	s2,0(sp)
    800028ee:	6105                	addi	sp,sp,32
    800028f0:	8082                	ret
    panic("usertrap: not from user mode");
    800028f2:	00006517          	auipc	a0,0x6
    800028f6:	a0650513          	addi	a0,a0,-1530 # 800082f8 <states.1707+0x50>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c4e080e7          	jalr	-946(ra) # 80000548 <panic>
      exit(-1);
    80002902:	557d                	li	a0,-1
    80002904:	fffff097          	auipc	ra,0xfffff
    80002908:	7f2080e7          	jalr	2034(ra) # 800020f6 <exit>
    8000290c:	bf4d                	j	800028be <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	ecc080e7          	jalr	-308(ra) # 800027da <devintr>
    80002916:	892a                	mv	s2,a0
    80002918:	c501                	beqz	a0,80002920 <usertrap+0xa4>
  if(p->killed)
    8000291a:	589c                	lw	a5,48(s1)
    8000291c:	c3a1                	beqz	a5,8000295c <usertrap+0xe0>
    8000291e:	a815                	j	80002952 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002920:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002924:	5c90                	lw	a2,56(s1)
    80002926:	00006517          	auipc	a0,0x6
    8000292a:	9f250513          	addi	a0,a0,-1550 # 80008318 <states.1707+0x70>
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	c64080e7          	jalr	-924(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002936:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	a0a50513          	addi	a0,a0,-1526 # 80008348 <states.1707+0xa0>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	c4c080e7          	jalr	-948(ra) # 80000592 <printf>
    p->killed = 1;
    8000294e:	4785                	li	a5,1
    80002950:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002952:	557d                	li	a0,-1
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	7a2080e7          	jalr	1954(ra) # 800020f6 <exit>
  if(which_dev == 2)
    8000295c:	4789                	li	a5,2
    8000295e:	f8f910e3          	bne	s2,a5,800028de <usertrap+0x62>
    yield();
    80002962:	00000097          	auipc	ra,0x0
    80002966:	89e080e7          	jalr	-1890(ra) # 80002200 <yield>
    8000296a:	bf95                	j	800028de <usertrap+0x62>
  int which_dev = 0;
    8000296c:	4901                	li	s2,0
    8000296e:	b7d5                	j	80002952 <usertrap+0xd6>

0000000080002970 <kerneltrap>:
{
    80002970:	7179                	addi	sp,sp,-48
    80002972:	f406                	sd	ra,40(sp)
    80002974:	f022                	sd	s0,32(sp)
    80002976:	ec26                	sd	s1,24(sp)
    80002978:	e84a                	sd	s2,16(sp)
    8000297a:	e44e                	sd	s3,8(sp)
    8000297c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002982:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002986:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298a:	1004f793          	andi	a5,s1,256
    8000298e:	cb85                	beqz	a5,800029be <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002990:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002994:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002996:	ef85                	bnez	a5,800029ce <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	e42080e7          	jalr	-446(ra) # 800027da <devintr>
    800029a0:	cd1d                	beqz	a0,800029de <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a2:	4789                	li	a5,2
    800029a4:	06f50a63          	beq	a0,a5,80002a18 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ac:	10049073          	csrw	sstatus,s1
}
    800029b0:	70a2                	ld	ra,40(sp)
    800029b2:	7402                	ld	s0,32(sp)
    800029b4:	64e2                	ld	s1,24(sp)
    800029b6:	6942                	ld	s2,16(sp)
    800029b8:	69a2                	ld	s3,8(sp)
    800029ba:	6145                	addi	sp,sp,48
    800029bc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029be:	00006517          	auipc	a0,0x6
    800029c2:	9aa50513          	addi	a0,a0,-1622 # 80008368 <states.1707+0xc0>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	b82080e7          	jalr	-1150(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9c250513          	addi	a0,a0,-1598 # 80008390 <states.1707+0xe8>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	b72080e7          	jalr	-1166(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    800029de:	85ce                	mv	a1,s3
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	9d050513          	addi	a0,a0,-1584 # 800083b0 <states.1707+0x108>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	baa080e7          	jalr	-1110(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029f8:	00006517          	auipc	a0,0x6
    800029fc:	9c850513          	addi	a0,a0,-1592 # 800083c0 <states.1707+0x118>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b92080e7          	jalr	-1134(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	9d050513          	addi	a0,a0,-1584 # 800083d8 <states.1707+0x130>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b38080e7          	jalr	-1224(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	010080e7          	jalr	16(ra) # 80001a28 <myproc>
    80002a20:	d541                	beqz	a0,800029a8 <kerneltrap+0x38>
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	006080e7          	jalr	6(ra) # 80001a28 <myproc>
    80002a2a:	4d18                	lw	a4,24(a0)
    80002a2c:	478d                	li	a5,3
    80002a2e:	f6f71de3          	bne	a4,a5,800029a8 <kerneltrap+0x38>
    yield();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	7ce080e7          	jalr	1998(ra) # 80002200 <yield>
    80002a3a:	b7bd                	j	800029a8 <kerneltrap+0x38>

0000000080002a3c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a3c:	1101                	addi	sp,sp,-32
    80002a3e:	ec06                	sd	ra,24(sp)
    80002a40:	e822                	sd	s0,16(sp)
    80002a42:	e426                	sd	s1,8(sp)
    80002a44:	1000                	addi	s0,sp,32
    80002a46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	fe0080e7          	jalr	-32(ra) # 80001a28 <myproc>
  switch (n) {
    80002a50:	4795                	li	a5,5
    80002a52:	0497e163          	bltu	a5,s1,80002a94 <argraw+0x58>
    80002a56:	048a                	slli	s1,s1,0x2
    80002a58:	00006717          	auipc	a4,0x6
    80002a5c:	a8070713          	addi	a4,a4,-1408 # 800084d8 <states.1707+0x230>
    80002a60:	94ba                	add	s1,s1,a4
    80002a62:	409c                	lw	a5,0(s1)
    80002a64:	97ba                	add	a5,a5,a4
    80002a66:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a68:	6d3c                	ld	a5,88(a0)
    80002a6a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a6c:	60e2                	ld	ra,24(sp)
    80002a6e:	6442                	ld	s0,16(sp)
    80002a70:	64a2                	ld	s1,8(sp)
    80002a72:	6105                	addi	sp,sp,32
    80002a74:	8082                	ret
    return p->trapframe->a1;
    80002a76:	6d3c                	ld	a5,88(a0)
    80002a78:	7fa8                	ld	a0,120(a5)
    80002a7a:	bfcd                	j	80002a6c <argraw+0x30>
    return p->trapframe->a2;
    80002a7c:	6d3c                	ld	a5,88(a0)
    80002a7e:	63c8                	ld	a0,128(a5)
    80002a80:	b7f5                	j	80002a6c <argraw+0x30>
    return p->trapframe->a3;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	67c8                	ld	a0,136(a5)
    80002a86:	b7dd                	j	80002a6c <argraw+0x30>
    return p->trapframe->a4;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	6bc8                	ld	a0,144(a5)
    80002a8c:	b7c5                	j	80002a6c <argraw+0x30>
    return p->trapframe->a5;
    80002a8e:	6d3c                	ld	a5,88(a0)
    80002a90:	6fc8                	ld	a0,152(a5)
    80002a92:	bfe9                	j	80002a6c <argraw+0x30>
  panic("argraw");
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	95450513          	addi	a0,a0,-1708 # 800083e8 <states.1707+0x140>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aac080e7          	jalr	-1364(ra) # 80000548 <panic>

0000000080002aa4 <fetchaddr>:
{
    80002aa4:	1101                	addi	sp,sp,-32
    80002aa6:	ec06                	sd	ra,24(sp)
    80002aa8:	e822                	sd	s0,16(sp)
    80002aaa:	e426                	sd	s1,8(sp)
    80002aac:	e04a                	sd	s2,0(sp)
    80002aae:	1000                	addi	s0,sp,32
    80002ab0:	84aa                	mv	s1,a0
    80002ab2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	f74080e7          	jalr	-140(ra) # 80001a28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002abc:	653c                	ld	a5,72(a0)
    80002abe:	02f4f863          	bgeu	s1,a5,80002aee <fetchaddr+0x4a>
    80002ac2:	00848713          	addi	a4,s1,8
    80002ac6:	02e7e663          	bltu	a5,a4,80002af2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aca:	46a1                	li	a3,8
    80002acc:	8626                	mv	a2,s1
    80002ace:	85ca                	mv	a1,s2
    80002ad0:	6928                	ld	a0,80(a0)
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	cd6080e7          	jalr	-810(ra) # 800017a8 <copyin>
    80002ada:	00a03533          	snez	a0,a0
    80002ade:	40a00533          	neg	a0,a0
}
    80002ae2:	60e2                	ld	ra,24(sp)
    80002ae4:	6442                	ld	s0,16(sp)
    80002ae6:	64a2                	ld	s1,8(sp)
    80002ae8:	6902                	ld	s2,0(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret
    return -1;
    80002aee:	557d                	li	a0,-1
    80002af0:	bfcd                	j	80002ae2 <fetchaddr+0x3e>
    80002af2:	557d                	li	a0,-1
    80002af4:	b7fd                	j	80002ae2 <fetchaddr+0x3e>

0000000080002af6 <fetchstr>:
{
    80002af6:	7179                	addi	sp,sp,-48
    80002af8:	f406                	sd	ra,40(sp)
    80002afa:	f022                	sd	s0,32(sp)
    80002afc:	ec26                	sd	s1,24(sp)
    80002afe:	e84a                	sd	s2,16(sp)
    80002b00:	e44e                	sd	s3,8(sp)
    80002b02:	1800                	addi	s0,sp,48
    80002b04:	892a                	mv	s2,a0
    80002b06:	84ae                	mv	s1,a1
    80002b08:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	f1e080e7          	jalr	-226(ra) # 80001a28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b12:	86ce                	mv	a3,s3
    80002b14:	864a                	mv	a2,s2
    80002b16:	85a6                	mv	a1,s1
    80002b18:	6928                	ld	a0,80(a0)
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	d1a080e7          	jalr	-742(ra) # 80001834 <copyinstr>
  if(err < 0)
    80002b22:	00054763          	bltz	a0,80002b30 <fetchstr+0x3a>
  return strlen(buf);
    80002b26:	8526                	mv	a0,s1
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	3b6080e7          	jalr	950(ra) # 80000ede <strlen>
}
    80002b30:	70a2                	ld	ra,40(sp)
    80002b32:	7402                	ld	s0,32(sp)
    80002b34:	64e2                	ld	s1,24(sp)
    80002b36:	6942                	ld	s2,16(sp)
    80002b38:	69a2                	ld	s3,8(sp)
    80002b3a:	6145                	addi	sp,sp,48
    80002b3c:	8082                	ret

0000000080002b3e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	1000                	addi	s0,sp,32
    80002b48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	ef2080e7          	jalr	-270(ra) # 80002a3c <argraw>
    80002b52:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b54:	4501                	li	a0,0
    80002b56:	60e2                	ld	ra,24(sp)
    80002b58:	6442                	ld	s0,16(sp)
    80002b5a:	64a2                	ld	s1,8(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret

0000000080002b60 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
    80002b6a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	ed0080e7          	jalr	-304(ra) # 80002a3c <argraw>
    80002b74:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b76:	4501                	li	a0,0
    80002b78:	60e2                	ld	ra,24(sp)
    80002b7a:	6442                	ld	s0,16(sp)
    80002b7c:	64a2                	ld	s1,8(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret

0000000080002b82 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	e04a                	sd	s2,0(sp)
    80002b8c:	1000                	addi	s0,sp,32
    80002b8e:	84ae                	mv	s1,a1
    80002b90:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	eaa080e7          	jalr	-342(ra) # 80002a3c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b9a:	864a                	mv	a2,s2
    80002b9c:	85a6                	mv	a1,s1
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	f58080e7          	jalr	-168(ra) # 80002af6 <fetchstr>
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6902                	ld	s2,0(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret

0000000080002bb2 <syscall>:
[SYS_sysinfo]= "sysinfo",
};

void
syscall(void)
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	e04a                	sd	s2,0(sp)
    80002bbc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	e6a080e7          	jalr	-406(ra) # 80001a28 <myproc>
    80002bc6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bc8:	6d3c                	ld	a5,88(a0)
    80002bca:	77dc                	ld	a5,168(a5)
    80002bcc:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bd0:	37fd                	addiw	a5,a5,-1
    80002bd2:	4759                	li	a4,22
    80002bd4:	04f76663          	bltu	a4,a5,80002c20 <syscall+0x6e>
    80002bd8:	00391713          	slli	a4,s2,0x3
    80002bdc:	00006797          	auipc	a5,0x6
    80002be0:	91478793          	addi	a5,a5,-1772 # 800084f0 <syscalls>
    80002be4:	97ba                	add	a5,a5,a4
    80002be6:	639c                	ld	a5,0(a5)
    80002be8:	cf85                	beqz	a5,80002c20 <syscall+0x6e>
    uint64 ret = syscalls[num]();
    80002bea:	9782                	jalr	a5
    p->trapframe->a0 = ret;
    80002bec:	6cbc                	ld	a5,88(s1)
    80002bee:	fba8                	sd	a0,112(a5)
    // trace syscall
    int tmask = p->tmask;
    if (tmask & (1 << num))
    80002bf0:	5cdc                	lw	a5,60(s1)
    80002bf2:	4127d7bb          	sraw	a5,a5,s2
    80002bf6:	8b85                	andi	a5,a5,1
    80002bf8:	c3b9                	beqz	a5,80002c3e <syscall+0x8c>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], ret);
    80002bfa:	090e                	slli	s2,s2,0x3
    80002bfc:	00006797          	auipc	a5,0x6
    80002c00:	8f478793          	addi	a5,a5,-1804 # 800084f0 <syscalls>
    80002c04:	993e                	add	s2,s2,a5
    80002c06:	86aa                	mv	a3,a0
    80002c08:	0c093603          	ld	a2,192(s2)
    80002c0c:	5c8c                	lw	a1,56(s1)
    80002c0e:	00005517          	auipc	a0,0x5
    80002c12:	7e250513          	addi	a0,a0,2018 # 800083f0 <states.1707+0x148>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	97c080e7          	jalr	-1668(ra) # 80000592 <printf>
    80002c1e:	a005                	j	80002c3e <syscall+0x8c>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c20:	86ca                	mv	a3,s2
    80002c22:	15848613          	addi	a2,s1,344
    80002c26:	5c8c                	lw	a1,56(s1)
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	7e050513          	addi	a0,a0,2016 # 80008408 <states.1707+0x160>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	962080e7          	jalr	-1694(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c38:	6cbc                	ld	a5,88(s1)
    80002c3a:	577d                	li	a4,-1
    80002c3c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6902                	ld	s2,0(sp)
    80002c46:	6105                	addi	sp,sp,32
    80002c48:	8082                	ret

0000000080002c4a <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002c4a:	1101                	addi	sp,sp,-32
    80002c4c:	ec06                	sd	ra,24(sp)
    80002c4e:	e822                	sd	s0,16(sp)
    80002c50:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c52:	fec40593          	addi	a1,s0,-20
    80002c56:	4501                	li	a0,0
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	ee6080e7          	jalr	-282(ra) # 80002b3e <argint>
    return -1;
    80002c60:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c62:	00054963          	bltz	a0,80002c74 <sys_exit+0x2a>
  exit(n);
    80002c66:	fec42503          	lw	a0,-20(s0)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	48c080e7          	jalr	1164(ra) # 800020f6 <exit>
  return 0;  // not reached
    80002c72:	4781                	li	a5,0
}
    80002c74:	853e                	mv	a0,a5
    80002c76:	60e2                	ld	ra,24(sp)
    80002c78:	6442                	ld	s0,16(sp)
    80002c7a:	6105                	addi	sp,sp,32
    80002c7c:	8082                	ret

0000000080002c7e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c7e:	1141                	addi	sp,sp,-16
    80002c80:	e406                	sd	ra,8(sp)
    80002c82:	e022                	sd	s0,0(sp)
    80002c84:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	da2080e7          	jalr	-606(ra) # 80001a28 <myproc>
}
    80002c8e:	5d08                	lw	a0,56(a0)
    80002c90:	60a2                	ld	ra,8(sp)
    80002c92:	6402                	ld	s0,0(sp)
    80002c94:	0141                	addi	sp,sp,16
    80002c96:	8082                	ret

0000000080002c98 <sys_fork>:

uint64
sys_fork(void)
{
    80002c98:	1141                	addi	sp,sp,-16
    80002c9a:	e406                	sd	ra,8(sp)
    80002c9c:	e022                	sd	s0,0(sp)
    80002c9e:	0800                	addi	s0,sp,16
  return fork();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	148080e7          	jalr	328(ra) # 80001de8 <fork>
}
    80002ca8:	60a2                	ld	ra,8(sp)
    80002caa:	6402                	ld	s0,0(sp)
    80002cac:	0141                	addi	sp,sp,16
    80002cae:	8082                	ret

0000000080002cb0 <sys_wait>:

uint64
sys_wait(void)
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cb8:	fe840593          	addi	a1,s0,-24
    80002cbc:	4501                	li	a0,0
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	ea2080e7          	jalr	-350(ra) # 80002b60 <argaddr>
    80002cc6:	87aa                	mv	a5,a0
    return -1;
    80002cc8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cca:	0007c863          	bltz	a5,80002cda <sys_wait+0x2a>
  return wait(p);
    80002cce:	fe843503          	ld	a0,-24(s0)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	5e8080e7          	jalr	1512(ra) # 800022ba <wait>
}
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret

0000000080002ce2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ce2:	7179                	addi	sp,sp,-48
    80002ce4:	f406                	sd	ra,40(sp)
    80002ce6:	f022                	sd	s0,32(sp)
    80002ce8:	ec26                	sd	s1,24(sp)
    80002cea:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cec:	fdc40593          	addi	a1,s0,-36
    80002cf0:	4501                	li	a0,0
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	e4c080e7          	jalr	-436(ra) # 80002b3e <argint>
    80002cfa:	87aa                	mv	a5,a0
    return -1;
    80002cfc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cfe:	0207c063          	bltz	a5,80002d1e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	d26080e7          	jalr	-730(ra) # 80001a28 <myproc>
    80002d0a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d0c:	fdc42503          	lw	a0,-36(s0)
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	064080e7          	jalr	100(ra) # 80001d74 <growproc>
    80002d18:	00054863          	bltz	a0,80002d28 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d1c:	8526                	mv	a0,s1
}
    80002d1e:	70a2                	ld	ra,40(sp)
    80002d20:	7402                	ld	s0,32(sp)
    80002d22:	64e2                	ld	s1,24(sp)
    80002d24:	6145                	addi	sp,sp,48
    80002d26:	8082                	ret
    return -1;
    80002d28:	557d                	li	a0,-1
    80002d2a:	bfd5                	j	80002d1e <sys_sbrk+0x3c>

0000000080002d2c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d2c:	7139                	addi	sp,sp,-64
    80002d2e:	fc06                	sd	ra,56(sp)
    80002d30:	f822                	sd	s0,48(sp)
    80002d32:	f426                	sd	s1,40(sp)
    80002d34:	f04a                	sd	s2,32(sp)
    80002d36:	ec4e                	sd	s3,24(sp)
    80002d38:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d3a:	fcc40593          	addi	a1,s0,-52
    80002d3e:	4501                	li	a0,0
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	dfe080e7          	jalr	-514(ra) # 80002b3e <argint>
    return -1;
    80002d48:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d4a:	06054563          	bltz	a0,80002db4 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d4e:	00015517          	auipc	a0,0x15
    80002d52:	a1a50513          	addi	a0,a0,-1510 # 80017768 <tickslock>
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	f04080e7          	jalr	-252(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002d5e:	00006917          	auipc	s2,0x6
    80002d62:	2c292903          	lw	s2,706(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d66:	fcc42783          	lw	a5,-52(s0)
    80002d6a:	cf85                	beqz	a5,80002da2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d6c:	00015997          	auipc	s3,0x15
    80002d70:	9fc98993          	addi	s3,s3,-1540 # 80017768 <tickslock>
    80002d74:	00006497          	auipc	s1,0x6
    80002d78:	2ac48493          	addi	s1,s1,684 # 80009020 <ticks>
    if(myproc()->killed){
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	cac080e7          	jalr	-852(ra) # 80001a28 <myproc>
    80002d84:	591c                	lw	a5,48(a0)
    80002d86:	ef9d                	bnez	a5,80002dc4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d88:	85ce                	mv	a1,s3
    80002d8a:	8526                	mv	a0,s1
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	4b0080e7          	jalr	1200(ra) # 8000223c <sleep>
  while(ticks - ticks0 < n){
    80002d94:	409c                	lw	a5,0(s1)
    80002d96:	412787bb          	subw	a5,a5,s2
    80002d9a:	fcc42703          	lw	a4,-52(s0)
    80002d9e:	fce7efe3          	bltu	a5,a4,80002d7c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002da2:	00015517          	auipc	a0,0x15
    80002da6:	9c650513          	addi	a0,a0,-1594 # 80017768 <tickslock>
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	f64080e7          	jalr	-156(ra) # 80000d0e <release>
  return 0;
    80002db2:	4781                	li	a5,0
}
    80002db4:	853e                	mv	a0,a5
    80002db6:	70e2                	ld	ra,56(sp)
    80002db8:	7442                	ld	s0,48(sp)
    80002dba:	74a2                	ld	s1,40(sp)
    80002dbc:	7902                	ld	s2,32(sp)
    80002dbe:	69e2                	ld	s3,24(sp)
    80002dc0:	6121                	addi	sp,sp,64
    80002dc2:	8082                	ret
      release(&tickslock);
    80002dc4:	00015517          	auipc	a0,0x15
    80002dc8:	9a450513          	addi	a0,a0,-1628 # 80017768 <tickslock>
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	f42080e7          	jalr	-190(ra) # 80000d0e <release>
      return -1;
    80002dd4:	57fd                	li	a5,-1
    80002dd6:	bff9                	j	80002db4 <sys_sleep+0x88>

0000000080002dd8 <sys_kill>:

uint64
sys_kill(void)
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002de0:	fec40593          	addi	a1,s0,-20
    80002de4:	4501                	li	a0,0
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	d58080e7          	jalr	-680(ra) # 80002b3e <argint>
    80002dee:	87aa                	mv	a5,a0
    return -1;
    80002df0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002df2:	0007c863          	bltz	a5,80002e02 <sys_kill+0x2a>
  return kill(pid);
    80002df6:	fec42503          	lw	a0,-20(s0)
    80002dfa:	fffff097          	auipc	ra,0xfffff
    80002dfe:	632080e7          	jalr	1586(ra) # 8000242c <kill>
}
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	e426                	sd	s1,8(sp)
    80002e12:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e14:	00015517          	auipc	a0,0x15
    80002e18:	95450513          	addi	a0,a0,-1708 # 80017768 <tickslock>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	e3e080e7          	jalr	-450(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002e24:	00006497          	auipc	s1,0x6
    80002e28:	1fc4a483          	lw	s1,508(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e2c:	00015517          	auipc	a0,0x15
    80002e30:	93c50513          	addi	a0,a0,-1732 # 80017768 <tickslock>
    80002e34:	ffffe097          	auipc	ra,0xffffe
    80002e38:	eda080e7          	jalr	-294(ra) # 80000d0e <release>
  return xticks;
}
    80002e3c:	02049513          	slli	a0,s1,0x20
    80002e40:	9101                	srli	a0,a0,0x20
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret

0000000080002e4c <sys_trace>:

uint64
sys_trace(void)
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	1000                	addi	s0,sp,32
    int tmask;

    if (argint(0, &tmask) < 0)
    80002e54:	fec40593          	addi	a1,s0,-20
    80002e58:	4501                	li	a0,0
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	ce4080e7          	jalr	-796(ra) # 80002b3e <argint>
        return -1;
    80002e62:	57fd                	li	a5,-1
    if (argint(0, &tmask) < 0)
    80002e64:	00054a63          	bltz	a0,80002e78 <sys_trace+0x2c>
    myproc()->tmask = tmask;
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	bc0080e7          	jalr	-1088(ra) # 80001a28 <myproc>
    80002e70:	fec42783          	lw	a5,-20(s0)
    80002e74:	dd5c                	sw	a5,60(a0)
    return 0;
    80002e76:	4781                	li	a5,0
}
    80002e78:	853e                	mv	a0,a5
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <sys_sysinfo>:

uint64
sys_sysinfo(void)
{
    80002e82:	7139                	addi	sp,sp,-64
    80002e84:	fc06                	sd	ra,56(sp)
    80002e86:	f822                	sd	s0,48(sp)
    80002e88:	f426                	sd	s1,40(sp)
    80002e8a:	0080                	addi	s0,sp,64
  struct sysinfo si;
  struct proc *p = myproc();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	b9c080e7          	jalr	-1124(ra) # 80001a28 <myproc>
    80002e94:	84aa                	mv	s1,a0
  uint64 addr;
  // get user space address for sysinfo
  if (argaddr(0, &addr) < 0)
    80002e96:	fc840593          	addi	a1,s0,-56
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	cc4080e7          	jalr	-828(ra) # 80002b60 <argaddr>
    return -1;
    80002ea4:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0)
    80002ea6:	02054a63          	bltz	a0,80002eda <sys_sysinfo+0x58>

  si.freemem = kcountfree();
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	cd6080e7          	jalr	-810(ra) # 80000b80 <kcountfree>
    80002eb2:	fca43823          	sd	a0,-48(s0)
  si.nproc = countproc();
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	742080e7          	jalr	1858(ra) # 800025f8 <countproc>
    80002ebe:	fca43c23          	sd	a0,-40(s0)

  if (copyout(p->pagetable, addr, (char*)&si, sizeof(si)) < 0)
    80002ec2:	46c1                	li	a3,16
    80002ec4:	fd040613          	addi	a2,s0,-48
    80002ec8:	fc843583          	ld	a1,-56(s0)
    80002ecc:	68a8                	ld	a0,80(s1)
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	84e080e7          	jalr	-1970(ra) # 8000171c <copyout>
    80002ed6:	43f55793          	srai	a5,a0,0x3f
    return -1;

  return 0;
    80002eda:	853e                	mv	a0,a5
    80002edc:	70e2                	ld	ra,56(sp)
    80002ede:	7442                	ld	s0,48(sp)
    80002ee0:	74a2                	ld	s1,40(sp)
    80002ee2:	6121                	addi	sp,sp,64
    80002ee4:	8082                	ret

0000000080002ee6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ee6:	7179                	addi	sp,sp,-48
    80002ee8:	f406                	sd	ra,40(sp)
    80002eea:	f022                	sd	s0,32(sp)
    80002eec:	ec26                	sd	s1,24(sp)
    80002eee:	e84a                	sd	s2,16(sp)
    80002ef0:	e44e                	sd	s3,8(sp)
    80002ef2:	e052                	sd	s4,0(sp)
    80002ef4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ef6:	00005597          	auipc	a1,0x5
    80002efa:	77a58593          	addi	a1,a1,1914 # 80008670 <syscall_names+0xc0>
    80002efe:	00015517          	auipc	a0,0x15
    80002f02:	88250513          	addi	a0,a0,-1918 # 80017780 <bcache>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	cc4080e7          	jalr	-828(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f0e:	0001d797          	auipc	a5,0x1d
    80002f12:	87278793          	addi	a5,a5,-1934 # 8001f780 <bcache+0x8000>
    80002f16:	0001d717          	auipc	a4,0x1d
    80002f1a:	ad270713          	addi	a4,a4,-1326 # 8001f9e8 <bcache+0x8268>
    80002f1e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f22:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f26:	00015497          	auipc	s1,0x15
    80002f2a:	87248493          	addi	s1,s1,-1934 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f2e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f30:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f32:	00005a17          	auipc	s4,0x5
    80002f36:	746a0a13          	addi	s4,s4,1862 # 80008678 <syscall_names+0xc8>
    b->next = bcache.head.next;
    80002f3a:	2b893783          	ld	a5,696(s2)
    80002f3e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f40:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f44:	85d2                	mv	a1,s4
    80002f46:	01048513          	addi	a0,s1,16
    80002f4a:	00001097          	auipc	ra,0x1
    80002f4e:	4ac080e7          	jalr	1196(ra) # 800043f6 <initsleeplock>
    bcache.head.next->prev = b;
    80002f52:	2b893783          	ld	a5,696(s2)
    80002f56:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f58:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f5c:	45848493          	addi	s1,s1,1112
    80002f60:	fd349de3          	bne	s1,s3,80002f3a <binit+0x54>
  }
}
    80002f64:	70a2                	ld	ra,40(sp)
    80002f66:	7402                	ld	s0,32(sp)
    80002f68:	64e2                	ld	s1,24(sp)
    80002f6a:	6942                	ld	s2,16(sp)
    80002f6c:	69a2                	ld	s3,8(sp)
    80002f6e:	6a02                	ld	s4,0(sp)
    80002f70:	6145                	addi	sp,sp,48
    80002f72:	8082                	ret

0000000080002f74 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f74:	7179                	addi	sp,sp,-48
    80002f76:	f406                	sd	ra,40(sp)
    80002f78:	f022                	sd	s0,32(sp)
    80002f7a:	ec26                	sd	s1,24(sp)
    80002f7c:	e84a                	sd	s2,16(sp)
    80002f7e:	e44e                	sd	s3,8(sp)
    80002f80:	1800                	addi	s0,sp,48
    80002f82:	89aa                	mv	s3,a0
    80002f84:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f86:	00014517          	auipc	a0,0x14
    80002f8a:	7fa50513          	addi	a0,a0,2042 # 80017780 <bcache>
    80002f8e:	ffffe097          	auipc	ra,0xffffe
    80002f92:	ccc080e7          	jalr	-820(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f96:	0001d497          	auipc	s1,0x1d
    80002f9a:	aa24b483          	ld	s1,-1374(s1) # 8001fa38 <bcache+0x82b8>
    80002f9e:	0001d797          	auipc	a5,0x1d
    80002fa2:	a4a78793          	addi	a5,a5,-1462 # 8001f9e8 <bcache+0x8268>
    80002fa6:	02f48f63          	beq	s1,a5,80002fe4 <bread+0x70>
    80002faa:	873e                	mv	a4,a5
    80002fac:	a021                	j	80002fb4 <bread+0x40>
    80002fae:	68a4                	ld	s1,80(s1)
    80002fb0:	02e48a63          	beq	s1,a4,80002fe4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fb4:	449c                	lw	a5,8(s1)
    80002fb6:	ff379ce3          	bne	a5,s3,80002fae <bread+0x3a>
    80002fba:	44dc                	lw	a5,12(s1)
    80002fbc:	ff2799e3          	bne	a5,s2,80002fae <bread+0x3a>
      b->refcnt++;
    80002fc0:	40bc                	lw	a5,64(s1)
    80002fc2:	2785                	addiw	a5,a5,1
    80002fc4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	7ba50513          	addi	a0,a0,1978 # 80017780 <bcache>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	d40080e7          	jalr	-704(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80002fd6:	01048513          	addi	a0,s1,16
    80002fda:	00001097          	auipc	ra,0x1
    80002fde:	456080e7          	jalr	1110(ra) # 80004430 <acquiresleep>
      return b;
    80002fe2:	a8b9                	j	80003040 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe4:	0001d497          	auipc	s1,0x1d
    80002fe8:	a4c4b483          	ld	s1,-1460(s1) # 8001fa30 <bcache+0x82b0>
    80002fec:	0001d797          	auipc	a5,0x1d
    80002ff0:	9fc78793          	addi	a5,a5,-1540 # 8001f9e8 <bcache+0x8268>
    80002ff4:	00f48863          	beq	s1,a5,80003004 <bread+0x90>
    80002ff8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ffa:	40bc                	lw	a5,64(s1)
    80002ffc:	cf81                	beqz	a5,80003014 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ffe:	64a4                	ld	s1,72(s1)
    80003000:	fee49de3          	bne	s1,a4,80002ffa <bread+0x86>
  panic("bget: no buffers");
    80003004:	00005517          	auipc	a0,0x5
    80003008:	67c50513          	addi	a0,a0,1660 # 80008680 <syscall_names+0xd0>
    8000300c:	ffffd097          	auipc	ra,0xffffd
    80003010:	53c080e7          	jalr	1340(ra) # 80000548 <panic>
      b->dev = dev;
    80003014:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003018:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000301c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003020:	4785                	li	a5,1
    80003022:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	75c50513          	addi	a0,a0,1884 # 80017780 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	ce2080e7          	jalr	-798(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003034:	01048513          	addi	a0,s1,16
    80003038:	00001097          	auipc	ra,0x1
    8000303c:	3f8080e7          	jalr	1016(ra) # 80004430 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003040:	409c                	lw	a5,0(s1)
    80003042:	cb89                	beqz	a5,80003054 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003044:	8526                	mv	a0,s1
    80003046:	70a2                	ld	ra,40(sp)
    80003048:	7402                	ld	s0,32(sp)
    8000304a:	64e2                	ld	s1,24(sp)
    8000304c:	6942                	ld	s2,16(sp)
    8000304e:	69a2                	ld	s3,8(sp)
    80003050:	6145                	addi	sp,sp,48
    80003052:	8082                	ret
    virtio_disk_rw(b, 0);
    80003054:	4581                	li	a1,0
    80003056:	8526                	mv	a0,s1
    80003058:	00003097          	auipc	ra,0x3
    8000305c:	f34080e7          	jalr	-204(ra) # 80005f8c <virtio_disk_rw>
    b->valid = 1;
    80003060:	4785                	li	a5,1
    80003062:	c09c                	sw	a5,0(s1)
  return b;
    80003064:	b7c5                	j	80003044 <bread+0xd0>

0000000080003066 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	1000                	addi	s0,sp,32
    80003070:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003072:	0541                	addi	a0,a0,16
    80003074:	00001097          	auipc	ra,0x1
    80003078:	456080e7          	jalr	1110(ra) # 800044ca <holdingsleep>
    8000307c:	cd01                	beqz	a0,80003094 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000307e:	4585                	li	a1,1
    80003080:	8526                	mv	a0,s1
    80003082:	00003097          	auipc	ra,0x3
    80003086:	f0a080e7          	jalr	-246(ra) # 80005f8c <virtio_disk_rw>
}
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	64a2                	ld	s1,8(sp)
    80003090:	6105                	addi	sp,sp,32
    80003092:	8082                	ret
    panic("bwrite");
    80003094:	00005517          	auipc	a0,0x5
    80003098:	60450513          	addi	a0,a0,1540 # 80008698 <syscall_names+0xe8>
    8000309c:	ffffd097          	auipc	ra,0xffffd
    800030a0:	4ac080e7          	jalr	1196(ra) # 80000548 <panic>

00000000800030a4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	e04a                	sd	s2,0(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b2:	01050913          	addi	s2,a0,16
    800030b6:	854a                	mv	a0,s2
    800030b8:	00001097          	auipc	ra,0x1
    800030bc:	412080e7          	jalr	1042(ra) # 800044ca <holdingsleep>
    800030c0:	c92d                	beqz	a0,80003132 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030c2:	854a                	mv	a0,s2
    800030c4:	00001097          	auipc	ra,0x1
    800030c8:	3c2080e7          	jalr	962(ra) # 80004486 <releasesleep>

  acquire(&bcache.lock);
    800030cc:	00014517          	auipc	a0,0x14
    800030d0:	6b450513          	addi	a0,a0,1716 # 80017780 <bcache>
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	b86080e7          	jalr	-1146(ra) # 80000c5a <acquire>
  b->refcnt--;
    800030dc:	40bc                	lw	a5,64(s1)
    800030de:	37fd                	addiw	a5,a5,-1
    800030e0:	0007871b          	sext.w	a4,a5
    800030e4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030e6:	eb05                	bnez	a4,80003116 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030e8:	68bc                	ld	a5,80(s1)
    800030ea:	64b8                	ld	a4,72(s1)
    800030ec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030ee:	64bc                	ld	a5,72(s1)
    800030f0:	68b8                	ld	a4,80(s1)
    800030f2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030f4:	0001c797          	auipc	a5,0x1c
    800030f8:	68c78793          	addi	a5,a5,1676 # 8001f780 <bcache+0x8000>
    800030fc:	2b87b703          	ld	a4,696(a5)
    80003100:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003102:	0001d717          	auipc	a4,0x1d
    80003106:	8e670713          	addi	a4,a4,-1818 # 8001f9e8 <bcache+0x8268>
    8000310a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000310c:	2b87b703          	ld	a4,696(a5)
    80003110:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003112:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003116:	00014517          	auipc	a0,0x14
    8000311a:	66a50513          	addi	a0,a0,1642 # 80017780 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	bf0080e7          	jalr	-1040(ra) # 80000d0e <release>
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6902                	ld	s2,0(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret
    panic("brelse");
    80003132:	00005517          	auipc	a0,0x5
    80003136:	56e50513          	addi	a0,a0,1390 # 800086a0 <syscall_names+0xf0>
    8000313a:	ffffd097          	auipc	ra,0xffffd
    8000313e:	40e080e7          	jalr	1038(ra) # 80000548 <panic>

0000000080003142 <bpin>:

void
bpin(struct buf *b) {
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314e:	00014517          	auipc	a0,0x14
    80003152:	63250513          	addi	a0,a0,1586 # 80017780 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	b04080e7          	jalr	-1276(ra) # 80000c5a <acquire>
  b->refcnt++;
    8000315e:	40bc                	lw	a5,64(s1)
    80003160:	2785                	addiw	a5,a5,1
    80003162:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003164:	00014517          	auipc	a0,0x14
    80003168:	61c50513          	addi	a0,a0,1564 # 80017780 <bcache>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	ba2080e7          	jalr	-1118(ra) # 80000d0e <release>
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret

000000008000317e <bunpin>:

void
bunpin(struct buf *b) {
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	1000                	addi	s0,sp,32
    80003188:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318a:	00014517          	auipc	a0,0x14
    8000318e:	5f650513          	addi	a0,a0,1526 # 80017780 <bcache>
    80003192:	ffffe097          	auipc	ra,0xffffe
    80003196:	ac8080e7          	jalr	-1336(ra) # 80000c5a <acquire>
  b->refcnt--;
    8000319a:	40bc                	lw	a5,64(s1)
    8000319c:	37fd                	addiw	a5,a5,-1
    8000319e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	5e050513          	addi	a0,a0,1504 # 80017780 <bcache>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	b66080e7          	jalr	-1178(ra) # 80000d0e <release>
}
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	64a2                	ld	s1,8(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret

00000000800031ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	e426                	sd	s1,8(sp)
    800031c2:	e04a                	sd	s2,0(sp)
    800031c4:	1000                	addi	s0,sp,32
    800031c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031c8:	00d5d59b          	srliw	a1,a1,0xd
    800031cc:	0001d797          	auipc	a5,0x1d
    800031d0:	c907a783          	lw	a5,-880(a5) # 8001fe5c <sb+0x1c>
    800031d4:	9dbd                	addw	a1,a1,a5
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	d9e080e7          	jalr	-610(ra) # 80002f74 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031de:	0074f713          	andi	a4,s1,7
    800031e2:	4785                	li	a5,1
    800031e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031e8:	14ce                	slli	s1,s1,0x33
    800031ea:	90d9                	srli	s1,s1,0x36
    800031ec:	00950733          	add	a4,a0,s1
    800031f0:	05874703          	lbu	a4,88(a4)
    800031f4:	00e7f6b3          	and	a3,a5,a4
    800031f8:	c69d                	beqz	a3,80003226 <bfree+0x6c>
    800031fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031fc:	94aa                	add	s1,s1,a0
    800031fe:	fff7c793          	not	a5,a5
    80003202:	8ff9                	and	a5,a5,a4
    80003204:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003208:	00001097          	auipc	ra,0x1
    8000320c:	100080e7          	jalr	256(ra) # 80004308 <log_write>
  brelse(bp);
    80003210:	854a                	mv	a0,s2
    80003212:	00000097          	auipc	ra,0x0
    80003216:	e92080e7          	jalr	-366(ra) # 800030a4 <brelse>
}
    8000321a:	60e2                	ld	ra,24(sp)
    8000321c:	6442                	ld	s0,16(sp)
    8000321e:	64a2                	ld	s1,8(sp)
    80003220:	6902                	ld	s2,0(sp)
    80003222:	6105                	addi	sp,sp,32
    80003224:	8082                	ret
    panic("freeing free block");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	48250513          	addi	a0,a0,1154 # 800086a8 <syscall_names+0xf8>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	31a080e7          	jalr	794(ra) # 80000548 <panic>

0000000080003236 <balloc>:
{
    80003236:	711d                	addi	sp,sp,-96
    80003238:	ec86                	sd	ra,88(sp)
    8000323a:	e8a2                	sd	s0,80(sp)
    8000323c:	e4a6                	sd	s1,72(sp)
    8000323e:	e0ca                	sd	s2,64(sp)
    80003240:	fc4e                	sd	s3,56(sp)
    80003242:	f852                	sd	s4,48(sp)
    80003244:	f456                	sd	s5,40(sp)
    80003246:	f05a                	sd	s6,32(sp)
    80003248:	ec5e                	sd	s7,24(sp)
    8000324a:	e862                	sd	s8,16(sp)
    8000324c:	e466                	sd	s9,8(sp)
    8000324e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003250:	0001d797          	auipc	a5,0x1d
    80003254:	bf47a783          	lw	a5,-1036(a5) # 8001fe44 <sb+0x4>
    80003258:	cbd1                	beqz	a5,800032ec <balloc+0xb6>
    8000325a:	8baa                	mv	s7,a0
    8000325c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000325e:	0001db17          	auipc	s6,0x1d
    80003262:	be2b0b13          	addi	s6,s6,-1054 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003266:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003268:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000326c:	6c89                	lui	s9,0x2
    8000326e:	a831                	j	8000328a <balloc+0x54>
    brelse(bp);
    80003270:	854a                	mv	a0,s2
    80003272:	00000097          	auipc	ra,0x0
    80003276:	e32080e7          	jalr	-462(ra) # 800030a4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000327a:	015c87bb          	addw	a5,s9,s5
    8000327e:	00078a9b          	sext.w	s5,a5
    80003282:	004b2703          	lw	a4,4(s6)
    80003286:	06eaf363          	bgeu	s5,a4,800032ec <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000328a:	41fad79b          	sraiw	a5,s5,0x1f
    8000328e:	0137d79b          	srliw	a5,a5,0x13
    80003292:	015787bb          	addw	a5,a5,s5
    80003296:	40d7d79b          	sraiw	a5,a5,0xd
    8000329a:	01cb2583          	lw	a1,28(s6)
    8000329e:	9dbd                	addw	a1,a1,a5
    800032a0:	855e                	mv	a0,s7
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	cd2080e7          	jalr	-814(ra) # 80002f74 <bread>
    800032aa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ac:	004b2503          	lw	a0,4(s6)
    800032b0:	000a849b          	sext.w	s1,s5
    800032b4:	8662                	mv	a2,s8
    800032b6:	faa4fde3          	bgeu	s1,a0,80003270 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032ba:	41f6579b          	sraiw	a5,a2,0x1f
    800032be:	01d7d69b          	srliw	a3,a5,0x1d
    800032c2:	00c6873b          	addw	a4,a3,a2
    800032c6:	00777793          	andi	a5,a4,7
    800032ca:	9f95                	subw	a5,a5,a3
    800032cc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d0:	4037571b          	sraiw	a4,a4,0x3
    800032d4:	00e906b3          	add	a3,s2,a4
    800032d8:	0586c683          	lbu	a3,88(a3)
    800032dc:	00d7f5b3          	and	a1,a5,a3
    800032e0:	cd91                	beqz	a1,800032fc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e2:	2605                	addiw	a2,a2,1
    800032e4:	2485                	addiw	s1,s1,1
    800032e6:	fd4618e3          	bne	a2,s4,800032b6 <balloc+0x80>
    800032ea:	b759                	j	80003270 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	3d450513          	addi	a0,a0,980 # 800086c0 <syscall_names+0x110>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	254080e7          	jalr	596(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032fc:	974a                	add	a4,a4,s2
    800032fe:	8fd5                	or	a5,a5,a3
    80003300:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003304:	854a                	mv	a0,s2
    80003306:	00001097          	auipc	ra,0x1
    8000330a:	002080e7          	jalr	2(ra) # 80004308 <log_write>
        brelse(bp);
    8000330e:	854a                	mv	a0,s2
    80003310:	00000097          	auipc	ra,0x0
    80003314:	d94080e7          	jalr	-620(ra) # 800030a4 <brelse>
  bp = bread(dev, bno);
    80003318:	85a6                	mv	a1,s1
    8000331a:	855e                	mv	a0,s7
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	c58080e7          	jalr	-936(ra) # 80002f74 <bread>
    80003324:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003326:	40000613          	li	a2,1024
    8000332a:	4581                	li	a1,0
    8000332c:	05850513          	addi	a0,a0,88
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	a26080e7          	jalr	-1498(ra) # 80000d56 <memset>
  log_write(bp);
    80003338:	854a                	mv	a0,s2
    8000333a:	00001097          	auipc	ra,0x1
    8000333e:	fce080e7          	jalr	-50(ra) # 80004308 <log_write>
  brelse(bp);
    80003342:	854a                	mv	a0,s2
    80003344:	00000097          	auipc	ra,0x0
    80003348:	d60080e7          	jalr	-672(ra) # 800030a4 <brelse>
}
    8000334c:	8526                	mv	a0,s1
    8000334e:	60e6                	ld	ra,88(sp)
    80003350:	6446                	ld	s0,80(sp)
    80003352:	64a6                	ld	s1,72(sp)
    80003354:	6906                	ld	s2,64(sp)
    80003356:	79e2                	ld	s3,56(sp)
    80003358:	7a42                	ld	s4,48(sp)
    8000335a:	7aa2                	ld	s5,40(sp)
    8000335c:	7b02                	ld	s6,32(sp)
    8000335e:	6be2                	ld	s7,24(sp)
    80003360:	6c42                	ld	s8,16(sp)
    80003362:	6ca2                	ld	s9,8(sp)
    80003364:	6125                	addi	sp,sp,96
    80003366:	8082                	ret

0000000080003368 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003368:	7179                	addi	sp,sp,-48
    8000336a:	f406                	sd	ra,40(sp)
    8000336c:	f022                	sd	s0,32(sp)
    8000336e:	ec26                	sd	s1,24(sp)
    80003370:	e84a                	sd	s2,16(sp)
    80003372:	e44e                	sd	s3,8(sp)
    80003374:	e052                	sd	s4,0(sp)
    80003376:	1800                	addi	s0,sp,48
    80003378:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000337a:	47ad                	li	a5,11
    8000337c:	04b7fe63          	bgeu	a5,a1,800033d8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003380:	ff45849b          	addiw	s1,a1,-12
    80003384:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003388:	0ff00793          	li	a5,255
    8000338c:	0ae7e363          	bltu	a5,a4,80003432 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003390:	08052583          	lw	a1,128(a0)
    80003394:	c5ad                	beqz	a1,800033fe <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003396:	00092503          	lw	a0,0(s2)
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	bda080e7          	jalr	-1062(ra) # 80002f74 <bread>
    800033a2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033a4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033a8:	02049593          	slli	a1,s1,0x20
    800033ac:	9181                	srli	a1,a1,0x20
    800033ae:	058a                	slli	a1,a1,0x2
    800033b0:	00b784b3          	add	s1,a5,a1
    800033b4:	0004a983          	lw	s3,0(s1)
    800033b8:	04098d63          	beqz	s3,80003412 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033bc:	8552                	mv	a0,s4
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	ce6080e7          	jalr	-794(ra) # 800030a4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033c6:	854e                	mv	a0,s3
    800033c8:	70a2                	ld	ra,40(sp)
    800033ca:	7402                	ld	s0,32(sp)
    800033cc:	64e2                	ld	s1,24(sp)
    800033ce:	6942                	ld	s2,16(sp)
    800033d0:	69a2                	ld	s3,8(sp)
    800033d2:	6a02                	ld	s4,0(sp)
    800033d4:	6145                	addi	sp,sp,48
    800033d6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033d8:	02059493          	slli	s1,a1,0x20
    800033dc:	9081                	srli	s1,s1,0x20
    800033de:	048a                	slli	s1,s1,0x2
    800033e0:	94aa                	add	s1,s1,a0
    800033e2:	0504a983          	lw	s3,80(s1)
    800033e6:	fe0990e3          	bnez	s3,800033c6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ea:	4108                	lw	a0,0(a0)
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	e4a080e7          	jalr	-438(ra) # 80003236 <balloc>
    800033f4:	0005099b          	sext.w	s3,a0
    800033f8:	0534a823          	sw	s3,80(s1)
    800033fc:	b7e9                	j	800033c6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033fe:	4108                	lw	a0,0(a0)
    80003400:	00000097          	auipc	ra,0x0
    80003404:	e36080e7          	jalr	-458(ra) # 80003236 <balloc>
    80003408:	0005059b          	sext.w	a1,a0
    8000340c:	08b92023          	sw	a1,128(s2)
    80003410:	b759                	j	80003396 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003412:	00092503          	lw	a0,0(s2)
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	e20080e7          	jalr	-480(ra) # 80003236 <balloc>
    8000341e:	0005099b          	sext.w	s3,a0
    80003422:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003426:	8552                	mv	a0,s4
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	ee0080e7          	jalr	-288(ra) # 80004308 <log_write>
    80003430:	b771                	j	800033bc <bmap+0x54>
  panic("bmap: out of range");
    80003432:	00005517          	auipc	a0,0x5
    80003436:	2a650513          	addi	a0,a0,678 # 800086d8 <syscall_names+0x128>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	10e080e7          	jalr	270(ra) # 80000548 <panic>

0000000080003442 <iget>:
{
    80003442:	7179                	addi	sp,sp,-48
    80003444:	f406                	sd	ra,40(sp)
    80003446:	f022                	sd	s0,32(sp)
    80003448:	ec26                	sd	s1,24(sp)
    8000344a:	e84a                	sd	s2,16(sp)
    8000344c:	e44e                	sd	s3,8(sp)
    8000344e:	e052                	sd	s4,0(sp)
    80003450:	1800                	addi	s0,sp,48
    80003452:	89aa                	mv	s3,a0
    80003454:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003456:	0001d517          	auipc	a0,0x1d
    8000345a:	a0a50513          	addi	a0,a0,-1526 # 8001fe60 <icache>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	7fc080e7          	jalr	2044(ra) # 80000c5a <acquire>
  empty = 0;
    80003466:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003468:	0001d497          	auipc	s1,0x1d
    8000346c:	a1048493          	addi	s1,s1,-1520 # 8001fe78 <icache+0x18>
    80003470:	0001e697          	auipc	a3,0x1e
    80003474:	49868693          	addi	a3,a3,1176 # 80021908 <log>
    80003478:	a039                	j	80003486 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000347a:	02090b63          	beqz	s2,800034b0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000347e:	08848493          	addi	s1,s1,136
    80003482:	02d48a63          	beq	s1,a3,800034b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003486:	449c                	lw	a5,8(s1)
    80003488:	fef059e3          	blez	a5,8000347a <iget+0x38>
    8000348c:	4098                	lw	a4,0(s1)
    8000348e:	ff3716e3          	bne	a4,s3,8000347a <iget+0x38>
    80003492:	40d8                	lw	a4,4(s1)
    80003494:	ff4713e3          	bne	a4,s4,8000347a <iget+0x38>
      ip->ref++;
    80003498:	2785                	addiw	a5,a5,1
    8000349a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000349c:	0001d517          	auipc	a0,0x1d
    800034a0:	9c450513          	addi	a0,a0,-1596 # 8001fe60 <icache>
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	86a080e7          	jalr	-1942(ra) # 80000d0e <release>
      return ip;
    800034ac:	8926                	mv	s2,s1
    800034ae:	a03d                	j	800034dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b0:	f7f9                	bnez	a5,8000347e <iget+0x3c>
    800034b2:	8926                	mv	s2,s1
    800034b4:	b7e9                	j	8000347e <iget+0x3c>
  if(empty == 0)
    800034b6:	02090c63          	beqz	s2,800034ee <iget+0xac>
  ip->dev = dev;
    800034ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c2:	4785                	li	a5,1
    800034c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034c8:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034cc:	0001d517          	auipc	a0,0x1d
    800034d0:	99450513          	addi	a0,a0,-1644 # 8001fe60 <icache>
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	83a080e7          	jalr	-1990(ra) # 80000d0e <release>
}
    800034dc:	854a                	mv	a0,s2
    800034de:	70a2                	ld	ra,40(sp)
    800034e0:	7402                	ld	s0,32(sp)
    800034e2:	64e2                	ld	s1,24(sp)
    800034e4:	6942                	ld	s2,16(sp)
    800034e6:	69a2                	ld	s3,8(sp)
    800034e8:	6a02                	ld	s4,0(sp)
    800034ea:	6145                	addi	sp,sp,48
    800034ec:	8082                	ret
    panic("iget: no inodes");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	20250513          	addi	a0,a0,514 # 800086f0 <syscall_names+0x140>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	052080e7          	jalr	82(ra) # 80000548 <panic>

00000000800034fe <fsinit>:
fsinit(int dev) {
    800034fe:	7179                	addi	sp,sp,-48
    80003500:	f406                	sd	ra,40(sp)
    80003502:	f022                	sd	s0,32(sp)
    80003504:	ec26                	sd	s1,24(sp)
    80003506:	e84a                	sd	s2,16(sp)
    80003508:	e44e                	sd	s3,8(sp)
    8000350a:	1800                	addi	s0,sp,48
    8000350c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000350e:	4585                	li	a1,1
    80003510:	00000097          	auipc	ra,0x0
    80003514:	a64080e7          	jalr	-1436(ra) # 80002f74 <bread>
    80003518:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000351a:	0001d997          	auipc	s3,0x1d
    8000351e:	92698993          	addi	s3,s3,-1754 # 8001fe40 <sb>
    80003522:	02000613          	li	a2,32
    80003526:	05850593          	addi	a1,a0,88
    8000352a:	854e                	mv	a0,s3
    8000352c:	ffffe097          	auipc	ra,0xffffe
    80003530:	88a080e7          	jalr	-1910(ra) # 80000db6 <memmove>
  brelse(bp);
    80003534:	8526                	mv	a0,s1
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	b6e080e7          	jalr	-1170(ra) # 800030a4 <brelse>
  if(sb.magic != FSMAGIC)
    8000353e:	0009a703          	lw	a4,0(s3)
    80003542:	102037b7          	lui	a5,0x10203
    80003546:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000354a:	02f71263          	bne	a4,a5,8000356e <fsinit+0x70>
  initlog(dev, &sb);
    8000354e:	0001d597          	auipc	a1,0x1d
    80003552:	8f258593          	addi	a1,a1,-1806 # 8001fe40 <sb>
    80003556:	854a                	mv	a0,s2
    80003558:	00001097          	auipc	ra,0x1
    8000355c:	b38080e7          	jalr	-1224(ra) # 80004090 <initlog>
}
    80003560:	70a2                	ld	ra,40(sp)
    80003562:	7402                	ld	s0,32(sp)
    80003564:	64e2                	ld	s1,24(sp)
    80003566:	6942                	ld	s2,16(sp)
    80003568:	69a2                	ld	s3,8(sp)
    8000356a:	6145                	addi	sp,sp,48
    8000356c:	8082                	ret
    panic("invalid file system");
    8000356e:	00005517          	auipc	a0,0x5
    80003572:	19250513          	addi	a0,a0,402 # 80008700 <syscall_names+0x150>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	fd2080e7          	jalr	-46(ra) # 80000548 <panic>

000000008000357e <iinit>:
{
    8000357e:	7179                	addi	sp,sp,-48
    80003580:	f406                	sd	ra,40(sp)
    80003582:	f022                	sd	s0,32(sp)
    80003584:	ec26                	sd	s1,24(sp)
    80003586:	e84a                	sd	s2,16(sp)
    80003588:	e44e                	sd	s3,8(sp)
    8000358a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000358c:	00005597          	auipc	a1,0x5
    80003590:	18c58593          	addi	a1,a1,396 # 80008718 <syscall_names+0x168>
    80003594:	0001d517          	auipc	a0,0x1d
    80003598:	8cc50513          	addi	a0,a0,-1844 # 8001fe60 <icache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	62e080e7          	jalr	1582(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    800035a4:	0001d497          	auipc	s1,0x1d
    800035a8:	8e448493          	addi	s1,s1,-1820 # 8001fe88 <icache+0x28>
    800035ac:	0001e997          	auipc	s3,0x1e
    800035b0:	36c98993          	addi	s3,s3,876 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035b4:	00005917          	auipc	s2,0x5
    800035b8:	16c90913          	addi	s2,s2,364 # 80008720 <syscall_names+0x170>
    800035bc:	85ca                	mv	a1,s2
    800035be:	8526                	mv	a0,s1
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	e36080e7          	jalr	-458(ra) # 800043f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035c8:	08848493          	addi	s1,s1,136
    800035cc:	ff3498e3          	bne	s1,s3,800035bc <iinit+0x3e>
}
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6145                	addi	sp,sp,48
    800035dc:	8082                	ret

00000000800035de <ialloc>:
{
    800035de:	715d                	addi	sp,sp,-80
    800035e0:	e486                	sd	ra,72(sp)
    800035e2:	e0a2                	sd	s0,64(sp)
    800035e4:	fc26                	sd	s1,56(sp)
    800035e6:	f84a                	sd	s2,48(sp)
    800035e8:	f44e                	sd	s3,40(sp)
    800035ea:	f052                	sd	s4,32(sp)
    800035ec:	ec56                	sd	s5,24(sp)
    800035ee:	e85a                	sd	s6,16(sp)
    800035f0:	e45e                	sd	s7,8(sp)
    800035f2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f4:	0001d717          	auipc	a4,0x1d
    800035f8:	85872703          	lw	a4,-1960(a4) # 8001fe4c <sb+0xc>
    800035fc:	4785                	li	a5,1
    800035fe:	04e7fa63          	bgeu	a5,a4,80003652 <ialloc+0x74>
    80003602:	8aaa                	mv	s5,a0
    80003604:	8bae                	mv	s7,a1
    80003606:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003608:	0001da17          	auipc	s4,0x1d
    8000360c:	838a0a13          	addi	s4,s4,-1992 # 8001fe40 <sb>
    80003610:	00048b1b          	sext.w	s6,s1
    80003614:	0044d593          	srli	a1,s1,0x4
    80003618:	018a2783          	lw	a5,24(s4)
    8000361c:	9dbd                	addw	a1,a1,a5
    8000361e:	8556                	mv	a0,s5
    80003620:	00000097          	auipc	ra,0x0
    80003624:	954080e7          	jalr	-1708(ra) # 80002f74 <bread>
    80003628:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000362a:	05850993          	addi	s3,a0,88
    8000362e:	00f4f793          	andi	a5,s1,15
    80003632:	079a                	slli	a5,a5,0x6
    80003634:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003636:	00099783          	lh	a5,0(s3)
    8000363a:	c785                	beqz	a5,80003662 <ialloc+0x84>
    brelse(bp);
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	a68080e7          	jalr	-1432(ra) # 800030a4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003644:	0485                	addi	s1,s1,1
    80003646:	00ca2703          	lw	a4,12(s4)
    8000364a:	0004879b          	sext.w	a5,s1
    8000364e:	fce7e1e3          	bltu	a5,a4,80003610 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003652:	00005517          	auipc	a0,0x5
    80003656:	0d650513          	addi	a0,a0,214 # 80008728 <syscall_names+0x178>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	eee080e7          	jalr	-274(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003662:	04000613          	li	a2,64
    80003666:	4581                	li	a1,0
    80003668:	854e                	mv	a0,s3
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	6ec080e7          	jalr	1772(ra) # 80000d56 <memset>
      dip->type = type;
    80003672:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003676:	854a                	mv	a0,s2
    80003678:	00001097          	auipc	ra,0x1
    8000367c:	c90080e7          	jalr	-880(ra) # 80004308 <log_write>
      brelse(bp);
    80003680:	854a                	mv	a0,s2
    80003682:	00000097          	auipc	ra,0x0
    80003686:	a22080e7          	jalr	-1502(ra) # 800030a4 <brelse>
      return iget(dev, inum);
    8000368a:	85da                	mv	a1,s6
    8000368c:	8556                	mv	a0,s5
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	db4080e7          	jalr	-588(ra) # 80003442 <iget>
}
    80003696:	60a6                	ld	ra,72(sp)
    80003698:	6406                	ld	s0,64(sp)
    8000369a:	74e2                	ld	s1,56(sp)
    8000369c:	7942                	ld	s2,48(sp)
    8000369e:	79a2                	ld	s3,40(sp)
    800036a0:	7a02                	ld	s4,32(sp)
    800036a2:	6ae2                	ld	s5,24(sp)
    800036a4:	6b42                	ld	s6,16(sp)
    800036a6:	6ba2                	ld	s7,8(sp)
    800036a8:	6161                	addi	sp,sp,80
    800036aa:	8082                	ret

00000000800036ac <iupdate>:
{
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	e04a                	sd	s2,0(sp)
    800036b6:	1000                	addi	s0,sp,32
    800036b8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ba:	415c                	lw	a5,4(a0)
    800036bc:	0047d79b          	srliw	a5,a5,0x4
    800036c0:	0001c597          	auipc	a1,0x1c
    800036c4:	7985a583          	lw	a1,1944(a1) # 8001fe58 <sb+0x18>
    800036c8:	9dbd                	addw	a1,a1,a5
    800036ca:	4108                	lw	a0,0(a0)
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	8a8080e7          	jalr	-1880(ra) # 80002f74 <bread>
    800036d4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d6:	05850793          	addi	a5,a0,88
    800036da:	40c8                	lw	a0,4(s1)
    800036dc:	893d                	andi	a0,a0,15
    800036de:	051a                	slli	a0,a0,0x6
    800036e0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036e2:	04449703          	lh	a4,68(s1)
    800036e6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036ea:	04649703          	lh	a4,70(s1)
    800036ee:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036f2:	04849703          	lh	a4,72(s1)
    800036f6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036fa:	04a49703          	lh	a4,74(s1)
    800036fe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003702:	44f8                	lw	a4,76(s1)
    80003704:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003706:	03400613          	li	a2,52
    8000370a:	05048593          	addi	a1,s1,80
    8000370e:	0531                	addi	a0,a0,12
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	6a6080e7          	jalr	1702(ra) # 80000db6 <memmove>
  log_write(bp);
    80003718:	854a                	mv	a0,s2
    8000371a:	00001097          	auipc	ra,0x1
    8000371e:	bee080e7          	jalr	-1042(ra) # 80004308 <log_write>
  brelse(bp);
    80003722:	854a                	mv	a0,s2
    80003724:	00000097          	auipc	ra,0x0
    80003728:	980080e7          	jalr	-1664(ra) # 800030a4 <brelse>
}
    8000372c:	60e2                	ld	ra,24(sp)
    8000372e:	6442                	ld	s0,16(sp)
    80003730:	64a2                	ld	s1,8(sp)
    80003732:	6902                	ld	s2,0(sp)
    80003734:	6105                	addi	sp,sp,32
    80003736:	8082                	ret

0000000080003738 <idup>:
{
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	1000                	addi	s0,sp,32
    80003742:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003744:	0001c517          	auipc	a0,0x1c
    80003748:	71c50513          	addi	a0,a0,1820 # 8001fe60 <icache>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	50e080e7          	jalr	1294(ra) # 80000c5a <acquire>
  ip->ref++;
    80003754:	449c                	lw	a5,8(s1)
    80003756:	2785                	addiw	a5,a5,1
    80003758:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000375a:	0001c517          	auipc	a0,0x1c
    8000375e:	70650513          	addi	a0,a0,1798 # 8001fe60 <icache>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	5ac080e7          	jalr	1452(ra) # 80000d0e <release>
}
    8000376a:	8526                	mv	a0,s1
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6105                	addi	sp,sp,32
    80003774:	8082                	ret

0000000080003776 <ilock>:
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	e04a                	sd	s2,0(sp)
    80003780:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003782:	c115                	beqz	a0,800037a6 <ilock+0x30>
    80003784:	84aa                	mv	s1,a0
    80003786:	451c                	lw	a5,8(a0)
    80003788:	00f05f63          	blez	a5,800037a6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000378c:	0541                	addi	a0,a0,16
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	ca2080e7          	jalr	-862(ra) # 80004430 <acquiresleep>
  if(ip->valid == 0){
    80003796:	40bc                	lw	a5,64(s1)
    80003798:	cf99                	beqz	a5,800037b6 <ilock+0x40>
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6902                	ld	s2,0(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret
    panic("ilock");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	f9a50513          	addi	a0,a0,-102 # 80008740 <syscall_names+0x190>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	d9a080e7          	jalr	-614(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037b6:	40dc                	lw	a5,4(s1)
    800037b8:	0047d79b          	srliw	a5,a5,0x4
    800037bc:	0001c597          	auipc	a1,0x1c
    800037c0:	69c5a583          	lw	a1,1692(a1) # 8001fe58 <sb+0x18>
    800037c4:	9dbd                	addw	a1,a1,a5
    800037c6:	4088                	lw	a0,0(s1)
    800037c8:	fffff097          	auipc	ra,0xfffff
    800037cc:	7ac080e7          	jalr	1964(ra) # 80002f74 <bread>
    800037d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d2:	05850593          	addi	a1,a0,88
    800037d6:	40dc                	lw	a5,4(s1)
    800037d8:	8bbd                	andi	a5,a5,15
    800037da:	079a                	slli	a5,a5,0x6
    800037dc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037de:	00059783          	lh	a5,0(a1)
    800037e2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037e6:	00259783          	lh	a5,2(a1)
    800037ea:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037ee:	00459783          	lh	a5,4(a1)
    800037f2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037f6:	00659783          	lh	a5,6(a1)
    800037fa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037fe:	459c                	lw	a5,8(a1)
    80003800:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003802:	03400613          	li	a2,52
    80003806:	05b1                	addi	a1,a1,12
    80003808:	05048513          	addi	a0,s1,80
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	5aa080e7          	jalr	1450(ra) # 80000db6 <memmove>
    brelse(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	88e080e7          	jalr	-1906(ra) # 800030a4 <brelse>
    ip->valid = 1;
    8000381e:	4785                	li	a5,1
    80003820:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003822:	04449783          	lh	a5,68(s1)
    80003826:	fbb5                	bnez	a5,8000379a <ilock+0x24>
      panic("ilock: no type");
    80003828:	00005517          	auipc	a0,0x5
    8000382c:	f2050513          	addi	a0,a0,-224 # 80008748 <syscall_names+0x198>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	d18080e7          	jalr	-744(ra) # 80000548 <panic>

0000000080003838 <iunlock>:
{
    80003838:	1101                	addi	sp,sp,-32
    8000383a:	ec06                	sd	ra,24(sp)
    8000383c:	e822                	sd	s0,16(sp)
    8000383e:	e426                	sd	s1,8(sp)
    80003840:	e04a                	sd	s2,0(sp)
    80003842:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003844:	c905                	beqz	a0,80003874 <iunlock+0x3c>
    80003846:	84aa                	mv	s1,a0
    80003848:	01050913          	addi	s2,a0,16
    8000384c:	854a                	mv	a0,s2
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	c7c080e7          	jalr	-900(ra) # 800044ca <holdingsleep>
    80003856:	cd19                	beqz	a0,80003874 <iunlock+0x3c>
    80003858:	449c                	lw	a5,8(s1)
    8000385a:	00f05d63          	blez	a5,80003874 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000385e:	854a                	mv	a0,s2
    80003860:	00001097          	auipc	ra,0x1
    80003864:	c26080e7          	jalr	-986(ra) # 80004486 <releasesleep>
}
    80003868:	60e2                	ld	ra,24(sp)
    8000386a:	6442                	ld	s0,16(sp)
    8000386c:	64a2                	ld	s1,8(sp)
    8000386e:	6902                	ld	s2,0(sp)
    80003870:	6105                	addi	sp,sp,32
    80003872:	8082                	ret
    panic("iunlock");
    80003874:	00005517          	auipc	a0,0x5
    80003878:	ee450513          	addi	a0,a0,-284 # 80008758 <syscall_names+0x1a8>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	ccc080e7          	jalr	-820(ra) # 80000548 <panic>

0000000080003884 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003884:	7179                	addi	sp,sp,-48
    80003886:	f406                	sd	ra,40(sp)
    80003888:	f022                	sd	s0,32(sp)
    8000388a:	ec26                	sd	s1,24(sp)
    8000388c:	e84a                	sd	s2,16(sp)
    8000388e:	e44e                	sd	s3,8(sp)
    80003890:	e052                	sd	s4,0(sp)
    80003892:	1800                	addi	s0,sp,48
    80003894:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003896:	05050493          	addi	s1,a0,80
    8000389a:	08050913          	addi	s2,a0,128
    8000389e:	a021                	j	800038a6 <itrunc+0x22>
    800038a0:	0491                	addi	s1,s1,4
    800038a2:	01248d63          	beq	s1,s2,800038bc <itrunc+0x38>
    if(ip->addrs[i]){
    800038a6:	408c                	lw	a1,0(s1)
    800038a8:	dde5                	beqz	a1,800038a0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038aa:	0009a503          	lw	a0,0(s3)
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	90c080e7          	jalr	-1780(ra) # 800031ba <bfree>
      ip->addrs[i] = 0;
    800038b6:	0004a023          	sw	zero,0(s1)
    800038ba:	b7dd                	j	800038a0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038bc:	0809a583          	lw	a1,128(s3)
    800038c0:	e185                	bnez	a1,800038e0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038c2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038c6:	854e                	mv	a0,s3
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	de4080e7          	jalr	-540(ra) # 800036ac <iupdate>
}
    800038d0:	70a2                	ld	ra,40(sp)
    800038d2:	7402                	ld	s0,32(sp)
    800038d4:	64e2                	ld	s1,24(sp)
    800038d6:	6942                	ld	s2,16(sp)
    800038d8:	69a2                	ld	s3,8(sp)
    800038da:	6a02                	ld	s4,0(sp)
    800038dc:	6145                	addi	sp,sp,48
    800038de:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038e0:	0009a503          	lw	a0,0(s3)
    800038e4:	fffff097          	auipc	ra,0xfffff
    800038e8:	690080e7          	jalr	1680(ra) # 80002f74 <bread>
    800038ec:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038ee:	05850493          	addi	s1,a0,88
    800038f2:	45850913          	addi	s2,a0,1112
    800038f6:	a811                	j	8000390a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038f8:	0009a503          	lw	a0,0(s3)
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	8be080e7          	jalr	-1858(ra) # 800031ba <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003904:	0491                	addi	s1,s1,4
    80003906:	01248563          	beq	s1,s2,80003910 <itrunc+0x8c>
      if(a[j])
    8000390a:	408c                	lw	a1,0(s1)
    8000390c:	dde5                	beqz	a1,80003904 <itrunc+0x80>
    8000390e:	b7ed                	j	800038f8 <itrunc+0x74>
    brelse(bp);
    80003910:	8552                	mv	a0,s4
    80003912:	fffff097          	auipc	ra,0xfffff
    80003916:	792080e7          	jalr	1938(ra) # 800030a4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000391a:	0809a583          	lw	a1,128(s3)
    8000391e:	0009a503          	lw	a0,0(s3)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	898080e7          	jalr	-1896(ra) # 800031ba <bfree>
    ip->addrs[NDIRECT] = 0;
    8000392a:	0809a023          	sw	zero,128(s3)
    8000392e:	bf51                	j	800038c2 <itrunc+0x3e>

0000000080003930 <iput>:
{
    80003930:	1101                	addi	sp,sp,-32
    80003932:	ec06                	sd	ra,24(sp)
    80003934:	e822                	sd	s0,16(sp)
    80003936:	e426                	sd	s1,8(sp)
    80003938:	e04a                	sd	s2,0(sp)
    8000393a:	1000                	addi	s0,sp,32
    8000393c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000393e:	0001c517          	auipc	a0,0x1c
    80003942:	52250513          	addi	a0,a0,1314 # 8001fe60 <icache>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	314080e7          	jalr	788(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394e:	4498                	lw	a4,8(s1)
    80003950:	4785                	li	a5,1
    80003952:	02f70363          	beq	a4,a5,80003978 <iput+0x48>
  ip->ref--;
    80003956:	449c                	lw	a5,8(s1)
    80003958:	37fd                	addiw	a5,a5,-1
    8000395a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000395c:	0001c517          	auipc	a0,0x1c
    80003960:	50450513          	addi	a0,a0,1284 # 8001fe60 <icache>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	3aa080e7          	jalr	938(ra) # 80000d0e <release>
}
    8000396c:	60e2                	ld	ra,24(sp)
    8000396e:	6442                	ld	s0,16(sp)
    80003970:	64a2                	ld	s1,8(sp)
    80003972:	6902                	ld	s2,0(sp)
    80003974:	6105                	addi	sp,sp,32
    80003976:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003978:	40bc                	lw	a5,64(s1)
    8000397a:	dff1                	beqz	a5,80003956 <iput+0x26>
    8000397c:	04a49783          	lh	a5,74(s1)
    80003980:	fbf9                	bnez	a5,80003956 <iput+0x26>
    acquiresleep(&ip->lock);
    80003982:	01048913          	addi	s2,s1,16
    80003986:	854a                	mv	a0,s2
    80003988:	00001097          	auipc	ra,0x1
    8000398c:	aa8080e7          	jalr	-1368(ra) # 80004430 <acquiresleep>
    release(&icache.lock);
    80003990:	0001c517          	auipc	a0,0x1c
    80003994:	4d050513          	addi	a0,a0,1232 # 8001fe60 <icache>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	376080e7          	jalr	886(ra) # 80000d0e <release>
    itrunc(ip);
    800039a0:	8526                	mv	a0,s1
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	ee2080e7          	jalr	-286(ra) # 80003884 <itrunc>
    ip->type = 0;
    800039aa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ae:	8526                	mv	a0,s1
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	cfc080e7          	jalr	-772(ra) # 800036ac <iupdate>
    ip->valid = 0;
    800039b8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039bc:	854a                	mv	a0,s2
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	ac8080e7          	jalr	-1336(ra) # 80004486 <releasesleep>
    acquire(&icache.lock);
    800039c6:	0001c517          	auipc	a0,0x1c
    800039ca:	49a50513          	addi	a0,a0,1178 # 8001fe60 <icache>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	28c080e7          	jalr	652(ra) # 80000c5a <acquire>
    800039d6:	b741                	j	80003956 <iput+0x26>

00000000800039d8 <iunlockput>:
{
    800039d8:	1101                	addi	sp,sp,-32
    800039da:	ec06                	sd	ra,24(sp)
    800039dc:	e822                	sd	s0,16(sp)
    800039de:	e426                	sd	s1,8(sp)
    800039e0:	1000                	addi	s0,sp,32
    800039e2:	84aa                	mv	s1,a0
  iunlock(ip);
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	e54080e7          	jalr	-428(ra) # 80003838 <iunlock>
  iput(ip);
    800039ec:	8526                	mv	a0,s1
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	f42080e7          	jalr	-190(ra) # 80003930 <iput>
}
    800039f6:	60e2                	ld	ra,24(sp)
    800039f8:	6442                	ld	s0,16(sp)
    800039fa:	64a2                	ld	s1,8(sp)
    800039fc:	6105                	addi	sp,sp,32
    800039fe:	8082                	ret

0000000080003a00 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a00:	1141                	addi	sp,sp,-16
    80003a02:	e422                	sd	s0,8(sp)
    80003a04:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a06:	411c                	lw	a5,0(a0)
    80003a08:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a0a:	415c                	lw	a5,4(a0)
    80003a0c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a0e:	04451783          	lh	a5,68(a0)
    80003a12:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a16:	04a51783          	lh	a5,74(a0)
    80003a1a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a1e:	04c56783          	lwu	a5,76(a0)
    80003a22:	e99c                	sd	a5,16(a1)
}
    80003a24:	6422                	ld	s0,8(sp)
    80003a26:	0141                	addi	sp,sp,16
    80003a28:	8082                	ret

0000000080003a2a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a2a:	457c                	lw	a5,76(a0)
    80003a2c:	0ed7e863          	bltu	a5,a3,80003b1c <readi+0xf2>
{
    80003a30:	7159                	addi	sp,sp,-112
    80003a32:	f486                	sd	ra,104(sp)
    80003a34:	f0a2                	sd	s0,96(sp)
    80003a36:	eca6                	sd	s1,88(sp)
    80003a38:	e8ca                	sd	s2,80(sp)
    80003a3a:	e4ce                	sd	s3,72(sp)
    80003a3c:	e0d2                	sd	s4,64(sp)
    80003a3e:	fc56                	sd	s5,56(sp)
    80003a40:	f85a                	sd	s6,48(sp)
    80003a42:	f45e                	sd	s7,40(sp)
    80003a44:	f062                	sd	s8,32(sp)
    80003a46:	ec66                	sd	s9,24(sp)
    80003a48:	e86a                	sd	s10,16(sp)
    80003a4a:	e46e                	sd	s11,8(sp)
    80003a4c:	1880                	addi	s0,sp,112
    80003a4e:	8baa                	mv	s7,a0
    80003a50:	8c2e                	mv	s8,a1
    80003a52:	8ab2                	mv	s5,a2
    80003a54:	84b6                	mv	s1,a3
    80003a56:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a58:	9f35                	addw	a4,a4,a3
    return 0;
    80003a5a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a5c:	08d76f63          	bltu	a4,a3,80003afa <readi+0xd0>
  if(off + n > ip->size)
    80003a60:	00e7f463          	bgeu	a5,a4,80003a68 <readi+0x3e>
    n = ip->size - off;
    80003a64:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a68:	0a0b0863          	beqz	s6,80003b18 <readi+0xee>
    80003a6c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a72:	5cfd                	li	s9,-1
    80003a74:	a82d                	j	80003aae <readi+0x84>
    80003a76:	020a1d93          	slli	s11,s4,0x20
    80003a7a:	020ddd93          	srli	s11,s11,0x20
    80003a7e:	05890613          	addi	a2,s2,88
    80003a82:	86ee                	mv	a3,s11
    80003a84:	963a                	add	a2,a2,a4
    80003a86:	85d6                	mv	a1,s5
    80003a88:	8562                	mv	a0,s8
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	a14080e7          	jalr	-1516(ra) # 8000249e <either_copyout>
    80003a92:	05950d63          	beq	a0,s9,80003aec <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	60c080e7          	jalr	1548(ra) # 800030a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa0:	013a09bb          	addw	s3,s4,s3
    80003aa4:	009a04bb          	addw	s1,s4,s1
    80003aa8:	9aee                	add	s5,s5,s11
    80003aaa:	0569f663          	bgeu	s3,s6,80003af6 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aae:	000ba903          	lw	s2,0(s7)
    80003ab2:	00a4d59b          	srliw	a1,s1,0xa
    80003ab6:	855e                	mv	a0,s7
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	8b0080e7          	jalr	-1872(ra) # 80003368 <bmap>
    80003ac0:	0005059b          	sext.w	a1,a0
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	4ae080e7          	jalr	1198(ra) # 80002f74 <bread>
    80003ace:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad0:	3ff4f713          	andi	a4,s1,1023
    80003ad4:	40ed07bb          	subw	a5,s10,a4
    80003ad8:	413b06bb          	subw	a3,s6,s3
    80003adc:	8a3e                	mv	s4,a5
    80003ade:	2781                	sext.w	a5,a5
    80003ae0:	0006861b          	sext.w	a2,a3
    80003ae4:	f8f679e3          	bgeu	a2,a5,80003a76 <readi+0x4c>
    80003ae8:	8a36                	mv	s4,a3
    80003aea:	b771                	j	80003a76 <readi+0x4c>
      brelse(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	5b6080e7          	jalr	1462(ra) # 800030a4 <brelse>
  }
  return tot;
    80003af6:	0009851b          	sext.w	a0,s3
}
    80003afa:	70a6                	ld	ra,104(sp)
    80003afc:	7406                	ld	s0,96(sp)
    80003afe:	64e6                	ld	s1,88(sp)
    80003b00:	6946                	ld	s2,80(sp)
    80003b02:	69a6                	ld	s3,72(sp)
    80003b04:	6a06                	ld	s4,64(sp)
    80003b06:	7ae2                	ld	s5,56(sp)
    80003b08:	7b42                	ld	s6,48(sp)
    80003b0a:	7ba2                	ld	s7,40(sp)
    80003b0c:	7c02                	ld	s8,32(sp)
    80003b0e:	6ce2                	ld	s9,24(sp)
    80003b10:	6d42                	ld	s10,16(sp)
    80003b12:	6da2                	ld	s11,8(sp)
    80003b14:	6165                	addi	sp,sp,112
    80003b16:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b18:	89da                	mv	s3,s6
    80003b1a:	bff1                	j	80003af6 <readi+0xcc>
    return 0;
    80003b1c:	4501                	li	a0,0
}
    80003b1e:	8082                	ret

0000000080003b20 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b20:	457c                	lw	a5,76(a0)
    80003b22:	10d7e663          	bltu	a5,a3,80003c2e <writei+0x10e>
{
    80003b26:	7159                	addi	sp,sp,-112
    80003b28:	f486                	sd	ra,104(sp)
    80003b2a:	f0a2                	sd	s0,96(sp)
    80003b2c:	eca6                	sd	s1,88(sp)
    80003b2e:	e8ca                	sd	s2,80(sp)
    80003b30:	e4ce                	sd	s3,72(sp)
    80003b32:	e0d2                	sd	s4,64(sp)
    80003b34:	fc56                	sd	s5,56(sp)
    80003b36:	f85a                	sd	s6,48(sp)
    80003b38:	f45e                	sd	s7,40(sp)
    80003b3a:	f062                	sd	s8,32(sp)
    80003b3c:	ec66                	sd	s9,24(sp)
    80003b3e:	e86a                	sd	s10,16(sp)
    80003b40:	e46e                	sd	s11,8(sp)
    80003b42:	1880                	addi	s0,sp,112
    80003b44:	8baa                	mv	s7,a0
    80003b46:	8c2e                	mv	s8,a1
    80003b48:	8ab2                	mv	s5,a2
    80003b4a:	8936                	mv	s2,a3
    80003b4c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b4e:	00e687bb          	addw	a5,a3,a4
    80003b52:	0ed7e063          	bltu	a5,a3,80003c32 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b56:	00043737          	lui	a4,0x43
    80003b5a:	0cf76e63          	bltu	a4,a5,80003c36 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5e:	0a0b0763          	beqz	s6,80003c0c <writei+0xec>
    80003b62:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b64:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b68:	5cfd                	li	s9,-1
    80003b6a:	a091                	j	80003bae <writei+0x8e>
    80003b6c:	02099d93          	slli	s11,s3,0x20
    80003b70:	020ddd93          	srli	s11,s11,0x20
    80003b74:	05848513          	addi	a0,s1,88
    80003b78:	86ee                	mv	a3,s11
    80003b7a:	8656                	mv	a2,s5
    80003b7c:	85e2                	mv	a1,s8
    80003b7e:	953a                	add	a0,a0,a4
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	974080e7          	jalr	-1676(ra) # 800024f4 <either_copyin>
    80003b88:	07950263          	beq	a0,s9,80003bec <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	77a080e7          	jalr	1914(ra) # 80004308 <log_write>
    brelse(bp);
    80003b96:	8526                	mv	a0,s1
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	50c080e7          	jalr	1292(ra) # 800030a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	01498a3b          	addw	s4,s3,s4
    80003ba4:	0129893b          	addw	s2,s3,s2
    80003ba8:	9aee                	add	s5,s5,s11
    80003baa:	056a7663          	bgeu	s4,s6,80003bf6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bae:	000ba483          	lw	s1,0(s7)
    80003bb2:	00a9559b          	srliw	a1,s2,0xa
    80003bb6:	855e                	mv	a0,s7
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	7b0080e7          	jalr	1968(ra) # 80003368 <bmap>
    80003bc0:	0005059b          	sext.w	a1,a0
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	3ae080e7          	jalr	942(ra) # 80002f74 <bread>
    80003bce:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd0:	3ff97713          	andi	a4,s2,1023
    80003bd4:	40ed07bb          	subw	a5,s10,a4
    80003bd8:	414b06bb          	subw	a3,s6,s4
    80003bdc:	89be                	mv	s3,a5
    80003bde:	2781                	sext.w	a5,a5
    80003be0:	0006861b          	sext.w	a2,a3
    80003be4:	f8f674e3          	bgeu	a2,a5,80003b6c <writei+0x4c>
    80003be8:	89b6                	mv	s3,a3
    80003bea:	b749                	j	80003b6c <writei+0x4c>
      brelse(bp);
    80003bec:	8526                	mv	a0,s1
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	4b6080e7          	jalr	1206(ra) # 800030a4 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bf6:	04cba783          	lw	a5,76(s7)
    80003bfa:	0127f463          	bgeu	a5,s2,80003c02 <writei+0xe2>
      ip->size = off;
    80003bfe:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c02:	855e                	mv	a0,s7
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	aa8080e7          	jalr	-1368(ra) # 800036ac <iupdate>
  }

  return n;
    80003c0c:	000b051b          	sext.w	a0,s6
}
    80003c10:	70a6                	ld	ra,104(sp)
    80003c12:	7406                	ld	s0,96(sp)
    80003c14:	64e6                	ld	s1,88(sp)
    80003c16:	6946                	ld	s2,80(sp)
    80003c18:	69a6                	ld	s3,72(sp)
    80003c1a:	6a06                	ld	s4,64(sp)
    80003c1c:	7ae2                	ld	s5,56(sp)
    80003c1e:	7b42                	ld	s6,48(sp)
    80003c20:	7ba2                	ld	s7,40(sp)
    80003c22:	7c02                	ld	s8,32(sp)
    80003c24:	6ce2                	ld	s9,24(sp)
    80003c26:	6d42                	ld	s10,16(sp)
    80003c28:	6da2                	ld	s11,8(sp)
    80003c2a:	6165                	addi	sp,sp,112
    80003c2c:	8082                	ret
    return -1;
    80003c2e:	557d                	li	a0,-1
}
    80003c30:	8082                	ret
    return -1;
    80003c32:	557d                	li	a0,-1
    80003c34:	bff1                	j	80003c10 <writei+0xf0>
    return -1;
    80003c36:	557d                	li	a0,-1
    80003c38:	bfe1                	j	80003c10 <writei+0xf0>

0000000080003c3a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c3a:	1141                	addi	sp,sp,-16
    80003c3c:	e406                	sd	ra,8(sp)
    80003c3e:	e022                	sd	s0,0(sp)
    80003c40:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c42:	4639                	li	a2,14
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	1ee080e7          	jalr	494(ra) # 80000e32 <strncmp>
}
    80003c4c:	60a2                	ld	ra,8(sp)
    80003c4e:	6402                	ld	s0,0(sp)
    80003c50:	0141                	addi	sp,sp,16
    80003c52:	8082                	ret

0000000080003c54 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c54:	7139                	addi	sp,sp,-64
    80003c56:	fc06                	sd	ra,56(sp)
    80003c58:	f822                	sd	s0,48(sp)
    80003c5a:	f426                	sd	s1,40(sp)
    80003c5c:	f04a                	sd	s2,32(sp)
    80003c5e:	ec4e                	sd	s3,24(sp)
    80003c60:	e852                	sd	s4,16(sp)
    80003c62:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c64:	04451703          	lh	a4,68(a0)
    80003c68:	4785                	li	a5,1
    80003c6a:	00f71a63          	bne	a4,a5,80003c7e <dirlookup+0x2a>
    80003c6e:	892a                	mv	s2,a0
    80003c70:	89ae                	mv	s3,a1
    80003c72:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c74:	457c                	lw	a5,76(a0)
    80003c76:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c78:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7a:	e79d                	bnez	a5,80003ca8 <dirlookup+0x54>
    80003c7c:	a8a5                	j	80003cf4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c7e:	00005517          	auipc	a0,0x5
    80003c82:	ae250513          	addi	a0,a0,-1310 # 80008760 <syscall_names+0x1b0>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	8c2080e7          	jalr	-1854(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	aea50513          	addi	a0,a0,-1302 # 80008778 <syscall_names+0x1c8>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	8b2080e7          	jalr	-1870(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	24c1                	addiw	s1,s1,16
    80003ca0:	04c92783          	lw	a5,76(s2)
    80003ca4:	04f4f763          	bgeu	s1,a5,80003cf2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca8:	4741                	li	a4,16
    80003caa:	86a6                	mv	a3,s1
    80003cac:	fc040613          	addi	a2,s0,-64
    80003cb0:	4581                	li	a1,0
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	d76080e7          	jalr	-650(ra) # 80003a2a <readi>
    80003cbc:	47c1                	li	a5,16
    80003cbe:	fcf518e3          	bne	a0,a5,80003c8e <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc2:	fc045783          	lhu	a5,-64(s0)
    80003cc6:	dfe1                	beqz	a5,80003c9e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc8:	fc240593          	addi	a1,s0,-62
    80003ccc:	854e                	mv	a0,s3
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	f6c080e7          	jalr	-148(ra) # 80003c3a <namecmp>
    80003cd6:	f561                	bnez	a0,80003c9e <dirlookup+0x4a>
      if(poff)
    80003cd8:	000a0463          	beqz	s4,80003ce0 <dirlookup+0x8c>
        *poff = off;
    80003cdc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce0:	fc045583          	lhu	a1,-64(s0)
    80003ce4:	00092503          	lw	a0,0(s2)
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	75a080e7          	jalr	1882(ra) # 80003442 <iget>
    80003cf0:	a011                	j	80003cf4 <dirlookup+0xa0>
  return 0;
    80003cf2:	4501                	li	a0,0
}
    80003cf4:	70e2                	ld	ra,56(sp)
    80003cf6:	7442                	ld	s0,48(sp)
    80003cf8:	74a2                	ld	s1,40(sp)
    80003cfa:	7902                	ld	s2,32(sp)
    80003cfc:	69e2                	ld	s3,24(sp)
    80003cfe:	6a42                	ld	s4,16(sp)
    80003d00:	6121                	addi	sp,sp,64
    80003d02:	8082                	ret

0000000080003d04 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d04:	711d                	addi	sp,sp,-96
    80003d06:	ec86                	sd	ra,88(sp)
    80003d08:	e8a2                	sd	s0,80(sp)
    80003d0a:	e4a6                	sd	s1,72(sp)
    80003d0c:	e0ca                	sd	s2,64(sp)
    80003d0e:	fc4e                	sd	s3,56(sp)
    80003d10:	f852                	sd	s4,48(sp)
    80003d12:	f456                	sd	s5,40(sp)
    80003d14:	f05a                	sd	s6,32(sp)
    80003d16:	ec5e                	sd	s7,24(sp)
    80003d18:	e862                	sd	s8,16(sp)
    80003d1a:	e466                	sd	s9,8(sp)
    80003d1c:	1080                	addi	s0,sp,96
    80003d1e:	84aa                	mv	s1,a0
    80003d20:	8b2e                	mv	s6,a1
    80003d22:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d24:	00054703          	lbu	a4,0(a0)
    80003d28:	02f00793          	li	a5,47
    80003d2c:	02f70363          	beq	a4,a5,80003d52 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d30:	ffffe097          	auipc	ra,0xffffe
    80003d34:	cf8080e7          	jalr	-776(ra) # 80001a28 <myproc>
    80003d38:	15053503          	ld	a0,336(a0)
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	9fc080e7          	jalr	-1540(ra) # 80003738 <idup>
    80003d44:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d46:	02f00913          	li	s2,47
  len = path - s;
    80003d4a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d4c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d4e:	4c05                	li	s8,1
    80003d50:	a865                	j	80003e08 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d52:	4585                	li	a1,1
    80003d54:	4505                	li	a0,1
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	6ec080e7          	jalr	1772(ra) # 80003442 <iget>
    80003d5e:	89aa                	mv	s3,a0
    80003d60:	b7dd                	j	80003d46 <namex+0x42>
      iunlockput(ip);
    80003d62:	854e                	mv	a0,s3
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	c74080e7          	jalr	-908(ra) # 800039d8 <iunlockput>
      return 0;
    80003d6c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d6e:	854e                	mv	a0,s3
    80003d70:	60e6                	ld	ra,88(sp)
    80003d72:	6446                	ld	s0,80(sp)
    80003d74:	64a6                	ld	s1,72(sp)
    80003d76:	6906                	ld	s2,64(sp)
    80003d78:	79e2                	ld	s3,56(sp)
    80003d7a:	7a42                	ld	s4,48(sp)
    80003d7c:	7aa2                	ld	s5,40(sp)
    80003d7e:	7b02                	ld	s6,32(sp)
    80003d80:	6be2                	ld	s7,24(sp)
    80003d82:	6c42                	ld	s8,16(sp)
    80003d84:	6ca2                	ld	s9,8(sp)
    80003d86:	6125                	addi	sp,sp,96
    80003d88:	8082                	ret
      iunlock(ip);
    80003d8a:	854e                	mv	a0,s3
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	aac080e7          	jalr	-1364(ra) # 80003838 <iunlock>
      return ip;
    80003d94:	bfe9                	j	80003d6e <namex+0x6a>
      iunlockput(ip);
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	c40080e7          	jalr	-960(ra) # 800039d8 <iunlockput>
      return 0;
    80003da0:	89d2                	mv	s3,s4
    80003da2:	b7f1                	j	80003d6e <namex+0x6a>
  len = path - s;
    80003da4:	40b48633          	sub	a2,s1,a1
    80003da8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dac:	094cd463          	bge	s9,s4,80003e34 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003db0:	4639                	li	a2,14
    80003db2:	8556                	mv	a0,s5
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	002080e7          	jalr	2(ra) # 80000db6 <memmove>
  while(*path == '/')
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	01279763          	bne	a5,s2,80003dce <namex+0xca>
    path++;
    80003dc4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc6:	0004c783          	lbu	a5,0(s1)
    80003dca:	ff278de3          	beq	a5,s2,80003dc4 <namex+0xc0>
    ilock(ip);
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	9a6080e7          	jalr	-1626(ra) # 80003776 <ilock>
    if(ip->type != T_DIR){
    80003dd8:	04499783          	lh	a5,68(s3)
    80003ddc:	f98793e3          	bne	a5,s8,80003d62 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003de0:	000b0563          	beqz	s6,80003dea <namex+0xe6>
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	d3cd                	beqz	a5,80003d8a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dea:	865e                	mv	a2,s7
    80003dec:	85d6                	mv	a1,s5
    80003dee:	854e                	mv	a0,s3
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	e64080e7          	jalr	-412(ra) # 80003c54 <dirlookup>
    80003df8:	8a2a                	mv	s4,a0
    80003dfa:	dd51                	beqz	a0,80003d96 <namex+0x92>
    iunlockput(ip);
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	bda080e7          	jalr	-1062(ra) # 800039d8 <iunlockput>
    ip = next;
    80003e06:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	05279763          	bne	a5,s2,80003e5a <namex+0x156>
    path++;
    80003e10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	ff278de3          	beq	a5,s2,80003e10 <namex+0x10c>
  if(*path == 0)
    80003e1a:	c79d                	beqz	a5,80003e48 <namex+0x144>
    path++;
    80003e1c:	85a6                	mv	a1,s1
  len = path - s;
    80003e1e:	8a5e                	mv	s4,s7
    80003e20:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e22:	01278963          	beq	a5,s2,80003e34 <namex+0x130>
    80003e26:	dfbd                	beqz	a5,80003da4 <namex+0xa0>
    path++;
    80003e28:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	ff279ce3          	bne	a5,s2,80003e26 <namex+0x122>
    80003e32:	bf8d                	j	80003da4 <namex+0xa0>
    memmove(name, s, len);
    80003e34:	2601                	sext.w	a2,a2
    80003e36:	8556                	mv	a0,s5
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	f7e080e7          	jalr	-130(ra) # 80000db6 <memmove>
    name[len] = 0;
    80003e40:	9a56                	add	s4,s4,s5
    80003e42:	000a0023          	sb	zero,0(s4)
    80003e46:	bf9d                	j	80003dbc <namex+0xb8>
  if(nameiparent){
    80003e48:	f20b03e3          	beqz	s6,80003d6e <namex+0x6a>
    iput(ip);
    80003e4c:	854e                	mv	a0,s3
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	ae2080e7          	jalr	-1310(ra) # 80003930 <iput>
    return 0;
    80003e56:	4981                	li	s3,0
    80003e58:	bf19                	j	80003d6e <namex+0x6a>
  if(*path == 0)
    80003e5a:	d7fd                	beqz	a5,80003e48 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	85a6                	mv	a1,s1
    80003e62:	b7d1                	j	80003e26 <namex+0x122>

0000000080003e64 <dirlink>:
{
    80003e64:	7139                	addi	sp,sp,-64
    80003e66:	fc06                	sd	ra,56(sp)
    80003e68:	f822                	sd	s0,48(sp)
    80003e6a:	f426                	sd	s1,40(sp)
    80003e6c:	f04a                	sd	s2,32(sp)
    80003e6e:	ec4e                	sd	s3,24(sp)
    80003e70:	e852                	sd	s4,16(sp)
    80003e72:	0080                	addi	s0,sp,64
    80003e74:	892a                	mv	s2,a0
    80003e76:	8a2e                	mv	s4,a1
    80003e78:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e7a:	4601                	li	a2,0
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	dd8080e7          	jalr	-552(ra) # 80003c54 <dirlookup>
    80003e84:	e93d                	bnez	a0,80003efa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e86:	04c92483          	lw	s1,76(s2)
    80003e8a:	c49d                	beqz	s1,80003eb8 <dirlink+0x54>
    80003e8c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8e:	4741                	li	a4,16
    80003e90:	86a6                	mv	a3,s1
    80003e92:	fc040613          	addi	a2,s0,-64
    80003e96:	4581                	li	a1,0
    80003e98:	854a                	mv	a0,s2
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	b90080e7          	jalr	-1136(ra) # 80003a2a <readi>
    80003ea2:	47c1                	li	a5,16
    80003ea4:	06f51163          	bne	a0,a5,80003f06 <dirlink+0xa2>
    if(de.inum == 0)
    80003ea8:	fc045783          	lhu	a5,-64(s0)
    80003eac:	c791                	beqz	a5,80003eb8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eae:	24c1                	addiw	s1,s1,16
    80003eb0:	04c92783          	lw	a5,76(s2)
    80003eb4:	fcf4ede3          	bltu	s1,a5,80003e8e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eb8:	4639                	li	a2,14
    80003eba:	85d2                	mv	a1,s4
    80003ebc:	fc240513          	addi	a0,s0,-62
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	fae080e7          	jalr	-82(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80003ec8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ecc:	4741                	li	a4,16
    80003ece:	86a6                	mv	a3,s1
    80003ed0:	fc040613          	addi	a2,s0,-64
    80003ed4:	4581                	li	a1,0
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	c48080e7          	jalr	-952(ra) # 80003b20 <writei>
    80003ee0:	872a                	mv	a4,a0
    80003ee2:	47c1                	li	a5,16
  return 0;
    80003ee4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	02f71863          	bne	a4,a5,80003f16 <dirlink+0xb2>
}
    80003eea:	70e2                	ld	ra,56(sp)
    80003eec:	7442                	ld	s0,48(sp)
    80003eee:	74a2                	ld	s1,40(sp)
    80003ef0:	7902                	ld	s2,32(sp)
    80003ef2:	69e2                	ld	s3,24(sp)
    80003ef4:	6a42                	ld	s4,16(sp)
    80003ef6:	6121                	addi	sp,sp,64
    80003ef8:	8082                	ret
    iput(ip);
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	a36080e7          	jalr	-1482(ra) # 80003930 <iput>
    return -1;
    80003f02:	557d                	li	a0,-1
    80003f04:	b7dd                	j	80003eea <dirlink+0x86>
      panic("dirlink read");
    80003f06:	00005517          	auipc	a0,0x5
    80003f0a:	88250513          	addi	a0,a0,-1918 # 80008788 <syscall_names+0x1d8>
    80003f0e:	ffffc097          	auipc	ra,0xffffc
    80003f12:	63a080e7          	jalr	1594(ra) # 80000548 <panic>
    panic("dirlink");
    80003f16:	00005517          	auipc	a0,0x5
    80003f1a:	98a50513          	addi	a0,a0,-1654 # 800088a0 <syscall_names+0x2f0>
    80003f1e:	ffffc097          	auipc	ra,0xffffc
    80003f22:	62a080e7          	jalr	1578(ra) # 80000548 <panic>

0000000080003f26 <namei>:

struct inode*
namei(char *path)
{
    80003f26:	1101                	addi	sp,sp,-32
    80003f28:	ec06                	sd	ra,24(sp)
    80003f2a:	e822                	sd	s0,16(sp)
    80003f2c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f2e:	fe040613          	addi	a2,s0,-32
    80003f32:	4581                	li	a1,0
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	dd0080e7          	jalr	-560(ra) # 80003d04 <namex>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	6105                	addi	sp,sp,32
    80003f42:	8082                	ret

0000000080003f44 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f44:	1141                	addi	sp,sp,-16
    80003f46:	e406                	sd	ra,8(sp)
    80003f48:	e022                	sd	s0,0(sp)
    80003f4a:	0800                	addi	s0,sp,16
    80003f4c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f4e:	4585                	li	a1,1
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	db4080e7          	jalr	-588(ra) # 80003d04 <namex>
}
    80003f58:	60a2                	ld	ra,8(sp)
    80003f5a:	6402                	ld	s0,0(sp)
    80003f5c:	0141                	addi	sp,sp,16
    80003f5e:	8082                	ret

0000000080003f60 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f60:	1101                	addi	sp,sp,-32
    80003f62:	ec06                	sd	ra,24(sp)
    80003f64:	e822                	sd	s0,16(sp)
    80003f66:	e426                	sd	s1,8(sp)
    80003f68:	e04a                	sd	s2,0(sp)
    80003f6a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f6c:	0001e917          	auipc	s2,0x1e
    80003f70:	99c90913          	addi	s2,s2,-1636 # 80021908 <log>
    80003f74:	01892583          	lw	a1,24(s2)
    80003f78:	02892503          	lw	a0,40(s2)
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	ff8080e7          	jalr	-8(ra) # 80002f74 <bread>
    80003f84:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f86:	02c92683          	lw	a3,44(s2)
    80003f8a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f8c:	02d05763          	blez	a3,80003fba <write_head+0x5a>
    80003f90:	0001e797          	auipc	a5,0x1e
    80003f94:	9a878793          	addi	a5,a5,-1624 # 80021938 <log+0x30>
    80003f98:	05c50713          	addi	a4,a0,92
    80003f9c:	36fd                	addiw	a3,a3,-1
    80003f9e:	1682                	slli	a3,a3,0x20
    80003fa0:	9281                	srli	a3,a3,0x20
    80003fa2:	068a                	slli	a3,a3,0x2
    80003fa4:	0001e617          	auipc	a2,0x1e
    80003fa8:	99860613          	addi	a2,a2,-1640 # 8002193c <log+0x34>
    80003fac:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fae:	4390                	lw	a2,0(a5)
    80003fb0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fb2:	0791                	addi	a5,a5,4
    80003fb4:	0711                	addi	a4,a4,4
    80003fb6:	fed79ce3          	bne	a5,a3,80003fae <write_head+0x4e>
  }
  bwrite(buf);
    80003fba:	8526                	mv	a0,s1
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	0aa080e7          	jalr	170(ra) # 80003066 <bwrite>
  brelse(buf);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	0de080e7          	jalr	222(ra) # 800030a4 <brelse>
}
    80003fce:	60e2                	ld	ra,24(sp)
    80003fd0:	6442                	ld	s0,16(sp)
    80003fd2:	64a2                	ld	s1,8(sp)
    80003fd4:	6902                	ld	s2,0(sp)
    80003fd6:	6105                	addi	sp,sp,32
    80003fd8:	8082                	ret

0000000080003fda <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fda:	0001e797          	auipc	a5,0x1e
    80003fde:	95a7a783          	lw	a5,-1702(a5) # 80021934 <log+0x2c>
    80003fe2:	0af05663          	blez	a5,8000408e <install_trans+0xb4>
{
    80003fe6:	7139                	addi	sp,sp,-64
    80003fe8:	fc06                	sd	ra,56(sp)
    80003fea:	f822                	sd	s0,48(sp)
    80003fec:	f426                	sd	s1,40(sp)
    80003fee:	f04a                	sd	s2,32(sp)
    80003ff0:	ec4e                	sd	s3,24(sp)
    80003ff2:	e852                	sd	s4,16(sp)
    80003ff4:	e456                	sd	s5,8(sp)
    80003ff6:	0080                	addi	s0,sp,64
    80003ff8:	0001ea97          	auipc	s5,0x1e
    80003ffc:	940a8a93          	addi	s5,s5,-1728 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004000:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004002:	0001e997          	auipc	s3,0x1e
    80004006:	90698993          	addi	s3,s3,-1786 # 80021908 <log>
    8000400a:	0189a583          	lw	a1,24(s3)
    8000400e:	014585bb          	addw	a1,a1,s4
    80004012:	2585                	addiw	a1,a1,1
    80004014:	0289a503          	lw	a0,40(s3)
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	f5c080e7          	jalr	-164(ra) # 80002f74 <bread>
    80004020:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004022:	000aa583          	lw	a1,0(s5)
    80004026:	0289a503          	lw	a0,40(s3)
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	f4a080e7          	jalr	-182(ra) # 80002f74 <bread>
    80004032:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004034:	40000613          	li	a2,1024
    80004038:	05890593          	addi	a1,s2,88
    8000403c:	05850513          	addi	a0,a0,88
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	d76080e7          	jalr	-650(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004048:	8526                	mv	a0,s1
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	01c080e7          	jalr	28(ra) # 80003066 <bwrite>
    bunpin(dbuf);
    80004052:	8526                	mv	a0,s1
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	12a080e7          	jalr	298(ra) # 8000317e <bunpin>
    brelse(lbuf);
    8000405c:	854a                	mv	a0,s2
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	046080e7          	jalr	70(ra) # 800030a4 <brelse>
    brelse(dbuf);
    80004066:	8526                	mv	a0,s1
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	03c080e7          	jalr	60(ra) # 800030a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004070:	2a05                	addiw	s4,s4,1
    80004072:	0a91                	addi	s5,s5,4
    80004074:	02c9a783          	lw	a5,44(s3)
    80004078:	f8fa49e3          	blt	s4,a5,8000400a <install_trans+0x30>
}
    8000407c:	70e2                	ld	ra,56(sp)
    8000407e:	7442                	ld	s0,48(sp)
    80004080:	74a2                	ld	s1,40(sp)
    80004082:	7902                	ld	s2,32(sp)
    80004084:	69e2                	ld	s3,24(sp)
    80004086:	6a42                	ld	s4,16(sp)
    80004088:	6aa2                	ld	s5,8(sp)
    8000408a:	6121                	addi	sp,sp,64
    8000408c:	8082                	ret
    8000408e:	8082                	ret

0000000080004090 <initlog>:
{
    80004090:	7179                	addi	sp,sp,-48
    80004092:	f406                	sd	ra,40(sp)
    80004094:	f022                	sd	s0,32(sp)
    80004096:	ec26                	sd	s1,24(sp)
    80004098:	e84a                	sd	s2,16(sp)
    8000409a:	e44e                	sd	s3,8(sp)
    8000409c:	1800                	addi	s0,sp,48
    8000409e:	892a                	mv	s2,a0
    800040a0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040a2:	0001e497          	auipc	s1,0x1e
    800040a6:	86648493          	addi	s1,s1,-1946 # 80021908 <log>
    800040aa:	00004597          	auipc	a1,0x4
    800040ae:	6ee58593          	addi	a1,a1,1774 # 80008798 <syscall_names+0x1e8>
    800040b2:	8526                	mv	a0,s1
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	b16080e7          	jalr	-1258(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    800040bc:	0149a583          	lw	a1,20(s3)
    800040c0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040c2:	0109a783          	lw	a5,16(s3)
    800040c6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040c8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040cc:	854a                	mv	a0,s2
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	ea6080e7          	jalr	-346(ra) # 80002f74 <bread>
  log.lh.n = lh->n;
    800040d6:	4d3c                	lw	a5,88(a0)
    800040d8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040da:	02f05563          	blez	a5,80004104 <initlog+0x74>
    800040de:	05c50713          	addi	a4,a0,92
    800040e2:	0001e697          	auipc	a3,0x1e
    800040e6:	85668693          	addi	a3,a3,-1962 # 80021938 <log+0x30>
    800040ea:	37fd                	addiw	a5,a5,-1
    800040ec:	1782                	slli	a5,a5,0x20
    800040ee:	9381                	srli	a5,a5,0x20
    800040f0:	078a                	slli	a5,a5,0x2
    800040f2:	06050613          	addi	a2,a0,96
    800040f6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040f8:	4310                	lw	a2,0(a4)
    800040fa:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040fc:	0711                	addi	a4,a4,4
    800040fe:	0691                	addi	a3,a3,4
    80004100:	fef71ce3          	bne	a4,a5,800040f8 <initlog+0x68>
  brelse(buf);
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	fa0080e7          	jalr	-96(ra) # 800030a4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	ece080e7          	jalr	-306(ra) # 80003fda <install_trans>
  log.lh.n = 0;
    80004114:	0001e797          	auipc	a5,0x1e
    80004118:	8207a023          	sw	zero,-2016(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	e44080e7          	jalr	-444(ra) # 80003f60 <write_head>
}
    80004124:	70a2                	ld	ra,40(sp)
    80004126:	7402                	ld	s0,32(sp)
    80004128:	64e2                	ld	s1,24(sp)
    8000412a:	6942                	ld	s2,16(sp)
    8000412c:	69a2                	ld	s3,8(sp)
    8000412e:	6145                	addi	sp,sp,48
    80004130:	8082                	ret

0000000080004132 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004132:	1101                	addi	sp,sp,-32
    80004134:	ec06                	sd	ra,24(sp)
    80004136:	e822                	sd	s0,16(sp)
    80004138:	e426                	sd	s1,8(sp)
    8000413a:	e04a                	sd	s2,0(sp)
    8000413c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000413e:	0001d517          	auipc	a0,0x1d
    80004142:	7ca50513          	addi	a0,a0,1994 # 80021908 <log>
    80004146:	ffffd097          	auipc	ra,0xffffd
    8000414a:	b14080e7          	jalr	-1260(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    8000414e:	0001d497          	auipc	s1,0x1d
    80004152:	7ba48493          	addi	s1,s1,1978 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004156:	4979                	li	s2,30
    80004158:	a039                	j	80004166 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000415a:	85a6                	mv	a1,s1
    8000415c:	8526                	mv	a0,s1
    8000415e:	ffffe097          	auipc	ra,0xffffe
    80004162:	0de080e7          	jalr	222(ra) # 8000223c <sleep>
    if(log.committing){
    80004166:	50dc                	lw	a5,36(s1)
    80004168:	fbed                	bnez	a5,8000415a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000416a:	509c                	lw	a5,32(s1)
    8000416c:	0017871b          	addiw	a4,a5,1
    80004170:	0007069b          	sext.w	a3,a4
    80004174:	0027179b          	slliw	a5,a4,0x2
    80004178:	9fb9                	addw	a5,a5,a4
    8000417a:	0017979b          	slliw	a5,a5,0x1
    8000417e:	54d8                	lw	a4,44(s1)
    80004180:	9fb9                	addw	a5,a5,a4
    80004182:	00f95963          	bge	s2,a5,80004194 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004186:	85a6                	mv	a1,s1
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffe097          	auipc	ra,0xffffe
    8000418e:	0b2080e7          	jalr	178(ra) # 8000223c <sleep>
    80004192:	bfd1                	j	80004166 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004194:	0001d517          	auipc	a0,0x1d
    80004198:	77450513          	addi	a0,a0,1908 # 80021908 <log>
    8000419c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	b70080e7          	jalr	-1168(ra) # 80000d0e <release>
      break;
    }
  }
}
    800041a6:	60e2                	ld	ra,24(sp)
    800041a8:	6442                	ld	s0,16(sp)
    800041aa:	64a2                	ld	s1,8(sp)
    800041ac:	6902                	ld	s2,0(sp)
    800041ae:	6105                	addi	sp,sp,32
    800041b0:	8082                	ret

00000000800041b2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041b2:	7139                	addi	sp,sp,-64
    800041b4:	fc06                	sd	ra,56(sp)
    800041b6:	f822                	sd	s0,48(sp)
    800041b8:	f426                	sd	s1,40(sp)
    800041ba:	f04a                	sd	s2,32(sp)
    800041bc:	ec4e                	sd	s3,24(sp)
    800041be:	e852                	sd	s4,16(sp)
    800041c0:	e456                	sd	s5,8(sp)
    800041c2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041c4:	0001d497          	auipc	s1,0x1d
    800041c8:	74448493          	addi	s1,s1,1860 # 80021908 <log>
    800041cc:	8526                	mv	a0,s1
    800041ce:	ffffd097          	auipc	ra,0xffffd
    800041d2:	a8c080e7          	jalr	-1396(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    800041d6:	509c                	lw	a5,32(s1)
    800041d8:	37fd                	addiw	a5,a5,-1
    800041da:	0007891b          	sext.w	s2,a5
    800041de:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041e0:	50dc                	lw	a5,36(s1)
    800041e2:	efb9                	bnez	a5,80004240 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041e4:	06091663          	bnez	s2,80004250 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041e8:	0001d497          	auipc	s1,0x1d
    800041ec:	72048493          	addi	s1,s1,1824 # 80021908 <log>
    800041f0:	4785                	li	a5,1
    800041f2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	b18080e7          	jalr	-1256(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041fe:	54dc                	lw	a5,44(s1)
    80004200:	06f04763          	bgtz	a5,8000426e <end_op+0xbc>
    acquire(&log.lock);
    80004204:	0001d497          	auipc	s1,0x1d
    80004208:	70448493          	addi	s1,s1,1796 # 80021908 <log>
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	a4c080e7          	jalr	-1460(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004216:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000421a:	8526                	mv	a0,s1
    8000421c:	ffffe097          	auipc	ra,0xffffe
    80004220:	1a6080e7          	jalr	422(ra) # 800023c2 <wakeup>
    release(&log.lock);
    80004224:	8526                	mv	a0,s1
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	ae8080e7          	jalr	-1304(ra) # 80000d0e <release>
}
    8000422e:	70e2                	ld	ra,56(sp)
    80004230:	7442                	ld	s0,48(sp)
    80004232:	74a2                	ld	s1,40(sp)
    80004234:	7902                	ld	s2,32(sp)
    80004236:	69e2                	ld	s3,24(sp)
    80004238:	6a42                	ld	s4,16(sp)
    8000423a:	6aa2                	ld	s5,8(sp)
    8000423c:	6121                	addi	sp,sp,64
    8000423e:	8082                	ret
    panic("log.committing");
    80004240:	00004517          	auipc	a0,0x4
    80004244:	56050513          	addi	a0,a0,1376 # 800087a0 <syscall_names+0x1f0>
    80004248:	ffffc097          	auipc	ra,0xffffc
    8000424c:	300080e7          	jalr	768(ra) # 80000548 <panic>
    wakeup(&log);
    80004250:	0001d497          	auipc	s1,0x1d
    80004254:	6b848493          	addi	s1,s1,1720 # 80021908 <log>
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffe097          	auipc	ra,0xffffe
    8000425e:	168080e7          	jalr	360(ra) # 800023c2 <wakeup>
  release(&log.lock);
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	aaa080e7          	jalr	-1366(ra) # 80000d0e <release>
  if(do_commit){
    8000426c:	b7c9                	j	8000422e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426e:	0001da97          	auipc	s5,0x1d
    80004272:	6caa8a93          	addi	s5,s5,1738 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004276:	0001da17          	auipc	s4,0x1d
    8000427a:	692a0a13          	addi	s4,s4,1682 # 80021908 <log>
    8000427e:	018a2583          	lw	a1,24(s4)
    80004282:	012585bb          	addw	a1,a1,s2
    80004286:	2585                	addiw	a1,a1,1
    80004288:	028a2503          	lw	a0,40(s4)
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	ce8080e7          	jalr	-792(ra) # 80002f74 <bread>
    80004294:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004296:	000aa583          	lw	a1,0(s5)
    8000429a:	028a2503          	lw	a0,40(s4)
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	cd6080e7          	jalr	-810(ra) # 80002f74 <bread>
    800042a6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042a8:	40000613          	li	a2,1024
    800042ac:	05850593          	addi	a1,a0,88
    800042b0:	05848513          	addi	a0,s1,88
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	b02080e7          	jalr	-1278(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    800042bc:	8526                	mv	a0,s1
    800042be:	fffff097          	auipc	ra,0xfffff
    800042c2:	da8080e7          	jalr	-600(ra) # 80003066 <bwrite>
    brelse(from);
    800042c6:	854e                	mv	a0,s3
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	ddc080e7          	jalr	-548(ra) # 800030a4 <brelse>
    brelse(to);
    800042d0:	8526                	mv	a0,s1
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	dd2080e7          	jalr	-558(ra) # 800030a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042da:	2905                	addiw	s2,s2,1
    800042dc:	0a91                	addi	s5,s5,4
    800042de:	02ca2783          	lw	a5,44(s4)
    800042e2:	f8f94ee3          	blt	s2,a5,8000427e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	c7a080e7          	jalr	-902(ra) # 80003f60 <write_head>
    install_trans(); // Now install writes to home locations
    800042ee:	00000097          	auipc	ra,0x0
    800042f2:	cec080e7          	jalr	-788(ra) # 80003fda <install_trans>
    log.lh.n = 0;
    800042f6:	0001d797          	auipc	a5,0x1d
    800042fa:	6207af23          	sw	zero,1598(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	c62080e7          	jalr	-926(ra) # 80003f60 <write_head>
    80004306:	bdfd                	j	80004204 <end_op+0x52>

0000000080004308 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004308:	1101                	addi	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004314:	0001d717          	auipc	a4,0x1d
    80004318:	62072703          	lw	a4,1568(a4) # 80021934 <log+0x2c>
    8000431c:	47f5                	li	a5,29
    8000431e:	08e7c063          	blt	a5,a4,8000439e <log_write+0x96>
    80004322:	84aa                	mv	s1,a0
    80004324:	0001d797          	auipc	a5,0x1d
    80004328:	6007a783          	lw	a5,1536(a5) # 80021924 <log+0x1c>
    8000432c:	37fd                	addiw	a5,a5,-1
    8000432e:	06f75863          	bge	a4,a5,8000439e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004332:	0001d797          	auipc	a5,0x1d
    80004336:	5f67a783          	lw	a5,1526(a5) # 80021928 <log+0x20>
    8000433a:	06f05a63          	blez	a5,800043ae <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000433e:	0001d917          	auipc	s2,0x1d
    80004342:	5ca90913          	addi	s2,s2,1482 # 80021908 <log>
    80004346:	854a                	mv	a0,s2
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	912080e7          	jalr	-1774(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004350:	02c92603          	lw	a2,44(s2)
    80004354:	06c05563          	blez	a2,800043be <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004358:	44cc                	lw	a1,12(s1)
    8000435a:	0001d717          	auipc	a4,0x1d
    8000435e:	5de70713          	addi	a4,a4,1502 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004362:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004364:	4314                	lw	a3,0(a4)
    80004366:	04b68d63          	beq	a3,a1,800043c0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000436a:	2785                	addiw	a5,a5,1
    8000436c:	0711                	addi	a4,a4,4
    8000436e:	fec79be3          	bne	a5,a2,80004364 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004372:	0621                	addi	a2,a2,8
    80004374:	060a                	slli	a2,a2,0x2
    80004376:	0001d797          	auipc	a5,0x1d
    8000437a:	59278793          	addi	a5,a5,1426 # 80021908 <log>
    8000437e:	963e                	add	a2,a2,a5
    80004380:	44dc                	lw	a5,12(s1)
    80004382:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004384:	8526                	mv	a0,s1
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	dbc080e7          	jalr	-580(ra) # 80003142 <bpin>
    log.lh.n++;
    8000438e:	0001d717          	auipc	a4,0x1d
    80004392:	57a70713          	addi	a4,a4,1402 # 80021908 <log>
    80004396:	575c                	lw	a5,44(a4)
    80004398:	2785                	addiw	a5,a5,1
    8000439a:	d75c                	sw	a5,44(a4)
    8000439c:	a83d                	j	800043da <log_write+0xd2>
    panic("too big a transaction");
    8000439e:	00004517          	auipc	a0,0x4
    800043a2:	41250513          	addi	a0,a0,1042 # 800087b0 <syscall_names+0x200>
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	1a2080e7          	jalr	418(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043ae:	00004517          	auipc	a0,0x4
    800043b2:	41a50513          	addi	a0,a0,1050 # 800087c8 <syscall_names+0x218>
    800043b6:	ffffc097          	auipc	ra,0xffffc
    800043ba:	192080e7          	jalr	402(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043be:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043c0:	00878713          	addi	a4,a5,8
    800043c4:	00271693          	slli	a3,a4,0x2
    800043c8:	0001d717          	auipc	a4,0x1d
    800043cc:	54070713          	addi	a4,a4,1344 # 80021908 <log>
    800043d0:	9736                	add	a4,a4,a3
    800043d2:	44d4                	lw	a3,12(s1)
    800043d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043d6:	faf607e3          	beq	a2,a5,80004384 <log_write+0x7c>
  }
  release(&log.lock);
    800043da:	0001d517          	auipc	a0,0x1d
    800043de:	52e50513          	addi	a0,a0,1326 # 80021908 <log>
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	92c080e7          	jalr	-1748(ra) # 80000d0e <release>
}
    800043ea:	60e2                	ld	ra,24(sp)
    800043ec:	6442                	ld	s0,16(sp)
    800043ee:	64a2                	ld	s1,8(sp)
    800043f0:	6902                	ld	s2,0(sp)
    800043f2:	6105                	addi	sp,sp,32
    800043f4:	8082                	ret

00000000800043f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043f6:	1101                	addi	sp,sp,-32
    800043f8:	ec06                	sd	ra,24(sp)
    800043fa:	e822                	sd	s0,16(sp)
    800043fc:	e426                	sd	s1,8(sp)
    800043fe:	e04a                	sd	s2,0(sp)
    80004400:	1000                	addi	s0,sp,32
    80004402:	84aa                	mv	s1,a0
    80004404:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004406:	00004597          	auipc	a1,0x4
    8000440a:	3e258593          	addi	a1,a1,994 # 800087e8 <syscall_names+0x238>
    8000440e:	0521                	addi	a0,a0,8
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	7ba080e7          	jalr	1978(ra) # 80000bca <initlock>
  lk->name = name;
    80004418:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000441c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004420:	0204a423          	sw	zero,40(s1)
}
    80004424:	60e2                	ld	ra,24(sp)
    80004426:	6442                	ld	s0,16(sp)
    80004428:	64a2                	ld	s1,8(sp)
    8000442a:	6902                	ld	s2,0(sp)
    8000442c:	6105                	addi	sp,sp,32
    8000442e:	8082                	ret

0000000080004430 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000443e:	00850913          	addi	s2,a0,8
    80004442:	854a                	mv	a0,s2
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	816080e7          	jalr	-2026(ra) # 80000c5a <acquire>
  while (lk->locked) {
    8000444c:	409c                	lw	a5,0(s1)
    8000444e:	cb89                	beqz	a5,80004460 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004450:	85ca                	mv	a1,s2
    80004452:	8526                	mv	a0,s1
    80004454:	ffffe097          	auipc	ra,0xffffe
    80004458:	de8080e7          	jalr	-536(ra) # 8000223c <sleep>
  while (lk->locked) {
    8000445c:	409c                	lw	a5,0(s1)
    8000445e:	fbed                	bnez	a5,80004450 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004460:	4785                	li	a5,1
    80004462:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	5c4080e7          	jalr	1476(ra) # 80001a28 <myproc>
    8000446c:	5d1c                	lw	a5,56(a0)
    8000446e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004470:	854a                	mv	a0,s2
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	89c080e7          	jalr	-1892(ra) # 80000d0e <release>
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret

0000000080004486 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
    80004492:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004494:	00850913          	addi	s2,a0,8
    80004498:	854a                	mv	a0,s2
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	7c0080e7          	jalr	1984(ra) # 80000c5a <acquire>
  lk->locked = 0;
    800044a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffe097          	auipc	ra,0xffffe
    800044b0:	f16080e7          	jalr	-234(ra) # 800023c2 <wakeup>
  release(&lk->lk);
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffd097          	auipc	ra,0xffffd
    800044ba:	858080e7          	jalr	-1960(ra) # 80000d0e <release>
}
    800044be:	60e2                	ld	ra,24(sp)
    800044c0:	6442                	ld	s0,16(sp)
    800044c2:	64a2                	ld	s1,8(sp)
    800044c4:	6902                	ld	s2,0(sp)
    800044c6:	6105                	addi	sp,sp,32
    800044c8:	8082                	ret

00000000800044ca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ca:	7179                	addi	sp,sp,-48
    800044cc:	f406                	sd	ra,40(sp)
    800044ce:	f022                	sd	s0,32(sp)
    800044d0:	ec26                	sd	s1,24(sp)
    800044d2:	e84a                	sd	s2,16(sp)
    800044d4:	e44e                	sd	s3,8(sp)
    800044d6:	1800                	addi	s0,sp,48
    800044d8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044da:	00850913          	addi	s2,a0,8
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	77a080e7          	jalr	1914(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e8:	409c                	lw	a5,0(s1)
    800044ea:	ef99                	bnez	a5,80004508 <holdingsleep+0x3e>
    800044ec:	4481                	li	s1,0
  release(&lk->lk);
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffd097          	auipc	ra,0xffffd
    800044f4:	81e080e7          	jalr	-2018(ra) # 80000d0e <release>
  return r;
}
    800044f8:	8526                	mv	a0,s1
    800044fa:	70a2                	ld	ra,40(sp)
    800044fc:	7402                	ld	s0,32(sp)
    800044fe:	64e2                	ld	s1,24(sp)
    80004500:	6942                	ld	s2,16(sp)
    80004502:	69a2                	ld	s3,8(sp)
    80004504:	6145                	addi	sp,sp,48
    80004506:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004508:	0284a983          	lw	s3,40(s1)
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	51c080e7          	jalr	1308(ra) # 80001a28 <myproc>
    80004514:	5d04                	lw	s1,56(a0)
    80004516:	413484b3          	sub	s1,s1,s3
    8000451a:	0014b493          	seqz	s1,s1
    8000451e:	bfc1                	j	800044ee <holdingsleep+0x24>

0000000080004520 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004520:	1141                	addi	sp,sp,-16
    80004522:	e406                	sd	ra,8(sp)
    80004524:	e022                	sd	s0,0(sp)
    80004526:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004528:	00004597          	auipc	a1,0x4
    8000452c:	2d058593          	addi	a1,a1,720 # 800087f8 <syscall_names+0x248>
    80004530:	0001d517          	auipc	a0,0x1d
    80004534:	52050513          	addi	a0,a0,1312 # 80021a50 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	692080e7          	jalr	1682(ra) # 80000bca <initlock>
}
    80004540:	60a2                	ld	ra,8(sp)
    80004542:	6402                	ld	s0,0(sp)
    80004544:	0141                	addi	sp,sp,16
    80004546:	8082                	ret

0000000080004548 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004548:	1101                	addi	sp,sp,-32
    8000454a:	ec06                	sd	ra,24(sp)
    8000454c:	e822                	sd	s0,16(sp)
    8000454e:	e426                	sd	s1,8(sp)
    80004550:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004552:	0001d517          	auipc	a0,0x1d
    80004556:	4fe50513          	addi	a0,a0,1278 # 80021a50 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	700080e7          	jalr	1792(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004562:	0001d497          	auipc	s1,0x1d
    80004566:	50648493          	addi	s1,s1,1286 # 80021a68 <ftable+0x18>
    8000456a:	0001e717          	auipc	a4,0x1e
    8000456e:	49e70713          	addi	a4,a4,1182 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004572:	40dc                	lw	a5,4(s1)
    80004574:	cf99                	beqz	a5,80004592 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004576:	02848493          	addi	s1,s1,40
    8000457a:	fee49ce3          	bne	s1,a4,80004572 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000457e:	0001d517          	auipc	a0,0x1d
    80004582:	4d250513          	addi	a0,a0,1234 # 80021a50 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	788080e7          	jalr	1928(ra) # 80000d0e <release>
  return 0;
    8000458e:	4481                	li	s1,0
    80004590:	a819                	j	800045a6 <filealloc+0x5e>
      f->ref = 1;
    80004592:	4785                	li	a5,1
    80004594:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004596:	0001d517          	auipc	a0,0x1d
    8000459a:	4ba50513          	addi	a0,a0,1210 # 80021a50 <ftable>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	770080e7          	jalr	1904(ra) # 80000d0e <release>
}
    800045a6:	8526                	mv	a0,s1
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	64a2                	ld	s1,8(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret

00000000800045b2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	1000                	addi	s0,sp,32
    800045bc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045be:	0001d517          	auipc	a0,0x1d
    800045c2:	49250513          	addi	a0,a0,1170 # 80021a50 <ftable>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	694080e7          	jalr	1684(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800045ce:	40dc                	lw	a5,4(s1)
    800045d0:	02f05263          	blez	a5,800045f4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045d4:	2785                	addiw	a5,a5,1
    800045d6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	47850513          	addi	a0,a0,1144 # 80021a50 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	72e080e7          	jalr	1838(ra) # 80000d0e <release>
  return f;
}
    800045e8:	8526                	mv	a0,s1
    800045ea:	60e2                	ld	ra,24(sp)
    800045ec:	6442                	ld	s0,16(sp)
    800045ee:	64a2                	ld	s1,8(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret
    panic("filedup");
    800045f4:	00004517          	auipc	a0,0x4
    800045f8:	20c50513          	addi	a0,a0,524 # 80008800 <syscall_names+0x250>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	f4c080e7          	jalr	-180(ra) # 80000548 <panic>

0000000080004604 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004604:	7139                	addi	sp,sp,-64
    80004606:	fc06                	sd	ra,56(sp)
    80004608:	f822                	sd	s0,48(sp)
    8000460a:	f426                	sd	s1,40(sp)
    8000460c:	f04a                	sd	s2,32(sp)
    8000460e:	ec4e                	sd	s3,24(sp)
    80004610:	e852                	sd	s4,16(sp)
    80004612:	e456                	sd	s5,8(sp)
    80004614:	0080                	addi	s0,sp,64
    80004616:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	43850513          	addi	a0,a0,1080 # 80021a50 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	63a080e7          	jalr	1594(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004628:	40dc                	lw	a5,4(s1)
    8000462a:	06f05163          	blez	a5,8000468c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000462e:	37fd                	addiw	a5,a5,-1
    80004630:	0007871b          	sext.w	a4,a5
    80004634:	c0dc                	sw	a5,4(s1)
    80004636:	06e04363          	bgtz	a4,8000469c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000463a:	0004a903          	lw	s2,0(s1)
    8000463e:	0094ca83          	lbu	s5,9(s1)
    80004642:	0104ba03          	ld	s4,16(s1)
    80004646:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000464a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000464e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004652:	0001d517          	auipc	a0,0x1d
    80004656:	3fe50513          	addi	a0,a0,1022 # 80021a50 <ftable>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	6b4080e7          	jalr	1716(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    80004662:	4785                	li	a5,1
    80004664:	04f90d63          	beq	s2,a5,800046be <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004668:	3979                	addiw	s2,s2,-2
    8000466a:	4785                	li	a5,1
    8000466c:	0527e063          	bltu	a5,s2,800046ac <fileclose+0xa8>
    begin_op();
    80004670:	00000097          	auipc	ra,0x0
    80004674:	ac2080e7          	jalr	-1342(ra) # 80004132 <begin_op>
    iput(ff.ip);
    80004678:	854e                	mv	a0,s3
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	2b6080e7          	jalr	694(ra) # 80003930 <iput>
    end_op();
    80004682:	00000097          	auipc	ra,0x0
    80004686:	b30080e7          	jalr	-1232(ra) # 800041b2 <end_op>
    8000468a:	a00d                	j	800046ac <fileclose+0xa8>
    panic("fileclose");
    8000468c:	00004517          	auipc	a0,0x4
    80004690:	17c50513          	addi	a0,a0,380 # 80008808 <syscall_names+0x258>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	eb4080e7          	jalr	-332(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000469c:	0001d517          	auipc	a0,0x1d
    800046a0:	3b450513          	addi	a0,a0,948 # 80021a50 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	66a080e7          	jalr	1642(ra) # 80000d0e <release>
  }
}
    800046ac:	70e2                	ld	ra,56(sp)
    800046ae:	7442                	ld	s0,48(sp)
    800046b0:	74a2                	ld	s1,40(sp)
    800046b2:	7902                	ld	s2,32(sp)
    800046b4:	69e2                	ld	s3,24(sp)
    800046b6:	6a42                	ld	s4,16(sp)
    800046b8:	6aa2                	ld	s5,8(sp)
    800046ba:	6121                	addi	sp,sp,64
    800046bc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046be:	85d6                	mv	a1,s5
    800046c0:	8552                	mv	a0,s4
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	372080e7          	jalr	882(ra) # 80004a34 <pipeclose>
    800046ca:	b7cd                	j	800046ac <fileclose+0xa8>

00000000800046cc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046cc:	715d                	addi	sp,sp,-80
    800046ce:	e486                	sd	ra,72(sp)
    800046d0:	e0a2                	sd	s0,64(sp)
    800046d2:	fc26                	sd	s1,56(sp)
    800046d4:	f84a                	sd	s2,48(sp)
    800046d6:	f44e                	sd	s3,40(sp)
    800046d8:	0880                	addi	s0,sp,80
    800046da:	84aa                	mv	s1,a0
    800046dc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046de:	ffffd097          	auipc	ra,0xffffd
    800046e2:	34a080e7          	jalr	842(ra) # 80001a28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046e6:	409c                	lw	a5,0(s1)
    800046e8:	37f9                	addiw	a5,a5,-2
    800046ea:	4705                	li	a4,1
    800046ec:	04f76763          	bltu	a4,a5,8000473a <filestat+0x6e>
    800046f0:	892a                	mv	s2,a0
    ilock(f->ip);
    800046f2:	6c88                	ld	a0,24(s1)
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	082080e7          	jalr	130(ra) # 80003776 <ilock>
    stati(f->ip, &st);
    800046fc:	fb840593          	addi	a1,s0,-72
    80004700:	6c88                	ld	a0,24(s1)
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	2fe080e7          	jalr	766(ra) # 80003a00 <stati>
    iunlock(f->ip);
    8000470a:	6c88                	ld	a0,24(s1)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	12c080e7          	jalr	300(ra) # 80003838 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004714:	46e1                	li	a3,24
    80004716:	fb840613          	addi	a2,s0,-72
    8000471a:	85ce                	mv	a1,s3
    8000471c:	05093503          	ld	a0,80(s2)
    80004720:	ffffd097          	auipc	ra,0xffffd
    80004724:	ffc080e7          	jalr	-4(ra) # 8000171c <copyout>
    80004728:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000472c:	60a6                	ld	ra,72(sp)
    8000472e:	6406                	ld	s0,64(sp)
    80004730:	74e2                	ld	s1,56(sp)
    80004732:	7942                	ld	s2,48(sp)
    80004734:	79a2                	ld	s3,40(sp)
    80004736:	6161                	addi	sp,sp,80
    80004738:	8082                	ret
  return -1;
    8000473a:	557d                	li	a0,-1
    8000473c:	bfc5                	j	8000472c <filestat+0x60>

000000008000473e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000473e:	7179                	addi	sp,sp,-48
    80004740:	f406                	sd	ra,40(sp)
    80004742:	f022                	sd	s0,32(sp)
    80004744:	ec26                	sd	s1,24(sp)
    80004746:	e84a                	sd	s2,16(sp)
    80004748:	e44e                	sd	s3,8(sp)
    8000474a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000474c:	00854783          	lbu	a5,8(a0)
    80004750:	c3d5                	beqz	a5,800047f4 <fileread+0xb6>
    80004752:	84aa                	mv	s1,a0
    80004754:	89ae                	mv	s3,a1
    80004756:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004758:	411c                	lw	a5,0(a0)
    8000475a:	4705                	li	a4,1
    8000475c:	04e78963          	beq	a5,a4,800047ae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004760:	470d                	li	a4,3
    80004762:	04e78d63          	beq	a5,a4,800047bc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004766:	4709                	li	a4,2
    80004768:	06e79e63          	bne	a5,a4,800047e4 <fileread+0xa6>
    ilock(f->ip);
    8000476c:	6d08                	ld	a0,24(a0)
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	008080e7          	jalr	8(ra) # 80003776 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004776:	874a                	mv	a4,s2
    80004778:	5094                	lw	a3,32(s1)
    8000477a:	864e                	mv	a2,s3
    8000477c:	4585                	li	a1,1
    8000477e:	6c88                	ld	a0,24(s1)
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	2aa080e7          	jalr	682(ra) # 80003a2a <readi>
    80004788:	892a                	mv	s2,a0
    8000478a:	00a05563          	blez	a0,80004794 <fileread+0x56>
      f->off += r;
    8000478e:	509c                	lw	a5,32(s1)
    80004790:	9fa9                	addw	a5,a5,a0
    80004792:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004794:	6c88                	ld	a0,24(s1)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	0a2080e7          	jalr	162(ra) # 80003838 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000479e:	854a                	mv	a0,s2
    800047a0:	70a2                	ld	ra,40(sp)
    800047a2:	7402                	ld	s0,32(sp)
    800047a4:	64e2                	ld	s1,24(sp)
    800047a6:	6942                	ld	s2,16(sp)
    800047a8:	69a2                	ld	s3,8(sp)
    800047aa:	6145                	addi	sp,sp,48
    800047ac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047ae:	6908                	ld	a0,16(a0)
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	418080e7          	jalr	1048(ra) # 80004bc8 <piperead>
    800047b8:	892a                	mv	s2,a0
    800047ba:	b7d5                	j	8000479e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047bc:	02451783          	lh	a5,36(a0)
    800047c0:	03079693          	slli	a3,a5,0x30
    800047c4:	92c1                	srli	a3,a3,0x30
    800047c6:	4725                	li	a4,9
    800047c8:	02d76863          	bltu	a4,a3,800047f8 <fileread+0xba>
    800047cc:	0792                	slli	a5,a5,0x4
    800047ce:	0001d717          	auipc	a4,0x1d
    800047d2:	1e270713          	addi	a4,a4,482 # 800219b0 <devsw>
    800047d6:	97ba                	add	a5,a5,a4
    800047d8:	639c                	ld	a5,0(a5)
    800047da:	c38d                	beqz	a5,800047fc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047dc:	4505                	li	a0,1
    800047de:	9782                	jalr	a5
    800047e0:	892a                	mv	s2,a0
    800047e2:	bf75                	j	8000479e <fileread+0x60>
    panic("fileread");
    800047e4:	00004517          	auipc	a0,0x4
    800047e8:	03450513          	addi	a0,a0,52 # 80008818 <syscall_names+0x268>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	d5c080e7          	jalr	-676(ra) # 80000548 <panic>
    return -1;
    800047f4:	597d                	li	s2,-1
    800047f6:	b765                	j	8000479e <fileread+0x60>
      return -1;
    800047f8:	597d                	li	s2,-1
    800047fa:	b755                	j	8000479e <fileread+0x60>
    800047fc:	597d                	li	s2,-1
    800047fe:	b745                	j	8000479e <fileread+0x60>

0000000080004800 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004800:	00954783          	lbu	a5,9(a0)
    80004804:	14078563          	beqz	a5,8000494e <filewrite+0x14e>
{
    80004808:	715d                	addi	sp,sp,-80
    8000480a:	e486                	sd	ra,72(sp)
    8000480c:	e0a2                	sd	s0,64(sp)
    8000480e:	fc26                	sd	s1,56(sp)
    80004810:	f84a                	sd	s2,48(sp)
    80004812:	f44e                	sd	s3,40(sp)
    80004814:	f052                	sd	s4,32(sp)
    80004816:	ec56                	sd	s5,24(sp)
    80004818:	e85a                	sd	s6,16(sp)
    8000481a:	e45e                	sd	s7,8(sp)
    8000481c:	e062                	sd	s8,0(sp)
    8000481e:	0880                	addi	s0,sp,80
    80004820:	892a                	mv	s2,a0
    80004822:	8aae                	mv	s5,a1
    80004824:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004826:	411c                	lw	a5,0(a0)
    80004828:	4705                	li	a4,1
    8000482a:	02e78263          	beq	a5,a4,8000484e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000482e:	470d                	li	a4,3
    80004830:	02e78563          	beq	a5,a4,8000485a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004834:	4709                	li	a4,2
    80004836:	10e79463          	bne	a5,a4,8000493e <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000483a:	0ec05e63          	blez	a2,80004936 <filewrite+0x136>
    int i = 0;
    8000483e:	4981                	li	s3,0
    80004840:	6b05                	lui	s6,0x1
    80004842:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004846:	6b85                	lui	s7,0x1
    80004848:	c00b8b9b          	addiw	s7,s7,-1024
    8000484c:	a851                	j	800048e0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000484e:	6908                	ld	a0,16(a0)
    80004850:	00000097          	auipc	ra,0x0
    80004854:	254080e7          	jalr	596(ra) # 80004aa4 <pipewrite>
    80004858:	a85d                	j	8000490e <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000485a:	02451783          	lh	a5,36(a0)
    8000485e:	03079693          	slli	a3,a5,0x30
    80004862:	92c1                	srli	a3,a3,0x30
    80004864:	4725                	li	a4,9
    80004866:	0ed76663          	bltu	a4,a3,80004952 <filewrite+0x152>
    8000486a:	0792                	slli	a5,a5,0x4
    8000486c:	0001d717          	auipc	a4,0x1d
    80004870:	14470713          	addi	a4,a4,324 # 800219b0 <devsw>
    80004874:	97ba                	add	a5,a5,a4
    80004876:	679c                	ld	a5,8(a5)
    80004878:	cff9                	beqz	a5,80004956 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000487a:	4505                	li	a0,1
    8000487c:	9782                	jalr	a5
    8000487e:	a841                	j	8000490e <filewrite+0x10e>
    80004880:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004884:	00000097          	auipc	ra,0x0
    80004888:	8ae080e7          	jalr	-1874(ra) # 80004132 <begin_op>
      ilock(f->ip);
    8000488c:	01893503          	ld	a0,24(s2)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	ee6080e7          	jalr	-282(ra) # 80003776 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004898:	8762                	mv	a4,s8
    8000489a:	02092683          	lw	a3,32(s2)
    8000489e:	01598633          	add	a2,s3,s5
    800048a2:	4585                	li	a1,1
    800048a4:	01893503          	ld	a0,24(s2)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	278080e7          	jalr	632(ra) # 80003b20 <writei>
    800048b0:	84aa                	mv	s1,a0
    800048b2:	02a05f63          	blez	a0,800048f0 <filewrite+0xf0>
        f->off += r;
    800048b6:	02092783          	lw	a5,32(s2)
    800048ba:	9fa9                	addw	a5,a5,a0
    800048bc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048c0:	01893503          	ld	a0,24(s2)
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	f74080e7          	jalr	-140(ra) # 80003838 <iunlock>
      end_op();
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	8e6080e7          	jalr	-1818(ra) # 800041b2 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048d4:	049c1963          	bne	s8,s1,80004926 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048d8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048dc:	0349d663          	bge	s3,s4,80004908 <filewrite+0x108>
      int n1 = n - i;
    800048e0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048e4:	84be                	mv	s1,a5
    800048e6:	2781                	sext.w	a5,a5
    800048e8:	f8fb5ce3          	bge	s6,a5,80004880 <filewrite+0x80>
    800048ec:	84de                	mv	s1,s7
    800048ee:	bf49                	j	80004880 <filewrite+0x80>
      iunlock(f->ip);
    800048f0:	01893503          	ld	a0,24(s2)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	f44080e7          	jalr	-188(ra) # 80003838 <iunlock>
      end_op();
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	8b6080e7          	jalr	-1866(ra) # 800041b2 <end_op>
      if(r < 0)
    80004904:	fc04d8e3          	bgez	s1,800048d4 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004908:	8552                	mv	a0,s4
    8000490a:	033a1863          	bne	s4,s3,8000493a <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000490e:	60a6                	ld	ra,72(sp)
    80004910:	6406                	ld	s0,64(sp)
    80004912:	74e2                	ld	s1,56(sp)
    80004914:	7942                	ld	s2,48(sp)
    80004916:	79a2                	ld	s3,40(sp)
    80004918:	7a02                	ld	s4,32(sp)
    8000491a:	6ae2                	ld	s5,24(sp)
    8000491c:	6b42                	ld	s6,16(sp)
    8000491e:	6ba2                	ld	s7,8(sp)
    80004920:	6c02                	ld	s8,0(sp)
    80004922:	6161                	addi	sp,sp,80
    80004924:	8082                	ret
        panic("short filewrite");
    80004926:	00004517          	auipc	a0,0x4
    8000492a:	f0250513          	addi	a0,a0,-254 # 80008828 <syscall_names+0x278>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	c1a080e7          	jalr	-998(ra) # 80000548 <panic>
    int i = 0;
    80004936:	4981                	li	s3,0
    80004938:	bfc1                	j	80004908 <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000493a:	557d                	li	a0,-1
    8000493c:	bfc9                	j	8000490e <filewrite+0x10e>
    panic("filewrite");
    8000493e:	00004517          	auipc	a0,0x4
    80004942:	efa50513          	addi	a0,a0,-262 # 80008838 <syscall_names+0x288>
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	c02080e7          	jalr	-1022(ra) # 80000548 <panic>
    return -1;
    8000494e:	557d                	li	a0,-1
}
    80004950:	8082                	ret
      return -1;
    80004952:	557d                	li	a0,-1
    80004954:	bf6d                	j	8000490e <filewrite+0x10e>
    80004956:	557d                	li	a0,-1
    80004958:	bf5d                	j	8000490e <filewrite+0x10e>

000000008000495a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000495a:	7179                	addi	sp,sp,-48
    8000495c:	f406                	sd	ra,40(sp)
    8000495e:	f022                	sd	s0,32(sp)
    80004960:	ec26                	sd	s1,24(sp)
    80004962:	e84a                	sd	s2,16(sp)
    80004964:	e44e                	sd	s3,8(sp)
    80004966:	e052                	sd	s4,0(sp)
    80004968:	1800                	addi	s0,sp,48
    8000496a:	84aa                	mv	s1,a0
    8000496c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000496e:	0005b023          	sd	zero,0(a1)
    80004972:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	bd2080e7          	jalr	-1070(ra) # 80004548 <filealloc>
    8000497e:	e088                	sd	a0,0(s1)
    80004980:	c551                	beqz	a0,80004a0c <pipealloc+0xb2>
    80004982:	00000097          	auipc	ra,0x0
    80004986:	bc6080e7          	jalr	-1082(ra) # 80004548 <filealloc>
    8000498a:	00aa3023          	sd	a0,0(s4)
    8000498e:	c92d                	beqz	a0,80004a00 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	190080e7          	jalr	400(ra) # 80000b20 <kalloc>
    80004998:	892a                	mv	s2,a0
    8000499a:	c125                	beqz	a0,800049fa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000499c:	4985                	li	s3,1
    8000499e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049a2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049aa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ae:	00004597          	auipc	a1,0x4
    800049b2:	a9258593          	addi	a1,a1,-1390 # 80008440 <states.1707+0x198>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	214080e7          	jalr	532(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    800049be:	609c                	ld	a5,0(s1)
    800049c0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c4:	609c                	ld	a5,0(s1)
    800049c6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ca:	609c                	ld	a5,0(s1)
    800049cc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d6:	000a3783          	ld	a5,0(s4)
    800049da:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049de:	000a3783          	ld	a5,0(s4)
    800049e2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e6:	000a3783          	ld	a5,0(s4)
    800049ea:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ee:	000a3783          	ld	a5,0(s4)
    800049f2:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f6:	4501                	li	a0,0
    800049f8:	a025                	j	80004a20 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049fa:	6088                	ld	a0,0(s1)
    800049fc:	e501                	bnez	a0,80004a04 <pipealloc+0xaa>
    800049fe:	a039                	j	80004a0c <pipealloc+0xb2>
    80004a00:	6088                	ld	a0,0(s1)
    80004a02:	c51d                	beqz	a0,80004a30 <pipealloc+0xd6>
    fileclose(*f0);
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	c00080e7          	jalr	-1024(ra) # 80004604 <fileclose>
  if(*f1)
    80004a0c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a10:	557d                	li	a0,-1
  if(*f1)
    80004a12:	c799                	beqz	a5,80004a20 <pipealloc+0xc6>
    fileclose(*f1);
    80004a14:	853e                	mv	a0,a5
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	bee080e7          	jalr	-1042(ra) # 80004604 <fileclose>
  return -1;
    80004a1e:	557d                	li	a0,-1
}
    80004a20:	70a2                	ld	ra,40(sp)
    80004a22:	7402                	ld	s0,32(sp)
    80004a24:	64e2                	ld	s1,24(sp)
    80004a26:	6942                	ld	s2,16(sp)
    80004a28:	69a2                	ld	s3,8(sp)
    80004a2a:	6a02                	ld	s4,0(sp)
    80004a2c:	6145                	addi	sp,sp,48
    80004a2e:	8082                	ret
  return -1;
    80004a30:	557d                	li	a0,-1
    80004a32:	b7fd                	j	80004a20 <pipealloc+0xc6>

0000000080004a34 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a34:	1101                	addi	sp,sp,-32
    80004a36:	ec06                	sd	ra,24(sp)
    80004a38:	e822                	sd	s0,16(sp)
    80004a3a:	e426                	sd	s1,8(sp)
    80004a3c:	e04a                	sd	s2,0(sp)
    80004a3e:	1000                	addi	s0,sp,32
    80004a40:	84aa                	mv	s1,a0
    80004a42:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	216080e7          	jalr	534(ra) # 80000c5a <acquire>
  if(writable){
    80004a4c:	02090d63          	beqz	s2,80004a86 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a50:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a54:	21848513          	addi	a0,s1,536
    80004a58:	ffffe097          	auipc	ra,0xffffe
    80004a5c:	96a080e7          	jalr	-1686(ra) # 800023c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a60:	2204b783          	ld	a5,544(s1)
    80004a64:	eb95                	bnez	a5,80004a98 <pipeclose+0x64>
    release(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	2a6080e7          	jalr	678(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	fb2080e7          	jalr	-78(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6902                	ld	s2,0(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret
    pi->readopen = 0;
    80004a86:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a8a:	21c48513          	addi	a0,s1,540
    80004a8e:	ffffe097          	auipc	ra,0xffffe
    80004a92:	934080e7          	jalr	-1740(ra) # 800023c2 <wakeup>
    80004a96:	b7e9                	j	80004a60 <pipeclose+0x2c>
    release(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	274080e7          	jalr	628(ra) # 80000d0e <release>
}
    80004aa2:	bfe1                	j	80004a7a <pipeclose+0x46>

0000000080004aa4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa4:	7119                	addi	sp,sp,-128
    80004aa6:	fc86                	sd	ra,120(sp)
    80004aa8:	f8a2                	sd	s0,112(sp)
    80004aaa:	f4a6                	sd	s1,104(sp)
    80004aac:	f0ca                	sd	s2,96(sp)
    80004aae:	ecce                	sd	s3,88(sp)
    80004ab0:	e8d2                	sd	s4,80(sp)
    80004ab2:	e4d6                	sd	s5,72(sp)
    80004ab4:	e0da                	sd	s6,64(sp)
    80004ab6:	fc5e                	sd	s7,56(sp)
    80004ab8:	f862                	sd	s8,48(sp)
    80004aba:	f466                	sd	s9,40(sp)
    80004abc:	f06a                	sd	s10,32(sp)
    80004abe:	ec6e                	sd	s11,24(sp)
    80004ac0:	0100                	addi	s0,sp,128
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	8cae                	mv	s9,a1
    80004ac6:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	f60080e7          	jalr	-160(ra) # 80001a28 <myproc>
    80004ad0:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	186080e7          	jalr	390(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004adc:	0d605963          	blez	s6,80004bae <pipewrite+0x10a>
    80004ae0:	89a6                	mv	s3,s1
    80004ae2:	3b7d                	addiw	s6,s6,-1
    80004ae4:	1b02                	slli	s6,s6,0x20
    80004ae6:	020b5b13          	srli	s6,s6,0x20
    80004aea:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004aec:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af0:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af4:	5dfd                	li	s11,-1
    80004af6:	000b8d1b          	sext.w	s10,s7
    80004afa:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004afc:	2184a783          	lw	a5,536(s1)
    80004b00:	21c4a703          	lw	a4,540(s1)
    80004b04:	2007879b          	addiw	a5,a5,512
    80004b08:	02f71b63          	bne	a4,a5,80004b3e <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b0c:	2204a783          	lw	a5,544(s1)
    80004b10:	cbad                	beqz	a5,80004b82 <pipewrite+0xde>
    80004b12:	03092783          	lw	a5,48(s2)
    80004b16:	e7b5                	bnez	a5,80004b82 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b18:	8556                	mv	a0,s5
    80004b1a:	ffffe097          	auipc	ra,0xffffe
    80004b1e:	8a8080e7          	jalr	-1880(ra) # 800023c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b22:	85ce                	mv	a1,s3
    80004b24:	8552                	mv	a0,s4
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	716080e7          	jalr	1814(ra) # 8000223c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b2e:	2184a783          	lw	a5,536(s1)
    80004b32:	21c4a703          	lw	a4,540(s1)
    80004b36:	2007879b          	addiw	a5,a5,512
    80004b3a:	fcf709e3          	beq	a4,a5,80004b0c <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3e:	4685                	li	a3,1
    80004b40:	019b8633          	add	a2,s7,s9
    80004b44:	f8f40593          	addi	a1,s0,-113
    80004b48:	05093503          	ld	a0,80(s2)
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	c5c080e7          	jalr	-932(ra) # 800017a8 <copyin>
    80004b54:	05b50e63          	beq	a0,s11,80004bb0 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b58:	21c4a783          	lw	a5,540(s1)
    80004b5c:	0017871b          	addiw	a4,a5,1
    80004b60:	20e4ae23          	sw	a4,540(s1)
    80004b64:	1ff7f793          	andi	a5,a5,511
    80004b68:	97a6                	add	a5,a5,s1
    80004b6a:	f8f44703          	lbu	a4,-113(s0)
    80004b6e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b72:	001d0c1b          	addiw	s8,s10,1
    80004b76:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b7a:	036b8b63          	beq	s7,s6,80004bb0 <pipewrite+0x10c>
    80004b7e:	8bbe                	mv	s7,a5
    80004b80:	bf9d                	j	80004af6 <pipewrite+0x52>
        release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	18a080e7          	jalr	394(ra) # 80000d0e <release>
        return -1;
    80004b8c:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b8e:	8562                	mv	a0,s8
    80004b90:	70e6                	ld	ra,120(sp)
    80004b92:	7446                	ld	s0,112(sp)
    80004b94:	74a6                	ld	s1,104(sp)
    80004b96:	7906                	ld	s2,96(sp)
    80004b98:	69e6                	ld	s3,88(sp)
    80004b9a:	6a46                	ld	s4,80(sp)
    80004b9c:	6aa6                	ld	s5,72(sp)
    80004b9e:	6b06                	ld	s6,64(sp)
    80004ba0:	7be2                	ld	s7,56(sp)
    80004ba2:	7c42                	ld	s8,48(sp)
    80004ba4:	7ca2                	ld	s9,40(sp)
    80004ba6:	7d02                	ld	s10,32(sp)
    80004ba8:	6de2                	ld	s11,24(sp)
    80004baa:	6109                	addi	sp,sp,128
    80004bac:	8082                	ret
  for(i = 0; i < n; i++){
    80004bae:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bb0:	21848513          	addi	a0,s1,536
    80004bb4:	ffffe097          	auipc	ra,0xffffe
    80004bb8:	80e080e7          	jalr	-2034(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	150080e7          	jalr	336(ra) # 80000d0e <release>
  return i;
    80004bc6:	b7e1                	j	80004b8e <pipewrite+0xea>

0000000080004bc8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bc8:	715d                	addi	sp,sp,-80
    80004bca:	e486                	sd	ra,72(sp)
    80004bcc:	e0a2                	sd	s0,64(sp)
    80004bce:	fc26                	sd	s1,56(sp)
    80004bd0:	f84a                	sd	s2,48(sp)
    80004bd2:	f44e                	sd	s3,40(sp)
    80004bd4:	f052                	sd	s4,32(sp)
    80004bd6:	ec56                	sd	s5,24(sp)
    80004bd8:	e85a                	sd	s6,16(sp)
    80004bda:	0880                	addi	s0,sp,80
    80004bdc:	84aa                	mv	s1,a0
    80004bde:	892e                	mv	s2,a1
    80004be0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	e46080e7          	jalr	-442(ra) # 80001a28 <myproc>
    80004bea:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bec:	8b26                	mv	s6,s1
    80004bee:	8526                	mv	a0,s1
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	06a080e7          	jalr	106(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf8:	2184a703          	lw	a4,536(s1)
    80004bfc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c00:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c04:	02f71463          	bne	a4,a5,80004c2c <piperead+0x64>
    80004c08:	2244a783          	lw	a5,548(s1)
    80004c0c:	c385                	beqz	a5,80004c2c <piperead+0x64>
    if(pr->killed){
    80004c0e:	030a2783          	lw	a5,48(s4)
    80004c12:	ebc1                	bnez	a5,80004ca2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c14:	85da                	mv	a1,s6
    80004c16:	854e                	mv	a0,s3
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	624080e7          	jalr	1572(ra) # 8000223c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c20:	2184a703          	lw	a4,536(s1)
    80004c24:	21c4a783          	lw	a5,540(s1)
    80004c28:	fef700e3          	beq	a4,a5,80004c08 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2c:	09505263          	blez	s5,80004cb0 <piperead+0xe8>
    80004c30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c32:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c34:	2184a783          	lw	a5,536(s1)
    80004c38:	21c4a703          	lw	a4,540(s1)
    80004c3c:	02f70d63          	beq	a4,a5,80004c76 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c40:	0017871b          	addiw	a4,a5,1
    80004c44:	20e4ac23          	sw	a4,536(s1)
    80004c48:	1ff7f793          	andi	a5,a5,511
    80004c4c:	97a6                	add	a5,a5,s1
    80004c4e:	0187c783          	lbu	a5,24(a5)
    80004c52:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c56:	4685                	li	a3,1
    80004c58:	fbf40613          	addi	a2,s0,-65
    80004c5c:	85ca                	mv	a1,s2
    80004c5e:	050a3503          	ld	a0,80(s4)
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	aba080e7          	jalr	-1350(ra) # 8000171c <copyout>
    80004c6a:	01650663          	beq	a0,s6,80004c76 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6e:	2985                	addiw	s3,s3,1
    80004c70:	0905                	addi	s2,s2,1
    80004c72:	fd3a91e3          	bne	s5,s3,80004c34 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c76:	21c48513          	addi	a0,s1,540
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	748080e7          	jalr	1864(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	08a080e7          	jalr	138(ra) # 80000d0e <release>
  return i;
}
    80004c8c:	854e                	mv	a0,s3
    80004c8e:	60a6                	ld	ra,72(sp)
    80004c90:	6406                	ld	s0,64(sp)
    80004c92:	74e2                	ld	s1,56(sp)
    80004c94:	7942                	ld	s2,48(sp)
    80004c96:	79a2                	ld	s3,40(sp)
    80004c98:	7a02                	ld	s4,32(sp)
    80004c9a:	6ae2                	ld	s5,24(sp)
    80004c9c:	6b42                	ld	s6,16(sp)
    80004c9e:	6161                	addi	sp,sp,80
    80004ca0:	8082                	ret
      release(&pi->lock);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	06a080e7          	jalr	106(ra) # 80000d0e <release>
      return -1;
    80004cac:	59fd                	li	s3,-1
    80004cae:	bff9                	j	80004c8c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb0:	4981                	li	s3,0
    80004cb2:	b7d1                	j	80004c76 <piperead+0xae>

0000000080004cb4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cb4:	df010113          	addi	sp,sp,-528
    80004cb8:	20113423          	sd	ra,520(sp)
    80004cbc:	20813023          	sd	s0,512(sp)
    80004cc0:	ffa6                	sd	s1,504(sp)
    80004cc2:	fbca                	sd	s2,496(sp)
    80004cc4:	f7ce                	sd	s3,488(sp)
    80004cc6:	f3d2                	sd	s4,480(sp)
    80004cc8:	efd6                	sd	s5,472(sp)
    80004cca:	ebda                	sd	s6,464(sp)
    80004ccc:	e7de                	sd	s7,456(sp)
    80004cce:	e3e2                	sd	s8,448(sp)
    80004cd0:	ff66                	sd	s9,440(sp)
    80004cd2:	fb6a                	sd	s10,432(sp)
    80004cd4:	f76e                	sd	s11,424(sp)
    80004cd6:	0c00                	addi	s0,sp,528
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	dea43c23          	sd	a0,-520(s0)
    80004cde:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	d46080e7          	jalr	-698(ra) # 80001a28 <myproc>
    80004cea:	892a                	mv	s2,a0

  begin_op();
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	446080e7          	jalr	1094(ra) # 80004132 <begin_op>

  if((ip = namei(path)) == 0){
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	230080e7          	jalr	560(ra) # 80003f26 <namei>
    80004cfe:	c92d                	beqz	a0,80004d70 <exec+0xbc>
    80004d00:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	a74080e7          	jalr	-1420(ra) # 80003776 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d0a:	04000713          	li	a4,64
    80004d0e:	4681                	li	a3,0
    80004d10:	e4840613          	addi	a2,s0,-440
    80004d14:	4581                	li	a1,0
    80004d16:	8526                	mv	a0,s1
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	d12080e7          	jalr	-750(ra) # 80003a2a <readi>
    80004d20:	04000793          	li	a5,64
    80004d24:	00f51a63          	bne	a0,a5,80004d38 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d28:	e4842703          	lw	a4,-440(s0)
    80004d2c:	464c47b7          	lui	a5,0x464c4
    80004d30:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d34:	04f70463          	beq	a4,a5,80004d7c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d38:	8526                	mv	a0,s1
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	c9e080e7          	jalr	-866(ra) # 800039d8 <iunlockput>
    end_op();
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	470080e7          	jalr	1136(ra) # 800041b2 <end_op>
  }
  return -1;
    80004d4a:	557d                	li	a0,-1
}
    80004d4c:	20813083          	ld	ra,520(sp)
    80004d50:	20013403          	ld	s0,512(sp)
    80004d54:	74fe                	ld	s1,504(sp)
    80004d56:	795e                	ld	s2,496(sp)
    80004d58:	79be                	ld	s3,488(sp)
    80004d5a:	7a1e                	ld	s4,480(sp)
    80004d5c:	6afe                	ld	s5,472(sp)
    80004d5e:	6b5e                	ld	s6,464(sp)
    80004d60:	6bbe                	ld	s7,456(sp)
    80004d62:	6c1e                	ld	s8,448(sp)
    80004d64:	7cfa                	ld	s9,440(sp)
    80004d66:	7d5a                	ld	s10,432(sp)
    80004d68:	7dba                	ld	s11,424(sp)
    80004d6a:	21010113          	addi	sp,sp,528
    80004d6e:	8082                	ret
    end_op();
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	442080e7          	jalr	1090(ra) # 800041b2 <end_op>
    return -1;
    80004d78:	557d                	li	a0,-1
    80004d7a:	bfc9                	j	80004d4c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d7c:	854a                	mv	a0,s2
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	d6e080e7          	jalr	-658(ra) # 80001aec <proc_pagetable>
    80004d86:	8baa                	mv	s7,a0
    80004d88:	d945                	beqz	a0,80004d38 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8a:	e6842983          	lw	s3,-408(s0)
    80004d8e:	e8045783          	lhu	a5,-384(s0)
    80004d92:	c7ad                	beqz	a5,80004dfc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d94:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d96:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d98:	6c85                	lui	s9,0x1
    80004d9a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d9e:	def43823          	sd	a5,-528(s0)
    80004da2:	a42d                	j	80004fcc <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da4:	00004517          	auipc	a0,0x4
    80004da8:	aa450513          	addi	a0,a0,-1372 # 80008848 <syscall_names+0x298>
    80004dac:	ffffb097          	auipc	ra,0xffffb
    80004db0:	79c080e7          	jalr	1948(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db4:	8756                	mv	a4,s5
    80004db6:	012d86bb          	addw	a3,s11,s2
    80004dba:	4581                	li	a1,0
    80004dbc:	8526                	mv	a0,s1
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	c6c080e7          	jalr	-916(ra) # 80003a2a <readi>
    80004dc6:	2501                	sext.w	a0,a0
    80004dc8:	1aaa9963          	bne	s5,a0,80004f7a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dcc:	6785                	lui	a5,0x1
    80004dce:	0127893b          	addw	s2,a5,s2
    80004dd2:	77fd                	lui	a5,0xfffff
    80004dd4:	01478a3b          	addw	s4,a5,s4
    80004dd8:	1f897163          	bgeu	s2,s8,80004fba <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ddc:	02091593          	slli	a1,s2,0x20
    80004de0:	9181                	srli	a1,a1,0x20
    80004de2:	95ea                	add	a1,a1,s10
    80004de4:	855e                	mv	a0,s7
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	302080e7          	jalr	770(ra) # 800010e8 <walkaddr>
    80004dee:	862a                	mv	a2,a0
    if(pa == 0)
    80004df0:	d955                	beqz	a0,80004da4 <exec+0xf0>
      n = PGSIZE;
    80004df2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004df4:	fd9a70e3          	bgeu	s4,s9,80004db4 <exec+0x100>
      n = sz - i;
    80004df8:	8ad2                	mv	s5,s4
    80004dfa:	bf6d                	j	80004db4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dfc:	4901                	li	s2,0
  iunlockput(ip);
    80004dfe:	8526                	mv	a0,s1
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	bd8080e7          	jalr	-1064(ra) # 800039d8 <iunlockput>
  end_op();
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	3aa080e7          	jalr	938(ra) # 800041b2 <end_op>
  p = myproc();
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	c18080e7          	jalr	-1000(ra) # 80001a28 <myproc>
    80004e18:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e1a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e1e:	6785                	lui	a5,0x1
    80004e20:	17fd                	addi	a5,a5,-1
    80004e22:	993e                	add	s2,s2,a5
    80004e24:	757d                	lui	a0,0xfffff
    80004e26:	00a977b3          	and	a5,s2,a0
    80004e2a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e2e:	6609                	lui	a2,0x2
    80004e30:	963e                	add	a2,a2,a5
    80004e32:	85be                	mv	a1,a5
    80004e34:	855e                	mv	a0,s7
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	696080e7          	jalr	1686(ra) # 800014cc <uvmalloc>
    80004e3e:	8b2a                	mv	s6,a0
  ip = 0;
    80004e40:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e42:	12050c63          	beqz	a0,80004f7a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e46:	75f9                	lui	a1,0xffffe
    80004e48:	95aa                	add	a1,a1,a0
    80004e4a:	855e                	mv	a0,s7
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	89e080e7          	jalr	-1890(ra) # 800016ea <uvmclear>
  stackbase = sp - PGSIZE;
    80004e54:	7c7d                	lui	s8,0xfffff
    80004e56:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e58:	e0043783          	ld	a5,-512(s0)
    80004e5c:	6388                	ld	a0,0(a5)
    80004e5e:	c535                	beqz	a0,80004eca <exec+0x216>
    80004e60:	e8840993          	addi	s3,s0,-376
    80004e64:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e68:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	074080e7          	jalr	116(ra) # 80000ede <strlen>
    80004e72:	2505                	addiw	a0,a0,1
    80004e74:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e78:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e7c:	13896363          	bltu	s2,s8,80004fa2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e80:	e0043d83          	ld	s11,-512(s0)
    80004e84:	000dba03          	ld	s4,0(s11)
    80004e88:	8552                	mv	a0,s4
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	054080e7          	jalr	84(ra) # 80000ede <strlen>
    80004e92:	0015069b          	addiw	a3,a0,1
    80004e96:	8652                	mv	a2,s4
    80004e98:	85ca                	mv	a1,s2
    80004e9a:	855e                	mv	a0,s7
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	880080e7          	jalr	-1920(ra) # 8000171c <copyout>
    80004ea4:	10054363          	bltz	a0,80004faa <exec+0x2f6>
    ustack[argc] = sp;
    80004ea8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eac:	0485                	addi	s1,s1,1
    80004eae:	008d8793          	addi	a5,s11,8
    80004eb2:	e0f43023          	sd	a5,-512(s0)
    80004eb6:	008db503          	ld	a0,8(s11)
    80004eba:	c911                	beqz	a0,80004ece <exec+0x21a>
    if(argc >= MAXARG)
    80004ebc:	09a1                	addi	s3,s3,8
    80004ebe:	fb3c96e3          	bne	s9,s3,80004e6a <exec+0x1b6>
  sz = sz1;
    80004ec2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec6:	4481                	li	s1,0
    80004ec8:	a84d                	j	80004f7a <exec+0x2c6>
  sp = sz;
    80004eca:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ecc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ece:	00349793          	slli	a5,s1,0x3
    80004ed2:	f9040713          	addi	a4,s0,-112
    80004ed6:	97ba                	add	a5,a5,a4
    80004ed8:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004edc:	00148693          	addi	a3,s1,1
    80004ee0:	068e                	slli	a3,a3,0x3
    80004ee2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eea:	01897663          	bgeu	s2,s8,80004ef6 <exec+0x242>
  sz = sz1;
    80004eee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef2:	4481                	li	s1,0
    80004ef4:	a059                	j	80004f7a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef6:	e8840613          	addi	a2,s0,-376
    80004efa:	85ca                	mv	a1,s2
    80004efc:	855e                	mv	a0,s7
    80004efe:	ffffd097          	auipc	ra,0xffffd
    80004f02:	81e080e7          	jalr	-2018(ra) # 8000171c <copyout>
    80004f06:	0a054663          	bltz	a0,80004fb2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f0a:	058ab783          	ld	a5,88(s5)
    80004f0e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f12:	df843783          	ld	a5,-520(s0)
    80004f16:	0007c703          	lbu	a4,0(a5)
    80004f1a:	cf11                	beqz	a4,80004f36 <exec+0x282>
    80004f1c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f1e:	02f00693          	li	a3,47
    80004f22:	a029                	j	80004f2c <exec+0x278>
  for(last=s=path; *s; s++)
    80004f24:	0785                	addi	a5,a5,1
    80004f26:	fff7c703          	lbu	a4,-1(a5)
    80004f2a:	c711                	beqz	a4,80004f36 <exec+0x282>
    if(*s == '/')
    80004f2c:	fed71ce3          	bne	a4,a3,80004f24 <exec+0x270>
      last = s+1;
    80004f30:	def43c23          	sd	a5,-520(s0)
    80004f34:	bfc5                	j	80004f24 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f36:	4641                	li	a2,16
    80004f38:	df843583          	ld	a1,-520(s0)
    80004f3c:	158a8513          	addi	a0,s5,344
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	f6c080e7          	jalr	-148(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    80004f48:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f4c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f50:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f54:	058ab783          	ld	a5,88(s5)
    80004f58:	e6043703          	ld	a4,-416(s0)
    80004f5c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5e:	058ab783          	ld	a5,88(s5)
    80004f62:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f66:	85ea                	mv	a1,s10
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	c20080e7          	jalr	-992(ra) # 80001b88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f70:	0004851b          	sext.w	a0,s1
    80004f74:	bbe1                	j	80004d4c <exec+0x98>
    80004f76:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f7a:	e0843583          	ld	a1,-504(s0)
    80004f7e:	855e                	mv	a0,s7
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	c08080e7          	jalr	-1016(ra) # 80001b88 <proc_freepagetable>
  if(ip){
    80004f88:	da0498e3          	bnez	s1,80004d38 <exec+0x84>
  return -1;
    80004f8c:	557d                	li	a0,-1
    80004f8e:	bb7d                	j	80004d4c <exec+0x98>
    80004f90:	e1243423          	sd	s2,-504(s0)
    80004f94:	b7dd                	j	80004f7a <exec+0x2c6>
    80004f96:	e1243423          	sd	s2,-504(s0)
    80004f9a:	b7c5                	j	80004f7a <exec+0x2c6>
    80004f9c:	e1243423          	sd	s2,-504(s0)
    80004fa0:	bfe9                	j	80004f7a <exec+0x2c6>
  sz = sz1;
    80004fa2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa6:	4481                	li	s1,0
    80004fa8:	bfc9                	j	80004f7a <exec+0x2c6>
  sz = sz1;
    80004faa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fae:	4481                	li	s1,0
    80004fb0:	b7e9                	j	80004f7a <exec+0x2c6>
  sz = sz1;
    80004fb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb6:	4481                	li	s1,0
    80004fb8:	b7c9                	j	80004f7a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fba:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fbe:	2b05                	addiw	s6,s6,1
    80004fc0:	0389899b          	addiw	s3,s3,56
    80004fc4:	e8045783          	lhu	a5,-384(s0)
    80004fc8:	e2fb5be3          	bge	s6,a5,80004dfe <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fcc:	2981                	sext.w	s3,s3
    80004fce:	03800713          	li	a4,56
    80004fd2:	86ce                	mv	a3,s3
    80004fd4:	e1040613          	addi	a2,s0,-496
    80004fd8:	4581                	li	a1,0
    80004fda:	8526                	mv	a0,s1
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	a4e080e7          	jalr	-1458(ra) # 80003a2a <readi>
    80004fe4:	03800793          	li	a5,56
    80004fe8:	f8f517e3          	bne	a0,a5,80004f76 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fec:	e1042783          	lw	a5,-496(s0)
    80004ff0:	4705                	li	a4,1
    80004ff2:	fce796e3          	bne	a5,a4,80004fbe <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ff6:	e3843603          	ld	a2,-456(s0)
    80004ffa:	e3043783          	ld	a5,-464(s0)
    80004ffe:	f8f669e3          	bltu	a2,a5,80004f90 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005002:	e2043783          	ld	a5,-480(s0)
    80005006:	963e                	add	a2,a2,a5
    80005008:	f8f667e3          	bltu	a2,a5,80004f96 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000500c:	85ca                	mv	a1,s2
    8000500e:	855e                	mv	a0,s7
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	4bc080e7          	jalr	1212(ra) # 800014cc <uvmalloc>
    80005018:	e0a43423          	sd	a0,-504(s0)
    8000501c:	d141                	beqz	a0,80004f9c <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000501e:	e2043d03          	ld	s10,-480(s0)
    80005022:	df043783          	ld	a5,-528(s0)
    80005026:	00fd77b3          	and	a5,s10,a5
    8000502a:	fba1                	bnez	a5,80004f7a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000502c:	e1842d83          	lw	s11,-488(s0)
    80005030:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005034:	f80c03e3          	beqz	s8,80004fba <exec+0x306>
    80005038:	8a62                	mv	s4,s8
    8000503a:	4901                	li	s2,0
    8000503c:	b345                	j	80004ddc <exec+0x128>

000000008000503e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000503e:	7179                	addi	sp,sp,-48
    80005040:	f406                	sd	ra,40(sp)
    80005042:	f022                	sd	s0,32(sp)
    80005044:	ec26                	sd	s1,24(sp)
    80005046:	e84a                	sd	s2,16(sp)
    80005048:	1800                	addi	s0,sp,48
    8000504a:	892e                	mv	s2,a1
    8000504c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000504e:	fdc40593          	addi	a1,s0,-36
    80005052:	ffffe097          	auipc	ra,0xffffe
    80005056:	aec080e7          	jalr	-1300(ra) # 80002b3e <argint>
    8000505a:	04054063          	bltz	a0,8000509a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000505e:	fdc42703          	lw	a4,-36(s0)
    80005062:	47bd                	li	a5,15
    80005064:	02e7ed63          	bltu	a5,a4,8000509e <argfd+0x60>
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	9c0080e7          	jalr	-1600(ra) # 80001a28 <myproc>
    80005070:	fdc42703          	lw	a4,-36(s0)
    80005074:	01a70793          	addi	a5,a4,26
    80005078:	078e                	slli	a5,a5,0x3
    8000507a:	953e                	add	a0,a0,a5
    8000507c:	611c                	ld	a5,0(a0)
    8000507e:	c395                	beqz	a5,800050a2 <argfd+0x64>
    return -1;
  if(pfd)
    80005080:	00090463          	beqz	s2,80005088 <argfd+0x4a>
    *pfd = fd;
    80005084:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005088:	4501                	li	a0,0
  if(pf)
    8000508a:	c091                	beqz	s1,8000508e <argfd+0x50>
    *pf = f;
    8000508c:	e09c                	sd	a5,0(s1)
}
    8000508e:	70a2                	ld	ra,40(sp)
    80005090:	7402                	ld	s0,32(sp)
    80005092:	64e2                	ld	s1,24(sp)
    80005094:	6942                	ld	s2,16(sp)
    80005096:	6145                	addi	sp,sp,48
    80005098:	8082                	ret
    return -1;
    8000509a:	557d                	li	a0,-1
    8000509c:	bfcd                	j	8000508e <argfd+0x50>
    return -1;
    8000509e:	557d                	li	a0,-1
    800050a0:	b7fd                	j	8000508e <argfd+0x50>
    800050a2:	557d                	li	a0,-1
    800050a4:	b7ed                	j	8000508e <argfd+0x50>

00000000800050a6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a6:	1101                	addi	sp,sp,-32
    800050a8:	ec06                	sd	ra,24(sp)
    800050aa:	e822                	sd	s0,16(sp)
    800050ac:	e426                	sd	s1,8(sp)
    800050ae:	1000                	addi	s0,sp,32
    800050b0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	976080e7          	jalr	-1674(ra) # 80001a28 <myproc>
    800050ba:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050bc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050c0:	4501                	li	a0,0
    800050c2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050c4:	6398                	ld	a4,0(a5)
    800050c6:	cb19                	beqz	a4,800050dc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c8:	2505                	addiw	a0,a0,1
    800050ca:	07a1                	addi	a5,a5,8
    800050cc:	fed51ce3          	bne	a0,a3,800050c4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050d0:	557d                	li	a0,-1
}
    800050d2:	60e2                	ld	ra,24(sp)
    800050d4:	6442                	ld	s0,16(sp)
    800050d6:	64a2                	ld	s1,8(sp)
    800050d8:	6105                	addi	sp,sp,32
    800050da:	8082                	ret
      p->ofile[fd] = f;
    800050dc:	01a50793          	addi	a5,a0,26
    800050e0:	078e                	slli	a5,a5,0x3
    800050e2:	963e                	add	a2,a2,a5
    800050e4:	e204                	sd	s1,0(a2)
      return fd;
    800050e6:	b7f5                	j	800050d2 <fdalloc+0x2c>

00000000800050e8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e8:	715d                	addi	sp,sp,-80
    800050ea:	e486                	sd	ra,72(sp)
    800050ec:	e0a2                	sd	s0,64(sp)
    800050ee:	fc26                	sd	s1,56(sp)
    800050f0:	f84a                	sd	s2,48(sp)
    800050f2:	f44e                	sd	s3,40(sp)
    800050f4:	f052                	sd	s4,32(sp)
    800050f6:	ec56                	sd	s5,24(sp)
    800050f8:	0880                	addi	s0,sp,80
    800050fa:	89ae                	mv	s3,a1
    800050fc:	8ab2                	mv	s5,a2
    800050fe:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005100:	fb040593          	addi	a1,s0,-80
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	e40080e7          	jalr	-448(ra) # 80003f44 <nameiparent>
    8000510c:	892a                	mv	s2,a0
    8000510e:	12050f63          	beqz	a0,8000524c <create+0x164>
    return 0;

  ilock(dp);
    80005112:	ffffe097          	auipc	ra,0xffffe
    80005116:	664080e7          	jalr	1636(ra) # 80003776 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000511a:	4601                	li	a2,0
    8000511c:	fb040593          	addi	a1,s0,-80
    80005120:	854a                	mv	a0,s2
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	b32080e7          	jalr	-1230(ra) # 80003c54 <dirlookup>
    8000512a:	84aa                	mv	s1,a0
    8000512c:	c921                	beqz	a0,8000517c <create+0x94>
    iunlockput(dp);
    8000512e:	854a                	mv	a0,s2
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	8a8080e7          	jalr	-1880(ra) # 800039d8 <iunlockput>
    ilock(ip);
    80005138:	8526                	mv	a0,s1
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	63c080e7          	jalr	1596(ra) # 80003776 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005142:	2981                	sext.w	s3,s3
    80005144:	4789                	li	a5,2
    80005146:	02f99463          	bne	s3,a5,8000516e <create+0x86>
    8000514a:	0444d783          	lhu	a5,68(s1)
    8000514e:	37f9                	addiw	a5,a5,-2
    80005150:	17c2                	slli	a5,a5,0x30
    80005152:	93c1                	srli	a5,a5,0x30
    80005154:	4705                	li	a4,1
    80005156:	00f76c63          	bltu	a4,a5,8000516e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000515a:	8526                	mv	a0,s1
    8000515c:	60a6                	ld	ra,72(sp)
    8000515e:	6406                	ld	s0,64(sp)
    80005160:	74e2                	ld	s1,56(sp)
    80005162:	7942                	ld	s2,48(sp)
    80005164:	79a2                	ld	s3,40(sp)
    80005166:	7a02                	ld	s4,32(sp)
    80005168:	6ae2                	ld	s5,24(sp)
    8000516a:	6161                	addi	sp,sp,80
    8000516c:	8082                	ret
    iunlockput(ip);
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	868080e7          	jalr	-1944(ra) # 800039d8 <iunlockput>
    return 0;
    80005178:	4481                	li	s1,0
    8000517a:	b7c5                	j	8000515a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000517c:	85ce                	mv	a1,s3
    8000517e:	00092503          	lw	a0,0(s2)
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	45c080e7          	jalr	1116(ra) # 800035de <ialloc>
    8000518a:	84aa                	mv	s1,a0
    8000518c:	c529                	beqz	a0,800051d6 <create+0xee>
  ilock(ip);
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	5e8080e7          	jalr	1512(ra) # 80003776 <ilock>
  ip->major = major;
    80005196:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000519a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000519e:	4785                	li	a5,1
    800051a0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051a4:	8526                	mv	a0,s1
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	506080e7          	jalr	1286(ra) # 800036ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ae:	2981                	sext.w	s3,s3
    800051b0:	4785                	li	a5,1
    800051b2:	02f98a63          	beq	s3,a5,800051e6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051b6:	40d0                	lw	a2,4(s1)
    800051b8:	fb040593          	addi	a1,s0,-80
    800051bc:	854a                	mv	a0,s2
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	ca6080e7          	jalr	-858(ra) # 80003e64 <dirlink>
    800051c6:	06054b63          	bltz	a0,8000523c <create+0x154>
  iunlockput(dp);
    800051ca:	854a                	mv	a0,s2
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	80c080e7          	jalr	-2036(ra) # 800039d8 <iunlockput>
  return ip;
    800051d4:	b759                	j	8000515a <create+0x72>
    panic("create: ialloc");
    800051d6:	00003517          	auipc	a0,0x3
    800051da:	69250513          	addi	a0,a0,1682 # 80008868 <syscall_names+0x2b8>
    800051de:	ffffb097          	auipc	ra,0xffffb
    800051e2:	36a080e7          	jalr	874(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051e6:	04a95783          	lhu	a5,74(s2)
    800051ea:	2785                	addiw	a5,a5,1
    800051ec:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051f0:	854a                	mv	a0,s2
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	4ba080e7          	jalr	1210(ra) # 800036ac <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051fa:	40d0                	lw	a2,4(s1)
    800051fc:	00003597          	auipc	a1,0x3
    80005200:	67c58593          	addi	a1,a1,1660 # 80008878 <syscall_names+0x2c8>
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	c5e080e7          	jalr	-930(ra) # 80003e64 <dirlink>
    8000520e:	00054f63          	bltz	a0,8000522c <create+0x144>
    80005212:	00492603          	lw	a2,4(s2)
    80005216:	00003597          	auipc	a1,0x3
    8000521a:	66a58593          	addi	a1,a1,1642 # 80008880 <syscall_names+0x2d0>
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	c44080e7          	jalr	-956(ra) # 80003e64 <dirlink>
    80005228:	f80557e3          	bgez	a0,800051b6 <create+0xce>
      panic("create dots");
    8000522c:	00003517          	auipc	a0,0x3
    80005230:	65c50513          	addi	a0,a0,1628 # 80008888 <syscall_names+0x2d8>
    80005234:	ffffb097          	auipc	ra,0xffffb
    80005238:	314080e7          	jalr	788(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000523c:	00003517          	auipc	a0,0x3
    80005240:	65c50513          	addi	a0,a0,1628 # 80008898 <syscall_names+0x2e8>
    80005244:	ffffb097          	auipc	ra,0xffffb
    80005248:	304080e7          	jalr	772(ra) # 80000548 <panic>
    return 0;
    8000524c:	84aa                	mv	s1,a0
    8000524e:	b731                	j	8000515a <create+0x72>

0000000080005250 <sys_dup>:
{
    80005250:	7179                	addi	sp,sp,-48
    80005252:	f406                	sd	ra,40(sp)
    80005254:	f022                	sd	s0,32(sp)
    80005256:	ec26                	sd	s1,24(sp)
    80005258:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000525a:	fd840613          	addi	a2,s0,-40
    8000525e:	4581                	li	a1,0
    80005260:	4501                	li	a0,0
    80005262:	00000097          	auipc	ra,0x0
    80005266:	ddc080e7          	jalr	-548(ra) # 8000503e <argfd>
    return -1;
    8000526a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000526c:	02054363          	bltz	a0,80005292 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005270:	fd843503          	ld	a0,-40(s0)
    80005274:	00000097          	auipc	ra,0x0
    80005278:	e32080e7          	jalr	-462(ra) # 800050a6 <fdalloc>
    8000527c:	84aa                	mv	s1,a0
    return -1;
    8000527e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005280:	00054963          	bltz	a0,80005292 <sys_dup+0x42>
  filedup(f);
    80005284:	fd843503          	ld	a0,-40(s0)
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	32a080e7          	jalr	810(ra) # 800045b2 <filedup>
  return fd;
    80005290:	87a6                	mv	a5,s1
}
    80005292:	853e                	mv	a0,a5
    80005294:	70a2                	ld	ra,40(sp)
    80005296:	7402                	ld	s0,32(sp)
    80005298:	64e2                	ld	s1,24(sp)
    8000529a:	6145                	addi	sp,sp,48
    8000529c:	8082                	ret

000000008000529e <sys_read>:
{
    8000529e:	7179                	addi	sp,sp,-48
    800052a0:	f406                	sd	ra,40(sp)
    800052a2:	f022                	sd	s0,32(sp)
    800052a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a6:	fe840613          	addi	a2,s0,-24
    800052aa:	4581                	li	a1,0
    800052ac:	4501                	li	a0,0
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	d90080e7          	jalr	-624(ra) # 8000503e <argfd>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b8:	04054163          	bltz	a0,800052fa <sys_read+0x5c>
    800052bc:	fe440593          	addi	a1,s0,-28
    800052c0:	4509                	li	a0,2
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	87c080e7          	jalr	-1924(ra) # 80002b3e <argint>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052cc:	02054763          	bltz	a0,800052fa <sys_read+0x5c>
    800052d0:	fd840593          	addi	a1,s0,-40
    800052d4:	4505                	li	a0,1
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	88a080e7          	jalr	-1910(ra) # 80002b60 <argaddr>
    return -1;
    800052de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e0:	00054d63          	bltz	a0,800052fa <sys_read+0x5c>
  return fileread(f, p, n);
    800052e4:	fe442603          	lw	a2,-28(s0)
    800052e8:	fd843583          	ld	a1,-40(s0)
    800052ec:	fe843503          	ld	a0,-24(s0)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	44e080e7          	jalr	1102(ra) # 8000473e <fileread>
    800052f8:	87aa                	mv	a5,a0
}
    800052fa:	853e                	mv	a0,a5
    800052fc:	70a2                	ld	ra,40(sp)
    800052fe:	7402                	ld	s0,32(sp)
    80005300:	6145                	addi	sp,sp,48
    80005302:	8082                	ret

0000000080005304 <sys_write>:
{
    80005304:	7179                	addi	sp,sp,-48
    80005306:	f406                	sd	ra,40(sp)
    80005308:	f022                	sd	s0,32(sp)
    8000530a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530c:	fe840613          	addi	a2,s0,-24
    80005310:	4581                	li	a1,0
    80005312:	4501                	li	a0,0
    80005314:	00000097          	auipc	ra,0x0
    80005318:	d2a080e7          	jalr	-726(ra) # 8000503e <argfd>
    return -1;
    8000531c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531e:	04054163          	bltz	a0,80005360 <sys_write+0x5c>
    80005322:	fe440593          	addi	a1,s0,-28
    80005326:	4509                	li	a0,2
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	816080e7          	jalr	-2026(ra) # 80002b3e <argint>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005332:	02054763          	bltz	a0,80005360 <sys_write+0x5c>
    80005336:	fd840593          	addi	a1,s0,-40
    8000533a:	4505                	li	a0,1
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	824080e7          	jalr	-2012(ra) # 80002b60 <argaddr>
    return -1;
    80005344:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005346:	00054d63          	bltz	a0,80005360 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000534a:	fe442603          	lw	a2,-28(s0)
    8000534e:	fd843583          	ld	a1,-40(s0)
    80005352:	fe843503          	ld	a0,-24(s0)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	4aa080e7          	jalr	1194(ra) # 80004800 <filewrite>
    8000535e:	87aa                	mv	a5,a0
}
    80005360:	853e                	mv	a0,a5
    80005362:	70a2                	ld	ra,40(sp)
    80005364:	7402                	ld	s0,32(sp)
    80005366:	6145                	addi	sp,sp,48
    80005368:	8082                	ret

000000008000536a <sys_close>:
{
    8000536a:	1101                	addi	sp,sp,-32
    8000536c:	ec06                	sd	ra,24(sp)
    8000536e:	e822                	sd	s0,16(sp)
    80005370:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005372:	fe040613          	addi	a2,s0,-32
    80005376:	fec40593          	addi	a1,s0,-20
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	cc2080e7          	jalr	-830(ra) # 8000503e <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005386:	02054463          	bltz	a0,800053ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	69e080e7          	jalr	1694(ra) # 80001a28 <myproc>
    80005392:	fec42783          	lw	a5,-20(s0)
    80005396:	07e9                	addi	a5,a5,26
    80005398:	078e                	slli	a5,a5,0x3
    8000539a:	97aa                	add	a5,a5,a0
    8000539c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053a0:	fe043503          	ld	a0,-32(s0)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	260080e7          	jalr	608(ra) # 80004604 <fileclose>
  return 0;
    800053ac:	4781                	li	a5,0
}
    800053ae:	853e                	mv	a0,a5
    800053b0:	60e2                	ld	ra,24(sp)
    800053b2:	6442                	ld	s0,16(sp)
    800053b4:	6105                	addi	sp,sp,32
    800053b6:	8082                	ret

00000000800053b8 <sys_fstat>:
{
    800053b8:	1101                	addi	sp,sp,-32
    800053ba:	ec06                	sd	ra,24(sp)
    800053bc:	e822                	sd	s0,16(sp)
    800053be:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c0:	fe840613          	addi	a2,s0,-24
    800053c4:	4581                	li	a1,0
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	c76080e7          	jalr	-906(ra) # 8000503e <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d2:	02054563          	bltz	a0,800053fc <sys_fstat+0x44>
    800053d6:	fe040593          	addi	a1,s0,-32
    800053da:	4505                	li	a0,1
    800053dc:	ffffd097          	auipc	ra,0xffffd
    800053e0:	784080e7          	jalr	1924(ra) # 80002b60 <argaddr>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e6:	00054b63          	bltz	a0,800053fc <sys_fstat+0x44>
  return filestat(f, st);
    800053ea:	fe043583          	ld	a1,-32(s0)
    800053ee:	fe843503          	ld	a0,-24(s0)
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	2da080e7          	jalr	730(ra) # 800046cc <filestat>
    800053fa:	87aa                	mv	a5,a0
}
    800053fc:	853e                	mv	a0,a5
    800053fe:	60e2                	ld	ra,24(sp)
    80005400:	6442                	ld	s0,16(sp)
    80005402:	6105                	addi	sp,sp,32
    80005404:	8082                	ret

0000000080005406 <sys_link>:
{
    80005406:	7169                	addi	sp,sp,-304
    80005408:	f606                	sd	ra,296(sp)
    8000540a:	f222                	sd	s0,288(sp)
    8000540c:	ee26                	sd	s1,280(sp)
    8000540e:	ea4a                	sd	s2,272(sp)
    80005410:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005412:	08000613          	li	a2,128
    80005416:	ed040593          	addi	a1,s0,-304
    8000541a:	4501                	li	a0,0
    8000541c:	ffffd097          	auipc	ra,0xffffd
    80005420:	766080e7          	jalr	1894(ra) # 80002b82 <argstr>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005426:	10054e63          	bltz	a0,80005542 <sys_link+0x13c>
    8000542a:	08000613          	li	a2,128
    8000542e:	f5040593          	addi	a1,s0,-176
    80005432:	4505                	li	a0,1
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	74e080e7          	jalr	1870(ra) # 80002b82 <argstr>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543e:	10054263          	bltz	a0,80005542 <sys_link+0x13c>
  begin_op();
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	cf0080e7          	jalr	-784(ra) # 80004132 <begin_op>
  if((ip = namei(old)) == 0){
    8000544a:	ed040513          	addi	a0,s0,-304
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	ad8080e7          	jalr	-1320(ra) # 80003f26 <namei>
    80005456:	84aa                	mv	s1,a0
    80005458:	c551                	beqz	a0,800054e4 <sys_link+0xde>
  ilock(ip);
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	31c080e7          	jalr	796(ra) # 80003776 <ilock>
  if(ip->type == T_DIR){
    80005462:	04449703          	lh	a4,68(s1)
    80005466:	4785                	li	a5,1
    80005468:	08f70463          	beq	a4,a5,800054f0 <sys_link+0xea>
  ip->nlink++;
    8000546c:	04a4d783          	lhu	a5,74(s1)
    80005470:	2785                	addiw	a5,a5,1
    80005472:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	234080e7          	jalr	564(ra) # 800036ac <iupdate>
  iunlock(ip);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	3b6080e7          	jalr	950(ra) # 80003838 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000548a:	fd040593          	addi	a1,s0,-48
    8000548e:	f5040513          	addi	a0,s0,-176
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	ab2080e7          	jalr	-1358(ra) # 80003f44 <nameiparent>
    8000549a:	892a                	mv	s2,a0
    8000549c:	c935                	beqz	a0,80005510 <sys_link+0x10a>
  ilock(dp);
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	2d8080e7          	jalr	728(ra) # 80003776 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a6:	00092703          	lw	a4,0(s2)
    800054aa:	409c                	lw	a5,0(s1)
    800054ac:	04f71d63          	bne	a4,a5,80005506 <sys_link+0x100>
    800054b0:	40d0                	lw	a2,4(s1)
    800054b2:	fd040593          	addi	a1,s0,-48
    800054b6:	854a                	mv	a0,s2
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	9ac080e7          	jalr	-1620(ra) # 80003e64 <dirlink>
    800054c0:	04054363          	bltz	a0,80005506 <sys_link+0x100>
  iunlockput(dp);
    800054c4:	854a                	mv	a0,s2
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	512080e7          	jalr	1298(ra) # 800039d8 <iunlockput>
  iput(ip);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	460080e7          	jalr	1120(ra) # 80003930 <iput>
  end_op();
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	cda080e7          	jalr	-806(ra) # 800041b2 <end_op>
  return 0;
    800054e0:	4781                	li	a5,0
    800054e2:	a085                	j	80005542 <sys_link+0x13c>
    end_op();
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	cce080e7          	jalr	-818(ra) # 800041b2 <end_op>
    return -1;
    800054ec:	57fd                	li	a5,-1
    800054ee:	a891                	j	80005542 <sys_link+0x13c>
    iunlockput(ip);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	4e6080e7          	jalr	1254(ra) # 800039d8 <iunlockput>
    end_op();
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	cb8080e7          	jalr	-840(ra) # 800041b2 <end_op>
    return -1;
    80005502:	57fd                	li	a5,-1
    80005504:	a83d                	j	80005542 <sys_link+0x13c>
    iunlockput(dp);
    80005506:	854a                	mv	a0,s2
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	4d0080e7          	jalr	1232(ra) # 800039d8 <iunlockput>
  ilock(ip);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	264080e7          	jalr	612(ra) # 80003776 <ilock>
  ip->nlink--;
    8000551a:	04a4d783          	lhu	a5,74(s1)
    8000551e:	37fd                	addiw	a5,a5,-1
    80005520:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	186080e7          	jalr	390(ra) # 800036ac <iupdate>
  iunlockput(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	4a8080e7          	jalr	1192(ra) # 800039d8 <iunlockput>
  end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	c7a080e7          	jalr	-902(ra) # 800041b2 <end_op>
  return -1;
    80005540:	57fd                	li	a5,-1
}
    80005542:	853e                	mv	a0,a5
    80005544:	70b2                	ld	ra,296(sp)
    80005546:	7412                	ld	s0,288(sp)
    80005548:	64f2                	ld	s1,280(sp)
    8000554a:	6952                	ld	s2,272(sp)
    8000554c:	6155                	addi	sp,sp,304
    8000554e:	8082                	ret

0000000080005550 <sys_unlink>:
{
    80005550:	7151                	addi	sp,sp,-240
    80005552:	f586                	sd	ra,232(sp)
    80005554:	f1a2                	sd	s0,224(sp)
    80005556:	eda6                	sd	s1,216(sp)
    80005558:	e9ca                	sd	s2,208(sp)
    8000555a:	e5ce                	sd	s3,200(sp)
    8000555c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000555e:	08000613          	li	a2,128
    80005562:	f3040593          	addi	a1,s0,-208
    80005566:	4501                	li	a0,0
    80005568:	ffffd097          	auipc	ra,0xffffd
    8000556c:	61a080e7          	jalr	1562(ra) # 80002b82 <argstr>
    80005570:	18054163          	bltz	a0,800056f2 <sys_unlink+0x1a2>
  begin_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	bbe080e7          	jalr	-1090(ra) # 80004132 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000557c:	fb040593          	addi	a1,s0,-80
    80005580:	f3040513          	addi	a0,s0,-208
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	9c0080e7          	jalr	-1600(ra) # 80003f44 <nameiparent>
    8000558c:	84aa                	mv	s1,a0
    8000558e:	c979                	beqz	a0,80005664 <sys_unlink+0x114>
  ilock(dp);
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	1e6080e7          	jalr	486(ra) # 80003776 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005598:	00003597          	auipc	a1,0x3
    8000559c:	2e058593          	addi	a1,a1,736 # 80008878 <syscall_names+0x2c8>
    800055a0:	fb040513          	addi	a0,s0,-80
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	696080e7          	jalr	1686(ra) # 80003c3a <namecmp>
    800055ac:	14050a63          	beqz	a0,80005700 <sys_unlink+0x1b0>
    800055b0:	00003597          	auipc	a1,0x3
    800055b4:	2d058593          	addi	a1,a1,720 # 80008880 <syscall_names+0x2d0>
    800055b8:	fb040513          	addi	a0,s0,-80
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	67e080e7          	jalr	1662(ra) # 80003c3a <namecmp>
    800055c4:	12050e63          	beqz	a0,80005700 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055c8:	f2c40613          	addi	a2,s0,-212
    800055cc:	fb040593          	addi	a1,s0,-80
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	682080e7          	jalr	1666(ra) # 80003c54 <dirlookup>
    800055da:	892a                	mv	s2,a0
    800055dc:	12050263          	beqz	a0,80005700 <sys_unlink+0x1b0>
  ilock(ip);
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	196080e7          	jalr	406(ra) # 80003776 <ilock>
  if(ip->nlink < 1)
    800055e8:	04a91783          	lh	a5,74(s2)
    800055ec:	08f05263          	blez	a5,80005670 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f0:	04491703          	lh	a4,68(s2)
    800055f4:	4785                	li	a5,1
    800055f6:	08f70563          	beq	a4,a5,80005680 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055fa:	4641                	li	a2,16
    800055fc:	4581                	li	a1,0
    800055fe:	fc040513          	addi	a0,s0,-64
    80005602:	ffffb097          	auipc	ra,0xffffb
    80005606:	754080e7          	jalr	1876(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000560a:	4741                	li	a4,16
    8000560c:	f2c42683          	lw	a3,-212(s0)
    80005610:	fc040613          	addi	a2,s0,-64
    80005614:	4581                	li	a1,0
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	508080e7          	jalr	1288(ra) # 80003b20 <writei>
    80005620:	47c1                	li	a5,16
    80005622:	0af51563          	bne	a0,a5,800056cc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005626:	04491703          	lh	a4,68(s2)
    8000562a:	4785                	li	a5,1
    8000562c:	0af70863          	beq	a4,a5,800056dc <sys_unlink+0x18c>
  iunlockput(dp);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	3a6080e7          	jalr	934(ra) # 800039d8 <iunlockput>
  ip->nlink--;
    8000563a:	04a95783          	lhu	a5,74(s2)
    8000563e:	37fd                	addiw	a5,a5,-1
    80005640:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	066080e7          	jalr	102(ra) # 800036ac <iupdate>
  iunlockput(ip);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	388080e7          	jalr	904(ra) # 800039d8 <iunlockput>
  end_op();
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	b5a080e7          	jalr	-1190(ra) # 800041b2 <end_op>
  return 0;
    80005660:	4501                	li	a0,0
    80005662:	a84d                	j	80005714 <sys_unlink+0x1c4>
    end_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	b4e080e7          	jalr	-1202(ra) # 800041b2 <end_op>
    return -1;
    8000566c:	557d                	li	a0,-1
    8000566e:	a05d                	j	80005714 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005670:	00003517          	auipc	a0,0x3
    80005674:	23850513          	addi	a0,a0,568 # 800088a8 <syscall_names+0x2f8>
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	ed0080e7          	jalr	-304(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005680:	04c92703          	lw	a4,76(s2)
    80005684:	02000793          	li	a5,32
    80005688:	f6e7f9e3          	bgeu	a5,a4,800055fa <sys_unlink+0xaa>
    8000568c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005690:	4741                	li	a4,16
    80005692:	86ce                	mv	a3,s3
    80005694:	f1840613          	addi	a2,s0,-232
    80005698:	4581                	li	a1,0
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	38e080e7          	jalr	910(ra) # 80003a2a <readi>
    800056a4:	47c1                	li	a5,16
    800056a6:	00f51b63          	bne	a0,a5,800056bc <sys_unlink+0x16c>
    if(de.inum != 0)
    800056aa:	f1845783          	lhu	a5,-232(s0)
    800056ae:	e7a1                	bnez	a5,800056f6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b0:	29c1                	addiw	s3,s3,16
    800056b2:	04c92783          	lw	a5,76(s2)
    800056b6:	fcf9ede3          	bltu	s3,a5,80005690 <sys_unlink+0x140>
    800056ba:	b781                	j	800055fa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056bc:	00003517          	auipc	a0,0x3
    800056c0:	20450513          	addi	a0,a0,516 # 800088c0 <syscall_names+0x310>
    800056c4:	ffffb097          	auipc	ra,0xffffb
    800056c8:	e84080e7          	jalr	-380(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056cc:	00003517          	auipc	a0,0x3
    800056d0:	20c50513          	addi	a0,a0,524 # 800088d8 <syscall_names+0x328>
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	e74080e7          	jalr	-396(ra) # 80000548 <panic>
    dp->nlink--;
    800056dc:	04a4d783          	lhu	a5,74(s1)
    800056e0:	37fd                	addiw	a5,a5,-1
    800056e2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	fc4080e7          	jalr	-60(ra) # 800036ac <iupdate>
    800056f0:	b781                	j	80005630 <sys_unlink+0xe0>
    return -1;
    800056f2:	557d                	li	a0,-1
    800056f4:	a005                	j	80005714 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f6:	854a                	mv	a0,s2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	2e0080e7          	jalr	736(ra) # 800039d8 <iunlockput>
  iunlockput(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	2d6080e7          	jalr	726(ra) # 800039d8 <iunlockput>
  end_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	aa8080e7          	jalr	-1368(ra) # 800041b2 <end_op>
  return -1;
    80005712:	557d                	li	a0,-1
}
    80005714:	70ae                	ld	ra,232(sp)
    80005716:	740e                	ld	s0,224(sp)
    80005718:	64ee                	ld	s1,216(sp)
    8000571a:	694e                	ld	s2,208(sp)
    8000571c:	69ae                	ld	s3,200(sp)
    8000571e:	616d                	addi	sp,sp,240
    80005720:	8082                	ret

0000000080005722 <sys_open>:

uint64
sys_open(void)
{
    80005722:	7131                	addi	sp,sp,-192
    80005724:	fd06                	sd	ra,184(sp)
    80005726:	f922                	sd	s0,176(sp)
    80005728:	f526                	sd	s1,168(sp)
    8000572a:	f14a                	sd	s2,160(sp)
    8000572c:	ed4e                	sd	s3,152(sp)
    8000572e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005730:	08000613          	li	a2,128
    80005734:	f5040593          	addi	a1,s0,-176
    80005738:	4501                	li	a0,0
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	448080e7          	jalr	1096(ra) # 80002b82 <argstr>
    return -1;
    80005742:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005744:	0c054163          	bltz	a0,80005806 <sys_open+0xe4>
    80005748:	f4c40593          	addi	a1,s0,-180
    8000574c:	4505                	li	a0,1
    8000574e:	ffffd097          	auipc	ra,0xffffd
    80005752:	3f0080e7          	jalr	1008(ra) # 80002b3e <argint>
    80005756:	0a054863          	bltz	a0,80005806 <sys_open+0xe4>

  begin_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	9d8080e7          	jalr	-1576(ra) # 80004132 <begin_op>

  if(omode & O_CREATE){
    80005762:	f4c42783          	lw	a5,-180(s0)
    80005766:	2007f793          	andi	a5,a5,512
    8000576a:	cbdd                	beqz	a5,80005820 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000576c:	4681                	li	a3,0
    8000576e:	4601                	li	a2,0
    80005770:	4589                	li	a1,2
    80005772:	f5040513          	addi	a0,s0,-176
    80005776:	00000097          	auipc	ra,0x0
    8000577a:	972080e7          	jalr	-1678(ra) # 800050e8 <create>
    8000577e:	892a                	mv	s2,a0
    if(ip == 0){
    80005780:	c959                	beqz	a0,80005816 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005782:	04491703          	lh	a4,68(s2)
    80005786:	478d                	li	a5,3
    80005788:	00f71763          	bne	a4,a5,80005796 <sys_open+0x74>
    8000578c:	04695703          	lhu	a4,70(s2)
    80005790:	47a5                	li	a5,9
    80005792:	0ce7ec63          	bltu	a5,a4,8000586a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	db2080e7          	jalr	-590(ra) # 80004548 <filealloc>
    8000579e:	89aa                	mv	s3,a0
    800057a0:	10050263          	beqz	a0,800058a4 <sys_open+0x182>
    800057a4:	00000097          	auipc	ra,0x0
    800057a8:	902080e7          	jalr	-1790(ra) # 800050a6 <fdalloc>
    800057ac:	84aa                	mv	s1,a0
    800057ae:	0e054663          	bltz	a0,8000589a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b2:	04491703          	lh	a4,68(s2)
    800057b6:	478d                	li	a5,3
    800057b8:	0cf70463          	beq	a4,a5,80005880 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057bc:	4789                	li	a5,2
    800057be:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057c2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057ca:	f4c42783          	lw	a5,-180(s0)
    800057ce:	0017c713          	xori	a4,a5,1
    800057d2:	8b05                	andi	a4,a4,1
    800057d4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057d8:	0037f713          	andi	a4,a5,3
    800057dc:	00e03733          	snez	a4,a4
    800057e0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e4:	4007f793          	andi	a5,a5,1024
    800057e8:	c791                	beqz	a5,800057f4 <sys_open+0xd2>
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	4789                	li	a5,2
    800057f0:	08f70f63          	beq	a4,a5,8000588e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057f4:	854a                	mv	a0,s2
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	042080e7          	jalr	66(ra) # 80003838 <iunlock>
  end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	9b4080e7          	jalr	-1612(ra) # 800041b2 <end_op>

  return fd;
}
    80005806:	8526                	mv	a0,s1
    80005808:	70ea                	ld	ra,184(sp)
    8000580a:	744a                	ld	s0,176(sp)
    8000580c:	74aa                	ld	s1,168(sp)
    8000580e:	790a                	ld	s2,160(sp)
    80005810:	69ea                	ld	s3,152(sp)
    80005812:	6129                	addi	sp,sp,192
    80005814:	8082                	ret
      end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	99c080e7          	jalr	-1636(ra) # 800041b2 <end_op>
      return -1;
    8000581e:	b7e5                	j	80005806 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005820:	f5040513          	addi	a0,s0,-176
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	702080e7          	jalr	1794(ra) # 80003f26 <namei>
    8000582c:	892a                	mv	s2,a0
    8000582e:	c905                	beqz	a0,8000585e <sys_open+0x13c>
    ilock(ip);
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	f46080e7          	jalr	-186(ra) # 80003776 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005838:	04491703          	lh	a4,68(s2)
    8000583c:	4785                	li	a5,1
    8000583e:	f4f712e3          	bne	a4,a5,80005782 <sys_open+0x60>
    80005842:	f4c42783          	lw	a5,-180(s0)
    80005846:	dba1                	beqz	a5,80005796 <sys_open+0x74>
      iunlockput(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	18e080e7          	jalr	398(ra) # 800039d8 <iunlockput>
      end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	960080e7          	jalr	-1696(ra) # 800041b2 <end_op>
      return -1;
    8000585a:	54fd                	li	s1,-1
    8000585c:	b76d                	j	80005806 <sys_open+0xe4>
      end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	954080e7          	jalr	-1708(ra) # 800041b2 <end_op>
      return -1;
    80005866:	54fd                	li	s1,-1
    80005868:	bf79                	j	80005806 <sys_open+0xe4>
    iunlockput(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	16c080e7          	jalr	364(ra) # 800039d8 <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	93e080e7          	jalr	-1730(ra) # 800041b2 <end_op>
    return -1;
    8000587c:	54fd                	li	s1,-1
    8000587e:	b761                	j	80005806 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005880:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005884:	04691783          	lh	a5,70(s2)
    80005888:	02f99223          	sh	a5,36(s3)
    8000588c:	bf2d                	j	800057c6 <sys_open+0xa4>
    itrunc(ip);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	ff4080e7          	jalr	-12(ra) # 80003884 <itrunc>
    80005898:	bfb1                	j	800057f4 <sys_open+0xd2>
      fileclose(f);
    8000589a:	854e                	mv	a0,s3
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	d68080e7          	jalr	-664(ra) # 80004604 <fileclose>
    iunlockput(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	132080e7          	jalr	306(ra) # 800039d8 <iunlockput>
    end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	904080e7          	jalr	-1788(ra) # 800041b2 <end_op>
    return -1;
    800058b6:	54fd                	li	s1,-1
    800058b8:	b7b9                	j	80005806 <sys_open+0xe4>

00000000800058ba <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058ba:	7175                	addi	sp,sp,-144
    800058bc:	e506                	sd	ra,136(sp)
    800058be:	e122                	sd	s0,128(sp)
    800058c0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	870080e7          	jalr	-1936(ra) # 80004132 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058ca:	08000613          	li	a2,128
    800058ce:	f7040593          	addi	a1,s0,-144
    800058d2:	4501                	li	a0,0
    800058d4:	ffffd097          	auipc	ra,0xffffd
    800058d8:	2ae080e7          	jalr	686(ra) # 80002b82 <argstr>
    800058dc:	02054963          	bltz	a0,8000590e <sys_mkdir+0x54>
    800058e0:	4681                	li	a3,0
    800058e2:	4601                	li	a2,0
    800058e4:	4585                	li	a1,1
    800058e6:	f7040513          	addi	a0,s0,-144
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	7fe080e7          	jalr	2046(ra) # 800050e8 <create>
    800058f2:	cd11                	beqz	a0,8000590e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	0e4080e7          	jalr	228(ra) # 800039d8 <iunlockput>
  end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	8b6080e7          	jalr	-1866(ra) # 800041b2 <end_op>
  return 0;
    80005904:	4501                	li	a0,0
}
    80005906:	60aa                	ld	ra,136(sp)
    80005908:	640a                	ld	s0,128(sp)
    8000590a:	6149                	addi	sp,sp,144
    8000590c:	8082                	ret
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	8a4080e7          	jalr	-1884(ra) # 800041b2 <end_op>
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	b7fd                	j	80005906 <sys_mkdir+0x4c>

000000008000591a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000591a:	7135                	addi	sp,sp,-160
    8000591c:	ed06                	sd	ra,152(sp)
    8000591e:	e922                	sd	s0,144(sp)
    80005920:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	810080e7          	jalr	-2032(ra) # 80004132 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592a:	08000613          	li	a2,128
    8000592e:	f7040593          	addi	a1,s0,-144
    80005932:	4501                	li	a0,0
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	24e080e7          	jalr	590(ra) # 80002b82 <argstr>
    8000593c:	04054a63          	bltz	a0,80005990 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005940:	f6c40593          	addi	a1,s0,-148
    80005944:	4505                	li	a0,1
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	1f8080e7          	jalr	504(ra) # 80002b3e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594e:	04054163          	bltz	a0,80005990 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005952:	f6840593          	addi	a1,s0,-152
    80005956:	4509                	li	a0,2
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	1e6080e7          	jalr	486(ra) # 80002b3e <argint>
     argint(1, &major) < 0 ||
    80005960:	02054863          	bltz	a0,80005990 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005964:	f6841683          	lh	a3,-152(s0)
    80005968:	f6c41603          	lh	a2,-148(s0)
    8000596c:	458d                	li	a1,3
    8000596e:	f7040513          	addi	a0,s0,-144
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	776080e7          	jalr	1910(ra) # 800050e8 <create>
     argint(2, &minor) < 0 ||
    8000597a:	c919                	beqz	a0,80005990 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	05c080e7          	jalr	92(ra) # 800039d8 <iunlockput>
  end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	82e080e7          	jalr	-2002(ra) # 800041b2 <end_op>
  return 0;
    8000598c:	4501                	li	a0,0
    8000598e:	a031                	j	8000599a <sys_mknod+0x80>
    end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	822080e7          	jalr	-2014(ra) # 800041b2 <end_op>
    return -1;
    80005998:	557d                	li	a0,-1
}
    8000599a:	60ea                	ld	ra,152(sp)
    8000599c:	644a                	ld	s0,144(sp)
    8000599e:	610d                	addi	sp,sp,160
    800059a0:	8082                	ret

00000000800059a2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a2:	7135                	addi	sp,sp,-160
    800059a4:	ed06                	sd	ra,152(sp)
    800059a6:	e922                	sd	s0,144(sp)
    800059a8:	e526                	sd	s1,136(sp)
    800059aa:	e14a                	sd	s2,128(sp)
    800059ac:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059ae:	ffffc097          	auipc	ra,0xffffc
    800059b2:	07a080e7          	jalr	122(ra) # 80001a28 <myproc>
    800059b6:	892a                	mv	s2,a0
  
  begin_op();
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	77a080e7          	jalr	1914(ra) # 80004132 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c0:	08000613          	li	a2,128
    800059c4:	f6040593          	addi	a1,s0,-160
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	1b8080e7          	jalr	440(ra) # 80002b82 <argstr>
    800059d2:	04054b63          	bltz	a0,80005a28 <sys_chdir+0x86>
    800059d6:	f6040513          	addi	a0,s0,-160
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	54c080e7          	jalr	1356(ra) # 80003f26 <namei>
    800059e2:	84aa                	mv	s1,a0
    800059e4:	c131                	beqz	a0,80005a28 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	d90080e7          	jalr	-624(ra) # 80003776 <ilock>
  if(ip->type != T_DIR){
    800059ee:	04449703          	lh	a4,68(s1)
    800059f2:	4785                	li	a5,1
    800059f4:	04f71063          	bne	a4,a5,80005a34 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	e3e080e7          	jalr	-450(ra) # 80003838 <iunlock>
  iput(p->cwd);
    80005a02:	15093503          	ld	a0,336(s2)
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	f2a080e7          	jalr	-214(ra) # 80003930 <iput>
  end_op();
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	7a4080e7          	jalr	1956(ra) # 800041b2 <end_op>
  p->cwd = ip;
    80005a16:	14993823          	sd	s1,336(s2)
  return 0;
    80005a1a:	4501                	li	a0,0
}
    80005a1c:	60ea                	ld	ra,152(sp)
    80005a1e:	644a                	ld	s0,144(sp)
    80005a20:	64aa                	ld	s1,136(sp)
    80005a22:	690a                	ld	s2,128(sp)
    80005a24:	610d                	addi	sp,sp,160
    80005a26:	8082                	ret
    end_op();
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	78a080e7          	jalr	1930(ra) # 800041b2 <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7ed                	j	80005a1c <sys_chdir+0x7a>
    iunlockput(ip);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	fa2080e7          	jalr	-94(ra) # 800039d8 <iunlockput>
    end_op();
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	774080e7          	jalr	1908(ra) # 800041b2 <end_op>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	bfd1                	j	80005a1c <sys_chdir+0x7a>

0000000080005a4a <sys_exec>:

uint64
sys_exec(void)
{
    80005a4a:	7145                	addi	sp,sp,-464
    80005a4c:	e786                	sd	ra,456(sp)
    80005a4e:	e3a2                	sd	s0,448(sp)
    80005a50:	ff26                	sd	s1,440(sp)
    80005a52:	fb4a                	sd	s2,432(sp)
    80005a54:	f74e                	sd	s3,424(sp)
    80005a56:	f352                	sd	s4,416(sp)
    80005a58:	ef56                	sd	s5,408(sp)
    80005a5a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a5c:	08000613          	li	a2,128
    80005a60:	f4040593          	addi	a1,s0,-192
    80005a64:	4501                	li	a0,0
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	11c080e7          	jalr	284(ra) # 80002b82 <argstr>
    return -1;
    80005a6e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a70:	0c054a63          	bltz	a0,80005b44 <sys_exec+0xfa>
    80005a74:	e3840593          	addi	a1,s0,-456
    80005a78:	4505                	li	a0,1
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	0e6080e7          	jalr	230(ra) # 80002b60 <argaddr>
    80005a82:	0c054163          	bltz	a0,80005b44 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a86:	10000613          	li	a2,256
    80005a8a:	4581                	li	a1,0
    80005a8c:	e4040513          	addi	a0,s0,-448
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	2c6080e7          	jalr	710(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a98:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a9c:	89a6                	mv	s3,s1
    80005a9e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa0:	02000a13          	li	s4,32
    80005aa4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa8:	00391513          	slli	a0,s2,0x3
    80005aac:	e3040593          	addi	a1,s0,-464
    80005ab0:	e3843783          	ld	a5,-456(s0)
    80005ab4:	953e                	add	a0,a0,a5
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	fee080e7          	jalr	-18(ra) # 80002aa4 <fetchaddr>
    80005abe:	02054a63          	bltz	a0,80005af2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ac2:	e3043783          	ld	a5,-464(s0)
    80005ac6:	c3b9                	beqz	a5,80005b0c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	058080e7          	jalr	88(ra) # 80000b20 <kalloc>
    80005ad0:	85aa                	mv	a1,a0
    80005ad2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad6:	cd11                	beqz	a0,80005af2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad8:	6605                	lui	a2,0x1
    80005ada:	e3043503          	ld	a0,-464(s0)
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	018080e7          	jalr	24(ra) # 80002af6 <fetchstr>
    80005ae6:	00054663          	bltz	a0,80005af2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aea:	0905                	addi	s2,s2,1
    80005aec:	09a1                	addi	s3,s3,8
    80005aee:	fb491be3          	bne	s2,s4,80005aa4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af2:	10048913          	addi	s2,s1,256
    80005af6:	6088                	ld	a0,0(s1)
    80005af8:	c529                	beqz	a0,80005b42 <sys_exec+0xf8>
    kfree(argv[i]);
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	f2a080e7          	jalr	-214(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b02:	04a1                	addi	s1,s1,8
    80005b04:	ff2499e3          	bne	s1,s2,80005af6 <sys_exec+0xac>
  return -1;
    80005b08:	597d                	li	s2,-1
    80005b0a:	a82d                	j	80005b44 <sys_exec+0xfa>
      argv[i] = 0;
    80005b0c:	0a8e                	slli	s5,s5,0x3
    80005b0e:	fc040793          	addi	a5,s0,-64
    80005b12:	9abe                	add	s5,s5,a5
    80005b14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b18:	e4040593          	addi	a1,s0,-448
    80005b1c:	f4040513          	addi	a0,s0,-192
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	194080e7          	jalr	404(ra) # 80004cb4 <exec>
    80005b28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	10048993          	addi	s3,s1,256
    80005b2e:	6088                	ld	a0,0(s1)
    80005b30:	c911                	beqz	a0,80005b44 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	ef2080e7          	jalr	-270(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3a:	04a1                	addi	s1,s1,8
    80005b3c:	ff3499e3          	bne	s1,s3,80005b2e <sys_exec+0xe4>
    80005b40:	a011                	j	80005b44 <sys_exec+0xfa>
  return -1;
    80005b42:	597d                	li	s2,-1
}
    80005b44:	854a                	mv	a0,s2
    80005b46:	60be                	ld	ra,456(sp)
    80005b48:	641e                	ld	s0,448(sp)
    80005b4a:	74fa                	ld	s1,440(sp)
    80005b4c:	795a                	ld	s2,432(sp)
    80005b4e:	79ba                	ld	s3,424(sp)
    80005b50:	7a1a                	ld	s4,416(sp)
    80005b52:	6afa                	ld	s5,408(sp)
    80005b54:	6179                	addi	sp,sp,464
    80005b56:	8082                	ret

0000000080005b58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b58:	7139                	addi	sp,sp,-64
    80005b5a:	fc06                	sd	ra,56(sp)
    80005b5c:	f822                	sd	s0,48(sp)
    80005b5e:	f426                	sd	s1,40(sp)
    80005b60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	ec6080e7          	jalr	-314(ra) # 80001a28 <myproc>
    80005b6a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b6c:	fd840593          	addi	a1,s0,-40
    80005b70:	4501                	li	a0,0
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	fee080e7          	jalr	-18(ra) # 80002b60 <argaddr>
    return -1;
    80005b7a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b7c:	0e054063          	bltz	a0,80005c5c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b80:	fc840593          	addi	a1,s0,-56
    80005b84:	fd040513          	addi	a0,s0,-48
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	dd2080e7          	jalr	-558(ra) # 8000495a <pipealloc>
    return -1;
    80005b90:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b92:	0c054563          	bltz	a0,80005c5c <sys_pipe+0x104>
  fd0 = -1;
    80005b96:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b9a:	fd043503          	ld	a0,-48(s0)
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	508080e7          	jalr	1288(ra) # 800050a6 <fdalloc>
    80005ba6:	fca42223          	sw	a0,-60(s0)
    80005baa:	08054c63          	bltz	a0,80005c42 <sys_pipe+0xea>
    80005bae:	fc843503          	ld	a0,-56(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	4f4080e7          	jalr	1268(ra) # 800050a6 <fdalloc>
    80005bba:	fca42023          	sw	a0,-64(s0)
    80005bbe:	06054863          	bltz	a0,80005c2e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc2:	4691                	li	a3,4
    80005bc4:	fc440613          	addi	a2,s0,-60
    80005bc8:	fd843583          	ld	a1,-40(s0)
    80005bcc:	68a8                	ld	a0,80(s1)
    80005bce:	ffffc097          	auipc	ra,0xffffc
    80005bd2:	b4e080e7          	jalr	-1202(ra) # 8000171c <copyout>
    80005bd6:	02054063          	bltz	a0,80005bf6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bda:	4691                	li	a3,4
    80005bdc:	fc040613          	addi	a2,s0,-64
    80005be0:	fd843583          	ld	a1,-40(s0)
    80005be4:	0591                	addi	a1,a1,4
    80005be6:	68a8                	ld	a0,80(s1)
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	b34080e7          	jalr	-1228(ra) # 8000171c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf2:	06055563          	bgez	a0,80005c5c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf6:	fc442783          	lw	a5,-60(s0)
    80005bfa:	07e9                	addi	a5,a5,26
    80005bfc:	078e                	slli	a5,a5,0x3
    80005bfe:	97a6                	add	a5,a5,s1
    80005c00:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c04:	fc042503          	lw	a0,-64(s0)
    80005c08:	0569                	addi	a0,a0,26
    80005c0a:	050e                	slli	a0,a0,0x3
    80005c0c:	9526                	add	a0,a0,s1
    80005c0e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c12:	fd043503          	ld	a0,-48(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	9ee080e7          	jalr	-1554(ra) # 80004604 <fileclose>
    fileclose(wf);
    80005c1e:	fc843503          	ld	a0,-56(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	9e2080e7          	jalr	-1566(ra) # 80004604 <fileclose>
    return -1;
    80005c2a:	57fd                	li	a5,-1
    80005c2c:	a805                	j	80005c5c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c2e:	fc442783          	lw	a5,-60(s0)
    80005c32:	0007c863          	bltz	a5,80005c42 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c36:	01a78513          	addi	a0,a5,26
    80005c3a:	050e                	slli	a0,a0,0x3
    80005c3c:	9526                	add	a0,a0,s1
    80005c3e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c42:	fd043503          	ld	a0,-48(s0)
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	9be080e7          	jalr	-1602(ra) # 80004604 <fileclose>
    fileclose(wf);
    80005c4e:	fc843503          	ld	a0,-56(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	9b2080e7          	jalr	-1614(ra) # 80004604 <fileclose>
    return -1;
    80005c5a:	57fd                	li	a5,-1
}
    80005c5c:	853e                	mv	a0,a5
    80005c5e:	70e2                	ld	ra,56(sp)
    80005c60:	7442                	ld	s0,48(sp)
    80005c62:	74a2                	ld	s1,40(sp)
    80005c64:	6121                	addi	sp,sp,64
    80005c66:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	cc1fc0ef          	jal	ra,80002970 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	710c                	ld	a1,32(a0)
    80005d0c:	7510                	ld	a2,40(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	cb4080e7          	jalr	-844(ra) # 800019fc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	c7c080e7          	jalr	-900(ra) # 800019fc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c54080e7          	jalr	-940(ra) # 800019fc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	04a7cc63          	blt	a5,a0,80005e28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005dd4:	0001d797          	auipc	a5,0x1d
    80005dd8:	22c78793          	addi	a5,a5,556 # 80023000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	eba1                	bnez	a5,80005e38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dea:	00451713          	slli	a4,a0,0x4
    80005dee:	0001f797          	auipc	a5,0x1f
    80005df2:	2127b783          	ld	a5,530(a5) # 80025000 <disk+0x2000>
    80005df6:	97ba                	add	a5,a5,a4
    80005df8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dfc:	0001d797          	auipc	a5,0x1d
    80005e00:	20478793          	addi	a5,a5,516 # 80023000 <disk>
    80005e04:	97aa                	add	a5,a5,a0
    80005e06:	6509                	lui	a0,0x2
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	4785                	li	a5,1
    80005e0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e10:	0001f517          	auipc	a0,0x1f
    80005e14:	20850513          	addi	a0,a0,520 # 80025018 <disk+0x2018>
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	5aa080e7          	jalr	1450(ra) # 800023c2 <wakeup>
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	ac050513          	addi	a0,a0,-1344 # 800088e8 <syscall_names+0x338>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	718080e7          	jalr	1816(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	ac850513          	addi	a0,a0,-1336 # 80008900 <syscall_names+0x350>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	708080e7          	jalr	1800(ra) # 80000548 <panic>

0000000080005e48 <virtio_disk_init>:
{
    80005e48:	1101                	addi	sp,sp,-32
    80005e4a:	ec06                	sd	ra,24(sp)
    80005e4c:	e822                	sd	s0,16(sp)
    80005e4e:	e426                	sd	s1,8(sp)
    80005e50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e52:	00003597          	auipc	a1,0x3
    80005e56:	ac658593          	addi	a1,a1,-1338 # 80008918 <syscall_names+0x368>
    80005e5a:	0001f517          	auipc	a0,0x1f
    80005e5e:	24e50513          	addi	a0,a0,590 # 800250a8 <disk+0x20a8>
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	d68080e7          	jalr	-664(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	4398                	lw	a4,0(a5)
    80005e70:	2701                	sext.w	a4,a4
    80005e72:	747277b7          	lui	a5,0x74727
    80005e76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e7a:	0ef71163          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	43dc                	lw	a5,4(a5)
    80005e84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e86:	4705                	li	a4,1
    80005e88:	0ce79a63          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	479c                	lw	a5,8(a5)
    80005e92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e94:	4709                	li	a4,2
    80005e96:	0ce79363          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	47d8                	lw	a4,12(a5)
    80005ea0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea2:	554d47b7          	lui	a5,0x554d4
    80005ea6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eaa:	0af71963          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	4705                	li	a4,1
    80005eb4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb6:	470d                	li	a4,3
    80005eb8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ebc:	c7ffe737          	lui	a4,0xc7ffe
    80005ec0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ec4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec6:	2701                	sext.w	a4,a4
    80005ec8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	472d                	li	a4,11
    80005ecc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	473d                	li	a4,15
    80005ed0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ed2:	6705                	lui	a4,0x1
    80005ed4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eda:	5bdc                	lw	a5,52(a5)
    80005edc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ede:	c7d9                	beqz	a5,80005f6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ee0:	471d                	li	a4,7
    80005ee2:	08f77d63          	bgeu	a4,a5,80005f7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ee6:	100014b7          	lui	s1,0x10001
    80005eea:	47a1                	li	a5,8
    80005eec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eee:	6609                	lui	a2,0x2
    80005ef0:	4581                	li	a1,0
    80005ef2:	0001d517          	auipc	a0,0x1d
    80005ef6:	10e50513          	addi	a0,a0,270 # 80023000 <disk>
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e5c080e7          	jalr	-420(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f02:	0001d717          	auipc	a4,0x1d
    80005f06:	0fe70713          	addi	a4,a4,254 # 80023000 <disk>
    80005f0a:	00c75793          	srli	a5,a4,0xc
    80005f0e:	2781                	sext.w	a5,a5
    80005f10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f12:	0001f797          	auipc	a5,0x1f
    80005f16:	0ee78793          	addi	a5,a5,238 # 80025000 <disk+0x2000>
    80005f1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f1c:	0001d717          	auipc	a4,0x1d
    80005f20:	16470713          	addi	a4,a4,356 # 80023080 <disk+0x80>
    80005f24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f26:	0001e717          	auipc	a4,0x1e
    80005f2a:	0da70713          	addi	a4,a4,218 # 80024000 <disk+0x1000>
    80005f2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f30:	4705                	li	a4,1
    80005f32:	00e78c23          	sb	a4,24(a5)
    80005f36:	00e78ca3          	sb	a4,25(a5)
    80005f3a:	00e78d23          	sb	a4,26(a5)
    80005f3e:	00e78da3          	sb	a4,27(a5)
    80005f42:	00e78e23          	sb	a4,28(a5)
    80005f46:	00e78ea3          	sb	a4,29(a5)
    80005f4a:	00e78f23          	sb	a4,30(a5)
    80005f4e:	00e78fa3          	sb	a4,31(a5)
}
    80005f52:	60e2                	ld	ra,24(sp)
    80005f54:	6442                	ld	s0,16(sp)
    80005f56:	64a2                	ld	s1,8(sp)
    80005f58:	6105                	addi	sp,sp,32
    80005f5a:	8082                	ret
    panic("could not find virtio disk");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	9cc50513          	addi	a0,a0,-1588 # 80008928 <syscall_names+0x378>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f6c:	00003517          	auipc	a0,0x3
    80005f70:	9dc50513          	addi	a0,a0,-1572 # 80008948 <syscall_names+0x398>
    80005f74:	ffffa097          	auipc	ra,0xffffa
    80005f78:	5d4080e7          	jalr	1492(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	9ec50513          	addi	a0,a0,-1556 # 80008968 <syscall_names+0x3b8>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	5c4080e7          	jalr	1476(ra) # 80000548 <panic>

0000000080005f8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f8c:	7119                	addi	sp,sp,-128
    80005f8e:	fc86                	sd	ra,120(sp)
    80005f90:	f8a2                	sd	s0,112(sp)
    80005f92:	f4a6                	sd	s1,104(sp)
    80005f94:	f0ca                	sd	s2,96(sp)
    80005f96:	ecce                	sd	s3,88(sp)
    80005f98:	e8d2                	sd	s4,80(sp)
    80005f9a:	e4d6                	sd	s5,72(sp)
    80005f9c:	e0da                	sd	s6,64(sp)
    80005f9e:	fc5e                	sd	s7,56(sp)
    80005fa0:	f862                	sd	s8,48(sp)
    80005fa2:	f466                	sd	s9,40(sp)
    80005fa4:	f06a                	sd	s10,32(sp)
    80005fa6:	0100                	addi	s0,sp,128
    80005fa8:	892a                	mv	s2,a0
    80005faa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fac:	00c52c83          	lw	s9,12(a0)
    80005fb0:	001c9c9b          	slliw	s9,s9,0x1
    80005fb4:	1c82                	slli	s9,s9,0x20
    80005fb6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fba:	0001f517          	auipc	a0,0x1f
    80005fbe:	0ee50513          	addi	a0,a0,238 # 800250a8 <disk+0x20a8>
    80005fc2:	ffffb097          	auipc	ra,0xffffb
    80005fc6:	c98080e7          	jalr	-872(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    80005fca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fcc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fce:	0001db97          	auipc	s7,0x1d
    80005fd2:	032b8b93          	addi	s7,s7,50 # 80023000 <disk>
    80005fd6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fd8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fda:	8a4e                	mv	s4,s3
    80005fdc:	a051                	j	80006060 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fde:	00fb86b3          	add	a3,s7,a5
    80005fe2:	96da                	add	a3,a3,s6
    80005fe4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fe8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fea:	0207c563          	bltz	a5,80006014 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fee:	2485                	addiw	s1,s1,1
    80005ff0:	0711                	addi	a4,a4,4
    80005ff2:	23548d63          	beq	s1,s5,8000622c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005ff6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ff8:	0001f697          	auipc	a3,0x1f
    80005ffc:	02068693          	addi	a3,a3,32 # 80025018 <disk+0x2018>
    80006000:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006002:	0006c583          	lbu	a1,0(a3)
    80006006:	fde1                	bnez	a1,80005fde <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006008:	2785                	addiw	a5,a5,1
    8000600a:	0685                	addi	a3,a3,1
    8000600c:	ff879be3          	bne	a5,s8,80006002 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006010:	57fd                	li	a5,-1
    80006012:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006014:	02905a63          	blez	s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006018:	f9042503          	lw	a0,-112(s0)
    8000601c:	00000097          	auipc	ra,0x0
    80006020:	daa080e7          	jalr	-598(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006024:	4785                	li	a5,1
    80006026:	0297d163          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000602a:	f9442503          	lw	a0,-108(s0)
    8000602e:	00000097          	auipc	ra,0x0
    80006032:	d98080e7          	jalr	-616(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006036:	4789                	li	a5,2
    80006038:	0097d863          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000603c:	f9842503          	lw	a0,-104(s0)
    80006040:	00000097          	auipc	ra,0x0
    80006044:	d86080e7          	jalr	-634(ra) # 80005dc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006048:	0001f597          	auipc	a1,0x1f
    8000604c:	06058593          	addi	a1,a1,96 # 800250a8 <disk+0x20a8>
    80006050:	0001f517          	auipc	a0,0x1f
    80006054:	fc850513          	addi	a0,a0,-56 # 80025018 <disk+0x2018>
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	1e4080e7          	jalr	484(ra) # 8000223c <sleep>
  for(int i = 0; i < 3; i++){
    80006060:	f9040713          	addi	a4,s0,-112
    80006064:	84ce                	mv	s1,s3
    80006066:	bf41                	j	80005ff6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006068:	4785                	li	a5,1
    8000606a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000606e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006072:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006076:	f9042983          	lw	s3,-112(s0)
    8000607a:	00499493          	slli	s1,s3,0x4
    8000607e:	0001fa17          	auipc	s4,0x1f
    80006082:	f82a0a13          	addi	s4,s4,-126 # 80025000 <disk+0x2000>
    80006086:	000a3a83          	ld	s5,0(s4)
    8000608a:	9aa6                	add	s5,s5,s1
    8000608c:	f8040513          	addi	a0,s0,-128
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	09a080e7          	jalr	154(ra) # 8000112a <kvmpa>
    80006098:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000609c:	000a3783          	ld	a5,0(s4)
    800060a0:	97a6                	add	a5,a5,s1
    800060a2:	4741                	li	a4,16
    800060a4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060a6:	000a3783          	ld	a5,0(s4)
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	4705                	li	a4,1
    800060ae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060b2:	f9442703          	lw	a4,-108(s0)
    800060b6:	000a3783          	ld	a5,0(s4)
    800060ba:	97a6                	add	a5,a5,s1
    800060bc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060c0:	0712                	slli	a4,a4,0x4
    800060c2:	000a3783          	ld	a5,0(s4)
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	05890693          	addi	a3,s2,88
    800060cc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ce:	000a3783          	ld	a5,0(s4)
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	40000693          	li	a3,1024
    800060d8:	c794                	sw	a3,8(a5)
  if(write)
    800060da:	100d0a63          	beqz	s10,800061ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060de:	0001f797          	auipc	a5,0x1f
    800060e2:	f227b783          	ld	a5,-222(a5) # 80025000 <disk+0x2000>
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ec:	0001d517          	auipc	a0,0x1d
    800060f0:	f1450513          	addi	a0,a0,-236 # 80023000 <disk>
    800060f4:	0001f797          	auipc	a5,0x1f
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80025000 <disk+0x2000>
    800060fc:	6394                	ld	a3,0(a5)
    800060fe:	96ba                	add	a3,a3,a4
    80006100:	00c6d603          	lhu	a2,12(a3)
    80006104:	00166613          	ori	a2,a2,1
    80006108:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000610c:	f9842683          	lw	a3,-104(s0)
    80006110:	6390                	ld	a2,0(a5)
    80006112:	9732                	add	a4,a4,a2
    80006114:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006118:	20098613          	addi	a2,s3,512
    8000611c:	0612                	slli	a2,a2,0x4
    8000611e:	962a                	add	a2,a2,a0
    80006120:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006124:	00469713          	slli	a4,a3,0x4
    80006128:	6394                	ld	a3,0(a5)
    8000612a:	96ba                	add	a3,a3,a4
    8000612c:	6589                	lui	a1,0x2
    8000612e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006132:	94ae                	add	s1,s1,a1
    80006134:	94aa                	add	s1,s1,a0
    80006136:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006138:	6394                	ld	a3,0(a5)
    8000613a:	96ba                	add	a3,a3,a4
    8000613c:	4585                	li	a1,1
    8000613e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006140:	6394                	ld	a3,0(a5)
    80006142:	96ba                	add	a3,a3,a4
    80006144:	4509                	li	a0,2
    80006146:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000614a:	6394                	ld	a3,0(a5)
    8000614c:	9736                	add	a4,a4,a3
    8000614e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006152:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006156:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000615a:	6794                	ld	a3,8(a5)
    8000615c:	0026d703          	lhu	a4,2(a3)
    80006160:	8b1d                	andi	a4,a4,7
    80006162:	2709                	addiw	a4,a4,2
    80006164:	0706                	slli	a4,a4,0x1
    80006166:	9736                	add	a4,a4,a3
    80006168:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000616c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006170:	6798                	ld	a4,8(a5)
    80006172:	00275783          	lhu	a5,2(a4)
    80006176:	2785                	addiw	a5,a5,1
    80006178:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006184:	00492703          	lw	a4,4(s2)
    80006188:	4785                	li	a5,1
    8000618a:	02f71163          	bne	a4,a5,800061ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000618e:	0001f997          	auipc	s3,0x1f
    80006192:	f1a98993          	addi	s3,s3,-230 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006196:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006198:	85ce                	mv	a1,s3
    8000619a:	854a                	mv	a0,s2
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	0a0080e7          	jalr	160(ra) # 8000223c <sleep>
  while(b->disk == 1) {
    800061a4:	00492783          	lw	a5,4(s2)
    800061a8:	fe9788e3          	beq	a5,s1,80006198 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061ac:	f9042483          	lw	s1,-112(s0)
    800061b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061b4:	00479713          	slli	a4,a5,0x4
    800061b8:	0001d797          	auipc	a5,0x1d
    800061bc:	e4878793          	addi	a5,a5,-440 # 80023000 <disk>
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061c6:	0001f917          	auipc	s2,0x1f
    800061ca:	e3a90913          	addi	s2,s2,-454 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ce:	8526                	mv	a0,s1
    800061d0:	00000097          	auipc	ra,0x0
    800061d4:	bf6080e7          	jalr	-1034(ra) # 80005dc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061d8:	0492                	slli	s1,s1,0x4
    800061da:	00093783          	ld	a5,0(s2)
    800061de:	94be                	add	s1,s1,a5
    800061e0:	00c4d783          	lhu	a5,12(s1)
    800061e4:	8b85                	andi	a5,a5,1
    800061e6:	cf89                	beqz	a5,80006200 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ec:	b7cd                	j	800061ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ee:	0001f797          	auipc	a5,0x1f
    800061f2:	e127b783          	ld	a5,-494(a5) # 80025000 <disk+0x2000>
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	4689                	li	a3,2
    800061fa:	00d79623          	sh	a3,12(a5)
    800061fe:	b5fd                	j	800060ec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006200:	0001f517          	auipc	a0,0x1f
    80006204:	ea850513          	addi	a0,a0,-344 # 800250a8 <disk+0x20a8>
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	b06080e7          	jalr	-1274(ra) # 80000d0e <release>
}
    80006210:	70e6                	ld	ra,120(sp)
    80006212:	7446                	ld	s0,112(sp)
    80006214:	74a6                	ld	s1,104(sp)
    80006216:	7906                	ld	s2,96(sp)
    80006218:	69e6                	ld	s3,88(sp)
    8000621a:	6a46                	ld	s4,80(sp)
    8000621c:	6aa6                	ld	s5,72(sp)
    8000621e:	6b06                	ld	s6,64(sp)
    80006220:	7be2                	ld	s7,56(sp)
    80006222:	7c42                	ld	s8,48(sp)
    80006224:	7ca2                	ld	s9,40(sp)
    80006226:	7d02                	ld	s10,32(sp)
    80006228:	6109                	addi	sp,sp,128
    8000622a:	8082                	ret
  if(write)
    8000622c:	e20d1ee3          	bnez	s10,80006068 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006230:	f8042023          	sw	zero,-128(s0)
    80006234:	bd2d                	j	8000606e <virtio_disk_rw+0xe2>

0000000080006236 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006236:	1101                	addi	sp,sp,-32
    80006238:	ec06                	sd	ra,24(sp)
    8000623a:	e822                	sd	s0,16(sp)
    8000623c:	e426                	sd	s1,8(sp)
    8000623e:	e04a                	sd	s2,0(sp)
    80006240:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006242:	0001f517          	auipc	a0,0x1f
    80006246:	e6650513          	addi	a0,a0,-410 # 800250a8 <disk+0x20a8>
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	a10080e7          	jalr	-1520(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006252:	0001f717          	auipc	a4,0x1f
    80006256:	dae70713          	addi	a4,a4,-594 # 80025000 <disk+0x2000>
    8000625a:	02075783          	lhu	a5,32(a4)
    8000625e:	6b18                	ld	a4,16(a4)
    80006260:	00275683          	lhu	a3,2(a4)
    80006264:	8ebd                	xor	a3,a3,a5
    80006266:	8a9d                	andi	a3,a3,7
    80006268:	cab9                	beqz	a3,800062be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000626a:	0001d917          	auipc	s2,0x1d
    8000626e:	d9690913          	addi	s2,s2,-618 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006272:	0001f497          	auipc	s1,0x1f
    80006276:	d8e48493          	addi	s1,s1,-626 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000627a:	078e                	slli	a5,a5,0x3
    8000627c:	97ba                	add	a5,a5,a4
    8000627e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006280:	20078713          	addi	a4,a5,512
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	974a                	add	a4,a4,s2
    80006288:	03074703          	lbu	a4,48(a4)
    8000628c:	ef21                	bnez	a4,800062e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000628e:	20078793          	addi	a5,a5,512
    80006292:	0792                	slli	a5,a5,0x4
    80006294:	97ca                	add	a5,a5,s2
    80006296:	7798                	ld	a4,40(a5)
    80006298:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000629c:	7788                	ld	a0,40(a5)
    8000629e:	ffffc097          	auipc	ra,0xffffc
    800062a2:	124080e7          	jalr	292(ra) # 800023c2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062a6:	0204d783          	lhu	a5,32(s1)
    800062aa:	2785                	addiw	a5,a5,1
    800062ac:	8b9d                	andi	a5,a5,7
    800062ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062b2:	6898                	ld	a4,16(s1)
    800062b4:	00275683          	lhu	a3,2(a4)
    800062b8:	8a9d                	andi	a3,a3,7
    800062ba:	fcf690e3          	bne	a3,a5,8000627a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062be:	10001737          	lui	a4,0x10001
    800062c2:	533c                	lw	a5,96(a4)
    800062c4:	8b8d                	andi	a5,a5,3
    800062c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062c8:	0001f517          	auipc	a0,0x1f
    800062cc:	de050513          	addi	a0,a0,-544 # 800250a8 <disk+0x20a8>
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	a3e080e7          	jalr	-1474(ra) # 80000d0e <release>
}
    800062d8:	60e2                	ld	ra,24(sp)
    800062da:	6442                	ld	s0,16(sp)
    800062dc:	64a2                	ld	s1,8(sp)
    800062de:	6902                	ld	s2,0(sp)
    800062e0:	6105                	addi	sp,sp,32
    800062e2:	8082                	ret
      panic("virtio_disk_intr status");
    800062e4:	00002517          	auipc	a0,0x2
    800062e8:	6a450513          	addi	a0,a0,1700 # 80008988 <syscall_names+0x3d8>
    800062ec:	ffffa097          	auipc	ra,0xffffa
    800062f0:	25c080e7          	jalr	604(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
