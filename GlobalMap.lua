
--[=[
	Copyright (c) 2014 Blequi

	Permission is hereby granted, free of charge,
	to any person obtaining a copy of this software
	and associated documentation files (the "Software"),
	to deal in the Software without restriction, including without
	limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software,
	and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:

	The above copyright notice and this permission notice
	shall be included in all copies or substantial portions
	of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
	FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
]=]










--[=[

		A brief description of the .map file format:

]=]

-- First of all, you are invited to read this great explanation
-- from TibiaApi team:
--		https://code.google.com/p/tibiaapi/source/browse/trunk/tibiaapi/Util/MapMerger.cs#16

-- Each .map file is a 256 x 256 rectangle containing info
-- related to colors, terrain costs and marks of the minimap

-- Each file can be thought of 3 large chunks of bytes:
--
-- 1)
--		The first chunk (256 x 256 bytes = 65536 bytes):
--			Each byte at this region is an index inside of
--			Tibia's map palette. A palette is just an array
--			of colors and will be discussed in details later.
--
--			This region can be thought as an 2D array of bytes
--			with each dimension storing 256 entries.
--
--			In C, this would assume the following layout:
--
--				unsigned char colorIndices[256][256];
--
-- 2)
--		The second chunk (256 x 256 bytes = 65536 bytes):
--			Each byte at this region is the terrain cost
--			of the given sqm in question. It is useful for "G" cost
--			in the A* pathfinding algorithm (used in formula F = G + H).
--
--			This region can be thought as an 2D array of bytes
--			with each dimension storing 256 entries.
--
--			In C, this would assume the following layout:
--
--				unsigned char terrainCosts[256][256];
--
-- 			For more info on A*:
-- 				http://en.wikipedia.org/wiki/A*_search_algorithm
--
-- 3)
--		The third chunk begins with the number (4 bytes)
--		of marks in the map area followed by all the marks
--		till the end of the file.
--
--		Each mark in the file will be presented this way:
--
--		mark = {
--			x							(4 bytes),
--			y							(4 bytes),
--			type						(4 bytes),
--			description string length 	(2 bytes. This value is between [0, 99]),
--			description string 			(description string length - bytes, at most 0x63 bytes long)
--		}










--[=[

		Constants

]=]

-- The side of the map rectangle
local MM_SECTOR_SIZE = 256

-- Offset in bytes from the beginning of the file to colors data
local MAP_MAP_PALETTE_BEGIN = 0

-- As described above, it's MM_SECTOR_SIZE x MM_SECTOR_SIZE = 256 x 256
local MAP_MAP_PALETTE_LEN = MM_SECTOR_SIZE ^ 2

-- Offset in bytes from the beginning of the file to terrain costs data
local MAP_PATHCOSTS_BEGIN = (MAP_MAP_PALETTE_BEGIN + MAP_MAP_PALETTE_LEN)

-- The same as MAP_MAP_PALETTE_LEN
local MAP_PATHCOSTS_LEN = MAP_MAP_PALETTE_LEN

-- The begin of marks data in the map
local MAP_MARKS_BEGIN = (MAP_PATHCOSTS_BEGIN + MAP_PATHCOSTS_LEN)

-- Empty terrain cost
local PATH_EMPTY = 0

-- The max value for terrain costs
local PATH_COST_MAX = 250

-- Unexplored sqm in the map receives this value
local PATH_COST_UNDEFINED = 254

-- It was temporarily unavailable to walk over this sqm
-- due to fire fields, energy fields,
-- some exceptional thing or it's just a tree, wall or anything that
-- blocks you to walk there, thus when you closed the Tibia Client,
-- it caused the client to save mark this sqm to have
-- an obstacle back in the time, but it might be already available to walk.
local PATH_COST_OBSTACLE = 255

-- Next variable is Tibia's map colors palette.
-- Basically, it's the web safe palette (216 colors) with some colors added
-- resulting in 256 different colors, so each byte identifies
-- a unique color.
-- Read carefully GlobalMap:GetColor function to understand the process.

