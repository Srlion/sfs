local math_floor = math.floor
local math_ldexp = math.ldexp
local math_frexp = math.frexp
local setmetatable = setmetatable
local table_concat = table.concat

-- string.char is not jit compiled in luajit 2.0.5
local chars = {}; do
    for i = 0, 255 do
        chars[i] = string.char(i)
    end
end
--

-- To tell Entity(0) (world) and NULL apart (since both have ent index 0), we use this (min i16 number) to represent NULL
-- -1 = non networked entities
-- 0 - 8192 = networked entities
-- Thanks to Redox for reporting the -1 case and to RaphaelIT7 for explaining it
local NULL_ENT_INDEX = -0x8000

local Writer = {}; do
    Writer.__index = Writer

    function Writer:__tostring()
        return table_concat(self, nil, 1, self[0])
    end

    Writer.tostring = Writer.__tostring

    function Writer.new()
        return setmetatable({ [0] = 0 }, Writer)
    end

    do
        local buffer = Writer.new()
        function Writer.cached()
            return buffer:reset()
        end
    end

    function Writer:reset()
        self[0] = 0
        return self
    end

    local function write_string(buf, s)
        local i = buf[0] + 1
        buf[0], buf[i] = i, s
        return buf
    end

    Writer.data = write_string

    function Writer:string(s)
        write_string(self, s)
        return write_string(self, "\0")
    end

    local function write_byte(buf, b)
        return write_string(buf, chars[b])
    end
    Writer.byte = write_byte
    Writer.u8 = write_byte

    local function write_u16(buf, n)
        write_byte(buf, (math_floor(n / 0x100)))
        return write_byte(buf, n % 0x100)
    end
    Writer.u16 = write_u16

    local function write_u32(buf, n)
        write_u16(buf, (math_floor(n / 0x10000)))
        return write_u16(buf, n % 0x10000)
    end
    Writer.u32 = write_u32

    local function write_u53(buf, n)
        write_byte(buf, math_floor(n / 0x1000000000000) % 0x100)
        write_byte(buf, math_floor(n / 0x10000000000) % 0x100)
        write_byte(buf, math_floor(n / 0x100000000) % 0x100)
        write_byte(buf, math_floor(n / 0x1000000) % 0x100)
        write_byte(buf, math_floor(n / 0x10000) % 0x100)
        write_byte(buf, math_floor(n / 0x100) % 0x100)
        return write_byte(buf, n % 0x100)
    end
    Writer.u53 = write_u53

    function Writer:i8(n)
        return write_byte(self, n % 0x100)
    end

    local function write_i16(buf, n)
        return write_u16(buf, n % 0x10000)
    end
    Writer.i16 = write_i16

    function Writer:i32(n)
        return write_u32(self, n % 0x100000000)
    end

    function Writer:i53(n)
        return write_u53(self, n % 0x20000000000000)
    end

    function Writer:float(f)
        local u32 = 0

        if f == 0 then
            u32 = 0x00000000     -- Positive zero
            if 1 / f < 0 then
                u32 = 0x80000000 -- Negative zero
            end
            return write_u32(self, u32)
        elseif f ~= f then -- NaN check
            u32 = 0x7FFFFFFF
            return write_u32(self, u32)
        end

        local sign = f < 0 and 1 or 0
        f = sign == 1 and -f or f

        if f == 1 / 0 then -- math.huge
            -- (sign << 31) + (0xFF << 23)
            u32 = (sign * (2 ^ 31)) + (0xFF * (2 ^ 23))
            return write_u32(self, u32)
        end

        local mantissa, exponent = math_frexp(f)
        mantissa = mantissa * 2
        exponent = exponent - 1

        local ieee_exponent = exponent + 127 -- IEEE 754 bias
        if ieee_exponent <= 0 then
            -- Handle subnormal numbers
            mantissa = math_ldexp(mantissa, ieee_exponent - 1)
            ieee_exponent = 0
        elseif ieee_exponent >= 255 then
            -- Handle overflow
            ieee_exponent = 255
            mantissa = 0
        end

        -- Scale mantissa to 23 bits and round
        local mantissa_bits = math_floor(
            ((mantissa - 1) * (2 ^ 23)) + 0.5
        )

        -- Ensure mantissa doesn't exceed 23 bits
        mantissa_bits = mantissa_bits % (2 ^ 23)

        -- Combine all parts
        -- (sign << 31) | (ieee_exponent << 23) | mantissa_bits
        u32 = (sign * (2 ^ 31)) + (ieee_exponent * (2 ^ 23)) + mantissa_bits

        return write_u32(self, u32)
    end

    function Writer:double(d)
        local u32_1 = 0
        local u32_2 = 0

        if d == 0 then
            u32_1 = 0x00000000
            if 1 / d < 0 then
                u32_1 = 0x80000000
            end
            write_u32(self, u32_1)
            return write_u32(self, u32_2)
        elseif d ~= d then -- NaN check
            u32_1 = 0x7FFFFFFF
            u32_2 = 1
            write_u32(self, u32_1)
            return write_u32(self, u32_2)
        end

        local sign = d < 0 and 1 or 0
        d = sign == 1 and -d or d

        if d == 1 / 0 then -- Infinity
            -- (sign << 31) | (0x7FF << 20)
            u32_1 = (sign * (2 ^ 31)) + (0x7FF * (2 ^ 20))
            write_u32(self, u32_1)
            return write_u32(self, u32_2)
        end

        local mantissa, exponent = math_frexp(d)

        local ieee_exponent = exponent + 1022
        if ieee_exponent > 0 then
            -- Normal numbers
            local mantissa_scaled = (mantissa * 2 - 1) * (2 ^ 52)
            local mantissa_upper = math_floor(mantissa_scaled / (2 ^ 32)) -- (mantissa_scaled >> 32)
            local mantissa_lower = mantissa_scaled % (2 ^ 32)             -- (mantissa_scaled & 0xFFFFFFFF)

            -- (sign << 31) | (ieee_exponent << 20) | (mantissa_upper % 2^20)
            u32_1 = (sign * (2 ^ 31)) + (ieee_exponent * (2 ^ 20)) + (mantissa_upper % (2 ^ 20))
            u32_2 = mantissa_lower
        else
            -- Subnormal numbers
            local mantissa_scaled = mantissa * math_ldexp(1, 52 + ieee_exponent)
            local mantissa_upper = math_floor(mantissa_scaled / (2 ^ 32)) -- (mantissa_scaled >> 32)
            local mantissa_lower = mantissa_scaled % (2 ^ 32)             -- (mantissa_scaled & 0xFFFFFFFF)

            -- (sign << 31) | (mantissa_upper & 0xFFFFF)
            u32_1 = (sign * (2 ^ 31)) + (mantissa_upper % (2 ^ 20))
            u32_2 = mantissa_lower
        end

        write_u32(self, u32_1)
        return write_u32(self, u32_2)
    end

    function Writer:bool(b)
        return write_byte(self, b and 1 or 0)
    end

    -- Garry's Mod types

    local Entity_EntIndex = FindMetaTable and FindMetaTable("Entity").EntIndex

    -- range between 1 and 128 for players, so we can safely use uint8
    function Writer:Player(p)
        return write_byte(self, (Entity_EntIndex(p)))
    end

    function Writer:Entity(ent)
        if ent == NULL then
            return write_i16(self, NULL_ENT_INDEX)
        else
            return write_i16(self, (Entity_EntIndex(ent)))
        end
    end

    Writer.Weapon = Writer.Entity
    Writer.Vehicle = Writer.Entity
    Writer.NextBot = Writer.Entity
    Writer.NPC = Writer.Entity

    local Vector_Unpack = FindMetaTable and FindMetaTable("Vector").Unpack
    function Writer:Vector(v)
        local x, y, z = Vector_Unpack(v)
        return self:float(x)
            :float(y)
            :float(z)
    end

    local Angle_Unpack = FindMetaTable and FindMetaTable("Angle").Unpack
    function Writer:Angle(a)
        local p, y, r = Angle_Unpack(a)
        return self:float(p)
            :float(y)
            :float(r)
    end

    local Matrix_Unpack = FindMetaTable and FindMetaTable("VMatrix").Unpack
    function Writer:Matrix(m)
        local m00, m01, m02, m03,
        m10, m11, m12, m13,
        m20, m21, m22, m23,
        m30, m31, m32, m33 = Matrix_Unpack(m)
        return self:float(m00)
            :float(m01)
            :float(m02)
            :float(m03)
            :float(m10)
            :float(m11)
            :float(m12)
            :float(m13)
            :float(m20)
            :float(m21)
            :float(m22)
            :float(m23)
            :float(m30)
            :float(m31)
            :float(m32)
            :float(m33)
    end

    Writer.VMatrix = Writer.Matrix

    function Writer:Color(c)
        return self:byte(c.r)
            :byte(c.g)
            :byte(c.b)
            :byte(c.a)
    end
