;@============================================================================
;@
;@ Name        : asuAdd.S
;@ Description : asuAdd subroutine for Assignment 1.
;@ Copyright (c) 2019 W. Craig Scratchley  --  wcs (at) sfu (dot) ca
;@============================================================================
@ Name1: Minh Phat Tran. SFU ID: 301297286
@ Name2: Lingchong Weng. SFU ID: 301308043

;@ For Eclipse...
;@ Set "Displayed tab width" to 8 in Window > Preferences > General > Editors > Text Editors

;@ For Keil MDK...
;@ Highly recommended in Edit > Configuration
;@ Set "Auto Indent" to: "None"
;@ Tabs set for 8 characters for ASM files

;@ include macro definitions including for FUNCTION and ENDFUNC
;@.include "../src/macros.i"

;@ arbitrary-sized-unsigned-addition subroutine
;@ implements:
;@     typedef unsigned int bigNumN[];
;@     int asuAdd(bigNumN bigN0PC, const bigNumN bigN1PC, unsigned int maxN0Size);
;@ as explained in the assignment handout
;@ returns -1 for error in inputs, 1 if overflow/carry-out and 0 if no overflow/carry-out

.global asuAdd
.equ holdMaxN0Size, 4
asuAdd:
;@ FUNCTION asuAdd

;@ de-optimized version of the solution -- but laying the groundwork for future exercises

	push	{r4-r11, lr}
	sub sp, sp, #holdMaxN0Size
	mov	r9, r0
	mov	r10, r1
	//ldr	r3, =holdMaxN0Size
	//str	r2, [r3]		;@ copy of naxN0Size saved to variable
	str r2, [sp]
	ldr	r8, [r10]		;@ r8 now holds const arg size
	ldr	r7, [r9]		;@ r7 now holds non-const arg size
	cmp	r7, r8

	;@ move min size (min of r7, r8) to r4
	mov	r4, r7
	movhi	r4, r8

	;@ move max size (max of r7, r8) to r5
	mov 	r5, r8
	movhi	r5, r7
	cmp 	r5, r2
	movhi	r0, #-1
	bhi 	Exit
;@	pophi	{r4-r11, pc}		;@ or... bhi Exit

	mov	r11, #0			;@ r11 holds index register
	adds	r6, r6, #0 		;@ clear carry flag

L1:
	teq	r11, r4			;@ this will NOT modify c flag
	beq	ExitL1
	add	r11, r11, #1
	ldr	r2, [r9, r11, lsl #2]
	ldr	r12, [r10, r11, lsl #2]
	adcs	r2, r2, r12
	str	r2, [r9, r11, lsl #2]
	b	L1

ExitL1:	mrs	r6, cpsr
	cmp	r7, r8
	bhs	HS			;@ unsigned higher or same.

	;@ r9 points to smaller size than r10 points to
	msr	cpsr_f, r6

L2:
	teq	r11, r8
	beq	ExitL2
	add	r11, r11, #1
	ldr	r12, [r10, r11, lsl #2]
	adcs	r12, r12, #0
	str	r12, [r9, r11, lsl #2]
	b	L2

	;@ r9 points to size higher than or same as what r10 points to
HS:	msr	cpsr_f, r6

L3:
	teq	r11, r7
	beq	ExitL3
	add	r11, r11, #1
	ldr	r12, [r9, r11, lsl #2]
	adcs	r12, r12, #0
	str	r12, [r9, r11, lsl #2]
	bcs	L3 			;@ don't need to continue if there is no carry.

	mov	r0, #0;
	b	Exit
;@	pop	{r4-r11, pc}		;@ or... b Exit

ExitL2:	mov 	r7, r8			;@ r7 now holds max of sizes

ExitL3:
	;@ put final carry flag in r6
	;@ sbcs	r6, r6, r6		;@ good try but no banana
	;@ rscs r6, r6, r6
	;@ mov	r6, ?, RRX
	movcc	r6, #0
	movcs	r6, #1

	//ldr	r3, =holdMaxN0Size

	ldr	r2, [sp]

	cmp	r2, r7			;@ equal (eq) if at the max size
	addhi	r11, r11, #1		;@ conditional increment
	strhi	r6, [r9, r11, lsl #2] 	;@ conditional str
	addhi	r7, r7, r6 			;@ possible expand output
	str	r7, [r9]

	;@ overflow return value
	movhi	r0, #0			;@ 0 if not maxSize
	moveq	r0, r6			;@ if maxSize: r6 (holding carry value)

Exit:
	add sp, sp, #holdMaxN0Size
	pop	{r4-r11, pc}

;@ENDFUNC asuAdd
;@	.size asuAdd, .-asuAdd

		.data
		.align
//holdMaxN0Size:	.space 4

		.end