local MAP_PALETTE = {
	-- we return as a function to be called
	-- to avoid library users to set R, G, B
	-- values back to the table and get wrong R, G, B
	-- in future calls to the GlobalMap:GetColor function
	function() return { R = 0x00, G = 0x00, B = 0x00 } end,
	function() return { R = 0x00, G = 0x00, B = 0x33 } end,
	function() return { R = 0x00, G = 0x00, B = 0x66 } end,
	function() return { R = 0x00, G = 0x00, B = 0x99 } end,
	function() return { R = 0x00, G = 0x00, B = 0xCC } end,
	function() return { R = 0x00, G = 0x00, B = 0xFF } end,
	function() return { R = 0x00, G = 0x33, B = 0x00 } end,
	function() return { R = 0x00, G = 0x33, B = 0x33 } end,
	function() return { R = 0x00, G = 0x33, B = 0x66 } end,
	function() return { R = 0x00, G = 0x33, B = 0x99 } end,
	function() return { R = 0x00, G = 0x33, B = 0xCC } end,
	function() return { R = 0x00, G = 0x33, B = 0xFF } end,
	function() return { R = 0x00, G = 0x66, B = 0x00 } end,
	function() return { R = 0x00, G = 0x66, B = 0x33 } end,
	function() return { R = 0x00, G = 0x66, B = 0x66 } end,
	function() return { R = 0x00, G = 0x66, B = 0x99 } end,
	function() return { R = 0x00, G = 0x66, B = 0xCC } end,
	function() return { R = 0x00, G = 0x66, B = 0xFF } end,
	function() return { R = 0x00, G = 0x99, B = 0x00 } end,
	function() return { R = 0x00, G = 0x99, B = 0x33 } end,
	function() return { R = 0x00, G = 0x99, B = 0x66 } end,
	function() return { R = 0x00, G = 0x99, B = 0x99 } end,
	function() return { R = 0x00, G = 0x99, B = 0xCC } end,
	function() return { R = 0x00, G = 0x99, B = 0xFF } end,
	function() return { R = 0x00, G = 0xCC, B = 0x00 } end,
	function() return { R = 0x00, G = 0xCC, B = 0x33 } end,
	function() return { R = 0x00, G = 0xCC, B = 0x66 } end,
	function() return { R = 0x00, G = 0xCC, B = 0x99 } end,
	function() return { R = 0x00, G = 0xCC, B = 0xCC } end,
	function() return { R = 0x00, G = 0xCC, B = 0xFF } end,
	function() return { R = 0x00, G = 0xFF, B = 0x00 } end,
	function() return { R = 0x00, G = 0xFF, B = 0x33 } end,
	function() return { R = 0x00, G = 0xFF, B = 0x66 } end,
	function() return { R = 0x00, G = 0xFF, B = 0x99 } end,
	function() return { R = 0x00, G = 0xFF, B = 0xCC } end,
	function() return { R = 0x00, G = 0xFF, B = 0xFF } end,
	function() return { R = 0x33, G = 0x00, B = 0x00 } end,
	function() return { R = 0x33, G = 0x00, B = 0x33 } end,
	function() return { R = 0x33, G = 0x00, B = 0x66 } end,
	function() return { R = 0x33, G = 0x00, B = 0x99 } end,
	function() return { R = 0x33, G = 0x00, B = 0xCC } end,
	function() return { R = 0x33, G = 0x00, B = 0xFF } end,
	function() return { R = 0x33, G = 0x33, B = 0x00 } end,
	function() return { R = 0x33, G = 0x33, B = 0x33 } end,
	function() return { R = 0x33, G = 0x33, B = 0x66 } end,
	function() return { R = 0x33, G = 0x33, B = 0x99 } end,
	function() return { R = 0x33, G = 0x33, B = 0xCC } end,
	function() return { R = 0x33, G = 0x33, B = 0xFF } end,
	function() return { R = 0x33, G = 0x66, B = 0x00 } end,
	function() return { R = 0x33, G = 0x66, B = 0x33 } end,
	function() return { R = 0x33, G = 0x66, B = 0x66 } end,
	function() return { R = 0x33, G = 0x66, B = 0x99 } end,
	function() return { R = 0x33, G = 0x66, B = 0xCC } end,
	function() return { R = 0x33, G = 0x66, B = 0xFF } end,
	function() return { R = 0x33, G = 0x99, B = 0x00 } end,
	function() return { R = 0x33, G = 0x99, B = 0x33 } end,
	function() return { R = 0x33, G = 0x99, B = 0x66 } end,
	function() return { R = 0x33, G = 0x99, B = 0x99 } end,
	function() return { R = 0x33, G = 0x99, B = 0xCC } end,
	function() return { R = 0x33, G = 0x99, B = 0xFF } end,
	function() return { R = 0x33, G = 0xCC, B = 0x00 } end,
	function() return { R = 0x33, G = 0xCC, B = 0x33 } end,
	function() return { R = 0x33, G = 0xCC, B = 0x66 } end,
	function() return { R = 0x33, G = 0xCC, B = 0x99 } end,
	function() return { R = 0x33, G = 0xCC, B = 0xCC } end,
	function() return { R = 0x33, G = 0xCC, B = 0xFF } end,
	function() return { R = 0x33, G = 0xFF, B = 0x00 } end,
	function() return { R = 0x33, G = 0xFF, B = 0x33 } end,
	function() return { R = 0x33, G = 0xFF, B = 0x66 } end,
	function() return { R = 0x33, G = 0xFF, B = 0x99 } end,
	function() return { R = 0x33, G = 0xFF, B = 0xCC } end,
	function() return { R = 0x33, G = 0xFF, B = 0xFF } end,
	function() return { R = 0x66, G = 0x00, B = 0x00 } end,
	function() return { R = 0x66, G = 0x00, B = 0x33 } end,
	function() return { R = 0x66, G = 0x00, B = 0x66 } end,
	function() return { R = 0x66, G = 0x00, B = 0x99 } end,
	function() return { R = 0x66, G = 0x00, B = 0xCC } end,
	function() return { R = 0x66, G = 0x00, B = 0xFF } end,
	function() return { R = 0x66, G = 0x33, B = 0x00 } end,
	function() return { R = 0x66, G = 0x33, B = 0x33 } end,
	function() return { R = 0x66, G = 0x33, B = 0x66 } end,
	function() return { R = 0x66, G = 0x33, B = 0x99 } end,
	function() return { R = 0x66, G = 0x33, B = 0xCC } end,
	function() return { R = 0x66, G = 0x33, B = 0xFF } end,
	function() return { R = 0x66, G = 0x66, B = 0x00 } end,
	function() return { R = 0x66, G = 0x66, B = 0x33 } end,
	function() return { R = 0x66, G = 0x66, B = 0x66 } end,
	function() return { R = 0x66, G = 0x66, B = 0x99 } end,
	function() return { R = 0x66, G = 0x66, B = 0xCC } end,
	function() return { R = 0x66, G = 0x66, B = 0xFF } end,
	function() return { R = 0x66, G = 0x99, B = 0x00 } end,
	function() return { R = 0x66, G = 0x99, B = 0x33 } end,
	function() return { R = 0x66, G = 0x99, B = 0x66 } end,
	function() return { R = 0x66, G = 0x99, B = 0x99 } end,
	function() return { R = 0x66, G = 0x99, B = 0xCC } end,
	function() return { R = 0x66, G = 0x99, B = 0xFF } end,
	function() return { R = 0x66, G = 0xCC, B = 0x00 } end,
	function() return { R = 0x66, G = 0xCC, B = 0x33 } end,
	function() return { R = 0x66, G = 0xCC, B = 0x66 } end,
	function() return { R = 0x66, G = 0xCC, B = 0x99 } end,
	function() return { R = 0x66, G = 0xCC, B = 0xCC } end,
	function() return { R = 0x66, G = 0xCC, B = 0xFF } end,
	function() return { R = 0x66, G = 0xFF, B = 0x00 } end,
	function() return { R = 0x66, G = 0xFF, B = 0x33 } end,
	function() return { R = 0x66, G = 0xFF, B = 0x66 } end,
	function() return { R = 0x66, G = 0xFF, B = 0x99 } end,
	function() return { R = 0x66, G = 0xFF, B = 0xCC } end,
	function() return { R = 0x66, G = 0xFF, B = 0xFF } end,
	function() return { R = 0x99, G = 0x00, B = 0x00 } end,
	function() return { R = 0x99, G = 0x00, B = 0x33 } end,
	function() return { R = 0x99, G = 0x00, B = 0x66 } end,
	function() return { R = 0x99, G = 0x00, B = 0x99 } end,
	function() return { R = 0x99, G = 0x00, B = 0xCC } end,
	function() return { R = 0x99, G = 0x00, B = 0xFF } end,
	function() return { R = 0x99, G = 0x33, B = 0x00 } end,
	function() return { R = 0x99, G = 0x33, B = 0x33 } end,
	function() return { R = 0x99, G = 0x33, B = 0x66 } end,
	function() return { R = 0x99, G = 0x33, B = 0x99 } end,
	function() return { R = 0x99, G = 0x33, B = 0xCC } end,
	function() return { R = 0x99, G = 0x33, B = 0xFF } end,
	function() return { R = 0x99, G = 0x66, B = 0x00 } end,
	function() return { R = 0x99, G = 0x66, B = 0x33 } end,
	function() return { R = 0x99, G = 0x66, B = 0x66 } end,
	function() return { R = 0x99, G = 0x66, B = 0x99 } end,
	function() return { R = 0x99, G = 0x66, B = 0xCC } end,
	function() return { R = 0x99, G = 0x66, B = 0xFF } end,
	function() return { R = 0x99, G = 0x99, B = 0x00 } end,
	function() return { R = 0x99, G = 0x99, B = 0x33 } end,
	function() return { R = 0x99, G = 0x99, B = 0x66 } end,
	function() return { R = 0x99, G = 0x99, B = 0x99 } end,
	function() return { R = 0x99, G = 0x99, B = 0xCC } end,
	function() return { R = 0x99, G = 0x99, B = 0xFF } end,
	function() return { R = 0x99, G = 0xCC, B = 0x00 } end,
	function() return { R = 0x99, G = 0xCC, B = 0x33 } end,
	function() return { R = 0x99, G = 0xCC, B = 0x66 } end,
	function() return { R = 0x99, G = 0xCC, B = 0x99 } end,
	function() return { R = 0x99, G = 0xCC, B = 0xCC } end,
	function() return { R = 0x99, G = 0xCC, B = 0xFF } end,
	function() return { R = 0x99, G = 0xFF, B = 0x00 } end,
	function() return { R = 0x99, G = 0xFF, B = 0x33 } end,
	function() return { R = 0x99, G = 0xFF, B = 0x66 } end,
	function() return { R = 0x99, G = 0xFF, B = 0x99 } end,
	function() return { R = 0x99, G = 0xFF, B = 0xCC } end,
	function() return { R = 0x99, G = 0xFF, B = 0xFF } end,
	function() return { R = 0xCC, G = 0x00, B = 0x00 } end,
	function() return { R = 0xCC, G = 0x00, B = 0x33 } end,
	function() return { R = 0xCC, G = 0x00, B = 0x66 } end,
	function() return { R = 0xCC, G = 0x00, B = 0x99 } end,
	function() return { R = 0xCC, G = 0x00, B = 0xCC } end,
	function() return { R = 0xCC, G = 0x00, B = 0xFF } end,
	function() return { R = 0xCC, G = 0x33, B = 0x00 } end,
	function() return { R = 0xCC, G = 0x33, B = 0x33 } end,
	function() return { R = 0xCC, G = 0x33, B = 0x66 } end,
	function() return { R = 0xCC, G = 0x33, B = 0x99 } end,
	function() return { R = 0xCC, G = 0x33, B = 0xCC } end,
	function() return { R = 0xCC, G = 0x33, B = 0xFF } end,
	function() return { R = 0xCC, G = 0x66, B = 0x00 } end,
	function() return { R = 0xCC, G = 0x66, B = 0x33 } end,
	function() return { R = 0xCC, G = 0x66, B = 0x66 } end,
	function() return { R = 0xCC, G = 0x66, B = 0x99 } end,
	function() return { R = 0xCC, G = 0x66, B = 0xCC } end,
	function() return { R = 0xCC, G = 0x66, B = 0xFF } end,
	function() return { R = 0xCC, G = 0x99, B = 0x00 } end,
	function() return { R = 0xCC, G = 0x99, B = 0x33 } end,
	function() return { R = 0xCC, G = 0x99, B = 0x66 } end,
	function() return { R = 0xCC, G = 0x99, B = 0x99 } end,
	function() return { R = 0xCC, G = 0x99, B = 0xCC } end,
	function() return { R = 0xCC, G = 0x99, B = 0xFF } end,
	function() return { R = 0xCC, G = 0xCC, B = 0x00 } end,
	function() return { R = 0xCC, G = 0xCC, B = 0x33 } end,
	function() return { R = 0xCC, G = 0xCC, B = 0x66 } end,
	function() return { R = 0xCC, G = 0xCC, B = 0x99 } end,
	function() return { R = 0xCC, G = 0xCC, B = 0xCC } end,
	function() return { R = 0xCC, G = 0xCC, B = 0xFF } end,
	function() return { R = 0xCC, G = 0xFF, B = 0x00 } end,
	function() return { R = 0xCC, G = 0xFF, B = 0x33 } end,
	function() return { R = 0xCC, G = 0xFF, B = 0x66 } end,
	function() return { R = 0xCC, G = 0xFF, B = 0x99 } end,
	function() return { R = 0xCC, G = 0xFF, B = 0xCC } end,
	function() return { R = 0xCC, G = 0xFF, B = 0xFF } end,
	function() return { R = 0xFF, G = 0x00, B = 0x00 } end,
	function() return { R = 0xFF, G = 0x00, B = 0x33 } end,
	function() return { R = 0xFF, G = 0x00, B = 0x66 } end,
	function() return { R = 0xFF, G = 0x00, B = 0x99 } end,
	function() return { R = 0xFF, G = 0x00, B = 0xCC } end,
	function() return { R = 0xFF, G = 0x00, B = 0xFF } end,
	function() return { R = 0xFF, G = 0x33, B = 0x00 } end,
	function() return { R = 0xFF, G = 0x33, B = 0x33 } end,
	function() return { R = 0xFF, G = 0x33, B = 0x66 } end,
	function() return { R = 0xFF, G = 0x33, B = 0x99 } end,
	function() return { R = 0xFF, G = 0x33, B = 0xCC } end,
	function() return { R = 0xFF, G = 0x33, B = 0xFF } end,
	function() return { R = 0xFF, G = 0x66, B = 0x00 } end,
	function() return { R = 0xFF, G = 0x66, B = 0x33 } end,
	function() return { R = 0xFF, G = 0x66, B = 0x66 } end,
	function() return { R = 0xFF, G = 0x66, B = 0x99 } end,
	function() return { R = 0xFF, G = 0x66, B = 0xCC } end,
	function() return { R = 0xFF, G = 0x66, B = 0xFF } end,
	function() return { R = 0xFF, G = 0x99, B = 0x00 } end,
	function() return { R = 0xFF, G = 0x99, B = 0x33 } end,
	function() return { R = 0xFF, G = 0x99, B = 0x66 } end,
	function() return { R = 0xFF, G = 0x99, B = 0x99 } end,
	function() return { R = 0xFF, G = 0x99, B = 0xCC } end,
	function() return { R = 0xFF, G = 0x99, B = 0xFF } end,
	function() return { R = 0xFF, G = 0xCC, B = 0x00 } end,
	function() return { R = 0xFF, G = 0xCC, B = 0x33 } end,
	function() return { R = 0xFF, G = 0xCC, B = 0x66 } end,
	function() return { R = 0xFF, G = 0xCC, B = 0x99 } end,
	function() return { R = 0xFF, G = 0xCC, B = 0xCC } end,
	function() return { R = 0xFF, G = 0xCC, B = 0xFF } end,
	function() return { R = 0xFF, G = 0xFF, B = 0x00 } end,
	function() return { R = 0xFF, G = 0xFF, B = 0x33 } end,
	function() return { R = 0xFF, G = 0xFF, B = 0x66 } end,
	function() return { R = 0xFF, G = 0xFF, B = 0x99 } end,
	function() return { R = 0xFF, G = 0xFF, B = 0xCC } end,
	function() return { R = 0xFF, G = 0xFF, B = 0xFF } end,

	-- tibia added the next colors to the web safe palette

	function() return { R = 0x32, G = 0x00, B = 0x00 } end,
	function() return { R = 0x32, G = 0x00, B = 0x33 } end,
	function() return { R = 0x32, G = 0x00, B = 0x66 } end,
	function() return { R = 0x32, G = 0x00, B = 0x99 } end,
	function() return { R = 0x32, G = 0x00, B = 0xCC } end,
	function() return { R = 0x32, G = 0x00, B = 0xFF } end,
	function() return { R = 0x32, G = 0x33, B = 0x00 } end,
	function() return { R = 0x32, G = 0x33, B = 0x33 } end,
	function() return { R = 0x32, G = 0x33, B = 0x66 } end,
	function() return { R = 0x32, G = 0x33, B = 0x99 } end,
	function() return { R = 0x32, G = 0x33, B = 0xCC } end,
	function() return { R = 0x32, G = 0x33, B = 0xFF } end,
	function() return { R = 0x32, G = 0x66, B = 0x00 } end,
	function() return { R = 0x32, G = 0x66, B = 0x33 } end,
	function() return { R = 0x32, G = 0x66, B = 0x66 } end,
	function() return { R = 0x32, G = 0x66, B = 0x99 } end,
	function() return { R = 0x32, G = 0x66, B = 0xCC } end,
	function() return { R = 0x32, G = 0x66, B = 0xFF } end,
	function() return { R = 0x32, G = 0x99, B = 0x00 } end,
	function() return { R = 0x32, G = 0x99, B = 0x33 } end,
	function() return { R = 0x32, G = 0x99, B = 0x66 } end,
	function() return { R = 0x32, G = 0x99, B = 0x99 } end,
	function() return { R = 0x32, G = 0x99, B = 0xCC } end,
	function() return { R = 0x32, G = 0x99, B = 0xFF } end,
	function() return { R = 0x32, G = 0xCC, B = 0x00 } end,
	function() return { R = 0x32, G = 0xCC, B = 0x33 } end,
	function() return { R = 0x32, G = 0xCC, B = 0x66 } end,
	function() return { R = 0x32, G = 0xCC, B = 0x99 } end,
	function() return { R = 0x32, G = 0xCC, B = 0xCC } end,
	function() return { R = 0x32, G = 0xCC, B = 0xFF } end,
	function() return { R = 0x32, G = 0xFF, B = 0x00 } end,
	function() return { R = 0x32, G = 0xFF, B = 0x33 } end,
	function() return { R = 0x32, G = 0xFF, B = 0x66 } end,
	function() return { R = 0x32, G = 0xFF, B = 0x99 } end,
	function() return { R = 0x32, G = 0xFF, B = 0xCC } end,
	function() return { R = 0x32, G = 0xFF, B = 0xFF } end,

	function() return { R = 0x65, G = 0x00, B = 0x00 } end,
	function() return { R = 0x65, G = 0x00, B = 0x33 } end,
	function() return { R = 0x65, G = 0x00, B = 0x66 } end,
	function() return { R = 0x65, G = 0x00, B = 0x99 } end

}

