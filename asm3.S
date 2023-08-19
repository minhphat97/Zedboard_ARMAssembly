@ Code for Lab 6 for ENSC 254
@ Copyright (C) 2019 Craig Scratchley
@ Name1: Minh Phat Tran. SFU ID: 301297286
@ Name2: Lingchong Weng. SFU ID: 301308043

@Declare the labels of the interrupt handler and the main routine as globals
.global asm_main
.global FIQHandler

#include "asm_include.h"
//#include "macros.i"

.equ XTC_CSR_NEEDED_MASKS, XTC_CSR_ENABLE_TMR_MASK | XTC_CSR_ENABLE_INT_MASK | XTC_CSR_DOWN_COUNT_MASK | XTC_CSR_INT_OCCURED_MASK

.text

//FUNCTION asm_main
asm_main:
  PUSH {R4-R11, LR}
  BL OLED_clear
  BL OLED_welcome
  LDR R0, =0 @ total_events

  @Switch to FIQ mode
  LDR R1, =XREG_CPSR_FIQ_MODE
  MSR CPSR_c, R1

  @Initialize FIQ registers for the purposes
  @of the FIQ being able to use them
  LDR R9, =XPAR_AXI_GPIO_BTNS_BASEADDR
  LDR R10, =XPAR_AXI_GPIO_LEDS_BASEADDR
  LDR R11, =XPAR_AXI_TIMER_0_BASEADDR

  @configure timer
    @Count goes here -- 1s
    LDR R8, =XPAR_AXI_TIMER_0_CLOCK_FREQ_HZ
  @Now load the load register.
    STR R8, [R11, #XTC_TLR_OFFSET]
  @Load the counter register.
	LDR R8, =XTC_CSR_LOAD_MASK
    STR R8, [R11, #XTC_TCSR_OFFSET]


  @Button interrupt on.
  LDR R8, =XGPIO_GIE_GINTR_ENABLE_MASK @0x0
  STR R8, [R9, #XGPIO_GIE_OFFSET]
  LDR R8, =XGPIO_IR_CH1_MASK
  STR R8, [R9, #XGPIO_IER_OFFSET]
  	str r0, [r10, #XGPIO_DATA_OFFSET]	;@ write 0 to LEDs to turn them off

	;@ The connections to the LEDs and switches are initially configured as inputs. This works well
	;@ for the switches but not so helpful for the LEDs.  Connections can be changed to outputs by
	;@ clearing their corresponding bits in the GPIO 'Tristate Register'. The
	;@ Tristate register is at an offset from the base address for GPIO ports.
	ldr R8, [R10, #XGPIO_TRI_OFFSET] ;@ Read the tristate register for the LEDs
	bic R8, #0xFF   				;@ Clear the first 8 tristate bits to enable the 8 LEDs as outputs
	str R8, [R10, #XGPIO_TRI_OFFSET]	;@ Write new value to LED tristate register to enable as outputs
  MOV R8, R0 @ total_events

  @Switch back to system mode
  LDR R1, =XREG_CPSR_SYSTEM_MODE
  MSR CPSR_c, R1

  @Print initial count of events on the OLED
  MOV R1, #3
  BL OLED_print_R0_on_row_R1

  @Enable fast interrupts
  CPSIE f
  ;@ Load base addresses for and Slider Switch GPIO
  ldr r4, =XPAR_AXI_GPIO_SWS_BASEADDR		;@ load base address of Switches into r4

.poll:
	ldr r6, =4000  @ first argument for subroutine and function
	@ ldr r6, =32
	@ mov	r6, r6, lsl #9					;@ scale value up
	mov r0, r6
	mov r1, #1
	BL OLED_print_R0_on_row_R1
	mov r0, r6
	BL fib_main
	ldr r5, =184375  @ return value from fib_main should be 184375
	teq r5, r0
	beq	cont
  	MOV R1, #2
  	BL OLED_print_R0_on_row_R1
err_loop: bkpt
	b err_loop

cont:
  	MOV R1, #2
  	BL OLED_print_R0_on_row_R1
  	B .poll

	@ we should never get here
  	POP {R4-R11, PC}
//ENDFUNC main

@ offsets from stack pointer for automatic variables
.equ bigN0, 0
.equ bigN1, 4 + bigN0

.equ autoSize, 4 + bigN1 @ total space for automatic variables

FIQHandler:
    PUSH {r0-r3, r12, lr}
    sub	sp, sp, #autoSize @ make space for automatic variables

	mov r2, #0
  	str	r2, [sp, #bigN0] @ bigN0 is the value 0
  	str	r2, [sp, #bigN1] @ bigN1 is the value 0
  	add r0, sp, #bigN0  @ put address in r0
  	add r1, sp, #bigN1  @ put other address in r1
	BL asuAdd         @ commented out for now


  LDR R3, [R11, #XTC_TCSR_OFFSET]
  TST R3, #XTC_CSR_INT_OCCURED_MASK @ see if timer interrupt occured.
  @Conditionally clear the timer interrupt here.
  LDRNE R3, =XGPIO_GIE_GINTR_ENABLE_MASK
  STRNE R3, [R9, #XGPIO_GIE_OFFSET]

  LDR R3, [R9, #XGPIO_ISR_OFFSET]
  TST R3, #XGPIO_IR_CH1_MASK          @ see if button interrupt occured.
  BNE checkPressOnly
continueButtonInterrupt:
  @STRNE R3, [R9, #XGPIO_ISR_OFFSET]   @ Clear the button interrupt here.
  ADDNE R8, R8, #1 @ decrement count
  LDRNE R3, =0x0
  STRNE R3, [R9, #XGPIO_GIE_OFFSET]
  @enable the countdown timer with autoload and an interrupt
  LDRNE R3, =XTC_CSR_LOAD_MASK
  STRNE R3, [R11, #XTC_TCSR_OFFSET]
  LDR R3, =XTC_CSR_NEEDED_MASKS
  STR R3, [R11, #XTC_TCSR_OFFSET]

return:
  str r8, [r10, #XGPIO_DATA_OFFSET]	;@ write count value to LED

  @ write count to OLED
  MOV R0, R8
  MOV R1, #3
  BL OLED_print_R0_on_row_R1

  add	sp, sp, #autoSize	@ remove space for automatic variables
  POP {r0-r3, r12, lr}

  @Dubious offset, I know. Still, here's the reference:
  @http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0040d/Cacbacic.html

  @ The S at the end of SUBS causes the SPSR of the mode (FIQ in this case) to be put back in the CPSR
  SUBS	 	PC, LR, #4

checkPressOnly:
  LDR R3, [R9 ,#XGPIO_DATA_OFFSET]
  TST R3, #0x1F
  BNE continueButtonInterrupt
  BEQ return
