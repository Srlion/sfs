local sfs = include("sfs/sfs.lua")

local encode = sfs.encode
local decode = sfs.decode

local Encoder = sfs.Encoder
local Decoder = sfs.Decoder

local function name(v)
    return "type: " .. v
end

local function are_equal(t1, t2)
    if type(t1) ~= type(t2) then
        return false
    end

    if type(t1) ~= "table" then
        if t1 ~= t1 and t2 ~= t2 then -- NaN
            return true
        end

        return t1 == t2
    end

    for k in pairs(t1) do
        if not t2[k] then
            return false
        end

        if not are_equal(t1[k], t2[k]) then
            return false
        end
    end

    if table.Count(t1) ~= table.Count(t2) then
        return false
    end

    return true
end

local function generate_test_numbers(total_range)
    local to_test = {}
    local current_value = 0
    local step_factor = 1.5
    while current_value < total_range do
        local step = math.min(math.floor(step_factor * math.random(10, 100)), total_range - current_value)
        current_value = current_value + step
        table.insert(to_test, current_value)
        step_factor = step_factor * 1.1
    end
    table.insert(to_test, total_range)
    return to_test
end

local function generate_test_strings(total_range)
    local result = {}
    local length = 1
    table.insert(result, string.rep("a", length))
    while length < total_range do
        local increase = math.floor(length * 0.75)
        increase = math.max(1, increase)
        length = length + increase
        if length > total_range then
            length = total_range
        end
        table.insert(result, string.rep("a", length))
    end
    return result
end

local function generate_test_array(total_range)
    local result = {}
    local length = 1
    table.insert(result, {0})
    while length < total_range do
        local increase = math.floor(length * 0.75)
        increase = math.max(1, increase)
        length = length + increase
        if length > total_range then
            length = total_range
        end
        local new_array = {}
        for i = 1, length do
            new_array[i] = true
        end
        table.insert(result, new_array)
    end
    return result
end

local function generate_test_table(total_range)
    local result = {}
    local length = 1
    table.insert(result, {key1 = "value1"})
    while length < total_range do
        local increase = math.floor(length * 0.75)
        increase = math.max(1, increase)
        length = length + increase
        if length > total_range then
            length = total_range
        end
        local new_table = {}
        for i = 1, length do
            new_table["key" .. i] = "value" .. i
        end
        table.insert(result, new_table)
    end
    return result
end

-- local tested = sfs.encode(9007199254740991)
-- print(sfs.decode(tested) == 9007199254740992)

