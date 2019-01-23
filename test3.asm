
;
; Program to multiply an integer by the constant 6.
; Before execution, an integer must be stored in NUMBER.
;
		.ORIG 	x200
		JSR 	L1 ; Perform jump to the entry point.

		.ORIG	x600
L1		JSR		L2
		
		.ORIG 	xa00
L2		JSR 	L3

		.ORIG 	xe00
L3		JSR		L4

		.ORIG	x1200
L4		JSR		L5

		.ORIG	x1600
L5		JSR 	L6

		.ORIG	x1a00
L6		JSR		L7

		.ORIG	x1e00
L7		JSR		L8

		.ORIG	x2200
L8		JSR		L9

		.ORIG	x2600
L9		JSR		L10

		.ORIG x2a00
L10		JSR		L11

		.ORIGx2e00
L11		JSR		START

		.ORIG	x3050
START	LD		R1,SIX
		LD		R2,NUMBER
		AND		R3,R3,#0

; The inner loop
;
AGAIN	ADD	R3,R3,R2
		ADD R1,R1,#-1
		BRp	AGAIN

;
		TRAP x25
;
NUMBER	.BLKW	1
SIX		.FILL	x0006
;
		.END
