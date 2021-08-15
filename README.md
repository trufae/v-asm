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
$ v run main.v mov rax, 33
b800000021

$ v run main.v test.amd64.asm
b8000000210f05cd8090ebfbb800000015
```

## Using the API
