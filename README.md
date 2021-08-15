# vasm

Assembler API for the V programming language.

This library aims to provide the interface to generate native code out of a string

## Features

* Compatible with rasm2 (from the radare2 project)
* Supports at least amd64 and arm64
* Statements separated by newlines or semicolons
* Support multiple architectures
* Limited instruction set supported
* Special syntax (not full-compliant with the spec)
* Aims to be used by the asm {} V statement for the C and Native backends
* Absolute and relative relocs
* Variables from V can be accessed by using the $ prefix
* Empty lines and comments // # are skipped

## Example

This is an example on how to use the main program:

```
$ v run main.v mov eax, 33
b800000021

$ v run main.v test.amd64.asm
b8000000210f05cd8090ebfbb800000015
```

## Using the API

```v

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
```

outputs:

```v
$ v run example.v | v fmt - > a.v
$ cat a.v

fn main() {
	myvar := $if macos { 0x2000001 } $else { 1 }
	rc := 42
	mut res := 0
	asm amd64 {
		mov edi, rc
		mov eax, myvar
		syscall
		mov res, eax
		; =r (res)
		; r (rc)
		  r (myvar)
	}
	println(res)
}
```

Runs like this:

```
$ v run a.v
$ echo $?
42
```
