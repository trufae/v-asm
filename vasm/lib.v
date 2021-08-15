module vasm

const spaces = ' \t\r\n'

pub struct AsmLabel {
	name string
	off  int
}

type AsmResolver = fn (k string) &AsmLabel

pub interface AsmTarget {
	cpuregs []string
	resolve AsmResolver
	assemble_insn(mut AsmBlock, []string) ?[]byte
}

pub struct AsmBlock {
pub mut:
	addr    u64
	code    []byte
	codestr string
	relocs  []AsmReloc
	labels  []AsmLabel
	inputs  []AsmLabel
	outputs []AsmLabel
	// resolve AsmResolver
}

enum RelocType {
	abs // absolute
	rel // relative address
	loc // local variables
}

struct AsmReloc {
	typ   RelocType
	off   int
	siz   int
	name  string
	delta int
}

enum AsmArg {
	svar // stack variable
	reg
	imm
	imm8
	adr
	adr8
}

fn (target AsmTarget) check_syntax(code []string, nargs int, argtyp []AsmArg) ? {
	ins := code[0]
	if code.len != nargs + 1 {
		return error('expected $nargs for $ins')
	}
	for i := 0; i < nargs; i++ {
		cod := code[i + 1]
		match argtyp[i] {
			.reg {
				if cod in target.cpuregs {
				} else {
					return error('invalid register name for $ins')
				}
			}
			.imm {
				if cod[0] != `0` && cod.int() == 0 && !cod[0].is_letter() {
					return error('invalid immediate $cod for $ins')
				}
			}
			.imm8 {
				n := cod.int()
				if cod[0] != `0` && n == 0 && !cod[0].is_letter() {
					return error('invalid immediate $cod for $ins')
				}
				if (n >> 8) > 0 {
					return error('invalid 8bit immediate $cod for $ins')
				}
			}
			.adr, .adr8 {
				// no checks at assembly time, relocation must happen later
			}
			.svar {
				// maybe check with a callback or function from the interface?
				if cod[0] != `$` {
					return error('not a variable')
				}
			}
		}
	}
}

[inline]
fn byt(n int, s int) byte {
	return byte((n >> (s * 8)) & 0xff)
}

fn (block AsmBlock) resolve_label(name string) int {
	for lab in block.labels {
		if lab.name == name {
			return lab.off
		}
	}
	return 0
}

pub fn (mut block AsmBlock) patch_relocs() {
	for rel in block.relocs {
		match rel.typ {
			.abs {
				if rel.siz == 1 {
					eprintln('TODO: abs size')
				} else {
					eprintln('TODO: unsupported rel $rel')
				}
			}
			.rel {
				match rel.siz {
					4 {
						n := rel.delta - block.resolve_label(rel.name)
						block.code[rel.off] = byt(n, 3)
						block.code[rel.off + 1] = byt(n, 2)
						block.code[rel.off + 2] = byt(n, 1)
						block.code[rel.off + 3] = byt(n, 0)
					}
					1 {
						n := rel.delta - block.resolve_label(rel.name)
						block.code[rel.off] = byt(n, 0)
					}
					else {
						eprintln('TODO: unsupported rel $rel')
					}
				}
			}
			.loc {
				label := rel.name
				eprintln('TODO: $label relocation for local variable')
			}
		}
	}
}

pub fn (block AsmBlock) to_cstring() string {
	codestr := block.codestr.replace('$', '')
	mut r := '$codestr\n'
	if block.outputs.len > 0 {
		r += '; '
		for o in block.outputs {
			r += '=r($o.name)\n'
		}
	}
	if block.inputs.len > 0 {
		r += '; '
		for o in block.inputs {
			r += ' r($o.name)\n'
		}
	}
	return r
}

fn trim_comment(res string, token string) string {
	comment := res.index(token) or { -1 }
	if comment != -1 {
		return res[0..comment].trim(vasm.spaces)
	}
	return res
}

pub fn (target AsmTarget) assemble(code string) ?AsmBlock {
	mut block := AsmBlock{}
	mut lines := code.trim(vasm.spaces).split_into_lines()
	for curline in lines {
		inlines := curline.split(';')
		for curinline in inlines {
			// remove comments
			mut line := curinline.trim(vasm.spaces)
			line = trim_comment(line, '//')
			line = trim_comment(line, '#')
			line = line.trim(vasm.spaces)
			line = line.replace_once(' ', ',')
			mut words := line.split(',')
			for i := 0; i < words.len; i++ {
				words[i] = words[i].trim(vasm.spaces)
			}
			if words.len == 0 || words[0].len == 0 {
				continue
			}
			if words[0].ends_with(':') {
				block.labels << AsmLabel{
					name: words[0][0..words[0].len - 1]
					off: block.code.len
				}
			} else {
				res := target.assemble_insn(mut block, words) or { return err }
				block.code << res
			}
			mut w := words[0]
			if words.len > 1 {
				w += ' '
				w += words[1..].join(', ')
			}
			block.codestr += '$w\n'
		}
	}
	return block
}
