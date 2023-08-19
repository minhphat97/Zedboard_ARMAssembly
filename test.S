;@============================================================================
;@
;@ ** Handing this file in is optional but recommended.  
;@ ** Only hand it in if you have added/modified testcases or testing code.
;@
;@ Student Name 1: student1
;@ Student 1 #: 123456781
;@ Student 1 userid (email): stu1 (stu1@sfu.ca)
;@
;@ Student Name 2: student2
;@ Student 2 #: 123456782
;@ Student 2 userid (email): stu2 (stu2@sfu.ca)
;@
;@ Below, edit to list any people who helped you with the code in this file,
;@      or put �none� if nobody helped (the two of) you.
;@
;@ Helpers: _everybody helped us/me with the assignment (list names or put �none�)__
;@
;@ Also, reference resources beyond the course textbooks and the course pages on Canvas
;@ that you used in making your submission.
;@
;@ Resources:  ___________
;@
;@% Instructions:
;@ * Put your name(s), student number(s), userid(s) in the above section.
;@ * Edit the "Helpers" line and "Resources" line.
;@ * Your group name should be "<userid1>_<userid2>" (eg. stu1_stu2)
;@ * Form groups as described at:  https://courses.cs.sfu.ca/docs/students
;@ * Submit your file(s) to courses.cs.sfu.ca
;@
;@ Description : Testing code and testcases for Assignment 1.
;@ Copyright (C) 2019 Craig Scratchley    wcs (at) sfu (dot) ca
;@============================================================================

.include "../src/macros.i"

	.EQU	WORDS_PER_ARRAY,	4
	.EQU	BYTES_PER_WORD,		4
	.EQU	BYTES_PER_ARRAY,	WORDS_PER_ARRAY * BYTES_PER_WORD
	.EQU	ARRAYS_PER_ROW,		3
	.EQU	BYTES_PER_ROW,		BYTES_PER_ARRAY * ARRAYS_PER_ROW + 3 * BYTES_PER_WORD 

	.EQU	RAND_REG,	6 	;@ regs to fill with random and compare
	.EQU	USED_REG,	3	;@ number of "other" registers that are used

	.text			;@ start storing in simulated ROM

;@ For Eclipse...
;@ Set "Displayed tab width" to 8 in Window > Preferences > General > Editors > Text Editors

;@ For Keil MDK...
;@ Highly recommended in Edit > Configuration
;@ Set "Auto Indent" to: "None"
;@ Tabs set for 8 characters for ASM files
;@Reset_Handler:
;@	.global Reset_Handler				;@ The entry point on reset
;@	ldr sp, =0x40004000				;@ Initialize SP just past the end of RAM

FUNCTION main
;@ you can improve the testing code below if you want to.  	
	push	{r4-r11, lr}
	ldr	r4, =TestTableAsuAdd + BYTES_PER_ARRAY	;@ load with address after bnt1
	ldr	r5, =bnt				;@ load address of bnt

	ldr	r0, =rndLoc
	bl	srand					;@ seed random generator with c function
	
loop:
	ldmdb	r4, {r0, r1, r2, r3}
	cmn	r0, #1					;@ compare size of bnt1 with -1 marking end of table
done:	bne	cont0
done2:	;@b	done					;@ loop here if ... (Keil MDK)
	mov 	r0, #0					;@ ... program successful
	pop	{r4-r11, pc}				;@ or return from main (Eclipse with gdb simulator)
	