return {
    groupName = "sfs",
    beforeAll = function()
        collectgarbage()
        collectgarbage()
        collectgarbage()
    end,
    afterEach = function()
        collectgarbage()
        collectgarbage()
        collectgarbage()
    end,
    cases = {
        {
            name = name("nil"),
            func = function()
                local data = nil
                local encoded = encode(data)
                local decoded = decode(encoded)
                expect(decoded).to.equal(data)
            end
        },
        {
            name = name("false"),
            func = function()
                local data = false
                local encoded = encode(data)
                local decoded = decode(encoded)
                expect(decoded).to.equal(data)
            end
        },
        {
            name = name("true"),
            func = function()
                local data = true
                local encoded = encode(data)
                local decoded = decode(encoded)
                expect(decoded).to.equal(data)
            end
        },
        {
            name = name("float"),
            func = function()
                local numbers = {
                    0.0,
                    -0.0,
                    1.0,
                    -1.0,
                    2.0^0,
                    2.0^1,
                    2.0^10,
                    2.0^20,
                    2.0^30,
                    2.0^-10,
                    2.0^-30,
                    16777216.0,
                    16777217.0,
                    2147483647.0,
                    -2147483648.0,
                    9007199254740991.0,
                    9007199254740992.0,
                    9007199254740993.0,
                    123456789.0,
                    -123456789.0,
                    0.1,
                    -0.1,
                    0.3,
                    -0.3,
                    0.25,
                    -0.25,
                    0.5,
                    -0.5,
                    0.75,
                    -0.75,
                    1.23456789,
                    -1.23456789,
                    1.33333333,
                    -1.33333333,
                    2.66666667,
                    -2.66666667,
                    3.1415926535,
                    -3.1415926535,
                    math.pi,
                    -math.pi,
                    1.0e-45,
                    -1.0e-45,
                    1.0e-38,
                    -1.0e-38,
                    1.0e-300,
                    -1.0e-300,
                    1.0e-308,
                    -1.0e-308,
                    1.17549435e-38,
                    -1.17549435e-38,
                    1.0e38,
                    -1.0e38,
                    1.0e300,
                    -1.0e300,
                    1.0e308,
                    -1.0e308,
                    1.7976931348623157e+308,
                    -1.7976931348623157e+308,
                    1.0e309,
                    -1.0e309,
                    4.9406564584124654e-324,
                    -4.9406564584124654e-324,
                    1.0e-323,
                    -1.0e-323,
                    2.0^-1074,
                    -2.0^-1074,
                    math.huge,
                    -math.huge,
                    0 / 0,
                    -0 / 0,
                    1.0 / 0.0 * 0.0,
                    math.sqrt(-1.0),
                    1.401298464e-45,
                    -1.401298464e-45,
                    5.0e-45,
                    -5.0e-45,
                    123.456,
                    -123.456,
                    -0,
                    1.0e-10,
                    -1.0e-10,
                    1.0e+10,
                    -1.0e+10,
                    6.02214076e+23,
                    -6.02214076e+23,
                    9.10938356e-31,
                    -9.10938356e-31,
                    1.602176634e-19,
                    -1.602176634e-19,
                    2.998e8,
                    -2.998e8,
                    1.380649e-23,
                    -1.380649e-23,
                    6.62607015e-34,
                    -6.62607015e-34,
                    0.2,
                    -0.2,
                    0.3333333333333333,
                    -0.3333333333333333,
                    0.6666666666666666,
                    -0.6666666666666666,
                    3.4028235e+38,
                    -3.4028235e+38,
                    3.4028236e+38,
                    -3.4028236e+38,
                    2.2250738585072014e-308,
                    -2.2250738585072014e-308,
                    1.0e+1000,
                    -1.0e+1000,
                    1.0e-324,
                    -1.0e-324,
                    1.234e+2,
                    -1.234e+2,
                    5.678e-3,
                    -5.678e-3,
                }
                -- this is just to make sure that we are testing with actual floats
                -- vectors in gmod are single precision floats, so we give them a double and they convert it to a float :)
                -- the test will actually fail if we pass it just as it is
                local vec = Vector()
                local buffer = sfs.new_buffer()
                for _, original in ipairs(numbers) do
                    vec.x = original -- double -> float
                    original = vec.x -- now it's a float

                    sfs.reset_buffer(buffer)

                    Encoder.encoders.float(buffer, original)
                    local encoded = sfs.end_buffer(buffer)

                    local decoded = decode(encoded)
                    if original ~= original then
                        expect(decoded).notTo.equal(original)
                    else
                        expect(decoded).to.equal(original)
                    end
                end
            end
        },
        {
            name = name("double"),
            func = function()
                local numbers = {
                    0.0,
                    -0.0,
                    1.0,
                    -1.0,
                    123.456,
                    -123.456,
                    1.7976931348623157e+308,
                    4.9406564584124654e-324,
                    -4.9406564584124654e-324,
                    2.2250738585072014e-308,
                    math.huge,
                    -math.huge,
                    0 / 0,
                    1,
                    2,
                    -1.143243,
                    1.23456789e123,
                    -1.23456789e-123,
                    2.0^(-1074),
                    2.0^(-1073),
                    2.0^(-1022),
                    2.0^(-1021),
                    2.0^0,
                    2.0^1,
                    2.0^10,
                    2.0^1023,
                    0.5,
                    0.25,
                    0.125,
                    -0.5,
                    -0.25,
                    -0.125,
                    1 - 2.0^(-52),
                    1 + 2.0^(-52),
                    1 - 2.0^(-53),
                    1 + 2.0^(-53),
                    2 - 2.0^(-51),
                    2 + 2.0^(-51),
                    4 - 2.0^(-50),
                    4 + 2.0^(-50),
                    math.pi,
                    -math.pi,
                    math.pi * 2,
                    math.pi / 2,
                    math.exp(1),
                    -math.exp(1),
                    0.1,
                    0.2,
                    0.3,
                    0.123456789,
                    -0.123456789,
                    1.7976931348623157e+308 / 2,
                    1.7976931348623157e+308 / 4,
                    1e308,
                    1e307,
                    1e306,
                    2.2250738585072014e-308 * 2,
                    2.2250738585072014e-308 * 4,
                    1e-307,
                    1e-306,
                    1e-305,
                    16777217.0,
                    16777219.0,
                    -16777217.0,
                    -16777219.0,
                    2.2250738585072009e-308,
                    2.2250738585072014e-308,
                    -0,
                    123.456,
                    -123.456,
                    0.0,
                    -0.0,
                    1.0,
                    -1.0,
                    2.0^0,
                    2.0^1,
                    2.0^10,
                    2.0^20,
                    2.0^30,
                    2.0^-10,
                    2.0^-30,
                    16777216.0,
                    16777217.0,
                    2147483647.0,
                    -2147483648.0,
                    9007199254740991.0,
                    9007199254740992.0,
                    9007199254740993.0,
                    123456789.0,
                    -123456789.0,
                    0.1,
                    -0.1,
                    0.3,
                    -0.3,
                    0.25,
                    -0.25,
                    0.5,
                    -0.5,
                    0.75,
                    -0.75,
                    1.23456789,
                    -1.23456789,
                    1.33333333,
                    -1.33333333,
                    2.66666667,
                    -2.66666667,
                    3.1415926535,
                    -3.1415926535,
                    math.pi,
                    -math.pi,
                    1.0e-45,
                    -1.0e-45,
                    1.0e-38,
                    -1.0e-38,
                    1.0e-300,
                    -1.0e-300,
                    1.0e-308,
                    -1.0e-308,
                    1.17549435e-38,
                    -1.17549435e-38,
                    1.0e38,
                    -1.0e38,
                    1.0e300,
                    -1.0e300,
                    1.0e308,
                    -1.0e308,
                    1.7976931348623157e+308,
                    -1.7976931348623157e+308,
                    1.0e309,
                    -1.0e309,
                    4.9406564584124654e-324,
                    -4.9406564584124654e-324,
                    1.0e-323,
                    -1.0e-323,
                    2.0^-1074,
                    -2.0^-1074,
                    math.huge,
                    -math.huge,
                    0 / 0,
                    -0 / 0,
                    1.0 / 0.0 * 0.0,
                    math.sqrt(-1.0),
                    1.401298464e-45,
                    -1.401298464e-45,
                    5.0e-45,
                    -5.0e-45,
                    123.456,
                    -123.456,
                    -0,
                    1.0e-10,
                    -1.0e-10,
                    1.0e+10,
                    -1.0e+10,
                    6.02214076e+23,
                    -6.02214076e+23,
                    9.10938356e-31,
                    -9.10938356e-31,
                    1.602176634e-19,
                    -1.602176634e-19,
                    2.998e8,
                    -2.998e8,
                    1.380649e-23,
                    -1.380649e-23,
                    6.62607015e-34,
                    -6.62607015e-34,
                    0.2,
                    -0.2,
                    0.3333333333333333,
                    -0.3333333333333333,
                    0.6666666666666666,
                    -0.6666666666666666,
                    3.4028235e+38,
                    -3.4028235e+38,
                    3.4028236e+38,
                    -3.4028236e+38,
                    2.2250738585072014e-308,
                    -2.2250738585072014e-308,
                    1.0e+1000,
                    -1.0e+1000,
                    1.0e-324,
                    -1.0e-324,
                    1.234e+2,
                    -1.234e+2,
                    5.678e-3,
                    -5.678e-3,
                }
                local buffer = sfs.new_buffer()
                for _, original in ipairs(numbers) do
                    sfs.reset_buffer(buffer)

                    Encoder.encoders.double(buffer, original)
                    local encoded = sfs.end_buffer(buffer)

                    local decoded = decode(encoded)
                    if original ~= original then
                        expect(decoded).notTo.equal(original)
                    else
                        expect(decoded).to.equal(original)
                    end
                end
            end
        },
        {
            name = name("entity"),
            func = function()
                local ent = ents.GetAll()[1]
                local encoded = encode(ent)
                local decoded = decode(encoded)
                expect(decoded).to.equal(ent)
            end
        },
        {
            name = name("player"),
            func = function()
                if player.GetCount() == 0 then
                    RunConsoleCommand("bot")
                end

                local ply = player.GetAll()[1]
                local encoded = encode(ply)
                local decoded = decode(encoded)
                expect(decoded).to.equal(ply)
            end
        },
        {
            name = name("vector"),
            func = function()
                local vec = Vector(1, 2, 3)
                local encoded = encode(vec)
                local decoded = decode(encoded)
                expect(decoded).to.equal(vec)
            end
        },
        {
            name = name("angle"),
            func = function()
                local ang = Angle(1, 2, 3)
                local encoded = encode(ang)
                local decoded = decode(encoded)
                expect(decoded).to.equal(ang)
            end
        },
        {
            name = name("matrix"),
            func = function()
                local matrix = Matrix({
                    {-9, -6, 2, -10},
                    {-3, -1, 2, -8},
                    {5.6, -1, 0, 1.1},
                    {-7, -7, 3, -8}
                })
                local encoded = encode(matrix)
                local decoded = decode(encoded)
                expect(decoded).to.equal(matrix)
            end
        },
        {
            name = name("color"),
            func = function()
                local col = Color(255, 0, 0, 255)
                local encoded = encode(col)
                local decoded = decode(encoded)
                expect(decoded).to.equal(col)
            end
        },
        {
            name = name("positive_fixed"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, sfs.TYPES.positive_fixed.max do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.positive_fixed.start + i)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(i)
                end
                expect(#sfs.encode(sfs.TYPES.positive_fixed.max)).to.equal(1)
                expect(#sfs.encode(sfs.TYPES.positive_fixed.max + 1)).to.equal(2)
            end
        },
        {
            name = name("positive_u8"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, 255 do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.positive_u8.start)
                    Encoder.write_u8(buffer, i)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(i)
                end
            end
        },
        {
            name = name("positive_u16"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, 65535 do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.positive_u16.start)
                    Encoder.write_u16(buffer, i)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(i)
                end
            end
        },
        {
            name = name("positive_u32"),
            func = function()
                local to_test = generate_test_numbers(4294967295)
                local TEST_POSITIVE_U32 = sfs.add_custom_type("bla bla", function()
                end, function(ctx)
                    ctx[1] = ctx[1] + 1
                    for i = 1, #to_test do
                        local decoded = Decoder.read_u32(ctx)
                        expect(decoded).to.equal(to_test[i])
                    end
                    return true
                end)
                local buffer = sfs.new_buffer()
                Encoder.write_byte(buffer, TEST_POSITIVE_U32)
                for k, v in ipairs(to_test) do
                    Encoder.write_u32(buffer, v)
                end
                local encoded = sfs.end_buffer(buffer)
                decode(encoded)
            end
        },
        {
            name = name("positive_u53"),
            func = function()
                local to_test = generate_test_numbers(9007199254740992)
                local TEST_POSITIVE_U53 = sfs.add_custom_type("bla bla 2", function()
                end, function(ctx)
                    ctx[1] = ctx[1] + 1
                    for i = 1, #to_test do
                        local decoded = Decoder.read_u53(ctx)
                        expect(decoded).to.equal(to_test[i])
                    end
                    return true
                end)
                local buffer = sfs.new_buffer()
                Encoder.write_byte(buffer, TEST_POSITIVE_U53)
                for k, v in ipairs(to_test) do
                    Encoder.write_u53(buffer, v)
                end
                local encoded = sfs.end_buffer(buffer)
                decode(encoded)
            end
        },
        {
            name = name("negative_fixed"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, sfs.TYPES.negative_fixed.max do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.negative_fixed.start + i)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(-i)
                end
                expect(#sfs.encode(-sfs.TYPES.negative_fixed.max)).to.equal(1)
                expect(#sfs.encode(-(sfs.TYPES.negative_fixed.max + 1))).to.equal(2)
            end
        },
        {
            name = name("negative_u8"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, 255 do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.negative_u8.start)
                    Encoder.write_u8(buffer, i)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(-i)
                end
            end
        },
        {
            name = name("negative_u16"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, 65535 do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.negative_u16.start)
                    Encoder.write_u16(buffer, i)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(-i)
                end
            end
        },
        {
            name = name("negative_u32"),
            func = function()
                local to_test = generate_test_numbers(4294967295)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.negative_u32.start)
                    Encoder.write_u32(buffer, v)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(-v)
                end
            end
        },
        {
            name = name("negative_u53"),
            func = function()
                local to_test = generate_test_numbers(4503599627370495)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.negative_u53.start)
                    Encoder.write_u53(buffer, v)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(-v)
                end
            end
        },
        {
            name = name("string_fixed"),
            func = function()
                local buffer = sfs.new_buffer()
                for i = 0, sfs.TYPES.string_fixed.max do
                    local str = string.rep("a", i)
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.string_fixed.start + i)
                    Encoder.write_str(buffer, str)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(str)
                end
                expect(#sfs.encode(string.rep("a", sfs.TYPES.string_fixed.max))).to.equal(sfs.TYPES.string_fixed.max + 1)
                expect(#sfs.encode(string.rep("a", sfs.TYPES.string_fixed.max + 1))).to.equal(sfs.TYPES.string_fixed.max + 3)
            end
        },
        {
            name = name("string_u8"),
            func = function()
                local to_test = generate_test_strings(255)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.string_u8.start)
                    Encoder.write_u8(buffer, #v)
                    Encoder.write_str(buffer, v)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(v)
                end
            end
        },
        {
            name = name("string_u16"),
            func = function()
                local to_test = generate_test_strings(65535)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.string_u16.start)
                    Encoder.write_u16(buffer, #v)
                    Encoder.write_str(buffer, v)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(v)
                end
            end
        },
        {
            name = name("string_u32"),
            func = function()
                local to_test = generate_test_strings(258435456)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.string_u32.start)
                    Encoder.write_u32(buffer, #v)
                    Encoder.write_str(buffer, v)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(decoded).to.equal(v)
                end
            end
        },
        {
            name = name("array_u8"),
            func = function()
                local to_test = generate_test_array(255)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.array.start)
                    for k2, v2 in ipairs(v) do
                        Encoder.write_value(buffer, v2)
                    end
                    Encoder.write_byte(buffer, sfs.Encoder.ENDING)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(are_equal(v, decoded)).to.beTrue()
                end
            end
        },
        {
            name = name("array_u16"),
            func = function()
                local to_test = generate_test_array(65535)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.array.start)
                    for k2, v2 in ipairs(v) do
                        Encoder.write_value(buffer, v2)
                    end
                    Encoder.write_byte(buffer, sfs.Encoder.ENDING)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(are_equal(v, decoded)).to.beTrue()
                end
            end
        },
        {
            name = name("array_u32"),
            func = function()
                local to_test = generate_test_array(21999999)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.array.start)
                    for k2, v2 in ipairs(v) do
                        Encoder.write_value(buffer, v2)
                    end
                    Encoder.write_byte(buffer, sfs.Encoder.ENDING)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(are_equal(v, decoded)).to.beTrue()
                end
            end
        },
        {
            name = name("table_u8"),
            func = function()
                local to_test = generate_test_table(255)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.table.start)
                    for k2, v2 in pairs(v) do
                        Encoder.write_value(buffer, k2)
                        Encoder.write_value(buffer, v2)
                    end
                    Encoder.write_byte(buffer, sfs.Encoder.ENDING)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(are_equal(v, decoded)).to.beTrue()
                end
            end
        },
        {
            name = name("table_u16"),
            func = function()
                local to_test = generate_test_table(65535)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.table.start)
                    for k2, v2 in pairs(v) do
                        Encoder.write_value(buffer, k2)
                        Encoder.write_value(buffer, v2)
                    end
                    Encoder.write_byte(buffer, sfs.Encoder.ENDING)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(are_equal(v, decoded)).to.beTrue()
                end
            end
        },
        {
            name = name("table_u32"),
            func = function()
                local to_test = generate_test_table(5999999)
                local buffer = sfs.new_buffer()
                for k, v in ipairs(to_test) do
                    sfs.reset_buffer(buffer)
                    Encoder.write_byte(buffer, sfs.TYPES.table.start)
                    for k2, v2 in pairs(v) do
                        Encoder.write_value(buffer, k2)
                        Encoder.write_value(buffer, v2)
                    end
                    Encoder.write_byte(buffer, sfs.Encoder.ENDING)
                    local encoded = sfs.end_buffer(buffer)
                    local decoded = decode(encoded)
                    expect(are_equal(v, decoded)).to.beTrue()
                end
            end
        },
    }
}
