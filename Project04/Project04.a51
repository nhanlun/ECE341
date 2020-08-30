Time1 EQU P2
Time2 EQU P1
Selector11 EQU P3.0
Selector12 EQU P3.1
Tmpbit EQU P3.2
Mode EQU P3.3 //1 for running, 0 for changing time
ModeButton EQU P3.4
LightButton EQU P3.5
DecreaseButton EQU P3.6
IncreaseButton EQU P3.7
Selector21 EQU P0.0
Selector22 EQU P0.1
Err EQU P0.2
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
	
	call SetupTime
	clr Selector11
	clr Selector12
	clr Selector21
	setb Selector22
	setb Err
	mov R5, #10H
	CALL GetTime1
	CALL GetTime2
	CALL DisplayTime1
	CALL DisplayTime2
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
	call CheckTime
	jnc call_Err
	setb Mode
	clr Selector11
	clr Selector12
	clr Selector21
	setb Selector22
	call GetTime1
	call GetTime2
	call DisplayTime1
	call DisplayTime2
	ret
	negate:
	clr Mode
	clr Selector11
	clr Selector12
	clr Selector21
	clr Selector22
	call GetTime1
	call GetTime2
	call DisplayTime1
	call DisplayTime2
	exit_mode_button:
	setb Err
	ret
	call_Err:
	clr Err
	ret
CheckLightButton:
	jb Mode, exit_light_button
	setb LightButton
	jb LightButton, exit_light_button
	jnb LightButton, $
	call ChangeLight1
	call GetTime1
	call ChangeLight2
	call GetTime2
	call DisplayTime1
	call DisplayTime2
	exit_light_button:
	ret
CheckDecreaseButton:
	jb Mode, exit_decrease_button
	setb DecreaseButton
	jb DecreaseButton, exit_decrease_button
	jnb DecreaseButton, $
	dec R6
	call SaveTime
	call GetTime1
	call DisplayTime1
	call GetTime2
	call DisplayTime2
	exit_decrease_button:
	ret
CheckIncreaseButton:
	jb Mode, exit_increase_button
	setb IncreaseButton
	jb IncreaseButton, exit_increase_button
	jnb IncreaseButton, $
	inc R6
	call SaveTime
	call GetTime1
	call DisplayTime1
	call GetTime2
	call DisplayTime2
	exit_increase_button:
	ret
CheckTime:
	mov R0, #10H
	mov A, @R0
	inc R0
	subb A, @R0
	inc R0
	subb A, @R0
	jnz clear_carry
	setb C
	ret
	clear_carry:
	clr C
	ret
SetupTime:
	MOV R0, #10H
	MOV A, #08H
	MOV @R0, A
	MOV R0, #11H
	MOV A, #03H
	MOV @R0, A
	MOV R0, #12H
	MOV A, #05H
	MOV @R0, A
	RET	
	
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
	
ChangeLight1:
	mov C, Selector11
	mov Tmpbit, C
	mov C, Selector12
	mov Selector11, C
	mov C, Tmpbit
	mov Selector12, C
	jnb Selector11, ToggleSelector12
	ret
	ToggleSelector12:
	jb Selector12, clear2
	setb Selector12
	ret
	clear2:
	clr Selector12
	ret
	

GetTime1:
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
Countdown1:
	dec R6
DisplayTime1:
	mov A, R6
	mov B, #10
	div AB
	swap A
	orl A, B
	mov Time1, A
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
	call Countdown1
	call Countdown2
	cjne R6, #0, exit_interrupt
	call ChangeLight1
	call GetTime1
	call DisplayTime1
	exit_interrupt:
	cjne R2, #0, actual_exit_interrupt
	call ChangeLight2
	call GetTime2
	call DisplayTime2
	actual_exit_interrupt:
	reti
	setting_mode:
	reti
ChangeLight2:
	mov C, Selector21
	mov Tmpbit, C
	mov C, Selector22
	mov Selector21, C
	mov C, Tmpbit
	mov Selector22, C
	jnb Selector21, ToggleSelector22
	ret
	ToggleSelector22:
	jb Selector22, clear22
	setb Selector22
	ret
	clear22:
	clr Selector22
	ret
GetTime2:
	mov A, P0
	mov R3, #03H
	anl A, R3
	mov R4, A 
	mov A, R5
	add A, R4
	mov R0, A
	mov A, @R0
	mov R2, A
	ret
Countdown2:
	dec R2
DisplayTime2:
	mov A, R2
	mov B, #10
	div AB
	swap A
	orl A, B
	mov Time2, A
	ret
END