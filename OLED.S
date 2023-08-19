@ Code for OLED display for ZedBoard for ENSC 254
@ For OLED controller designed for ENSC 254 at SFU
@ Copyright (C) 2019 School of Engineering Science, SFU
;@ Name 1: Minh Phat Tran, SFU ID: 301297286
;@ Name 2: Lingchong Weng, SFU ID: 301308043
#include "asm_include.h"
#include "definitions.i"

.section .rodata
message1:	.asciz "ENSC 254 Lab 5."
message2:   .asciz "maxSize: "
message3:   .asciz "return: "
message4:   .asciz "interrupts: "


.section .data
.align
@Reserving space to use for the OLED
counter_str:
  .space 16

.section .text
.global	OLED_clear
.global	OLED_welcome
.global OLED_print_R0_on_row_R1
.global OLED_maxSize
.global OLED_return
.global OLED_interrupt
.equ OLED_char, XPAR_AXI_OLED_CONTROLLER_0_S_AXI_BASEADDR + OLED_CHAR_OFFSET @ 0x41240400

OLED_clear:
    LDR R0, =OLED_char
	MOV R2, #64
	MOV R3, #' '
loop_clear:
	STRB R3, [r0], #1
	SUB R2, #1
	CMP r2, #0
	BNE loop_clear

	mov		PC, LR


OLED_welcome:
	;@ Display a nul terminated string on the OLED:
	ldr 	r0, =OLED_char		;@load base address for OLED
	ldr		r1, =message1		;@ use r5 as a pointer for the message string

OLED_print_loop:

	ldrb 	r2, [r1], #1		;@ Load the character pointed to and advance pointer by 1 addr

	cmp 	r2, #0			;@ stop when reaching null character
	beq 	OLED_print_loop_stop
	strb 	r2, [r0], #1		;@ store the character on OLED display buffer
	b 		OLED_print_loop
OLED_print_loop_stop:
	mov		PC, LR


;@ subroutine to divide number in r0 by 10
div10:
	;@ r0 should contain the dividend
	ldr		r1, =0xCCCCCCCD		;@ fix point binary representation of 1/10
	umull		r2, r1, r0, r1
	mov		r0, r1, LSR #3		;@ shifting the result of the multiplication by 32+3 bits
						;@ will give the division result
	mov		pc, lr


;@ Sub routine to display an integer number on a specific row of the OLED screen
;@ the number displayed will be considered unsigned
;@ argument: 	r0 should contain the number to be display upon entering the sub routine
;@ r1 holds the row number on the OLED screen to be displayed
//===================================================================================================================================================
OLED_maxSize:
    push   {r4-r6,lr}
	ldr 	r4,=OLED_char
 	add 	r4, #16
	ldr		r5, =message2
OLED_print_loop2:
	ldrb 	r2, [r5], #1		;@ Load the character pointed to and advance pointer by 1 addr
	cmp 	r2, #0			;@ stop when reaching null character
	beq 	OLED_print_loop_stop2
	strb 	r2, [r4], #1		;@ store the character on OLED display buffer
	b 		OLED_print_loop2
OLED_print_loop_stop2:
    pop {r4-r6, pc}
//===================================================================================================================================================

//===================================================================================================================================================
OLED_return:
	push {r4-r6,lr}
	ldr  r4, =OLED_char
	add  r4, r4, #32
	ldr	 r5, =message3
OLED_print_loop3:
	ldrb r2, [r5], #1
	cmp r2, #0
	beq OLED_print_loop_stop3
	strb r2, [r4], #1
	b OLED_print_loop3
OLED_print_loop_stop3:
	pop {r4-r6, pc}
//===================================================================================================================================================

//===================================================================================================================================================
OLED_interrupt:
	push {r4 - r6, lr}
	ldr r4, =OLED_char
	add r4, r4, #48
	ldr	r5, =message4
OLED_print_loop4:
	ldrb r2, [r5], #1
	cmp r2, #0
	beq OLED_print_loop_stop4
	strb r2, [r4], #1
	b OLED_print_loop4
OLED_print_loop_stop4:
	pop {r4-r6, pc}
//===================================================================================================================================================

//===================================================================================================================================================

OLED_print_R0_on_row_R1:
	push {r4-r10, lr}

	mov r5, r0					;@ use r5 to store the value to display
	mov r12, r1					;@ store specified row number in r12

	ldr r8, =counter_str		;@ use r8 as pointer to counter string
	mov r6, #0					;@ pad a NULL at the beginning
	strb r6, [r8], #1
div10_get_remainder_loop:
	mov r0, r5
	bl div10					;@ divide by 10
	mov r10, r0					;@ move division result from r0 to r10
	mov r6, #10
	umull r7, r6, r10, r6
	sub r9, r5, r7				;@ and get the remainder (this will be the least significant digit)
	add r9, r9, #'0'			;@ add the value to ascii equivalent of number 0 (0x30)
	strb r9, [r8], #1			;@ store the byte to counter string
	mov r5, r10					;@ store division result back to r5
	cmp r10, #0					;@ if division result is not 0, repeat
	bne	div10_get_remainder_loop

	;@ display the counter string on OLED:
	ldr r4, =OLED_char
	add r6, r4, r12, LSL #4			;@ point r6 to the beginning of the specified row on OLED
	cmp r12, #0
	addeq r12, #0
	cmp r12, #1
	addeq r6, #9
	cmp r12, #2
	addeq r6, #8
	cmp r12, #3
	addeq r6, #0xC

	//addne r6,#8
	//addeq r6,#11
	sub r8, r8, #1
	;@ at this point r8 should point at the end of the string and also the most significant digit of the counter


print_counter_OLED_loop:
	ldrb r5, [r8], #-1			;@ load character from the string in backward direction
	cmp r5, #0					;@ stop when reaching NULL at the beginning of the counter string
	beq	print_counter_OLED_loop_stop
	strb r5, [r6], #1			;@ store character on OLED display buffer
	b print_counter_OLED_loop
print_counter_OLED_loop_stop:

	;@ clean up the remaining of the line with white space
	add r12, r12, #1			;@ Specify the end of the specified row (beginning of next row)
print_counter_OLED_clean:
	mov r5, #' '
	strb r5, [r6], #1
	sub r7, r6, r4				;@ get current position of r6 pointer on OLED buffer (r7 represent offset from base addr)
				;@ compare position on OLED buffer with
	cmp r7, r12, LSL #4			;@ the first character of the specified row + 1
								;@ (make sure its past the last character of the row)
	blt	print_counter_OLED_clean

	pop {r4-r10, pc}