end

local Reader = {}; do
    local string_byte = string.byte
    local string_sub = string.sub
    local string_find = string.find

    Reader.__index = Reader

    function Reader.new(data, max_size)
        return setmetatable({ __data = data, __pos = 1, __size = #data, __max_size = max_size or (1 / 0) }, Reader)
    end

    local function can_read(r, size)
        local pos = r.__pos
        local new_pos = pos + size
        if new_pos - 1 > r.__size or new_pos - 1 > r.__max_size then
            return
        end
        r.__pos = new_pos
        return pos, new_pos - 1
    end

    function Reader:data(size)
        local pos, new_pos = can_read(self, size)
        if not pos then return "" end
        return string_sub(self.__data, pos, new_pos)
    end

    function Reader:string()
        local data = self.__data
        local pos = self.__pos
        local null_pos = string_find(data, "\0", pos, true)
        if not null_pos or null_pos > self.__max_size then return "" end
        self.__pos = null_pos + 1
        return string_sub(data, pos, null_pos - 1)
    end

    local function read_bytes(r, size)
        local pos, new_pos = can_read(r, size)
        if not pos then return 0 end
        return string_byte(r.__data, pos, new_pos)
    end
    Reader.bytes = read_bytes

    local function read_u8(r)
        return read_bytes(r, 1)
    end
    Reader.u8 = read_u8

    local function read_u16(r)
        local b1, b2 = read_bytes(r, 2)
        if not b2 then return 0 end
        return b1 * 0x100 + b2
    end
    Reader.u16 = read_u16

    local function read_u32(r)
        local b1, b2, b3, b4 = read_bytes(r, 4)
        if not b4 then return 0 end
        return b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4
    end
    Reader.u32 = read_u32

    local function read_u53(r)
        local b1, b2, b3, b4, b5, b6, b7 = read_bytes(r, 7)
        if not b7 then return 0 end
        return b1 * 0x1000000000000
            + b2 * 0x10000000000
            + b3 * 0x100000000
            + b4 * 0x1000000
            + b5 * 0x10000
            + b6 * 0x100
            + b7
    end
    Reader.u53 = read_u53

    local function read_i8(r)
        local u8 = read_u8(r)
        if u8 >= 0x80 then u8 = u8 - 0x100 end
        return u8
    end
    Reader.i8 = read_i8

    local function read_i16(r)
        local u16 = read_u16(r)
        if u16 >= 0x8000 then u16 = u16 - 0x10000 end
        return u16
    end
    Reader.i16 = read_i16

    local function read_i32(r)
        local u32 = read_u32(r)
        if u32 >= 0x80000000 then u32 = u32 - 0x100000000 end
        return u32
    end
    Reader.i32 = read_i32

    local function read_i53(r)
        local u53 = read_u53(r)
        if u53 >= 0x10000000000000 then u53 = u53 - 0x20000000000000 end
        return u53
    end
    Reader.i53 = read_i53

    local function read_float(r)
        local u32 = read_u32(r)

        -- ((u32 >> 31) & 1) == 1 and -1 or 1
        local sign = math_floor(u32 / (2 ^ 31)) % 2 == 1 and -1 or 1
        -- (u32 >> 23) & 0xFF
        local exponent_field = math_floor(u32 / (2 ^ 23)) % (2 ^ 8)
        -- u32 & 0x7FFFFF
        local mantissa = u32 % (2 ^ 23)

        if exponent_field == 0xFF then
            if mantissa == 0 then
                return sign * (1 / 0) -- math.huge
            end
            return 0 / 0              -- NaN
        end

        if exponent_field == 0 and mantissa == 0 then
            return sign * 0 -- Zero
        end

        -- mantissa >> 23
        local mantissa_scaled = mantissa / (2 ^ 23)

        if exponent_field ~= 0 then
            -- Normal numbers
            mantissa_scaled = mantissa_scaled + 1
            local actual_exponent = exponent_field - 127
            return sign * math_ldexp(mantissa_scaled, actual_exponent)
        else
            -- Subnormal numbers
            return sign * math_ldexp(mantissa_scaled, -126)
        end
    end
    Reader.float = read_float

    local function read_double(r)
        local u32_1 = read_u32(r)
        local u32_2 = read_u32(r)

        -- ((u32_1 >> 31) & 1) == 1 and -1 or 1
        local sign = math_floor(u32_1 / (2 ^ 31)) % 2 == 1 and -1 or 1
        -- (u32_1 >> 20) & 0x7FF
        local exponent_field = math_floor(u32_1 / (2 ^ 20)) % (2 ^ 11)
        -- u32_1 & 0xFFFFF
        local mantissa_upper = u32_1 % (2 ^ 20)

        if exponent_field == 0x7FF then
            if mantissa_upper == 0 and u32_2 == 0 then
                return sign * (1 / 0) -- math.huge
            end
            return 0 / 0              -- NaN
        end

        if exponent_field == 0 and mantissa_upper == 0 and u32_2 == 0 then
            return sign * 0 -- Zero
        end

        -- mantissa_upper << 32 + u32_2
        local mantissa_scaled = mantissa_upper * (2 ^ 32) + u32_2

        if exponent_field ~= 0 then
            -- Normal numbers
            mantissa_scaled = (mantissa_scaled / (2 ^ 52)) + 1
            local actual_exponent = exponent_field - 1023
            return sign * math_ldexp(mantissa_scaled, actual_exponent)
        else
            -- Subnormal numbers
            mantissa_scaled = mantissa_scaled / (2 ^ 52)
            return sign * math_ldexp(mantissa_scaled, -1022)
        end
    end
    Reader.double = read_double

    function Reader:bool()
        local b = read_u8(self)
        return b == 1
    end

    -- Garry's Mod types

    local Entity = Entity

    function Reader:Entity()
        local ent_idx = read_i16(self)
        if ent_idx == NULL_ENT_INDEX then
            return NULL
        end
        return Entity(ent_idx)
    end

    function Reader:Player()
        local ply_idx = read_u8(self)
        return Entity(ply_idx)
    end

    local Vector = Vector
    function Reader:Vector()
        local x, y, z = read_float(self), read_float(self), read_float(self)
        return Vector(x, y, z)
    end

    local Angle = Angle
    function Reader:Angle()
        local p, y, r = read_float(self), read_float(self), read_float(self)
        return Angle(p, y, r)
    end

    local Matrix = Matrix
    local Matrix_SetUnpacked = FindMetaTable and FindMetaTable("VMatrix").SetUnpacked
    function Reader:Matrix()
        local m = Matrix()
        local m00, m01, m02, m03,
        m10, m11, m12, m13,
        m20, m21, m22, m23,
        m30, m31, m32, m33 = read_float(self), read_float(self), read_float(self), read_float(self),
            read_float(self), read_float(self), read_float(self), read_float(self),
            read_float(self), read_float(self), read_float(self), read_float(self),
            read_float(self), read_float(self), read_float(self), read_float(self)
        Matrix_SetUnpacked(m, m00, m01, m02, m03,
            m10, m11, m12, m13,
            m20, m21, m22, m23,
            m30, m31, m32, m33)
        return m
    end

    Reader.VMatrix = Reader.Matrix

    local Color = Color
    function Reader:Color()
        local r, g, b, a = read_u8(self), read_u8(self), read_u8(self), read_u8(self)
        return Color(r, g, b, a)
    end
end

return {
    Writer = Writer,
    Reader = Reader,

    chars = chars,
    NULL_ENT_INDEX = NULL_ENT_INDEX,
}
