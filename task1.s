				AREA	main, CODE, READONLY
				EXPORT __main
				ENTRY

__main			PROC

				ldr 	r0, =7
				ldr		r1, =0
				push	{r0, r1}
				bl		isPrime

				pop		{r0, r1}		; R1 now holds the result
	
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