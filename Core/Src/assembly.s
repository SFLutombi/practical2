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

@ Masks for clarity
.equ SW0_MASK, 0x0001		@ PA0 - step +2 when pressed
.equ SW1_MASK, 0x0002		@ PA1 - short delay when pressed
.equ SW2_MASK, 0x0004		@ PA2 - force 0xAA when pressed
.equ SW3_MASK, 0x0008		@ PA3 - freeze when pressed

main_loop:
	@ Read GPIOA IDR (active-low switches)
	LDR  R0, GPIOA_BASE
	LDR  R3, [R0, #0x10]		@ IDR

	@ SW3 freeze while held
	MOVS R5, #SW3_MASK
	TST  R3, R5			@ pressed -> bit=0 -> Z=1
	BEQ  state_freeze

	@ SW2 force 0xAA while held
	MOVS R5, #SW2_MASK
	TST  R3, R5
	BEQ  state_force_AA

	@ Step: default 1, if SW0 pressed then 2
	MOVS R4, #1
	MOVS R5, #SW0_MASK
	TST  R3, R5
	BNE  step_decided
	MOVS R4, #2
step_decided:

	@ Output current value
	STR  R2, [R1, #0x14]		@ ODR

	@ Delay selection by SW1
	LDR  R3, [R0, #0x10]
	MOVS R5, #SW1_MASK
	TST  R3, R5
	BEQ  use_short_delay_normal
use_long_delay_normal:
	BL   delay_long
	B    do_increment
use_short_delay_normal:
	BL   delay_short

do_increment:
	ADDS R2, R2, R4			@ next value
	UXTB R2, R2			@ keep to 8 bits
	B    main_loop

@ SW2: force 0xAA
state_force_AA:
	MOVS R2, #0xAA
	STR  R2, [R1, #0x14]
	LDR  R3, [R0, #0x10]
	MOVS R5, #SW1_MASK
	TST  R3, R5
	BEQ  use_short_delay_AA
use_long_delay_AA:
	BL   delay_long
	B    main_loop
use_short_delay_AA:
	BL   delay_short
	B    main_loop

@ SW3: freeze current value
state_freeze:
	STR  R2, [R1, #0x14]
	LDR  R3, [R0, #0x10]
	MOVS R5, #SW1_MASK
	TST  R3, R5
	BEQ  use_short_delay_freeze
use_long_delay_freeze:
	BL   delay_long
	B    main_loop
use_short_delay_freeze:
	BL   delay_short
	B    main_loop

@ Busy-wait delays (tune on target clock)
delay_long:
	LDR  R6, LONG_DELAY_CNT
1:	SUBS R6, R6, #1
	BNE  1b
	BX   LR

delay_short:
	LDR  R6, SHORT_DELAY_CNT
2:	SUBS R6, R6, #1
	BNE  2b
	BX   LR

@ LITERALS; DO NOT EDIT
	.align
RCC_BASE: 			.word 0x40021000
AHBENR_GPIOAB: 		.word 0b1100000000000000000
GPIOA_BASE:  		.word 0x48000000
GPIOB_BASE:  		.word 0x48000400
MODER_OUTPUT: 		.word 0x5555

@ Delay constants
LONG_DELAY_CNT: 	.word 1400000	@ ~0.7s at ~8MHz HSI (tune on target)
SHORT_DELAY_CNT: 	.word 600000	@ ~0.3s at ~8MHz HSI (tune on target)
