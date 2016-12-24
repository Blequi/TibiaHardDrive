# Tibia Hard Drive

## Description

**Tibia Hard Drive** is a project meant to parse common files saved in the hard drive by the Tibia Client using [Lua](http://www.lua.org) as programming language.

Anyone with a toolset capable of running Lua code (compiler, interpreter, etc) can benefit from using this library and due the nature of Lua, you can call this library even from your host program in C, C++, C#, Java, etc running a Lua state.

The files planned to be supported are: **.map**, **.dat**, **.spr**, **.cfg** and possibly others. For now, .map is the only one supported.

## Features

* GlobalMap (.map):
  * Get location of the map (in x, y, z coordinates)
  * Left, Top, Right and Bottom locations of the map region in Tibian coordinates
  * Get rgb color at x, y as displayed by the Tibia Client's automap.
  * Get terrain cost at x, y
  * Get all the marks in the map
  * Save .bmp image of the map (probably Windows-only, not tested though)

## Planned Features

* .dat:
  * Get info related to any object given its id
  * Get Items info
  * Get Outfits info
  * Get Effects info
  * Get Missiles info

* .spr
  * Save .bmp image of any player with an outfit, given its head, body, legs and feet colors.
  * Save .bmp image of any sprite
    * Item
    * Creature Outfit
    * Effect
    * Missile

* .cfg
  * Get all the info related to Tibia Client configuration, including Hotkeys, Classic Control, etc

## Examples

### GlobalMap class (.map)

Replace "filename", "bmpfilename" below for you personal files.

* How to print all the marks on the map:
    ```lua

     local GlobalMap = require("GlobalMap")
    	local map = GlobalMap()
    	
    	local filename = "FILENAME" -- ex: os.getenv("appdata") .. "\\Tibia\\Automap\\12812507.map"
    	
    	map:Open(filename)
    
    	if (map:IsOpen()) then
    		for _, mark in ipairs(map:Marks()) do
    
    			print(
    				("{ x = %s, y = %s, type = %s, description = %q }"):format(mark.X, mark.Y, mark.Type, mark.Description)
    			)
    
    		end
    	else
    		print("cannot open map")
    	end
    
    	map:Close()
```

* How to save a .bmp image from the map:
    ```lua

     local GlobalMap = require("GlobalMap")
    	local map = GlobalMap()
    
    	local filename = "FILENAME" -- ex: os.getenv("appdata") .. "\\Tibia\\Automap\\12812507.map"
    	local bmpfilename = "USER_IMG.bmp" -- ex: os.getenv("userprofile") .. "\\venore.bmp"
    	
    	map:Open(filename)
    
    	if (map:IsOpen()) then
    		map:LoadColors()
    		map:SaveImage(bmpfilename)
    	else
    		print("cannot open map")
    	end
    
    	map:Close()
```

* How to print all the colors in the map and its respective Tibian locations:
    ```lua

     local GlobalMap = require("GlobalMap")
    	local map = GlobalMap()
    
    	local filename = "FILENAME" -- ex: os.getenv("appdata") .. "\\Tibia\\Automap\\12812507.map"
    	
    	map:Open(filename)
    	
    	if (map:IsOpen()) then
    	  
    	 map:LoadColors()
      	
    		local left, top, right, bottom =
    			map:Left(), map:Top(), map:Right(), map:Bottom()
    
    		local z = map:Z()
    		
    		local color = nil
    		
    		for x = left, right do
    			for y = top, bottom do
    			  
    			  color = map:GetColor(x, y)
    			
    				print(
    					('(%05i, %05i, %02i) = { r = 0x%02X, g = 0x%02X, b = 0x%02X }')
    					:format(x, y, z, color.R, color.G, color.B)
    				)
    			end
    		end
    	else
    	  print("cannot open map")
    	end
    	
    	map:Close()
```

* How to print all the terrain costs in the map and its respective Tibian locations:
    ```lua

     local GlobalMap = require("GlobalMap")
     
     local map = GlobalMap()
    
    	local filename = "FILENAME" -- ex: os.getenv("appdata") .. "\\Tibia\\Automap\\12812507.map"
    	
    	map:Open(filename)
    	
    	if (map:IsOpen()) then
    	
    		map:LoadTerrainCosts()
    
    		local left, top, right, bottom =
    			map:Left(), map:Top(), map:Right(), map:Bottom()
    
    		local z = map:Z()
    
    		for x = left, right do
    			for y = top, bottom do
    				print(
    					("(%05i, %05i, %02i) = 0x%02X"):format(x, y, z, map:GetTerrainCost(x, y))
    				)
    			end
    		end
    		
    	else
    		print("cannot open map")
    	end
    
    	map:Close()
````

## Thanks
* [Programming in Lua](http://www.lua.org/pil/contents.html)
* [Bitmap file format at Wikipedia](http://en.wikipedia.org/wiki/BMP_file_format)
* [TibiaApi](https://code.google.com/p/tibiaapi/source/browse/trunk/tibiaapi/Util/MapMerger.cs#16)
* Jo3Bingham, for things that will come
  * [Tibia: Data File Structure](http://tpforums.org/forum/threads/5030-Tibia-Data-File-Structure)
  * [Tibia: Sprite File Structure](http://tpforums.org/forum/threads/5031-Tibia-Sprite-File-Structure)
  
