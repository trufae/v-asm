	mov rax, 33
	syscall;nop;nop
label:
	int 0x80
	mov rax, $myvar
	nop
	jmp label
	mov rax, 21
