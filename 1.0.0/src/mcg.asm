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
	rest_rep:	db 'builtins are A = 0xBC8F, Mod = 0x7FFFFFFF', 0Ah, 0

	nl:		db 0Ah, 0

	mult		equ 0xBC8F
	mod		equ 0x7FFFFFFF
	regsiz		equ 8
	bufsiz		equ 128

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
	status	rest_rep	; print out the rest of the report
	ret

section .bss
	seed	resb	regsiz
	seedbuf	resb	bufsiz
