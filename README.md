## Overview

A Redis adapter for the [node-orm2](https://github.com/dresende/node-orm2) ORM.

This is currently a work in progress, and is not yet intended to be used.

## Usage

Don't.

## How it works

It doesn't.

## Known Limitations

* When querying with a `String` property, only equalities are supported.
  * _string equality is defined by `crc32`, [so YMMV on equality](http://stackoverflow.com/questions/14210298/probability-of-collision-crc32)_
* not-equals (`orm.ne`) is currently not supported.
* Each model has to have an id, it has to be called `id`, and it'll be assign as a GUID (unless already assigned).
  * _finding based on `id` is not subject to the same disclaimer about strings_
  
## License

Copyright (c) 2014, [Jason Whitehorn](https://github.com/jwhitehorn)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
