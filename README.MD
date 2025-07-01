# SFS

SFS - Srlion's Fast Binary Serializer for Garry's Mod

## Introduction

This is a blazing fast binary serializer. It is designed to be efficient and avoid operations not yet implemented in LuaJIT 2.0.5. It is particularly useful for encoding and decoding network messages. With LuaJIT 2.1 it's even way faster.

It's made for Garry's Mod in mind, designed to be blazing fast for addons that transfer lots of server -> client -> server data while being safe to use with user input.

I made it because I was done using pon outputting huge output and messagepack causing issues. Also they don't have anyway to limit the size when decoding.

Each type is encoded with a prefix byte to identify type, except for small numbers/strings/arrays/tables, which are encoded directly. This allows for efficient encoding and decoding of data, You can read sfs.lua to understand how it works.

Highly inspired by MessagePack.

## Usage

```lua
local sfs = include("sfs.lua")

-- To encode data
local encoded, err = sfs.encode(data)
if err then
    print("Error encoding data: ", err)
    return
end

-- To decode data
local decoded, err = sfs.decode(encoded)
if err then
    print("Error decoding data: ", err)
    return
end

print(decoded)
```

You can also add custom types!

```lua
local Encoder = sfs.Encoder
local Decoder = sfs.Decoder
local ENDING = Encoder.ENDING

local SortedMap; do
    local SortedMapMethods = {}
    local SortedMapMeta = {
        __index = SortedMapMethods,
        __tostring = function(s)
            return string.format("SortedMap: %p", s)
        end,
        MetaName = "SortedMap"
    }

    SortedMap = {
        Meta = SortedMapMeta,
    }

    function SortedMap.New()
        return setmetatable({
            map = {},
            keys = {},
            size = 0
        }, SortedMapMeta)
    end

    function SortedMapMethods:Hey()
        PrintTable(self)
    end
end

local SORTED_MAP_ID
SORTED_MAP_ID = sfs.add_custom_type(SortedMap.Meta, function(buf, v)
    Encoder.write_byte(buf, SORTED_MAP_ID)

    if Encoder.write_table(buf, v.map) then -- if it returns true, there was an error
        return true
    end
    Encoder.write_byte(buf, ENDING)

    if Encoder.write_array(buf, v.keys, v.size) then -- if it returns true, there was an error
        return true
    end
    Encoder.write_byte(buf, ENDING)
end, function(ctx)
    ctx[1] = ctx[1] + 1 -- Skip the type byte (SORTED_MAP_ID)

    local map, keys, err

    map, err = Decoder.read_table(ctx, ENDING)
    if err then return nil, err end

    keys, err = Decoder.read_array(ctx, ENDING)
    if err then return nil, err end

    return setmetatable({
        map = map,
        keys = keys,
        size = #keys
    }, SortedMap.Meta)
end)

local data = SortedMap.New()
data.map["keys"] = "values"
data.keys[1] = "key"
data.size = 1

local encoded, err = sfs.encode(data)
if err then
    print("Error encoding data: ", err)
    return
end

local decoded, err = sfs.decode(encoded)
if err then
    print("Error decoding data: ", err)
    return
end

PrintTable(decoded)
```

## Functions

- `encode(data)` Encodes the given data into a string. Returns the encoded string, an error string, and a secondary error string. If the encoding is successful, the error strings will be nil.

- `decode(encoded_data, max_size?)` Decodes the given string into the original data. Returns the decoded data, an error string, and a secondary error string. If the decoding is successful, the error strings will be nil. max_size is an optional parameter that allows you to specify a maximum size for the decoded data. This can be useful for preventing denial-of-service attacks where an attacker sends a very large encoded string.

- `set_type_function(t_fn)` Sets a custom type function. This can be useful if you have custom type function that you want the library to use instead of global `type` function.

- `add_custom_type(type_name, encode_fn, decode_fn)` Adds a custom type to the library. This can be useful if you have custom types that you want to encode and decode. Returns the type ID that was assigned to the custom type.

Note
This module does not throw errors. Instead, functions return an error string when something goes wrong. Always check these return values to make sure your calls to encode and decode were successful.

Internal Functions
The Encoder and Decoder tables are also exported for advanced usage. These tables contain the internal functions used for encoding and decoding data.

## Benchmarks

> [!NOTE]
> These benchmarks are not updated with new changes. I will update them soon™. (New changes shouldn't affect the performance that much)

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
