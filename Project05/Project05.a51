sensor equ p3.7
button_up equ p1.6
button_down equ p1.7

led equ p1.5
	
org 0
	mov p3, #0
	mov p2, #0
	mov p1, #0
	mov p0, #0
	
	setb p3.0
	mov p2, #0FFH
main_loop:
	call check_button_up
	call check_button_down
	call reset_sensor
	call skip_rom
	call convert
	call delay_200ms
	jmp main_loop
	
	
check_button_up:
	setb button_up
	jb button_up, exit_button_up
	jnb button_up, $
	inc r7
	cjne r7, #126, exit_button_up
	mov r7, #125
exit_button_up:
	ret
	
check_button_down:
	setb button_down
	jb button_down, exit_button_down
	jnb button_down, $
	dec r7
	cjne r7, #-56, exit_button_down
	mov r7, #-55
exit_button_down:
	ret
	
reset_sensor:
	setb sensor
	mov r1, #10
	djnz r1, $
	clr sensor
	mov r1, #250
	djnz r1, $
	setb sensor
	mov r1, #60
	djnz r1, $
	jnb sensor, $
	setb led
	ret
	
skip_rom:
	mov a, #0CCH
	call write_byte
	ret
	
convert:
	mov a, #44H
	call write_byte
	ret
	
write_byte:
	mov r1, #8
loop_write_byte:
	rrc a
	clr sensor
	mov sensor, c
	mov r2, #35
	djnz r2, $
	setb sensor
	djnz r1, loop_write_byte
	mov r2, #30
	djnz r2, $
	ret
	
delay_200ms:
	mov r1, #4
loop_delay_200ms:
	call delay_50ms
	djnz r1, loop_delay_200ms
	ret
	
delay_50ms:
	mov tmod, #1
	mov tcon, #0
	mov th0, #high(-50000)
	mov tl0, #low(-50000)
	setb tr0
	jnb tf0, $
	ret
end