--[=[

		Here the code begins

]=]






--[=[ Class definition ]=]

-- Our exportable class
local GlobalMap = {
	file = nil,
	location = nil,
	colors = nil,
	terraincosts = nil
}
-- lookup getter function (this case, our table itself)
GlobalMap.__index = GlobalMap

-- prevent getmetatable to modify the class metatable
GlobalMap.__metatable = false

--[[
	summary:
		equality comparer for the class

	parameters:
		left:
			GlobalMap instance
		right:
			GlobalMap instance

	returns:
		boolean
]]
function GlobalMap.__eq(left, right)

	if (left and right and left:IsOpen() and right:IsOpen()) then
		local lx, ly, lz = left:Location()
		local rx, ry, rz = right:Location()
		return (
			lx == rx and
			ly == ry and
			lz == rz
		)
	end

	return false
end

--[[
	summary:
		inequality comparer for the class

	parameters:
		left:
			GlobalMap instance
		right:
			GlobalMap instance

	returns:
		boolean
]]
function GlobalMap.__neq(left, right)
	return not (left == right)
end

--[[
	summary:
		allows "print(map)", where map is a GlobalMap instance

	returns:
		string
]]
function GlobalMap:__tostring()
	return ("{ Left = %i, Top = %i, Right = %i, Bottom = %i }"):format(self:Left(), self:Top(), self:Right(), self:Bottom())
