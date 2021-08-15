all:
	v run main.v

fmt:
	v fmt -w main.v
	v fmt -w vasm/*.v
