; https://en.wikipedia.org/wiki/Lehmer_random_number_generator
; A small algorithm in the form of A * X % M, where A is a given integer,
; X is the seed, and M is a given integer

%include "lib/io.asm"
%include "lib/defs.asm"

;=================================================
; File VIEWer, similar to 'cat'
; Version 1.1.0
; Made by anson, in April 2024
;=================================================

;=================================================
; MACROS BEGIN HERE
;=================================================

%macro status 1
	push	rdi
	mov	rdi, prog_pre
	call	puts
	mov	rdi, %1
	call	puts
	pop	rdi
%endmacro

%macro pdec 2
	push	rdi
	push	rax
	mov	rax, [%1]	; retrieve the saved seed
	mov	rdi, %2		; load in the buffer
	call	itoa_10		; and convert the number in rax
	mov	rdi, %2		; reload the clobbered register
	call	puts		; and print it
	pop	rax
	pop	rdi
%endmacro

%macro phex 2
	push	rdi
	push	rax
	mov	rax, %1		; set number for conversion
	mov	rdi, %2		; and the buffer
	call	itoa_16		; convert!
	mov	rdi, %2		; load the buffer
	call	puts
	pop	rax
	pop	rdi
%endmacro

;=================================================
; MACROS BEGIN HERE
;=================================================

section .data
	prog_pre:	db 'mcg: ', 0

	seed_rep:	db 'seed (__x64_sys_time) reports to be ', 0
	mult_rep:	db 'builtins are A = 0x', 0
	modu_rep:	db ', Mod = 0x', 0

	nl:		db 0Ah, 0

	mult		equ 0xBC8F
	mod		equ 0x7FFFFFFF
	regsiz		equ 8
	bufsiz		equ 32

section .text
global _start

_start:
	mov	rax, 0xC9	; we want to get time
	syscall
	mov	[seed], rax	; save our seed for later, in case
	call	mcg		; our argument is already loaded, so call
	mov	rdi, outbuf	; load in buffer...
	call	itoa_10		; ... to convert to string
	mov	rdi, outbuf	; reload buffer...
	call	puts		; ... to print out
	mov	rdi, nl		; and also print a newline
	call	puts
	call	report		; call a report
	call	exit_success	; and exit cleanly

; rax = seed
; mult and mod must already be defined
mcg:
	push	rdx		; save any registers we use
	imul	rax, rax, mult	; A * seed ...
	mov	rdx, mod	; make mod our divisor
	div	rax		; and divide
	mov	rax, rdx	; remainder is in rdx
	pop	rdx		; and return contents
	ret

report:
	status	seed_rep	; see the macro above
	pdec	seed, seedbuf
	mov	rdi, nl		; with a newline as well
	call	puts
	status	mult_rep	; print first part of string
	phex	mult, multbuf
	mov	rdi, modu_rep	; print first part of string
	call	puts
	phex	mod, modubuf
	mov	rdi, nl		; and then put a newline
	call	puts
	ret

section .bss
	seed	resb	regsiz
	seedbuf	resb	bufsiz
	multbuf	resb	bufsiz
	modubuf	resb	bufsiz
	outbuf	resb	bufsiz
