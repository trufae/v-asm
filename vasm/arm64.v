module vasm

pub struct AsmTargetArm64 {
mut:
	cpuregs []string
	resolve AsmResolver
}

pub fn (target AsmTargetArm64) assemble_insn(mut block AsmBlock, code []string) ?[]byte {
	t := AsmTarget(target)
	//
	// fn (mut block AsmBlock) assemble_instruction(code []string) ?[]byte {
	match code[0] {
		'nop' {
			t.check_syntax(code, 0, []) ?
			return [byte(0x1f), 0x20, 0x03, 0xd5]
		}
		else {
			return error('unknown instruction: ${code[0]}')
		}
	}
}

pub fn new_arm64(res AsmResolver) AsmTarget {
	mut target := AsmTargetArm64{
		resolve: res
		cpuregs: [
			'r0',
			'r1',
			'r2',
			'r3',
			'r4',
			'r5',
			'r6',
			'r7',
		]
	}
	return target
}
