
;@ Copyright (C) 2019 School of Engineering Science, SFU
;@ Name 1: Minh Phat Tran, SFU ID: 301297286
;@ Name 2: Lingchong Weng, SFU ID: 301308043
/*
====	Note: the code below is only work for the BTNS mode, if want to test the switch mode, please replace line26 "BTNS" to "SWS"
		  and comment out the uncomment "poll" function, then uncomment out the comment "poll" function.==============================================
*/
#include "asm_include.h"
.include "../src/macros.i"
.include "../src/definitions.i"

;@ .data
;@ .align

.text
.align		;@align the variable to 4 bytes word boundary

FUNCTION asm_main
	;@ Use r3 to hold the base address of the Switch GPIO ports
	;@ Use r1 to hold the base address of LED GPIO ports
	;@ Use r2 as scratch

	;@ Load base addresses for LED GPIO and Switch GPIO
	ldr r1, =XPAR_AXI_GPIO_LEDS_BASEADDR	;@ load base address of LEDs into r1
	ldr r3, =XPAR_AXI_GPIO_BTNS_BASEADDR    ;@ load base address of BUTTONs into r3, change to switch
	;@ The connections to the LEDs and switches are initially configured as inputs. This works well
	;@ for the switches but not so helpful for the LEDs.  Connections can be changed to outputs by
	;@ clearing their corresponding bits in the GPIO 'Tristate Register'. The
	;@ Tristate register is at an offset from the base address for GPIO ports.
	ldr r2, [r1, #XGPIO_TRI_OFFSET] ;@ Read the tristate register for the LEDs
	mov r2, #0x00   				;@ Clear the first 8 tristate bits to enable the 8 LEDs as outputs
	str r2, [r1, #XGPIO_TRI_OFFSET]	;@ Write new value to LED tristate register to enable as outputs
	MOV r5, #0x00

//=====================================================SWITCH PART================================================================
/*poll:
	;@ The Data Register is located directly at the base address of the GPIO ports
	;@ so by reading and writing the base address we can read from and write to the data register.
	;@ Still a (zero) offset has been defined for the Data Register.
	ldr r2, [r3, #XGPIO_DATA_OFFSET]	;@read switches
	str r2, [r1, #XGPIO_DATA_OFFSET]	;@write value to LED

	b poll ;@ Loop endlessly polling buttons and setting LEDs

	;@ An empty main project doing nothing
	;@ Follow the tutorial instruction and complete the main program to read from switches and update LEDs
	mov r0, #0
	mov pc, lr  ;@ Return from function call
ENDFUNC asm_main
*/
//================================================================================================================================

//===================================================BUTTON PART==================================================================
poll:

	;@ The Data Register is located directly at the base address of the GPIO ports
	;@ so by reading and writing the base address we can read from and write to the data register.
	;@ Still a (zero) offset has been defined for the Data Register.
	ldr r2, [r3, #XGPIO_DATA_OFFSET]	;@read switches\

	CMP r2, #0x01 //The centre button
	BEQ Operation1

    CMP r2, #0x10 //The up button
    BEQ loopUpButton

    CMP r2, #0x02 //The down button
    BEQ loopDownButton
    b poll

loopUpButton:
	ldr r2, [r3, #XGPIO_DATA_OFFSET]

	CMP r2, #0x10 //The up button
	BEQ loopUpButton //Keep pressing up button
	ADD r5, r5, #1
	str r5, [r1, #XGPIO_DATA_OFFSET] // store to LEDs
	b poll

loopDownButton:
	ldr r2, [r3, #XGPIO_DATA_OFFSET]
	CMP r2, #0x02 //The down button
	BEQ loopDownButton //Keep pressing down button
	ADD r5, r5, #-1
	str r5, [r1, #XGPIO_DATA_OFFSET] // store to LEDs
	b poll

Operation1:
	ldr r2, [r3, #XGPIO_DATA_OFFSET]
	CMP r2, #0x01
	BEQ Operation1
	MOV r5, #0x00  //Reset
	str r5, [r1, #XGPIO_DATA_OFFSET] // store to LEDs
	b poll
	;@ An empty main project doing nothing
	;@ Follow the tutorial instruction and complete the main program to read from switches and update LEDs
	mov r0, #0
	mov pc, lr  ;@ Return from function call
ENDFUNC asm_main
//=======================================================================================================================================

