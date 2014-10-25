## Overview

A Redis adapter for the [node-orm2](https://github.com/dresende/node-orm2) ORM.

Redis + Node ~= Peanut Butter + Chocolate :blue_heart:

## Usage

Incorporating this Redis adapter into your project is pretty straight forward, provided you're already using node-orm2 today.

If you're not already using node-orm2, please check their [Github page](https://github.com/dresende/node-orm2) for details of how to get started.

After that, you can start working with Redis by requiring this package and calling orm.addAdapter:

    redis = require 'node-orm2-redis'

    #more code here
    orm.addAdapter 'redis', redis
      orm.connect connectionString, (err, db)->

## How it works

Under the hood, this Redis adapter makes several assumptions about how your keyspace should be managed.
Each persisted model is stored as a `Hash`, and each property is converted to a numeric score and stored in a sorted set.

Doing both allows for models to quickly be reconstituted and easily queried, at the cost of slightly more storage space per record.

Since each property has to be converted to a numeric score, there are some known limitations...

## Known Limitations

* When querying with a `String` property, only equalities are supported.
* not-equals (`orm.ne`) is **not** supported.
  * No, it will _not_ be supported. Ever.
* Limit & Offset are "supported", but don't make a lot of sense for Redis, YMMV.
  * Because of this, `lt`, `gt`, `lte`, and `gte` are discouraged for querying against contious series (e.g. dates) - see the next bullet for more info.
* Each sub-filter has a hard limit of the number of keys it'll match. Any sub-filter exiting this limit will abort the entire filter, and return an error.
  * This is done to prevent queries from running amok. Hard limit is currently 10,000 records.
  * Seriously, this (and the previous bullet on offset & limit) aren't issues - this is Redis, not SQL, find a more nature way to paginate your data!
* Each model has to have an id, it has to be called `id`, and it'll be assign as a GUID (unless already assigned).
* Deletes are not yet implemented - easy to do, coming REAL soon though!

## Keyspace Map

_coming soon_

## License

Copyright (c) 2014, [Jason Whitehorn](https://github.com/jwhitehorn)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
