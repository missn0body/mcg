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
	mov	rdi, prog_pre
	call	puts
	mov	rdi, %1
	call	puts
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
	shiftnum	equ 31
	regsiz		equ 8
	bufsiz		equ 32

section .text
global _start

_start:
	mov	rax, 0xC9	; we want to get time
	syscall
	mov	[seed], rax	; save our seed for later, in case
	call	report		; call a report
	call	exit_success	; and exit cleanly

report:
	status	seed_rep	; see the macro above
	mov	rax, [seed]	; retrieve the saved seed
	mov	rdi, seedbuf	; load in the buffer
	call	itoa_10		; and convert the number in rax
	mov	rdi, seedbuf	; reload the clobbered register
	call	puts		; and print it
	mov	rdi, nl		; with a newline as well
	call	puts
	status	mult_rep	; print first part of string
	mov	rax, mult	; set number for conversion
	mov	rdi, multbuf	; and the buffer
	call	itoa_16		; convert!
	mov	rdi, multbuf	; load the buffer
	call	puts
	mov	rdi, modu_rep	; print first part of string
	call	puts
	mov	rax, mod	; set number for conversion
	mov	rdi, modubuf	; and the buffer
	call	itoa_16		; convert!
	mov	rdi, modubuf	; load the buffer
	call	puts
	mov	rdi, nl		; and then put a newline
	call	puts
	ret

section .bss
	seed	resb	regsiz
	seedbuf	resb	bufsiz
	multbuf	resb	bufsiz
	modubuf	resb	bufsiz
