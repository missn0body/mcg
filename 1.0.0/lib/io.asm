%include "lib/defs.asm"

; basic implementation of libc puts()
; NOTE, requires a null-terminated string
; rdi = address of null-terminated string
puts:
	push	rsi
	xor	rax, rax	; make sure register is clear for length
	call	strlen		; rdi should already contain address
	mov	rdx, rax	; move the count given into its place
	mov	rsi, rdi	; ready the address for the write() call
	mov	rax, 1		; we want to write...
	mov	rdi, STDOUT	; ... to stdout
	syscall
	pop	rsi
	ret

; basic implementation of libc strlen()
; rdi = address of string
; rax = length of string
strlen:
	push	rcx
	lea	rax, [rdi + 1]	; load input, as well as incrementing

strlen_loop:
	mov	cl, byte [rax]	; and move the first character into the lowest part of rcx
	inc	rax		; increment length
	test	cl, cl		; is the current byte null?
	jnz	strlen_loop	; if not, keep repeating
	sub	rax, rdi
	pop	rcx
	ret

; implementation of libc strcmp()
; NOTE: requires null-terminated strings
; rsi = address of string
; rdi = address of string
; rax = the difference of the strings
strcmp:
	push	r10
	push	r11
	xor	rcx, rcx		; ready counter

strcmp_loop:
	mov	r10b, [rdi + rcx]	; load each index
	mov	r11b, [rsi + rcx]
	cmp	r10b, r11b		; how do they compare?
	jne	strcmp_end		; if they aren't equal, exit
	test	r10b, r10b		; has the first string ended?
	je	strcmp_end		; if so, exit
	inc	rcx			; increment
	jmp	strcmp_loop		; and restart

strcmp_end:
	sub	r10b, r11b		; get the difference from indexes
	movsx	rax, r10b		; and load to returnValue
	pop	r11
	pop	r10
	ret

; implementation of libc atoi()
; NOTE: will not detect negative values
; rdi = address of string
; rax = resulting number
atoi:
	push	rcx
	xor	rax, rax		; reset returnValue

atoi_loop:
	movzx	rcx, byte [rdi]		; loading next index
	sub	rcx, '0'		; subtract 48 to convert from ASCII to int
	jl	atoi_end		; invalid character?
	cmp	rcx, 9			; was it too high?
	jg	atoi_end		; if so, return

	lea	rax, [rax * 4 + rax]	; rax = result * 5
	lea	rax, [rax * 2 + rcx]    ; rax = result * 5 * 2 + digit = result * 10 + digit
	inc	rdi			; rdi = address of next character
	jmp	atoi_loop

atoi_end:
	pop	rcx
	ret

; implementation of libc itoa(), into decimal representation
; rax = binary integer
; rdi = address of string
itoa_10:
	push 	rdx
	push 	rcx
	push 	rbx
	push 	rax

	mov 	rbx, 10		; base of the decimal system
	xor 	ecx, ecx	; number of digits generated

itoa_10_nextdiv:
	xor 	edx, edx	; rax extended to (rdx,rax)
	div 	rbx		; divide by the number-base
	push 	rdx		; save remainder on the stack
	inc 	rcx		; and count this remainder
	cmp 	rax, 0		; was the quotient zero?
	jne 	itoa_10_nextdiv	; no, do another division

itoa_10_nextdigit:
	pop 	rax			; else pop recent remainder
	add 	al, '0'			; and convert to a numeral
	stosb				; store to memory-buffer
	loop	itoa_10_nextdigit	; again for other remainders
	xor	al, al
	stosb				; store the null terminator

	pop	rax
	pop	rbx
	pop	rcx
	pop 	rdx
	ret

; implementation of libc itoa(), but specifically for hexadecimal
; rax = binary integer
; rdi = address of string
itoa_16:
	push	rdx
	push	rcx
	push	rbx
	push	rax

	mov	rbx, 16		; base of the decimal system
	xor	ecx, ecx	; number of digits generated

itoa_16_nextdiv:
	xor	edx, edx	; rax extended to (rdx,rax)
	div	rbx		; divide by the number-base
	push	rdx		; save remainder on the stack
	inc	rcx		; and count this remainder
	cmp	rax, 0		; was the quotient zero?
	jne	itoa_16_nextdiv	; no, do another division

itoa_16_nextdigit:
	pop	rax		; else pop recent remainder
	add	al, '0'		; and convert to a numeral
	cmp	al, 57		; are we past the digits?
	jle	itoa_16_noadd	; if not, continue
	add	al, 7		; else, add 7 so we can get letters

itoa_16_noadd:
	stosb				; store to memory-buffer
	loop	itoa_16_nextdigit	; again for other remainders
	mov	al, '.'
	stosb
	xor	al, al
	stosb

	pop	rax
	pop	rbx
	pop	rcx
	pop	rdx
	ret

; exit with return code 0
exit_success:
	mov     rax, 60
	mov     rdi, EXIT_SUCCESS
	syscall

; exit with return code -1
exit_failure:
	mov     rax, 60
	mov     rdi, EXIT_FAILURE
	syscall
