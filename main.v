import vasm
import os
import encoding.hex

const example_program = '
mov rax, 33
syscall
label:
int 0x80
nop
jmp label
mov rax, 21
'

fn slurp_file(b string) string {
	if os.exists(b) {
		return os.read_file(b) or { return b }
	}
	return b
}

fn show_help() {
	println('Usage: v run main.v test.amd64.asm')
}

fn main() {
	resolver := fn (name string) &vasm.AsmLabel {
		eprintln('resolve $name')
		return &vasm.AsmLabel{
			name: name
			off: 4
		}
	}
	mut is_arm64 := false
	mut args := os.args.clone()
	if os.args.len > 1 {
		match os.args[1] {
			'-arm64' {
				is_arm64 = true
				args = args[1..]
			}
			'-h', '-help' {
				show_help()
				return
			}
			else {}
		}
	}
	cstr := if args.len > 1 { slurp_file(args[1..].join(' ')) } else { example_program }
	a := if is_arm64 { vasm.new_arm64(resolver) } else { vasm.new_amd64(resolver) }
	mut bb := a.assemble(cstr) or { panic(err) }
	bb.patch_relocs()
	println(hex.encode(bb.code))
	println(bb.to_cstring())
	// dump(bb)
}
