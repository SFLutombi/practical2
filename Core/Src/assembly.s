/*
 * assembly.s
 *
 */
 
 @ DO NOT EDIT
	.syntax unified
    .text
    .global ASM_Main
    .thumb_func

@ DO NOT EDIT
vectors:
	.word 0x20002000
	.word ASM_Main + 1

@ DO NOT EDIT label ASM_Main
ASM_Main:

	@ Some code is given below for you to start with
	LDR R0, RCC_BASE  		@ Enable clock for GPIOA and B by setting bit 17 and 18 in RCC_AHBENR
	LDR R1, [R0, #0x14]
	LDR R2, AHBENR_GPIOAB	@ AHBENR_GPIOAB is defined under LITERALS at the end of the code
	ORRS R1, R1, R2
	STR R1, [R0, #0x14]

	LDR R0, GPIOA_BASE		@ Enable pull-up resistors for pushbuttons
	MOVS R1, #0b01010101
	STR R1, [R0, #0x0C]
	LDR R1, GPIOB_BASE  	@ Set pins connected to LEDs to outputs
	LDR R2, MODER_OUTPUT
	STR R2, [R1, #0]
	MOVS R2, #0         	@ NOTE: R2 will be dedicated to holding the value on the LEDs

@ TODO: Add code, labels and logic for button checks and LED patterns

main_loop:
	@ Read switches from GPIOA IDR, invert (pull-ups used), mask SW0..SW3
	LDR R3, GPIOA_BASE
	LDR R3, [R3, #0x10]
	MVNS R3, R3
	ANDS R3, R3, #0x0F

	@ Determine step size: default 1; if SW0 pressed then 2
	MOVS R4, #1
	TST R3, #0x01
	BEQ 1f
	MOVS R4, #2
1:

	@ Determine delay value: default LONG; if SW1 pressed then SHORT
	LDR R5, LONG_DELAY_CNT
	LDR R7, [R5]
	TST R3, #0x02
	BEQ 2f
	LDR R5, SHORT_DELAY_CNT
	LDR R7, [R5]
2:

	@ SW2 forces pattern 0xAA while held
	TST R3, #0x04
	BEQ 3f
	MOVS R2, #0xAA
	B write_and_delay
3:
	@ SW3 freezes pattern while held (no update to R2)
	TST R3, #0x08
	BNE write_and_delay

	@ Normal counting: add step and keep to 8 bits
	ADDS R2, R2, R4
	UXTB R2, R2

write_and_delay:
	@ Write LEDs to GPIOB ODR
	STR R2, [R1, #0x14]

	@ Busy-wait delay
delay_loop:
	SUBS R7, R7, #1
	BNE delay_loop
	B main_loop

@ LITERALS; DO NOT EDIT
	.align
RCC_BASE: 			.word 0x40021000
AHBENR_GPIOAB: 		.word 0b1100000000000000000
GPIOA_BASE:  		.word 0x48000000
GPIOB_BASE:  		.word 0x48000400
MODER_OUTPUT: 		.word 0x5555

@ TODO: Add your own values for these delays
LONG_DELAY_CNT: 	.word 1400000	@ ~0.7s at ~8MHz HSI (tune on target)
SHORT_DELAY_CNT: 	.word 600000	@ ~0.3s at ~8MHz HSI (tune on target)
