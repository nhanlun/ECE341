Time EQU P2
Selector1 EQU P3.0
Selector2 EQU P3.1
Tmpbit EQU P3.2
Mode EQU P3.3 //1 for running, 0 for changing time
ModeButton EQU P3.4
LightButton EQU P3.5
DecreaseButton EQU P3.6
IncreaseButton EQU P3.7

ORG 0
	JMP MAIN
	ORG 0BH
	LJMP TIMER0_ISP
	ORG 30H
MAIN:
	MOV IE, #82H
	MOV R7, #20
	MOV TMOD, #1
	MOV TH0, #HIGH(-50000)
	MOV TL0, #LOW(-50000)
	SETB TR0
	
	CALL SetupTime
	clr Selector1
	clr Selector2
	mov R5, #10H
	CALL GetTime
	CALL DisplayTime
	LOOP_MAIN:
	CALL CheckModeButton
	CALL CheckLightButton
	CALL CheckIncreaseButton
	CALL CheckDecreaseButton
	jmp LOOP_MAIN
	
CheckModeButton:
	setb ModeButton
	jb ModeButton, exit_mode_button
	jnb ModeButton, $
	jb Mode, negate
	setb Mode
	ret
	negate:
	clr Mode
	call GetTime
	call DisplayTime
	exit_mode_button:
	ret
CheckLightButton:
	jb Mode, exit_light_button
	setb LightButton
	jb LightButton, exit_light_button
	jnb LightButton, $
	call ChangeLight
	call GetTime
	call DisplayTime
	exit_light_button:
	ret
CheckDecreaseButton:
	jb Mode, exit_decrease_button
	setb DecreaseButton
	jb DecreaseButton, exit_decrease_button
	jnb DecreaseButton, $
	dec R6
	call DisplayTime
	call SaveTime
	exit_decrease_button:
	ret
CheckIncreaseButton:
	jb Mode, exit_increase_button
	setb IncreaseButton
	jb IncreaseButton, exit_increase_button
	jnb IncreaseButton, $
	inc R6
	call DisplayTime
	call SaveTime
	exit_increase_button:
	ret
SaveTime:
	mov A, P3
	mov R3, #03H
	anl A, R3
	mov R4, A 
	mov A, R5
	add A, R4
	
	mov R0, A
	mov A, R6
	mov @R0, A
	ret
	
ChangeLight:
	mov C, Selector1
	mov Tmpbit, C
	mov C, Selector2
	mov Selector1, C
	mov C, Tmpbit
	mov Selector2, C
	jnb Selector1, ToggleSelector2
	ret
	ToggleSelector2:
	jb Selector2, clear2
	setb Selector2
	ret
	clear2:
	clr Selector2
	ret
	
SetupTime:
	MOV R0, #10H
	MOV A, #14H
	MOV @R0, A
	MOV R0, #11H
	MOV A, #03H
	MOV @R0, A
	MOV R0, #12H
	MOV A, #14H
	MOV @R0, A
	RET
GetTime:
	mov A, P3
	mov R3, #03H
	anl A, R3
	mov R4, A 
	mov A, R5
	add A, R4
	mov R0, A
	mov A, @R0
	mov R6, A
	ret
Countdown:
	dec R6
DisplayTime:
	mov A, R6
	mov B, #10
	div AB
	swap A
	orl A, B
	mov Time, A
	ret
	
TIMER0_ISP:
	clr tr0
	mov th0, #high(-50000)
	mov tl0, #low(-50000)
	mov tmod, #1
	setb tr0
	jnb Mode, setting_mode
	djnz R7, exit_interrupt
	mov R7, #20
	CALL Countdown
	CJNE R6, #0, exit_interrupt
	CALL ChangeLight
	CALL GetTime
	exit_interrupt:
	reti
	setting_mode:
	reti
END