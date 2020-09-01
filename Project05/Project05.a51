sensor equ p1.4
output_sensor equ p2
output_setting equ p0
button_up equ p1.6
button_down equ p1.7

skip_rom_code equ 0CCH
read_scratch_pad_code equ 0BEH
write_scratch_pad_code equ 4EH
convert_code equ 44H

array_setting equ 50H
array_sensor equ 40H
led equ p1.5
	
org 1000H
	table: db 40H, 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH
org 0
main:
	mov r6, #25 ; default
	call config_sensor
	
main_loop:
	clr led
	call check_button_up
	call check_button_down

	call convert_sensor
	call delay_100ms
	call read_temp
	
	call compare
	
	mov r0, #array_sensor
	call calculate          ; calculate and store into array sensor
	call output
	
	jmp main_loop
;---------------------------------------------------------

compare:
	mov b, a
	xrl a, r6
	anl a, #80H
	jz same_sign
	mov a, r6
	anl a, #80H
	jz done_compare
	jmp set_led
same_sign:
	clr c
	mov a, r6
	subb a, b
	jnc done_compare
set_led:
	setb led
	call delay_500us
	call delay_500us
done_compare:
	mov a, b
	ret

check_button_up:
	setb button_up
	jb button_up, button_up_not_pressed
	jnb button_up, $
	inc r6
	cjne r6, #126, button_up_not_pressed
	mov r6, #125
button_up_not_pressed:
	mov a, r6
	mov r0, #array_setting
	call calculate
	ret
	
check_button_down:
	setb button_down
	jb button_down, button_down_not_pressed
	jnb button_down, $
	dec r6
	cjne r6, #-56, button_down_not_pressed
	mov r6, #-55
button_down_not_pressed:
	mov a, r6
	mov r0, #array_setting
	call calculate
	ret

output:
	mov a, 40H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_sensor, a
	mov a, 50H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_setting, a
	mov p3, #0EEH
	call delay_500us
	mov p3, #0FFH
	call delay_500us
		
	mov a, 41H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_sensor, a
	mov a, 51H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_setting, a
	mov p3, #0DDH
	call delay_500us
	mov p3, #0FFH
	call delay_500us
	
	mov a, 42H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	orl a, #80H                   ;decimal point
	mov output_sensor, a
	mov a, 52H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	orl a, #80H                   ;decimal point
	mov output_setting, a
	mov p3, #0BBH
	call delay_500us
	mov p3, #0FFH
	call delay_500us
	
	mov a, 43H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_sensor, a
	mov a, 53H
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_setting, a
	mov p3, #077H
	call delay_500us
	mov p3, #0FFH
	call delay_500us
	ret
	
delay_500us:
	mov r7, #250
	djnz r7, $
	ret
	
calculate:
	mov r1, #3
	mov b, a
	mov a, r0
	add a, #3
	mov r0, a
	mov a, b
	anl a, #80H
	mov r2, #0
	jz not_negative
	mov a, b
	cpl a
	inc a
	mov r2, #-1
	jmp loop_calculate
not_negative:
	mov a, b
loop_calculate:
	mov b, #10
	div ab
	dec r0
	mov @r0, b
	djnz r1, loop_calculate

	cjne r2, #-1, done_calculate
	mov @r0, #-1
done_calculate:
	ret

read_temp:
	call reset_sensor
	jc cannot_reset_sensor
	mov a, #skip_rom_code
	call write_byte
	mov a, #read_scratch_pad_code
	call write_byte
	call read_byte
	mov 43H, #0
	mov r1, a
	anl a, #08H
	jz no_decimal
	mov 43H, #5
no_decimal:
	mov a, r1
	anl a, #0F0H
	mov b, a
	call read_byte
	anl a, #0FH
	orl a, b
	swap a
cannot_reset_sensor:
	ret
		
convert_sensor:
	call reset_sensor
	mov a, #skip_rom_code
	call write_byte
	mov a, #convert_code
	call write_byte
	ret
		
config_sensor:
	call reset_sensor
	mov a, #skip_rom_code
	call write_byte
	mov a, #write_scratch_pad_code
	call write_byte
	mov a, #00H
	call write_byte
	mov a, #00H
	call write_byte
	mov a, #1FH
	call write_byte
	ret
	
reset_sensor:
	setb sensor
	nop 
	nop
	nop
	clr sensor
	mov r1, #240
	djnz r1, $
	setb sensor
	mov r1, #35
	djnz r1, $
	mov c, sensor
	mov r1, #205
	djnz r1, $
	ret

write_0:
	clr sensor
	mov r2, #30
	djnz r2, $
	setb sensor
	mov r2, #5
	djnz r2, $
	ret
	
write_1:
	clr sensor
	nop
	nop
	nop
	nop
	nop
	nop
	setb sensor
	mov r2, #32
	djnz r2, $
	ret

write_byte:
	mov r1, #8
	clr c
loop_write_byte:
	rrc a
	jc write1
	call write_0
	jmp done_write_1bit
write1:
	call write_1
done_write_1bit:
	djnz r1, loop_write_byte
	rrc a                     ; for easy to debug
	ret
	
read_byte:
	mov r1, #8
	clr a
	clr c
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
	mov r2, #27
	djnz r2, $
	nop
	djnz r1, loop_read_byte
	ret

delay_100ms:
	mov r1, #2
loop_delay_100ms:
	call delay_50ms
	djnz r1, loop_delay_100ms
	ret

delay_50ms:
	clr tr0
	clr tf0
	mov th0, #high(-50000)
	mov tl0, #low(-50000)
	setb tr0
	jnb tf0, $
	ret

end