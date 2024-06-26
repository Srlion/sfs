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
local encoded, err = sfs.encode(data)
if err then
    print("Error encoding data: ", err)
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

```lua
local sfs = include('sfs.lua')

-- To encode an array
local encoded, err = sfs.encode_array({false, true, nil, 1, 2, 3}, 6)
if err then
    print("Error encoding data: ", err)
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

- `encode_array(array, array_size)` Does internally what encode does, but it's to encode arrays.

- `decode(encoded_data)` Decodes the given string into the original data. Returns the decoded data, an error string, and a secondary error string. If the decoding is successful, the error strings will be nil.

- `decode_with_max_size(encoded_data, max_size)` Similar to decode, but allows you to specify a maximum size for the decoded data. This can be useful for preventing denial-of-service attacks where an attacker sends a very large encoded string.

- `set_type_function(t_fn)` Sets a custom type function. This can be useful if you have custom type function that you want the library to use instead of global `type` function.

Note
This module does not throw errors. Instead, functions return an error string and a secondary error string as the second and third return values when something goes wrong. Always check these return values to make sure your calls to encode and decode were successful.

Internal Functions
The Encoder and Decoder tables are also exported for advanced usage. These tables contain the internal functions used for encoding and decoding data.

~~Arrays are encoded as tables by default, as there is no real way to differentiate between a table and an array in Lua. If you want to encode a table as an array, you can use the `sfs.Encoder.array` function.~~ This is no longer the case. I made `sfs.encode_array` to encode arrays, but I realized sub-values can also be arrays. So, this function can only be useful if all values are anything but arrays. Therefore, I had to figure out a fast and accurate way to check if a table is an array or not. I wanted something that could work with array holes, but that's not possible without iterating and making the code more complex and 2x slower. So, I found a hacky way: LuaJIT and Lua 5.1 both iterate over the array part first, then the hash part. We can have a blazing fast check to see if a table is an array or not. The trick is to get the table size `local len = #tbl`, then call `next(tbl, #tbl)`. If it returns nil, then it's an array. This check is really accurate, simple, and fast. However, there was a problem because LuaJIT supports zero-based index arrays, so a new prefix byte was added to indicate if a table starts from 0 or 1. The prefix byte won't be added if the table is an array starting from 1.
This method is a lot better than what other serializers do, as they loop over the array and then if there is a hash value, they loop again as they have to encode keys, which can significantly impact performance for large tables.

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

- After some testing, pon can be smaller than sfs (not by a significant margin) when all the data is composed of strings (not in all cases). This is because pon always uses two bytes and does not include the string length, making it potentially smaller in certain string-based scenarios. However, it is important to note that the performance difference between the two is substantial, and when dealing with mixed data types, sfs will generally result in a much smaller output size.

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
