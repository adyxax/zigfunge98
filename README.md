# ZigFunge98 : a Funge-98 interpreter written in zig

This repository contains code for a zig program that can interpret a valid [Funge-98](https://github.com/catseye/Funge-98/blob/master/doc/funge98.markdown) program. It passes the [mycology test suite](https://github.com/Deewiant/Mycology).

Current limitations are :
- currently does not implement any fingerprints
- does not implement concurrent execution with the `t` command
- does not implement file I/O with the `i` and `o` commands
- does not implement system execution with the `=` command

## Contents

- [Dependencies](#dependencies)
- [Quick install](#quick-install)
- [Usage](#usage)
- [Building](#building)

## Dependencies

zig is required. Only zig version 0.11 on linux amd64 (Gentoo) is being regularly tested.

## Quick Install

To get, compile then install zigfunge98, do something like:
```sh
git clone https://git.adyxax.org/adyxax/zigfunge98
cd zigfunge98
zig build -Drelease-safe
install ./zig-out/bin/zigfunge98 ~/.local/bin/
```

## Usage

Launching zigfunge98 is as simple as :
```sh
zigfunge98 something.b98
```

The interpreter will load and execute the specified Funge-98 program until the program normally terminates or is interrupted or killed.

## Building

To run tests, use :
```sh
zig build test
```

To test the coverage, use:
```sh
zig build test -Dtest-coverage
firefox kcov-output/index.html
```

To build a debug build, simply use:
```sh
zig build
```

For a non debug build, use either one of:
```sh
zig build -Doptimize=ReleaseSafe
zig build -Doptimize=ReleaseSmall
zig build -Doptimize=ReleaseFast
```
