# SFS

SFS - Srlion's Fast Binary Serializer for Garry's Mod

## Introduction

This is a blazing fast binary serializer. It is designed to be efficient and avoid operations not yet implemented in LuaJIT 2.0.5. It is particularly useful for encoding and decoding network messages. With LuaJIT 2.1 it's even way faster.

It's made for Garry's Mod in mind, designed to be blazing fast for addons that transfer lots of server -> client -> server data while being safe to use with user input.

I made it because I was done using pon outputting huge output and messagepack causing issues. Also they don't have anyway to limit the size when decoding.

Each type is encoded with a prefix byte to identify type, except for small integers, which are encoded directly. This allows for efficient encoding and decoding of data, You can read sfs.lua to understand how it works.

Highly inspired by MessagePack.

## Usage

```lua
local sfs = include('sfs.lua')

-- To encode data
local encoded, err, err2 = sfs.encode(data) -- err2 can be nil
if err then
    print("Error encoding data: ", err, err2)
    return
end

-- To decode data
local decoded, err, err2 = sfs.decode(encoded) -- err2 can be nil
if err then
    print("Error decoding data: ", err, err2)
    return
end

print(decoded)
```

## Functions

- `encode(data)` Encodes the given data into a string. Returns the encoded string, an error string, and a secondary error string. If the encoding is successful, the error strings will be nil.
- `decode(encoded_data)` Decodes the given string into the original data. Returns the decoded data, an error string, and a secondary error string. If the decoding is successful, the error strings will be nil.
- `encode_with_buffer(data, buffer, max_size)` Similar to encode, but allows you to provide a buffer for the encoding. This can be more efficient if you're encoding many pieces of data in a loop. max_size is the max buffer length it can reach before resetting.
- `decode_with_max_size(encoded_data, max_size)` Similar to decode, but allows you to specify a maximum size for the decoded data. This can be useful for preventing denial-of-service attacks where an attacker sends a very large encoded string.
- `set_type_function(t_fn)` Sets a custom type function. This can be useful if you have custom type function that you want the library to use instead of global `type` function.

Note
This module does not throw errors. Instead, functions return an error string and a secondary error string as the second and third return values when something goes wrong. Always check these return values to make sure your calls to encode and decode were successful.

Internal Functions
The Encoder and Decoder tables are also exported for advanced usage. These tables contain the internal functions used for encoding and decoding data.

Arrays are encoded as tables by default, as there is no real way to differentiate between a table and an array in Lua. If you want to encode a table as an array, you can use the `sfs.Encoder.array` function.

## Benchmarks

This benchmark is not highly accurate, but it gives a rough idea of how fast the library is.

```lua
local value_to_encode = {nil, false, true, "xd lol hehe", 1, 0xFF, 0xFFFF, 0xFFFFFFFF, 0xFFFFFFFFFFFFF, 1.7976931348623e308}
```

Running it 100,000 times:

| Library | Encode + Decode |
| ------- | --------------- |
| sfs     | 1.233872852     |
| cbor    | 1.7398643       |
| pon     | 2.392090866     |

Around 40% faster than cbor and 94% faster than pon. Encode output will be almost the same size as cbor but way smaller than pon.

| Library | Encode Output Size |
| ------- | ------------------ |
| sfs     | 52                 |
| cbor    | 53                 |
| pon     | 88                 |

It may not make a difference for small data, but it will make a difference for big ones.

## Tested On [Physgun](https://billing.physgun.com/aff.php?aff=131) Dev Server

**Gamemode:** Sandbox

- Lua Refresh -> **OFF**
- Physgun Utils -> **OFF**
