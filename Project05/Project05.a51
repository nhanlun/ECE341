sensor equ p1.4
button_up equ p1.6
button_down equ p1.7

led equ p1.5
	
org 0
	mov p3, #0
	mov p2, #0
	mov p1, #0
	mov p0, #0
	
	mov p2, #000H
	setb sensor
	;call reset_sensor
	;call skip_rom
	;call write_scratch_pad
	
main_loop:
	setb sensor
	;call check_button_up
	;call check_button_down
	;call reset_sensor
	;call skip_rom
	;call convert
	call delay_200ms
	
	call reset_sensor
	call skip_rom
	call read_scratch_pad
	
	call output
	
	call delay_50ms
	jmp main_loop
	
output:
	mov b, #10
	div ab
	swap a
	anl a, #0F0H
	orl a, b
	mov p2, a
	ret

;------------------------------------------------------------------
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
	clr sensor
	mov r1, #240
	djnz r1, $
	setb sensor
	mov r1, #35
	djnz r1, $
	mov r1, #205
	djnz r1, $
	ret
	
read_scratch_pad:
	mov a, #0BEH
	call write_byte
	call read_byte
	anl a, #0F0H
	mov b, a
	call read_byte
	;mov r1, a
	anl a, #00FH
	;clr return_port
	;jz no_decimal
	;setb return_port
no_decimal:
	;mov a, r1
	;anl a, #0F0H
	orl a, b
	swap a
	call reset_sensor
	ret

read_byte:
	mov r1, #8
	mov a, #0
loop_read_byte:
	clr sensor
	nop
	nop
	nop
	nop
	nop
	nop
	setb sensor
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	mov c, sensor
	rrc a
	mov r2, #28
	djnz r2, $
	djnz r1, loop_read_byte
	ret

write_scratch_pad:
	mov a, #04EH
	call write_byte
	mov a, #10H
	call write_byte
	mov a, #10H
	call write_byte
	mov a, #01FH
	call write_byte
	ret
	
skip_rom:
	mov a, #0CCH
	call write_byte
	ret
	
convert:
	mov a, #44H
	call write_byte
	ret
	
write0:	
	clr sensor
	mov r2, #30
	djnz r2, $
	setb sensor
	mov r2, #10
	djnz r2, $
	ret
	
write1:
	clr sensor
	mov r2, #3
	djnz r2, $
	setb sensor
	mov r2, #32
	djnz r2, $
	ret
	
write_byte:
	mov r1, #8
loop_write_byte:
	rrc a
	jnc write_0
	call write1
	jmp done_write_1bit
write_0:
	call write0
done_write_1bit:
	djnz r1, loop_write_byte
	ret
	
	
	clr sensor
	nop 			; small delay
	nop
	mov sensor, c
	mov r2, #30
	djnz r2, $
	setb sensor
	djnz r1, loop_write_byte
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
	clr tf0
	ret
end