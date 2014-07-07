! Tibia Hard Drive

!! Description

*Tibia Hard Drive* is a project meant to parse common files saved in the hard drive by the Tibia Client using [url:Lua|http:www.lua.org] as programming language.

Anyone with a toolset capable of running Lua code (compiler, interpreter, etc) can benefit from using this library and due the nature of Lua, you can call this library even from your host program in C, C++, C#, Java, etc running a Lua state.

The files planned to be supported are: *.map*, *.dat*, *.spr*, *.cfg* and possibly others. For now, .map is the only one supported.

!! Features

* .map:
** Get location of the map (in x, y, z coordinates)
** Left, Top, Right and Bottom locations of the map region in Tibian coordinates
** Get rgb color at x, y as displayed by the Tibia Client's automap.
** Get terrain cost at x, y
** Get all the marks in the map
** Save .bmp image of the map (probably Windows-only, not tested though)

!! Planned Features

* .dat:
** Get info related to any object given its id
** Get Items info
** Get Outfits info
** Get Effects info
** Get Missiles info

* .spr
** Save .bmp image of any player with an outfit, given its head, body, legs and feet colors.
** Save .bmp image of any sprite
*** Item
*** Creature Outfit
*** Effect
*** Missile

* .cfg
** Get all the info related to Tibia Client configuration, including Hotkeys, Classic Control, etc