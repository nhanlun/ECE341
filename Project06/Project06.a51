button_up equ p2.6
button_down equ p2.7
sensor equ p2.0
light equ p2.1
	
output_sensor equ p0
output_humid equ p1
output_temp equ p3
org 0
	mov r1, #25
	clr light
	mov output_sensor, #25H
	
main_loop:
	setb button_up
	setb button_down
	
	call check_button_up
	call check_button_down
	
	clr sensor
	call wait_20ms
	setb sensor
	jb sensor, $
	jnb sensor, $
	jb sensor, $
	call receive
	setb sensor
	
	clr c
	mov a, r1
	subb a, r2
	setb light
	jc do_nothing
	clr light
do_nothing:
	
	mov r7, #5
loop:
	call wait_20ms
	djnz r7, loop
	
	jmp main_loop


receive:
	call receive_1_byte
	call calculate
	mov output_humid, a
	call receive_1_byte
	call receive_1_byte
	mov r2, a
	call calculate
	mov output_temp, a
	call receive_1_byte
	call receive_1_byte
	ret
	
receive_1_byte:
	mov a, #0
	mov r6, #8
	loop_receive_1_byte:
		mov r7, #20
		rl a
		jnb sensor, $
		djnz r7, $
		mov b, p2
		anl b, #01H
		orl a, b
		jb sensor, $
		djnz r6, loop_receive_1_byte
	ret
	
check_button_up:
	jb button_up, not_push_up	
	jnb button_up, $
	inc r1
	cjne r1, #100, continue_not_push_up
	mov r1, #99
continue_not_push_up:
	mov a, r1
	call calculate
	mov output_sensor, a
not_push_up:
	ret
	
check_button_down:
	jb button_down, not_push_down	
	jnb button_down, $
	dec r1
	cjne r1, #-1, continue_not_push_down
	mov r1, #0
continue_not_push_down:
	mov a, r1
	call calculate
	mov output_sensor, a
not_push_down:
	ret

calculate:
	mov b, #10
	div ab
	swap a
	orl a, b
	ret
	
wait_20ms:
	mov tmod, #1
	mov tcon, #0
	mov th0, #high(-20000)
	mov tl0, #low(-20000)
	setb tr0
	jnb tf0, $
	ret
	
end