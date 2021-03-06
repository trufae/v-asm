all:
	v run main.v
	v run main.v test.amd64.asm
	v run main.v -arm64 test.arm64.asm
	v run example.v > a.v
	-v run a.v

fmt:
	v fmt -w *.v
	v fmt -w vasm/*.v
