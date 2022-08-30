/*  Copyright (C) 1996-2022 id Software LLC

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

/*
========================
Bot_PreThink

Called by the engine every frame before running the bots update in C++

NOTE: "self" will be the calling bot

Example usages of this function:

	1. Telling bots what to do or where to go ( i.e. setting a high level goal ).
	2. Modifying properties on the bot player ( or other players in-game ) that the bots can see/use doing their update.
========================
*/
void Bot_PreThink() {
	// add your code here!
};

/*
========================
Bot_PostThink

Called by the engine every frame after running the bots update in C++

NOTE: "self" will be the calling bot

Example usages of this function:

	1. Overriding/modifying bot user cmds.
	2. Overriding/modifying bot player properties.
========================
*/
void Bot_PostThink() {
	// add your code here!
};