cont0:	stmia	r5, {r0-r3}				;@ copy bnt1 to bnt
	
	;@ fill the registers {r6-r11} with some random values 
	;@ 1) put random values in memory
	ldr 	r0, =randrb
	bl	rndGen

	;@ 2) load registers {r6-r11} from memory 
	ldmia 	r0, {r6-r11}	
	
	;@ save  registers {r4-r5, SP} in memory for further check
	ldr  	r12, =usedrb
	stmia 	r12, {r4-r5, sp}	
	
	mov	r0, r5						;@ load bigN0PC
	mov	r1, r4						;@ load bigN1PC
	ldr 	r2, [r4, #BYTES_PER_ARRAY*2 + BYTES_PER_WORD]	;@ load maxN0Size
	
	bl	asuAdd			;@ branch and link with our function

	ldr 	r1, =usedra	
	stmia 	r1, {r4-r5, sp}		
	
	push	{r0}			;@ put return value on stack

	ldr  	r0, =usedrb 
	mov	r2, #(USED_REG * 4)	;@ number of bytes to compare registers contents
	
	bl	memcmp			;@ compare using library function

	cmp	r0, #0			;@ are the current values of registers and their previous values equal?	
p4r5sp:	beq	cont1
p4r5s2:	;@b	p4r5sp			;@ loop here if ...
	mov	r0, #1			;@ ... a problem with r4, r5, or sp
	pop	{r1, r4-r11, pc}	;@ or return from main (Eclipse with gdb simulator)
					;@ return value put on stack above goes into r1
	
cont1:	;@ check if the registers {r6-r11} are changed during the bigAdd.
	;@    If stack is used properly then their values should not change.
	ldr  	r0, =randrb 
	ldr  	r1, =randra	
	stmia 	r1, {r6-r11}	
	mov	r2, #(RAND_REG * 4)	;@ number of bytes to compare registers contents
	
	bl	memcmp			;@ compare using library function

	cmp	r0, #0			;@ is the current values of registers and their previous values equal?	
	pop	{r0}			;@ get bigAdd return value back from stack.
p6r11:	beq	sumchk
p6r11b:	;@b	p6r11			;@ loop here if ...
	mov	r0, #2			;@ ... a problem with r6-r11
	pop	{r4-r11, pc}		;@ or return from main (Eclipse with gdb simulator)
	
sumchk:
	;@load correct return value
	ldr 	r1, [r4, #BYTES_PER_ARRAY*2 + 2*BYTES_PER_WORD]	
	cmp 	r0, r1
retWrg:	beq	cont3
retWr2:	;@b 	retWrg			;@ loop here if ...
	mov	r0, #3			;@ ... return value wrong
	pop	{r4-r11, pc}		;@ or return from main (Eclipse with gdb simulator)

cont3:	;@ compare to check whether an error correctly occurred and therefore further checks can be skipped
	cmp 	r0, #-1			;@ translated to "   cmn r0, #1"
	beq	nxtRow
	
	mov 	r0, r5 
	add	r1, r4,#BYTES_PER_ARRAY	;@put address of bntR in r1
	ldr	r2, [r1]
	add	r2, r2, #1		;@ add 1 word because size takes a word and needs to be compared too.
	mov	r2, r2, lsl #2		;@ quadruple to get number of bytes to compare

	bl	memcmp			;@ compare bytes using library function

	cmp	r0, #0			;@ is bntR and bnt equal?
notEq:	beq	nxtRow
notEq2:	;@b	notEq			;@ loop if ...
	mov	r0, #4			;@ ... test failure detected -- bntR and bnt not equal
	pop	{r4-r11, pc}		;@ or return from main (Eclipse with gdb simulator)

nxtRow:	add	r4, r4, #BYTES_PER_ROW	;@go to next "row" of table
	b	loop			;@loop back for next row
ENDFUNC	main

;@	.type	rndGen, %function
;@rndGen:					;@ generate random numbers
;@ function rndGen to generate random numbers
FUNCTION rndGen
	push	{r4-r5, lr}		;@ also push link register with return location
	mov	r4, r0			;@ r0 has base address to write results
	mov 	r5, #(RAND_REG - 1) * 4
rgLoop:
	bl	rand			;@ c-language rand function
	str    	r0, [r4, r5]
	subs   	r5, #4
	bpl 	rgLoop

	mov	r0, r4			;@ subroutine returns back the base address in r0
	pop	{r4-r5, pc}		;@ also pop return location into program counter
ENDFUNC	rndGen
;@	.size	rndGen, .-rndGen	;@ needed for GDB to work reliably.

	.section	.rodata
	.align 4
TestTableAsuAdd:
	.word	3, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFF
	.word	1, 0x80000000, 0x00000000, 0x00000000
	.word	4, 0x00000000, 0x00000000, 0x00000000, 1
	.word	4                        			;@ maxN0Size
	.word	0                       			;@ Check returned value


	.word	1, 0x80000000, 0x00000000, 0x00000000
	.word	3, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFF
	.word	4, 0x00000000, 0x00000000, 0x00000000, 1
	.word	4                        			;@ maxN0Size
	.word	0

        .word	1, 0, 0, 0 			;@ 5th "row" of table
	.word	2, 1, 0, 0
	.word	2, 1, 0, 0, 0
	.word	3 	 			;@ maxN0Size
	.word	0

	.word	2, 0, 0, 0 			;@ 3rd "row" of table
	.word	1, 0, 0, 0
	.word	2, 0, 0, 0, 0
	.word	3 	 			;@ maxN0Size
	.word	0


	.word	0, 0, 0, 0 			;@ bnt1 in 1st "row" of table
	.word	0, 0, 0, 0 			;@ bnt2
	.word	0, 0, 0, 0, 0 			;@ bntR -- Big Number Test - Expected Result
	.word	3 	 			;@ maxN0Size
	.word	0 				;@ Check returned value
//	.word	1				;@ Consider adding test identifier
		
	.word	1, 0, 0, 0 			;@ 2nd "row" of table
	.word	1, 0, 0, 0
	.word	1, 0, 0, 0, 0 			;@ note, does not become 0, 0, 0, 0
	.word	3 				;@ maxN0Size
	.word	0 				;@ Check returned value								  
		
				;@ Check returned value
		
	.word	1, 1, 0, 0 			;@ 4th "row" of table
	.word	1, 1, 0, 0
	.word	1, 2, 0, 0, 0
	.word	3 	 			;@ maxN0Size
	.word	0 				;@ Check returned value
		
					;@ Check returned value
		
	.word	1, 0x80000000, 0, 0 		;@ 6th "row" of table
	.word	1, 0x80000000, 0, 0
	.word	2, 0x00000000, 1, 0, 0 
	.word	3 	 			;@ maxN0Size
	.word	0 				;@ Check returned value								  
		
	.word	2, 0x80000000, 0xFFFFFFFF, 0 	;@ "row" 7 of table
	.word	1, 0x80000000, 0x00000000, 0 
	.word	3, 0x00000000, 0x00000000, 1, 0 
	.word	3 	 			;@ maxN0Size
	.word	0 				;@ Check returned value								  
		
	.word   1, 4, 0, 0 
	.word   2, 5, 0, 0
	.word   2, 9, 0, 0, 0 
	.word	3 				;@ maxN0Size
	.word	0 				;@ Check returned value								  
	
	.word   1, 0x80000000, 0x00000000, 0 
	.word   2, 0x80000000, 0xFFFFFFFF, 0
	.word   3, 0x00000000, 0x00000000, 1, 0 
	.word	3                                    
	.word	0                                   

	.word  	2, 0x80000000, 0x00000000, 0x00000000 
	.word  	3, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFF
	.word  	3, 0x00000000, 0x00000000, 0x00000000, 0
	.word	3 						;@ maxN0Size
	.word	1 						;@ Check returned value				  
	
	.word   3, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFF 
	.word   1, 0x80000000, 0x00000000, 0x00000000 
	.word   3, 0x00000000, 0x00000000, 0x00000000, 0
	.word	3 						;@ maxN0Size
	.word	1 						;@ Check returned value			  
	
	.word   1, 0, 0, 0 
	.word   4, 0, 0, 0
	.word   4, 0, 0, 0, 0
	.word	3 						;@ maxN0Size
	.word	-1 						;@ Check returned value			 
	
	.word   4, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFF 
	.word   1, 0x80000000, 0x00000000, 0x00000000 
	.word   4, 0x00000000, 0x00000000, 0x00000000, 0
	.word	3                        			;@ maxN0Size
	.word	-1                       			;@ Check returned value

	
	                       			;@ Check returned value
	
					  
	.word	-1	;@ end of testing table

rndLoc:	.word	.	;@ put location pointer at the location to use as seed value
	
	
	.data						;@ Store in RAM	
	.align
bnt: 	.space BYTES_PER_ARRAY + BYTES_PER_WORD		;@ Big Number Test

randrb: .space (RAND_REG * 4)				;@ registers holding random values before
randra: .space (RAND_REG * 4)				;@ registers holding random values after

usedrb: .space (USED_REG * 4)				;@ used registers before
usedra:	.space (USED_REG * 4)				;@ used registers after

	.end						;@ End of assembly in program file	
