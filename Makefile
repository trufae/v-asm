all:
	v run main.v
	v run main.v test.amd64.asm
	v run example.v > a.v
	-v run a.v

fmt:
	v fmt -w main.v
	v fmt -w vasm/*.v
