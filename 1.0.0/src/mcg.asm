; https://en.wikipedia.org/wiki/Lehmer_random_number_generator
; A small algorithm in the form of A * X % M, where A is a given integer,
; X is the seed, and M is a given integer

	bits 64
	cpu x64

%include "lib/io.asm"
%include "lib/defs.asm"

;=================================================
; Multiplicative Congruential Generator
; Version 1.0.0
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

%macro	error	1
	status	%1
	call	exit_failure
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

%macro	teststr	1
	mov	rsi, %1
	call	strcmp
	test	rax, rax
%endmacro

;=================================================
; MACROS BEGIN HERE
;=================================================

section .data

	filename:       db 'Multiplicative Congruential Generator '
	version:        db '(v. 1.0.0): '
	signature:      db 'a barebones assembly RNG.', 0Ah
			db 'created by anson <thesearethethingswesaw@gmail.com>', 0Ah, 0Ah, 0
	usage:          db 'Usage:', 0Ah, 09h, 'mcg (-h / --help)', 0Ah
			db 09h, 'mcg (-v / --version)', 0Ah
			db 09h, 'mcg (-r / --report)', 0Ah, 0Ah
			db 'Options:', 0Ah, 09h, '-r, --report', 09h, 'display algorithm internals', 0Ah, 0Ah, 0
	footer:		db 'this product refuses a license, see UNLICENSE for related details', 0Ah, 0

	prog_pre:	db 'mcg: ', 0

	; error messages down below
	bad_args:	db 'unknown argument', 0Ah, 0
	no_args:	db 'too few arguments, try "--help"', 0Ah, 0
	no_opt:		db 'no option argument', 0Ah, 0
	bad_opt:	db 'option argument not a number', 0Ah, 0
	ignore:		db 'non-argument string ignored', 0Ah, 0

	; report messages
	seed_rep:	db 'seed (__x64_sys_time) reports to be ', 0
	mult_rep:	db 'builtins are A = 0x', 0
	modu_rep:	db ', Mod = 0x', 0
	clam_rep:	db 'output is clamped to 0-', 0

	; long argument strings for testing
	help_string:	db 'help', 0
	version_string:	db 'version', 0
	report_string:	db 'report', 0

	nl:		db 0Ah, 0

	mult		equ 0x10A860C1
	mod		equ 0xFFFFFFFB
	defclamp	equ 256

	regsiz		equ 8
	bufsiz		equ 32

section .text
global _start

_start:
	pop	rcx		; get argc off the stack
	cmp	rcx, 2		; are there any arguments?
	jl	noargs		; go off to for further processing
	add	rsp, 8

args_loop:
	pop	rdi		; grab the next argv[] on the stack
	test	rdi, rdi	; does it start with a null character?
	je	noargs		; if so, exit loop
	cmp	[rdi], byte '-'	; does the character begin with a hyphen?
	je	args_parse	; go for further processing
	inc	rbx		; increment count, for each non argument string
	cmp	rbx, 1
	jge	ignore_nonargs	; if we've gotten more than two non-args, tell the user
	jmp	args_loop	; keep checking for more args

args_parse:
	inc	rdi		; move the pointer up one
	cmp	[rdi], byte '-'	; long option?
	je	longargs	; if so, move to different section
	cmp	[rdi], byte 0	; does the argument just end?
	je	args_loop	; if so, continue back to loop

	; the character itself is in rdi

	cmp	[rdi], byte 'h'	; first, test 'h'
	je	print_usage
	cmp	[rdi], byte 'v'	; do we want to print version info?
	je	print_version
	call	unknown_args
	jmp	args_loop

longargs:
	inc	rdi		; move the pointer up one
	cmp	[rdi], byte '-'	; are there even more hyphens???
	je	args_loop	; if so, trash it, go back
	cmp	[rdi], byte 0	; does the arg consist of just two hyphens?
	je	args_loop

	; the string begins at rdi, and is already null-terminated
	; at least, it plays nice with this implementation of puts()

	teststr help_string	; does the argument equal 'help'?
	je	print_usage	; if so, jump to usage
	teststr	version_string	; does the argument equal 'version'?
	je	print_version	; if so, jump to version
	call	unknown_args	; if its not these, we don't know what it is
	jmp	args_loop	; see if theres more arguments


print_usage:
	mov	rdi, filename
	call	puts
	mov	rdi, usage
	call	puts
	mov	rdi, footer
	call	puts
	call	exit_success

print_version:
	mov	rdi, filename
	call	puts
	call	exit_success

; this subroutine does not exit the program but rather
; returns back to the calling point
unknown_args:
	error	bad_args
	ret

ignore_nonargs:
	status	ignore
	jmp	args_loop

noargs:
	mov	rax, 0xC9	; we want to get time
	syscall
	mov	[seed], rax	; save our seed for later, in case
	mov	[clamp], word defclamp
	call	ready
	call	mcg		; our argument is already loaded, so call
	call	simpleclamp
	mov	rdi, outbuf	; load in buffer...
	call	itoa_10		; ... to convert to string
	mov	rdi, outbuf	; reload buffer...
	call	puts		; ... to print out
	mov	rdi, nl		; and also print a newline
	call	puts
	call	report		; call a report
	call	exit_success	; and exit cleanly

; rax = time input
ready:
	push	rdx
	test	rax, 1		; is the input even?
	jnz	ready_exit	; if not, exit early
	shl	rax, 1		; shift left
	or	rax, 1		; and set last bit to one
ready_exit:
	pop	rdx
	ret

; rax = seed
; mult and mod must already be defined
mcg:
	push	rcx
	push	rdx		; save any registers we use

; This is an older, slower method of obtaining a modulus,
; I keep it here as a failsafe for no reason

;	imul	rax, rax, mult	; A * seed ...
;	mov	rdx, mod	; make mod our divisor
;	div	rax		; and divide
;	mov	rax, rdx	; remainder is in rdx
;	and	rax, mod

; This code is a bit hard to describe, see
; https://godbolt.org/z/zn8b4o3c7

	imul    ecx, eax, mult	; A * seed ...
	cmp     ecx, -5
	setnb   al
	movzx   edx, al
	mov     eax, edx
	sal     eax, 2
	add     eax, edx
	neg     eax
	sub     ecx, eax
	mov     edx, ecx
	mov     eax, edx

	pop	rdx
	pop	rcx		; and return contents
	ret

; rax = number to clamp
simpleclamp:
	push	rdx
	mov	rdx, [clamp]
	dec	rdx
	and	rax, rdx	; rax % clamp == rax & (clamp - 1), if rdx is power of two
	pop	rdx
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
	cmp	[clamp], word 0	; is there a clamp set?
	jz	report_exit	; if not, skip entirely
	status	clam_rep	; otherwise report the clamp
	pdec	clamp, clambuf
	mov	rdi, nl
	call	puts
report_exit:
	ret

section .bss

; These are for holding a number
	seed	resb	regsiz
	clamp	resb	regsiz

; These are for holding the string of a number
	seedbuf	resb	bufsiz
	clambuf resb	bufsiz
	multbuf	resb	bufsiz
	modubuf	resb	bufsiz
	outbuf	resb	bufsiz
