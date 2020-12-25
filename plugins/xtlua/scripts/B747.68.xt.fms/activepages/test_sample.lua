-- Copyright (c) 2016 Saso Kiselkov
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


-- NOTE:
-- You don't need this file in your FMS. This is only a sample to show you
-- how to use the XRAAS_ND_msg_decode function and to test the decoder.
-- If you wish to run this file from the command line to test the decoder,
-- make sure you have the Lua BitOp module installed in your interpreter.
-- See http://bitop.luajit.org/ for more info.


dofile("XRAAS_ND_msg_decode.lua")

function test_decode(value)
	local msg, color = XRAAS_ND_msg_decode(value)
	assert(msg ~= nil and color ~= nil)

	local color_name
	if color == 0 then
		color_name = "GREEN"
	else
		color_name = "AMBER"
	end
	print(string.format("0x%08x\t%s\t%s", value, color_name, msg))
end

print("RAW VALUE\tCOLOR\tMESSAGE\n" ..
    "----------\t-----\t-------")
test_decode(0x00000041)
test_decode(0x00000042)
test_decode(0x00000043)
test_decode(0x00000044)
test_decode(0x00000045)
test_decode(0x00000046)
test_decode(0x00000047)
test_decode(0x00002308)
test_decode(0x00006308)
test_decode(0x00002508)
test_decode(0x00142348)
test_decode(0x00086348)
test_decode(0x00000049)
test_decode(0x00002309)
test_decode(0x00006309)
test_decode(0x00002509)
test_decode(0x0014E349)
test_decode(0x0008A349)
test_decode(0x0000004A)
test_decode(0x0000004B)
