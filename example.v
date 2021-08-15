
module main

import vasm
import os

fn main() {
	if os.args.len > 1 {
		os.system('v run example.v | v fmt - > a.v')
		res := os.system('v run a.v')
		eprintln(res)
		return
	}
	asmcode := '
		mov edi, %res
		mov eax, %myvar
		syscall
		mov %res, eax
	'
	resolver := fn (a string) &vasm.AsmLabel {
		if a == 'myvar' {
			return &vasm.AsmLabel{name: a, off: 8}
		}
		if a == 'res' {
			return &vasm.AsmLabel{name: a, off: 4}
		}
		return 0
	}
	mut vcode := 'fn main() {
		myvar := \$if macos { 0x2000001 } \$else { 1 }
		mut res := 42
		asm amd64 {
	'
	a := vasm.new_amd64(resolver)
	bb := a.assemble(asmcode) or {panic(err)}
	vcode += bb.to_cstring()
	println("$vcode
		}
		println(res)
	}
	")
}
