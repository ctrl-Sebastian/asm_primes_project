	AREA	mydata, DATA, READONLY
	
array	DCD		3,5,7,9999,20,23,100,97,98,90
	
	AREA	mybutt, DATA, READWRITE
		
result	SPACE	40
				
				
	AREA	main, CODE, READONLY
	EXPORT __main
	ENTRY

;============== MAIN ============================================

__main			PROC

				mov		r0, #0			; n
				mov		r1, #0			; true or false
				mov		r2, #0			; counter i = 0
				ldr 	r12, =array
				ldr		r11, =result
loop
				ldr 	r0, [r12, r2, LSL#2]	; load array value into r0, register offset 4 bytes
				push	{r0, r1}
				bl		isPrime
				pop		{r0, r1}		; R1 now holds if true or false
				
				cmp		r1, #1
				beq		true			; if true store
				b		false
true			str		r0, [r11], #4
false
				add		r2, #1					; ++i
				cmp		r2, #10
				blt		loop
				
stop			b 	stop
				ENDP


;	isPrime Function
;	-----------------
isPrime			PROC
				push	{r4-r8, lr}		; sp drops by 24
				
				ldr		r4, [sp, #24]	; load n from stack
				
				ldr		r5, =2			;
				cmp		r4, r5			; if n < 2 return false
				blt		return_false	;
				
			;	SQRT FUNCTION
			;	-------------
				
				mov		r6, #0
calc_sqrt		mul		r7, r6, r6
				cmp		r7, r4
				bgt		sqrt_found
				
				add		r6, r6, #1
				b		calc_sqrt
sqrt_found		sub		r6, r6, #1
				
				
prime_loop		
				cmp		r5, r6				; r5 = i (counter) r6 = sqrt(n) returned by sqrt function
				bgt		return_true			; if at the end of loop, return true
				
				udiv	r7, r4, r5			; r7 = quotient = n / i
				mul		r8, r7, r5			; r8 = product = quotient * i
				
				cmp		r8, r4				; if product = n return false
				beq		return_false		
				
				add		r5, r5, #1			; i += 1
				b		prime_loop
				
				
return_true		ldr		r1, =1
				str		r1, [sp, #28]
				pop		{r4-r8, pc}
						
return_false	ldr		r1, =0
				str		r1, [sp, #28]
				pop		{r4-r8, pc}
				ENDP