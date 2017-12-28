
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- There isnt any specification avaliable
-- I only use this for easy way to store graphical data
-- generated by render targets or something
-- and ye, i tried to make PNG read/write

local DLib = DLib
local meta = FindMetaTable('LPNGBuffer') or {}
debug.getregistry().LPNGBuffer = meta
DLib.LPNGBufferMeta = meta
meta.__index = meta

local Color = Color
local assert = assert
local type = type
local ipairs = ipairs
local table = table
local util = util
local math = math
local os = os

local header = {0, 32, 68, 76, 73, 66, 144, 73, 77, 65, 71, 69, 128, 10, 0}

function DLib.CreateImage(width, height, colorToUse)
	colorToUse = colorToUse or Color(255, 255, 255, 0)
	assert(type(width) == 'number' and width >= 0, 'Width must be positive number or zero')
	assert(type(height) == 'number' and height >= 0, 'Height must be positive number or zero')

	local buffer = DLib.BytesBuffer()

	for i, byte in ipairs(header) do
		buffer:WriteUByte(byte)
	end

	-- header of metadata
	buffer:WriteData('META')

	-- width
	buffer:WriteUInt32(width)

	-- height
	buffer:WriteUInt32(height)

	-- Image has translucency
	buffer:WriteUByte(1)

	-- creation stamp
	buffer:WriteUInt64(os.time())

	-- modification stamp
	buffer:WriteUInt64(os.time())

	-- tell we are going to write blocks
	-- there is no ending token
	-- guess length is width * height * 4 bytes

	-- each 4 byte of data is a color of next pixel
	-- example - pixel at position of 2x0 will have 2 position in bytebuffer (4 - 8 bytes)
	-- pixel at position of 2x1 will have width * y * 4 + 2 position in bytebuffer (if width is 4, guess position is 20 - 24 bytes)
	buffer:WriteData('BLKS')
	local pointer = buffer.pointer

	local obj = setmetatable({}, meta)
	obj.buffer = buffer
	obj.point = pointer
	obj.width = width
	obj.height = height
	obj.creationStamp = os.time()
	obj.modificationStamp = os.time()

	obj.posX = -1
	obj.posY = 0
	obj.created = false

	for x = 0, width do
		for y = 0, height do
			obj:WritePixel(x, y, colorToUse)
		end
	end

	obj.created = true

	return obj
end

function meta:Reset()
	self.buffer:Reset()
	return self
end

function meta:CalculateBytePosition(x, y)
	return self.point + y * self.width * 4 + x * 4
end

function meta:WritePixel(x, y, color)
	assert(x >= 0 and x <= self.width, 'Invalid X position to write')
	assert(y >= 0 and y <= self.height, 'Invalid Y position to write')
	assert(IsColor(color), 'Input is not a color!')

	if self.created then
		self.buffer:Seek(self:CalculateBytePosition(x, y))
	end

	self.buffer:WriteUByte(color.r)
	self.buffer:WriteUByte(color.g)
	self.buffer:WriteUByte(color.b)
	self.buffer:WriteUByte(color.a)
	return self
end

function meta:ReadPixel(x, y)
	assert(x >= 0 and x <= self.width, 'Invalid X position to write')
	assert(y >= 0 and y <= self.height, 'Invalid Y position to write')
	self.buffer:Seek(self:CalculateBytePosition(x, y))
	return Color(self.buffer:ReadUByte(), self.buffer:ReadUByte(), self.buffer:ReadUByte(), self.buffer:ReadUByte())
end

function meta:WriteNextPixel(color)
	local x = self.posX + 1
	local y = self.posY

	if x > self.width then
		y = y + 1
		x = 0
	end

	if y > self.height then
		error('Image resolution size exceeded')
	end

	self:WritePixel(x, y, color)
	self.posX = x
	self.posY = y

	return self
end

function meta:ReadNextPixel()
	local x = self.posX + 1
	local y = self.posY

	if x > self.width then
		y = y + 1
		x = 0
	end

	if y > self.height then
		error('Image resolution size exceeded')
	end

	return self:ReadPixel(x, y)
end

function meta:GetBuffer()
	return self.buffer
end

function meta:DumpBinary()
	return self.buffer:ToString()
end
