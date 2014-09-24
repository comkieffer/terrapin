# Terrapin

Welcome to terrapin ! Terrapin is a set of scripts for the mincraft mod computercraft. The mod gives the player computers a robots (turtles) can be programmed in Lua.

## What is Terrapin

Terrapin started out as a wrapper for the turtle APIs. Like almost every other turtle API it simplifies movement and digging. Digging and movement methods all accept a parameter which is the amount of blocks to move. The digging routines will handle sand and gravel without any problems.

Over time though the API grew into something much bigger. CUrrently it contains the full penlight API, a 'require' implementation, a new startup system and more !

Most Terrapin APIs add turtle related functions. There are few computer specific tools. 

#### Turtle programs : 
##### Core Programs

- DigMine : Dig a mine. This is one of the most complex programs in the suite. It is explained further down. 
- digStair : dig a staircase. Width and depth can be configured.
- digTunnel : digs a tunnel. This too will receive a more in depth explanation later on. 
- fill : fill a hole with material.
- replace : replace the a floor with a certain type of block.
- replaceWall : replca a wall with a certain type of block.

##### Utilities

- rc : simple remote control.
- refuel : refule the rutle from fuel stored in the inventory.
- DigNext : digs the next mine. This is just shortcut to avoid replacing the turtle manually.

##### Dig Mine

As it's name implies this program digs a mine. 

It digs a corridor 100 blocks line and 2 blocks high. If torches are placed in slot 1 (the top right slot) of the turtle then every 10 blocks it will dig out a block on the side of the mine and place a torch in it. This mantains a sufficient light level in the mine to prevent mobs from spawning.

It can also operate in "intelligent mining" mode. In this mode it will automatically mine out interesting blocks. The player inserts "junk" blocks in slots 5 + (the first slot on the right of the second row from the top). When the turtle finds blocks that are not in this junk list it will mine them. The turtle will actually explore the holes it makes to ensure that it mines out the entire deposit. 
This is most useful in ender chest mode. When the turtle is full it will drop an enderchest behind it and empty it's mining products into it.

##### digTunnel
