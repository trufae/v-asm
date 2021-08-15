	mov eax, 33
	syscall;nop;nop
label:
	int 0x80
	mov eax, %myvar
	nop
	jmp label
	mov eax, 21
