module main

import vasm

fn main() {
	asmcode := '
		mov edi, %rc
		mov eax, %myvar
		syscall
		mov %res, eax
	'
	resolver := fn (varname string) &vasm.AsmLabel {
		return match varname {
			'myvar', 'rc', 'res' {
				&vasm.AsmLabel{
					name: varname
					off: 8
				}
			}
			else {
				&vasm.AsmLabel(0)
			}
		}
	}
	mut vcode := 'fn main() {
		myvar := \$if macos { 0x2000001 } \$else { 1 }
		rc := 42
		mut res := 0
		asm amd64 {
	'
	a := vasm.new_amd64(resolver)
	bb := a.assemble(asmcode) or { panic(err) }
	vcode += bb.to_cstring()
	println('$vcode
		}
		println(res)
	}
	')
}
