# oxmysql

A FiveM resource to communicate with a MySQL database using [node-mysql2](https://github.com/sidorares/node-mysql2).

![](https://img.shields.io/github/downloads/overextended/oxmysql/total?logo=github)
![](https://img.shields.io/github/downloads/overextended/oxmysql/latest/total?logo=github)
![](https://img.shields.io/github/contributors/overextended/oxmysql?logo=github)
![](https://img.shields.io/github/v/release/overextended/oxmysql?logo=github) 

## 📚 Documentation

https://overextended.dev/oxmysql

## 💾 Download

https://github.com/overextended/oxmysql/releases/latest/download/oxmysql.zip

## ✨ Features

- Support for mysql-async and ghmattimysql syntax.
- Promises / async query handling allowing for non-blocking and awaitable responses.
- Improved performance and stability compared to other options.
- Support for named and unnamed placeholders, improving performance and security.
- Support for URI connection strings and semicolon separated values.
- Improved parameter checking and error handling.

### PrepareQuery

- add ?? for column and table names.
- add array/object (table) support to ? and ??

Examples:

```lua
local query, params
query, params = MySQL.PrepareQuery('SELECT * FROM ?? WHERE ?? = ?', {'players', 'id', 1})
query = 'SELECT * FROM `players` WHERE `id` = ?'
params = {1}

query, params = MySQL.PrepareQuery('INSERT INTO ?? (??) VALUES (?)', {'players', {'column1', 'column2'}, {'value1', 'value2'}})
query = 'INSERT INTO `players` (`column1`, `column2`) VALUES (?, ?)'
params = {'value1', 'value2'}

query, params = MySQL.PrepareQuery('UPDATE `players` SET ? WHERE id = ?', {{key1 = 1, key2 = 2, key3 = 3}, 'test'})
query = 'UPDATE `players` SET `key1` = ?, `key2` = ?, `key3` = ? WHERE id = ?'
params = {1, 2, 3, 'value1', 'value2'}
```

## npm Package

https://www.npmjs.com/package/@overextended/oxmysql

## Lua Language Server

- Install [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) to ease development with annotations, type checking, diagnostics, and more.
- See [ox_types](https://github.com/overextended/ox_types) for our Lua type definitions.