end
--[=[ end of class definition ]=]






--[=[ File operations ]=]

--[[
	summary:
		open .map for binary reading

	parameters:
		filename:
			string

	returns:
		void
]]
function GlobalMap:Open(filename)
	local file, msg = io.open(filename, "rb")
	if (file == nil) then
		return file, msg
	end

	self.file = file
	local x, y, z = filename:match("(%d%d%d)(%d%d%d)(%d%d).map$")

	-- make sure it's in the desired format
	assert(x and y and z, "bad filename format")
	self.location = {
		x = tonumber(x) * MM_SECTOR_SIZE,
		y = tonumber(y) * MM_SECTOR_SIZE,
		z = tonumber(z)
	}
end

--[[
	summary:
		check whether we our file handle is currently open

	returns:
		boolean
]]
function GlobalMap:IsOpen()
	return self.file ~= nil
end

--[[
	summary:
		close the file

	returns:
		void
]]
function GlobalMap:Close()
	local file = self.file
	if (file ~= nil) then

		file:close()

		self.file = nil
		self.location = nil
		self.colors = nil
		self.terraincosts = nil
	end
end
--[=[ end of file operations ]=]








--[=[ Helper local functions (these functions won't be exported) ]=]

--[[
	summary:
		make sure it's open

	parameters:
		self:
			GlobalMap instance

	returns:
		void
]]
local function assertopen(self)
	assert(self:IsOpen(), "You must open the file before any action")
end

--[[
	summary:
		make sure colors are loaded in memory

	parameters:
		self:
			GlobalMap instance

	returns:
		void
]]
local function assertcolors(self)
	assert(self.colors, "You must call LoadColors first")
end

--[[
	summary:
		make sure terrain costs are loaded in memory

	parameters:
		self:
			GlobalMap instance

	returns:
		void
]]
local function assertterraincosts(self)
	assert(self.terraincosts, "You must call LoadTerrainCosts first")
end

--[[
	summary:
		make sure both x and y are integers

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		void
]]
local function assertint(x, y)
	assert(
		type(x) == "number" and type(y) == "number" and math.floor(x) == x and math.floor(y) == y,
		"integer numbers expected"
	)
end

--[[
	summary:
		convert 4-bytes aligned into an 32-bit integer inside this interval [0, (2 ^ 32 - 1)].
		I haven't used bit32 functions, because it's Lua 5.2+
		and those Lua 5.1 users would face issues

	parameters:
		str:
			string
		index:
			number (integer)

	returns:
		number in the range [0, (2 ^ 32 - 1)]
]]
local function toint(str, index)
	-- make sure we can read 4 bytes
	assert(str:len() >= index + 3, "There are no bytes to read. It seems a corrupted file")

	local b0, b1, b2, b3 = str:byte(index, index + 3)

	local m1 = 256
	local m2 = m1 * m1
	local m3 = m2 * m1

	return b0 +
		b1 * m1 +
		b2 * m2 +
		b3 * m3
end

--[[
	summary:
		convert 2-bytes aligned into an 16-bit integer inside this interval [0, (2 ^ 16 - 1)].
		I haven't used bit32 functions, because it's Lua 5.2+
		and those Lua 5.1 users would face issues

	parameters:
		str:
			string
		index:
			number (integer)

	returns:
		number in the range [0, (2 ^ 16 - 1)]
]]
local function toshort(str, index)
	-- make sure we can read 2 bytes
	assert(str:len() >= index + 1, "There are no bytes to read. It seems a corrupted file")

	local b0, b1 = str:byte(index, index + 1)

	local m1 = 256

	return b0 + b1 * m1
end

--[[
	summary:
		basically, it converts 2D indices to 1D index (x, y) -> x * side + y

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		number between [0, (MM_SECTOR_SIZE ^ 2) - 1]
]]
local function getlinearoffset(x, y)
	return x * MM_SECTOR_SIZE + y
end
--[=[ end of helper functions ]=]










--[=[ Class properties ]=]

--[[
	summary:
		x position of the map (or left most position of the visual map)

		[|]-----
		[|]    |
		[|]    |
		[|]-----

	returns:
		number (integer)
]]
function GlobalMap:Left()
	assertopen(self)
	return self.location.x
end

--[[
	summary:
		y position of the map (or top most position of the visual map)

		[-----]
		|     |
		|     |
		-------

	returns:
		number (integer)
]]
function GlobalMap:Top()
	assertopen(self)
	return self.location.y
end

--[[
	summary:
		x position from the END of the map (or right most position of the visual map)

		-----[|]
		|    [|]
		|    [|]
		-----[|]

	returns:
		number (integer)
]]
function GlobalMap:Right()
	return self:Left() + MM_SECTOR_SIZE - 1
end

--[[
	summary:
		y position from the END of the map (or bottom most position of the visual map)

		-------
		|     |
		|     |
		[-----]

	returns:
		number (integer)
]]
function GlobalMap:Bottom()
	return self:Top() + MM_SECTOR_SIZE - 1
end

--[[
	summary:
		x position of the map (or left most position of the visual map)

		[|]-----
		[|]    |
		[|]    |
		[|]-----

	returns:
		number (integer)
]]
function GlobalMap:X()
	return self:Left()
end

--[[
	summary:
		y position of the map (or top most position of the visual map)

		[-----]
		|     |
		|     |
		-------

	returns:
		number (integer)
]]
function GlobalMap:Y()
	return self:Right()
end

--[[
	summary:
		level of map floor

	returns:
		number (integer)
]]
function GlobalMap:Z()
	assertopen(self)
	return self.location.z
end

--[[
	summary:
		Tibia position from the Left-Top corner of the map (in 3D)

	returns:
		number (integer)
]]
function GlobalMap:Location()
	assertopen(self)
	local location = self.location
	return location.x, location.y, location.z
end
--[=[ end of class properties ]=]









--[=[ Class methods ]=]

--[[
	summary:
		check whether the given Tibia position is in the file or not

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		boolean
]]
function GlobalMap:IsOnRange(x, y)
	return self:Left() <= x and
		x <= self:Right() and
		self:Top() <= y and
		y <= self:Bottom()
end

--[[
	summary:
		loads all the color data from the file to memory
		(256x256 bytes = 65536 bytes, so use it sparingly to avoid
		a crazy memory usage)
		Usually, you call it once per file

	returns:
		void
]]
function GlobalMap:LoadColors()
	assertopen(self)

	local file = self.file

	-- get the initial position
	local current = file:seek("cur")

	-- go to the colors region in file
	file:seek("set", MAP_MAP_PALETTE_BEGIN)

	-- read all the colors
	self.colors = assert(
		file:read(MAP_MAP_PALETTE_LEN),
		"failed to read file"
	)

	-- make sure we read MAP_MAP_PALETTE_LEN bytes from the file
	assert(
		self.colors:len() == MAP_MAP_PALETTE_LEN,
		("cannot read %i bytes from the file"):format(MAP_MAP_PALETTE_LEN)
	)

	-- restore initial position
	file:seek("set", current)
end

--[[
	summary:
		loads all the terrain costs data from the file to memory
		(256x256 bytes = 65536 bytes, so use it sparingly to avoid
		a crazy memory usage)
		Usually, you call it once per file

	returns:
		void
]]
function GlobalMap:LoadTerrainCosts()
	assertopen(self)

	local file = self.file

	-- get the initial position
	local current = file:seek("cur")

	-- go to the terrain costs region in the file
	file:seek("set", MAP_PATHCOSTS_BEGIN)

	-- read all the terrain costs (or sqms speeds)
	self.terraincosts = assert(
		file:read(MAP_PATHCOSTS_LEN),
		"failed to read file"
	)

	-- make sure we read MAP_PATHCOSTS_LEN bytes from the file
	assert(
		self.terraincosts:len() == MAP_PATHCOSTS_LEN,
		("cannot read %i bytes from the file"):format(MAP_PATHCOSTS_LEN)
	)

	-- restore initial position
	file:seek("set", current)
end

--[[
	summary:
		read all the marks from the file to memory and
		returns everything as a table of marks.

	returns:
		table:
			{
				{
					X		 	= ..., -- number
					Y 			= ..., -- number
					Type 		= ..., -- number
					Description = ...  -- string
				},

				{
					X		 	= ..., -- number
					Y 			= ..., -- number
					Type 		= ..., -- number
					Description = ...  -- string
				},
				.
				.
				.
			}
]]
function GlobalMap:Marks()

	local file = self.file

	-- get the initial position
	local current = file:seek("cur")

	-- get the size of the file
	local size = file:seek("end")

	-- the amount of bytes in the "marks" region of the file
	local markslen = size - MAP_MARKS_BEGIN

	-- make sure there are bytes to read
	assert(markslen > 0, "There are no bytes to read. This file is corrupted")

	-- go to the beginning of the "marks" region
	file:seek("set", MAP_MARKS_BEGIN)

	-- make sure we can read
	local marksdata = assert(
		file:read(markslen),
		"failed to read file"
	)

	-- make sure we read the data in the "marks" region and there
	-- are no bytes left to be read (a cache of the region in memory)
	assert(
		marksdata:len() == markslen,
		("cannot read %i bytes from the file"):format(markslen)
	)

	-- 1-based string (we will use "index"
	-- as a variable to walk into the file)
	-- Since Lua doesn't have a built-in
	-- solution for Memory Streams like
	-- C, C++, C#, Java, we have to make this
	-- work around
	local index = 1

	-- number of marks in the file
	local n = toint(marksdata, index)
	-- advance 4 bytes
	index = index + 4

	-- placeholder to the marks
	local marks = {}

	for i = 1, n do

		local markX = toint(marksdata, index)
		-- advance 4 bytes
		index = index + 4

		local markY = toint(marksdata, index)
		-- advance 4 bytes
		index = index + 4

		local markType = toint(marksdata, index)
		-- advance 4 bytes
		index = index + 4

		local descriptionLen = toshort(marksdata, index)
		-- advance 2 bytes
		index = index + 2

		assert(descriptionLen <= 99, "This value is expected to be between [0, 99]")

		local description = descriptionLen > 0 and
			marksdata:sub(index, index + descriptionLen - 1) or ""

		-- advance descriptionLen bytes
		index = index + descriptionLen

		-- add this mark to the list
		table.insert(marks,
			{
				X = markX,
				Y = markY,
				Type = markType,
				Description = description
			}
		)
	end

	-- restore initial position
	file:seek("set", current)

	-- returns all the marks
	return marks
end

--[[
	summary:
		get the color of the sqm in the minimap at x, y in the save time

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		table:
			{
				A = ...,	-- number
				R = ...,	-- number
				G = ...,	-- number
				B = ...		-- number
			}
]]
function GlobalMap:GetColor(x, y)
	-- make sure we have valid integers
	assertint(x, y)

	-- make sure we have loaded colors
	assertcolors(self)

	-- make sure it's in the right range
	assert(
		self:IsOnRange(x, y),
		("X: %i or Y: %i are out of range. Make sure to pass x between [%i, %i] and y between [%i, %i]")
		:format(x, y, self:Left(), self:Right(), self:Top(), self:Bottom())
	)

	-- x, y comes in Tibia positions, so subtract the left top
	-- position of the file to put x, y within [0, 255] x [0, 255]
	local offset = getlinearoffset(x - self:Left(), y - self:Top())

	-- Lua strings are 1-based, so add 1 to index self.colors below
	-- in the :byte() function.
	-- In programming languages with 0-based arrays like C/C++/C#/Java,
	-- we have to comment the following line in order to work properly
	offset = offset + 1

	local index = self.colors:byte(offset)

	-- As explained earlier, each value from file is an index
	-- within the palette, so access it. But remember that
	-- Lua tables are 1-based, so let's add 1 again.
	-- In programming languages with 0-based arrays like C/C++/C#/Java,
	-- we have to comment the following line in order to work properly
	index = index + 1

	return MAP_PALETTE[index]()
end

--[[
	summary:
		get the terrain cost in the sqm at x, y in the save time

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		number (integer)
]]
function GlobalMap:GetTerrainCost(x, y)
	-- make sure we have valid integers
	assertint(x, y)

	-- make sure we loaded terrain costs
	assertterraincosts(self)

	-- make sure it's in the right range
	assert(
		self:IsOnRange(x, y),
		("X: %i or Y: %i are out of range. Make sure to pass x between [%i, %i] and y between [%i, %i]")
		:format(x, y, self:Left(), self:Right(), self:Top(), self:Bottom())
	)

	-- x, y comes in Tibia positions, so subtract the left top
	-- position of the file to put x, y within [0, 255] x [0, 255]
	local offset = getlinearoffset(x - self:Left(), y - self:Top())

	-- Lua strings are 1-based, so add 1 to index self.colors below
	-- in the :sub() function
	-- In programming languages with 0-based arrays like C/C++/C#/Java,
	-- we have to comment the following line in order to work properly
	offset = offset + 1

	return self.terraincosts:byte(offset)
end

--[[
	summary:
		check if x, y had an obstacle at save time

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		boolean
]]
function GlobalMap:HasObstacle(x, y)
	return self:GetTerrainCost(x, y) == PATH_COST_OBSTACLE
end

--[[
	summary:
		check if x, y was undefined at save time

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		boolean
]]
function GlobalMap:IsUndefined(x, y)
	return self:GetTerrainCost(x, y) == PATH_COST_UNDEFINED
end

--[[
	summary:
		check if x, y was walkable at save time

	parameters:
		x:
			number (integer)
		y:
			number (integer)

	returns:
		boolean
]]
function GlobalMap:IsWalkable(x, y)
	local cost = self:GetTerrainCost(x, Y)
	return (
		cost ~= PATH_COST_OBSTACLE and
		cost ~= PATH_COST_UNDEFINED and
		cost ~= PATH_EMPTY and
		cost <= PATH_COST_MAX
	)
end
--[=[ end of class methods ]=]






--[=[ Save Image related functions (you can skip it) ]=]

--[[
	summary:
		get a (number) value and numberOfBytes
		and outputs value as string in binary
		form

	parameters:
		value:
			number (integer)
		numberOfBytes:
			number (integer)

	returns:
		string

	examples:
		getbinary(10, 2):
			It means we want 10 as 2-bytes value:
				10 = 0x0A 0x00
		getbinary(257, 4):
			It means we want 257 as 4-bytes value:
				257 = 0x01 0x01 0x00 0x00
]]
local function getbinary(value, numberOfBytes)
	local bytes = {}
	local v = value
	while (v >= 256) do
		local current = math.floor(v / 256)
		local reminder = v - current * 256
		table.insert(bytes, reminder)

		v = current
	end
	table.insert(bytes, v)

	local count = #bytes

	local missing = numberOfBytes - count
	for i = 1, missing do
		table.insert(bytes, 0)
	end

	for i = 1, numberOfBytes do
		bytes[i] = string.char(bytes[i])
	end

	return table.concat(bytes)
end

--[[
	summary:
		get a (integer) value and numberOfBytes
		and outputs value as string in binary
		form.

	parameters:
		value:
			number (integer [0, 2^32 - 1])

	returns:
		string
]]
local function getbinaryint(value)
	return getbinary(value, 4)
end

--[[
	summary:
		get a value and numberOfBytes
		and outputs value as string in binary
		form.

	parameters:
		value:
			number (short [0, 2^16 - 1])

	returns:
		string
]]
local function getbinaryshort(value)
	return getbinary(value, 2)
end

--[[
	summary:
		saves a .bmp file in RGB pixel format
		given its desired filename.

	parameters:
		filename:
			string

	returns:
		void
]]
function GlobalMap:SaveImage(filename)
	assert(
		filename and type(filename) == "string",
		"You must pass a valid file name"
	)
	assert(
		filename:sub(-4) == ".bmp",
		"You must pass a file name with bitmap '.bmp' extension. It's the only supported image format"
	)

	-- make sure it's open
	assertopen(self)

	-- make sure colors are loaded
	assertcolors(self)

	-- we are going to create a bitmap following .bmp file format
	-- For more info:
	-- http://en.wikipedia.org/wiki/BMP_file_format

	local file = assert(io.open(filename, "wb"))

	file:seek("set")

	local numBits = 24
	local imgWidth = MM_SECTOR_SIZE
	local imgHeight = MM_SECTOR_SIZE

	local stride = math.floor((numBits * imgWidth + 31) / 32) * 4
	local pixelsNumBytes = stride * imgHeight

	--[=[

		BMP HEADER

	]=]

	-- offset 0x0, size: 2: ID field (0x42, 0x4D)
	file:write("BM") -- Windows Only

	-- BMP HEADER size = 				0xE  bytes
	-- DIB HEADER size = (0x36 - 0xE) = 0x28 bytes
	--
	-- BITMAP size = (BMP HEADER size) +
	--				 (DIB HEADER size) +
	--				 (pixelsNumBytes)


	-- offset 0x2, size 4: Size of the BMP file
	file:write(getbinaryint(0xE + 0x28 + pixelsNumBytes))

	-- offset 0x6, size 2: Application specific
	file:write(getbinaryshort(0))

	-- offset 0x8, size 2: Application specific
	file:write(getbinaryshort(0))

	-- offset 0xA, size 4: Offset where the pixel array (bitmap data) can be found
	file:write(getbinaryint(54 --[[ 14 + 40 ]]))

	--[=[

		DIB Header

	]=]

	-- offset 0xE, size 4: Number of bytes in the DIB header (from this point)
	file:write(getbinaryint(40))

	-- offset 0x12, size 4: Width of the bitmap in pixels
	file:write(getbinaryint(imgWidth))

	-- offset 0x16, size 4: Height of the bitmap in pixels
	file:write(getbinaryint(imgHeight))

	-- offset 0x1A, size 2: Number of color planes being used
	file:write(getbinaryshort(1))

	-- offset 0x1C, size 2: Number of bits per pixel
	file:write(getbinaryshort(numBits))

	-- offset 0x1E, size 4: BI_RGB, no pixel array compression used
	file:write(getbinaryint(0))

	-- offset 0x22, size 4: Size of the raw bitmap data (including padding)
	file:write(getbinaryint(pixelsNumBytes))

	-- offset 0x26, size 4: Print resolution of the image, 72 DPI × 39.3701 inches per meter yields 2834.6472
	file:write(getbinaryint(2835))

	-- offset 0x2A, size 4: Print resolution of the image, 72 DPI × 39.3701 inches per meter yields 2834.6472
	file:write(getbinaryint(2835))

	-- offset 0x2E, size 4: Number of colors in the palette
	file:write(getbinaryint(0))

	-- offset 0x32, size 4: 0 means all colors are important
	file:write(getbinaryint(0))

	--[=[

		Start of pixels array (bitmap data)

	]=]

	local left, top, right, bottom =
		self:Left(), self:Top(), self:Right(), self:Bottom()

	local color = nil
	local paddingBytes = stride - math.floor(numBits * imgWidth / 32) * 4

	local padding = paddingBytes > 0 and ('\0'):rep(paddingBytes) or nil

	-- bottom-top, stacked rows

	for y = bottom, top, -1 do
		for x = left, right do

			color = self:GetColor(x, y)

			file:write(string.char(color.B, color.G, color.R))
		end

		if (padding ~= nil) then
			file:write(padding)
		end
	end

	file:flush()
	file:close()
end
--[=[ end of save image related functions ]=]








--[=[ Exporting the module ]=]

-- module metatable
local modulemetatable = {}

-- GlobalMap as the lookup table
modulemetatable.__index = GlobalMap

--[[
	summary:
		allows the module user to create
		a GlobalMap instance by calling
		"GlobalMap()"

	returns:
		a GlobalMap class instance
]]
function modulemetatable.__call()
	return setmetatable({}, GlobalMap)
end

--[=[

	local GlobalMap = require('GlobalMap')
	map = GlobalMap()
	.
	.
	.
]=]

--[=[ end of the module ]=]
return setmetatable({}, modulemetatable)
