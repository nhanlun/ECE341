output_port equ p0
	
return_port equ p1.0

hour equ 40H
minute equ 41H
second equ 42H
array equ 3FH
cmp equ 43H			; array for limit of hour, minute, second

led1 equ p1.1
led2 equ p1.2
led3 equ p1.3
	
button_mode equ p1.5
button_up equ p1.6
button_down equ p1.7

delay equ 20		; delay 20 times (each time 50ms), 1s = 20 * 50ms 

org 1000H
	table: db 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH     ; array to decode bcd to 7 segment display
org 0
	jmp main
org 0BH
	ljmp interrupt	; interrupt for delay 1s
org 30H
	
main:
	mov p2, #0FFH	; turn off every display
	mov ie, #82H	; enable interrupt 0
	mov tmod, #1	; choose mode 1 for counter 0
	mov th0, #high(-50000)
	mov tl0, #low(-50000)
	setb tr0
	mov r7, #delay
	
	mov hour, #0
	mov minute, #0
	mov second, #0
	
	mov 44H, #24	; limit for hour
	mov 45H, #60	; limit for minute
	mov 46H, #60	; limit for second
	
main_loop:
	clr led1		
	clr led2
	clr led3
	call check_button_mode	; mode 0, 1, 2, 3. 0 for running, 1 for setting hour, 2 for setting minute, 3 for setting second
	mov a, r6
	jz no_mode ; no mode chosen
	call turn_on_led
	call small_delay
	call check_button_up
	call small_delay
	call check_button_down
	call small_delay
no_mode:
	call output
	call small_delay
	jmp main_loop
	
;--------------------------------------------------------------------------------------
interrupt:
	clr tr0
	mov th0, #high(-50000)
	mov tl0, #low(-50000)
	setb tr0
	cjne r6, #0, exit_interrupt     ; if mode <> 0 (setting something) then the clock won't count
	djnz r7, exit_interrupt
	mov r7, #delay
	clr return_port					; increase second, if overflow then return_port will turn on
	call increase_second
	jnb return_port, exit_interrupt
	call increase_minute			; if return_port turn on then increase minute, if overflow the return port will turn on
	jnb return_port, exit_interrupt
	call increase_hour
exit_interrupt:
	reti
	
;--------------------------------------------------------------------------------------
check_button_mode:
	setb button_mode
	jb button_mode, button_mode_not_pressed
	jnb button_mode, $
	inc r6
	mov a, r6
	mov b, #4
	div ab
	mov r6, b
button_mode_not_pressed:
	ret
	
turn_on_led:		; since the led is p1.1 p1.2 p1.3, so we shift the led signal to the correct port
	mov a, #1
	mov b, r6
	mov r5, b
choose_led:
	rl a
	djnz r5, choose_led
	orl a, #0F0H
	mov p1, a
	ret

check_button_up:
	setb button_up
	jb button_up, button_up_not_pressed
	jnb button_up, $
		
	; calculate the index in the array, if setting hour then we access index 1, minute index 2, second index 3
	mov a, r6           
	add a, #array
	mov r0, a
	inc @r0
	
	; check if the number is over the limit
	mov a, r6
	add a, #cmp
	mov r1, a
	mov a, @r1
	subb a, @r0
	jnz button_up_not_pressed
	mov @r0, #0 	; if the increased number = limit then reset it to 0
button_up_not_pressed:
	ret

check_button_down:
	setb button_down
	jb button_down, button_down_not_pressed
	jnb button_down, $
		
	; calculate the index in the array, if setting hour then we access index 1, minute index 2, second index 3
	mov a, r6
	add a, #array
	mov r0, a
	dec @r0
	
	; check if the number is -1
	cjne @r0, #-1, button_down_not_pressed
	mov a, r6
	add a, #cmp
	mov r1, a
	mov a, @r1
	dec a
	mov @r0, a
button_down_not_pressed:
	ret

increase_second:
	inc second
	mov r3, second
	clr return_port
	cjne r3, #60, increase_second_done
	mov second, #0
	setb return_port			; overflow, set return_port = 1
increase_second_done:
	ret
	
increase_minute:
	inc minute
	mov r3, minute
	clr return_port
	cjne r3, #60, increase_minute_done
	mov minute, #0
	setb return_port			; overflow, set return_port = 1
increase_minute_done:
	ret
	
increase_hour:
	inc hour
	mov r3, hour
	clr return_port
	cjne r3, #24, increase_hour_done
	mov hour, #0
	setb return_port			; overflow, set return_port = 1
increase_hour_done:
	ret
	
output:
	call output_hour
	call output_minute
	call output_second
	ret
	
output_hour:
	mov a, hour
	call calculate			; convert hour to bcd to display
	
	; display the first digit of hour
	mov b, a
	anl a, #0F0H			
	swap a
	mov dptr, #table
	movc a, @a + dptr
	mov output_port, a
	clr p2.0
	call small_delay
	setb p2.0
	
	; display the second digit of hour
	mov a, b
	anl a, #0FH
	mov dptr, #table
	movc a, @a + dptr
	mov output_port, a
	clr p2.1
	call small_delay
	setb p2.1
	ret

output_minute:
	mov a, minute
	call calculate			; convert minute to bcd to display
	
	; display the first digit of minute
	mov b, a
	anl a, #0F0H
	swap a
	mov dptr, #table
	movc a, @a + dptr
	mov output_port, a
	clr p2.2
	call small_delay
	setb p2.2
	
	; display the second digit of minute
	mov a, b
	anl a, #0FH
	mov dptr, #table
	movc a, @a + dptr
	mov output_port, a
	clr p2.3
	call small_delay
	setb p2.3
	ret

output_second:
	mov a, second
	call calculate			; convert second to bcd to display
	
	; display the first digit of second
	mov b, a
	anl a, #0F0H
	swap a
	mov dptr, #table
	movc a, @a + dptr
	mov output_port, a
	clr p2.4
	call small_delay
	setb p2.4
	
	; display the second digit of second
	mov a, b
	anl a, #0FH
	mov dptr, #table
	movc a, @a + dptr
	mov output_port, a
	clr p2.5
	call small_delay
	setb p2.5
	ret

calculate:
	mov b, #10
	div ab
	swap a
	orl a, b
	ret

small_delay:
	mov r2, #250
	djnz r2, $
	ret

end