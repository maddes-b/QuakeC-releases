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

string GetNetName( float item_number ) = {
	switch ( item_number ) {
		case IT_AXE:
			return "Axe";
		case IT_SHOTGUN:
			return "Shotgun";
		case IT_SUPER_SHOTGUN:
			return "Super Shotgun";
		case IT_NAILGUN:
			return "Nailgun";
		case IT_SUPER_NAILGUN:
			return "Perforator";
		case IT_GRENADE_LAUNCHER:
			return "Grenade Launcher";
		case IT_ROCKET_LAUNCHER:
			return "Rocket Launcher";
		case IT_LIGHTNING:
			return "Lightning Gun";
		case IT_EXTRA_WEAPON:
			return "Extra Weapon";
		case IT_SHELLS:
			return "Shells";
		case IT_NAILS:
			return "Nails";
		case IT_ROCKETS:
			return "Rockets";
		case IT_CELLS:
			return "Cells";
		case IT_ARMOR1:
			return "Green Armor";
		case IT_ARMOR2:
			return "Yellow Armor";
		case IT_ARMOR3:
			return "Red Armor";
		case IT_SUPERHEALTH:
			return "Mega Health";
		case IT_KEY1: {
			if ( world.worldtype == WORLDTYPE_MEDIEVAL )
				return "Silver key";
			else if ( world.worldtype == WORLDTYPE_METAL )
				return "Silver runkey";
			else if ( world.worldtype == WORLDTYPE_BASE )
				return "Silver keycard";
		}
		case IT_KEY2: {
			if ( world.worldtype == WORLDTYPE_MEDIEVAL )
				return "Gold key";
			else if ( world.worldtype == WORLDTYPE_METAL )
				return "Gold runkey";
			else if ( world.worldtype == WORLDTYPE_BASE )
				return "Gold keycard";
		}
		case IT_INVISIBILITY:
			return "Ring of Shadows";
		case IT_INVULNERABILITY:
			return "Pentagram of Protection";
		case IT_SUIT:
			return "Biohazard Suit";
		case IT_QUAD:
			return "Quad Damage";

		default:
			return string_null;
	}
};
