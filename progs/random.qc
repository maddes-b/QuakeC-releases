/*  Copyright (C) 1996-1997  Rogue Entertainment

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
// Random.qc

// =======================================================
// Random Items!
// =======================================================

// equal divisions of 1:
// 5: 0.2, 0.4, 0.6, 0.8, 1
// 6: 0.16, 0.33, 0.48, 0.66, 0.83, 1
// 7: 0.14, 0.28, 0.43, 0.56, 0.71, 0.86, 1
// 8: 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1
void() random_pick_type =
{
	local float randItem;

	randItem = random();

	self.touch = powerup_touch;
	setsize (self, '-16 -16 -24', '16 16 32');

	if(randItem < 0.2)
	{
		self.touch = newitems_touch;
		self.noise = "shield/pickup.wav";
		setmodel (self, "progs/shield.mdl");
		self.netname = "Power Shield";
		self.items = 0;
		self.items2 = IT2_SHIELD;
//		if(norandom == 1)
//			self.classname = "item_powerup_shield";
	}
	else if (randItem < 0.4)
	{
		self.touch = newitems_touch;
		self.noise = "belt/pickup.wav";
		setmodel (self, "progs/beltup.mdl");
		self.netname = "Anti-Grav Belt";
		self.items = 0;
		self.items2 = IT2_ANTIGRAV;
//		if(norandom == 1)
//			self.classname = "item_powerup_belt";
	}
	else if (randItem < 0.6)
	{
		self.noise = "items/protect.wav";
		setmodel (self, "progs/invulner.mdl");
		self.netname = "Pentagram of Protection";
		self.items = IT_INVULNERABILITY;
		self.items2 = 0;
//		if(norandom == 1)
//			self.classname = "item_artifact_invulnerability";
	}
	else if (randItem < 0.8)
	{
		self.noise = "items/inv1.wav";
		setmodel (self, "progs/invisibl.mdl");
		self.netname = "Ring of Shadows";
		self.items = IT_INVISIBILITY;
		self.items2 = 0;
//		if(norandom == 1)
//			self.classname = "item_artifact_invisibility";
	}
	else
	{
		self.noise = "items/damage.wav";
		setmodel (self, "progs/quaddama.mdl");
		self.netname = "Quad Damage";
		self.items = IT_QUAD;
		self.items2 = 0;
//		if(norandom == 1)
//			self.classname = "item_artifact_super_damage";
	}
};

/*QUAKED item_random_powerup (0 .5 .8) (-16 -16 -24) (16 16 32)
The Random Box!

Contains a random powerup.
*/
void() item_random_powerup =
{
	if (!deathmatch)
	{
		remove(self);
		return;
	}

	// Precache the lot of it....
	precache_model ("progs/shield.mdl");
	precache_model ("progs/p_shield.mdl");
	precache_model ("progs/beltup.mdl");
	precache_model ("progs/invulner.mdl");
	precache_model ("progs/invisibl.mdl");
	precache_model ("progs/quaddama.mdl");

	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");


	precache_sound ("belt/pickup.wav");
	precache_sound ("belt/use.wav");
	precache_sound ("belt/fadeout.wav");
	precache_sound ("shield/pickup.wav");
	precache_sound ("shield/hit.wav");
	precache_sound ("shield/fadeout.wav");

	random_pick_type();
	StartItem ();
};

void() random_regen =
{
	random_pick_type();
	SUB_regen();
};
