module vasm

pub struct AsmTargetAmd64 {
mut:
	cpuregs []string
	resolve AsmResolver
}

pub fn (target AsmTargetAmd64) assemble_insn(mut block AsmBlock, code []string) ?[]byte {
	t := AsmTarget(target)
	//
	// fn (mut block AsmBlock) assemble_instruction(code []string) ?[]byte {
	match code[0] {
		'cpuid' {
			t.check_syntax(code, 0, []) ?
			return [byte(0x0f), 0xa2]
		}
		'nop' {
			t.check_syntax(code, 0, []) ?
			return [byte(0x90)]
		}
		'syscall' {
			t.check_syntax(code, 0, []) ?
			return [byte(0x0f), 0x05]
		}
		'call' { // call
			t.check_syntax(code, 1, [.reg]) or {
				// assume saddr here
				block.relocs << AsmReloc{
					typ: .rel
					off: block.code.len + 1
					name: code[1]
					siz: 4
					delta: 5
				}
				return [byte(0xe8), 0, 0,0, 0]
			}
			reg := target.cpuregs.index(code[1])
			return [byte(0xff), byte(0xd0 + reg)]
		}
		'jmp' { // jmp
			t.check_syntax(code, 1, [.imm8]) or { return err }
			// only short jump for now
			block.relocs << AsmReloc{
				typ: .rel
				off: block.code.len + 1
				name: code[1]
				siz: 1
				delta: 2
			}
			return [byte(0xeb), 0]
		}
		'int' { // int 0x80
			t.check_syntax(code, 1, [.imm]) or { return err }
			imm := byte(code[1].int())
			return [byte(0xcd), imm]
		}
		'int3' { // int3
			t.check_syntax(code, 0, []) or { return err }
			return [byte(0xcc)]
		}
		'ret' { // ret
			t.check_syntax(code, 0, []) or { return err }
			return [byte(0xc3)]
		}
		'push' { // push reg|imm
			t.check_syntax(code, 1, [.reg]) or {
				t.check_syntax(code, 1, [.imm]) or { return err }
				// XXX only 0-255 value is supported
				imm := byte(code[1].int())
				return [byte(0x6a), imm]
			}
			reg := target.cpuregs.index(code[1])
			return [byte(0x50 + reg)]
		}
		'lea' { // mov reg, addr
			t.check_syntax(code, 2, [.reg, .adr]) ?
			dst := code[2]
			// IGNORED reg := cpuregs.index(code[1])
			reg := target.cpuregs.index(code[1])
			block.relocs << AsmReloc{
				typ: .rel
				off: block.code.len + 4
				name: dst
				siz: 4
				delta: 7
			}
			return [byte(0x48 + reg), 0x8d, 0x05, 0, 0, 0, 0]
		}
		'movl', 'mov' { // mov reg, imm
			t.check_syntax(code, 2, [.reg, .imm]) or {
				t.check_syntax(code, 2, [.loc, .reg]) or {
					t.check_syntax(code, 2, [.reg, .loc]) ?
					varname := code[2][1..]
					varnode := target.resolve(varname)
					if varnode.name != '' {
						block.inputs << varnode
					}
					block.relocs << AsmReloc{
						typ: .loc
						off: block.code.len
						name: code[2][1..]
						siz: 4
						delta: 0
					}
					return [byte(0x48), 0x89, 0x85, 0, 0, 0]
				}
				varname := code[1][1..]
				varnode := t.resolve(varname)
				if varnode.name != '' {
					block.outputs << varnode
				}
				block.relocs << AsmReloc{
					typ: .loc
					off: block.code.len
					name: code[2][1..]
					siz: 4
					delta: 0
				}
				// XXX
				return [byte(0x48), 0x89, 0x85, 0, 0, 0]
			}
			// mov reg, 33
			reg := target.cpuregs.index(code[1])
			dst := code[2].int()
			i0 := byt(dst, 0)
			i1 := byt(dst, 1)
			i2 := byt(dst, 2)
			i3 := byt(dst, 3)
			return [byte(0xb8 + reg), i3, i2, i1, i0]
		}
		else {
			return error('unknown instruction: ${code[0]}')
		}
	}
}

pub fn new_amd64(res AsmResolver) AsmTarget {
	mut target := AsmTargetAmd64{
		resolve: res
		cpuregs: [
			'eax',
			'ecx',
			'edx',
			'ebx',
			'esp',
			'ebp',
			'esi',
			'edi',
		]
	}
	return target
}
