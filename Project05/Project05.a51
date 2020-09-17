sensor equ p1.4
output_port equ p2
button_up equ p1.6
button_down equ p1.7
button_mode equ p1.3

skip_rom_code equ 0CCH
read_scratch_pad_code equ 0BEH
write_scratch_pad_code equ 4EH
convert_code equ 44H

array_setting equ 50H
array_sensor equ 40H
led equ p1.5
mode equ p1.2			; mode = 1 is setting, 0 is running
	
org 1000H
	table: db 40H, 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH		; array to decode bcd to 7 segment (also included '-' for negative at index 0)
org 0
main:
	mov r6, #25 		; default setting for alarm
	call config_sensor	; choose mode 9 bit for sensor
	clr mode
	
main_loop:
	clr led
	call check_button_mode
	jnb mode, continue	; if it is not in setting mode, then we skip the check up and down. 
	call check_button_up
	call check_button_down
	
continue:
	call convert_sensor	; make the sensor measure new temperature
	call delay_100ms
	call read_temp		; read new temperature from sensor
	
	call compare		; compare the temperature from the sensor with the temperature in setting
	
	mov r0, #array_sensor
	call calculate          ; calculate and store into array sensor
	mov r0, #array_sensor
	jnb mode, output_array_sensor	; if it is in setting mode then we output array setting instead of array sensor
	mov r0, #array_setting
output_array_sensor:
	call output
	
	jmp main_loop
;---------------------------------------------------------

compare:			; if the temperature from sensor and the temperature from setting are the same sign, then we subtract them to compare
					; otherwise we check the sign of the temparature to see which one is smaller.
					; compare with different signs cause the subtraction incorrect.
	mov b, a
	xrl a, r6
	anl a, #80H		; get the sign of 2 temperature
	jz same_sign	; check if they are same sign
	mov a, r6		; if not check which one is smaller. If the temperature from setting (from r6) is smaller, then we raise the alarm.
	anl a, #80H		
	jz done_compare
	jmp set_led
same_sign:
	clr c			
	mov a, r6
	subb a, b
	jnc done_compare ; if temperature from sensor is smaller, then carry is set to 1.
set_led:
	setb led
	call delay_500us
	call delay_500us
done_compare:
	mov a, b
	ret
	
check_button_mode:
	setb button_mode
	jb button_mode, button_mode_not_pressed
	jnb button_mode, $
	cpl mode			; complement of mode (flip bit)
button_mode_not_pressed:
	ret

check_button_up:
	setb button_up
	jb button_up, button_up_not_pressed
	jnb button_up, $
	inc r6						; r6 store the temperature of setting
	cjne r6, #126, button_up_not_pressed
	mov r6, #125				; if r6 is more than 125 set it back to 125
button_up_not_pressed:
	mov a, r6
	mov r0, #array_setting
	call calculate				; convert to bcd and save at array setting to display
	ret
	
check_button_down:
	setb button_down
	jb button_down, button_down_not_pressed
	jnb button_down, $
	dec r6						; r6 store the temperature of setting
	cjne r6, #-56, button_down_not_pressed
	mov r6, #-55				; if r6 is below -55 set it back to -55
button_down_not_pressed:
	mov a, r6
	mov r0, #array_setting
	call calculate				; convert to bcd and save at array setting to display
	ret

output:
	mov a, @r0
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_port, a
	clr p3.0
	call delay_500us
	setb p3.0
	call delay_500us
	
	inc r0
	mov a, @r0
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_port, a
	clr p3.1
	call delay_500us
	setb p3.1
	call delay_500us
	
	inc r0
	mov a, @r0
	mov dptr, #table
	inc a
	movc a, @a + dptr
	orl a, #80H               ; decimal point
	mov output_port, a
	clr p3.2
	call delay_500us
	setb p3.2
	call delay_500us
	
	inc r0
	mov a, @r0
	mov dptr, #table
	inc a
	movc a, @a + dptr
	mov output_port, a
	clr p3.3
	call delay_500us
	setb p3.3
	call delay_500us
	ret
	
	
delay_500us:
	mov r7, #250
	djnz r7, $
	ret
	
calculate:		; take input from a and r0, a holds the value that need to convert to bcd, r0 holds the location to store the result
	mov r1, #3	; the output will be 3 digits, therefore, we convert to bcd for 3 digits
	mov b, a
	mov a, r0
	add a, #3	; start from the end of the array
	mov r0, a
	mov a, b
	anl a, #80H ; check if the value is negative
	mov r2, #0
	jz not_negative
	mov a, b	; if the value is negative we take the absolute of it, then calculate as normal
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

	cjne r2, #-1, done_calculate ; if the value is negative we move -1 to the first position of the array to tell the output function that we need '-' here
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
	mov 43H, #5			; if the information return contain .5 then we move 5 to 43H
no_decimal:
	; combine the 2 half of 2 bytes to get the temperatur.
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