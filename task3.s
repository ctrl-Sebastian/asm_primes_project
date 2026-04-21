				AREA	myData, DATA, READWRITE
GPIO_B_BASE		EQU		0x48000400
RCC_BASE		EQU		0x40021000
	
GPIO_MODER		equ		0x00
GPIO_ODR		equ		0x14
	
RCC_AHB2ENR		equ		0x4C
	
result			SPACE	40			; where the result array of primes is going to be stored
size_of_result 	dcd		0x00			; to increase as a counter

; ======================================================================================================

				AREA	readData, DATA, READONLY
;						   0	 1	   2	 3	   4	 5	   6	 7	   8	 9
seg_patterns    DCB     0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
				ALIGN
digit_select    DCW		0x0E00		; Thousands
				DCW     0x0D00      ; Hundreds (CA2)
                DCW     0x0B00      ; Tens     (CA3)
                DCW     0x0700      ; Ones     (CA4)
				ALIGN
array			dcd		17, 37, 89, 223, 509, 541, 673, 4021, 7919, 9973, 482, 1001, 6400, 3456, 121, 777, 8888, 9999, 2500, 444
size			equ		20

; ======================================================================================================

				AREA	myCode, CODE, READONLY
				EXPORT	__main
				ENTRY

__main			proc

				bl		enable_clock
				bl		setup_gpio

;		get prime numbers from the array into the result array
;  --------------------------------------------------------------
				mov		r0, #0			; n
				mov		r1, #0			; true or false
				mov		r2, #0			; counter i = 0
				ldr		r4, =size_of_result
				
				ldr		r5, =0
				str		r5, [r4]			; storing 0 in the result array size variable
				
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
				ldr		r5, [r4]
				add		r5, r5, #1
				str		r5, [r4]
false
				add		r2, #1					; ++i
				cmp		r2, #size
				blt		loop
				
				
				ldr		r12, [r4]
				
;	START DISPLAYING
; ----------------------

reset_loop		ldr		r4, =result
				mov		r5, #0
display_loop		
				cmp		r5, r12
				bge		reset_loop
				
				; get the number from the array into R1

				ldr		r0, [r4, r5, lsl #2]	; r2 holds the current number

				bl		calc_digits				; process r2, r3 & r4
				
												; allocating 4 words
				sub		sp, sp, #16				; pushing the values to display
				
				str     r0, [sp, #0]     		; +0 	= Thousands 
                str     r1, [sp, #4]     		; +4 	= Hundreds  
                str     r2, [sp, #8]     		; +8 	= Tens      	
				str		r3, [sp, #12]			; +12 	= Ones
				
				ldr     r6, =75  
				; (Array location) as arg to R0
mux_1sec        mov     r0, sp
                bl      display_number               
                subs    r6, r6, #1
                bne     mux_1sec			; turn on
				
				bl		display_blank			;
				bl		delay_1sec				; turn off
				
				add		sp, sp, #16
				
				add		r5, r5, #1
				b		display_loop
				endp

; ======================================================================================================

display_blank	proc
				ldr     r0, =GPIO_B_BASE
                ldr     r1, =0x00000FFF
                ldr     r2, [r0, #GPIO_ODR]
                bic     r2, r2, r1
                ldr     r1, =0x00000F00
                orr     r2, r2, r1
                str     r2, [r0, #GPIO_ODR]
                bx      lr
				endp
					
; ======================================================================================================

display_number	proc
				push    {r4-r8, lr}
				mov		r4, r0					; copying digit pointer to r4
				mov		r5, #0					; r5 = loop index
				ldr     r6, =GPIO_B_BASE
                ldr     r7, =seg_patterns
                ldr     r8, =digit_select
				
				
mux_loop		cmp		r5, #3
				bgt		mux_finish	

				ldr		r0, [r4, r5, lsl #2]	; get digit
				ldrb	r1, [r7, r0]			; load segment pattern in position 
												; of digit to display
												
				ldrh	r2, [r8, r5, lsl #1]	; load the digit select half word
				
				; combination of segment pattern and digit selection
				orr		r1, r1, r2
				ldr		r3, =0x00000FFF
				ldr		r0, [r6, #GPIO_ODR]
				bic		r0, r0, r3
				orr		r0, r0, r1
				str		r0, [r6, #GPIO_ODR]
				
				bl		delay_2ms	
				
				; turn off display
				ldr		r3, =0x00000FFF
				ldr		r0, [r6, #GPIO_ODR]
				bic		r0, r0, r3
				ldr     r3, =0x00000F00         ; turn off digits    1000      0000 0000
                orr     r0, r0, r3            ;						4digits    8 segments
				str		r3, [r6, #GPIO_ODR]
				
				
				add		r5, r5, #1
				b		mux_loop	
						
mux_finish		pop 	{r4-r8, pc}			
				endp
; ======================================================================================================


; calc digits return by registers
; r0 holding the number to display
; ======================================================================================================
calc_digits		proc
				push	{r4, r5, lr}
				
				mov		r4, r0			; r4 will hold the ones at the end
				mov		r0, #0			; thousands
				mov		r1, #0			; hundreds counter
				mov		r2, #0			; tens counter
				ldr		r5, =1000
				
calc_1000s		cmp		r4, r5
				blt		calc_100s
				sub		r4, r4, r5
				add		r0, r0, #1
				b		calc_1000s
				
calc_100s		cmp		r4, #100
				blt		calc_10s
				sub		r4, r4, #100
				add		r1, r1, #1				; r4 storing hundreds
				b		calc_100s
				
calc_10s		cmp		r4, #10
				blt		done_calc
				sub		r4, r4, #10
				add		r2, r2, #1				; r3 storing tens
				b		calc_10s
				
done_calc		mov		r3, r4
				pop		{r4, r5, pc}
				endp
; ======================================================================================================

;	isPrime Function
; ======================================================================================================

isPrime			PROC
				push	{r4-r8, lr}		; sp drops by 24
				
				ldr		r4, [sp, #24]	; load n from stack
				
				ldr		r5, =2			;
				cmp		r4, r5			; if n < 2 return false
				blt		return_false	;
				
; 	sqrt function
; 	-------------

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
; ======================================================================================================

enable_clock	proc
	
				ldr		r2, =RCC_BASE
				ldr		r1, [r2, #RCC_AHB2ENR]
				orr		r1, r1, #0x06				;0110	(bit 1 & bit 2)
				str		r1, [r2, #RCC_AHB2ENR]
				bx		lr

				endp

setup_gpio		proc
	
				;		configuring port b 12 pins as output
				ldr		r0, =GPIO_B_BASE
				ldr		r1, [r0, #GPIO_MODER]
				ldr		r2, =0x00FFFFFF
				bic		r1, r1, r2
				ldr		r2, =0x00555555
				orr		r1, r1, r2
				str		r1, [r0, #GPIO_MODER]
				
				bx		lr
				endp

; ======================================================================================================

;		delays

delay_2ms       PROC
                push    {r4, r5}
                mov     r4, #10
outer_2ms       mov     r5, #400 
inner_2ms       subs    r5, r5, #1
                bne     inner_2ms
                subs    r4, r4, #1
                bne     outer_2ms
                pop     {r4, r5}
                bx      lr
                ENDP
                    
delay_1sec      PROC
                push    {r4, r5}
                mov     r4, #1500
outer_1sec      mov     r5, #500 
inner_1sec      subs    r5, r5, #1
                bne     inner_1sec
                subs    r4, r4, #1
                bne     outer_1sec
                pop     {r4, r5}
                bx      lr
                ENDP

                ALIGN
                END