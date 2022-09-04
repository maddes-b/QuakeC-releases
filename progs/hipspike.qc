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
==============================================================================

spike mine

==============================================================================
*/

$cd id1/models/demon3
$scale	0.8
$origin 0 0 24
$base base
$skin base

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8

$frame run1 run2 run3 run4 run5 run6

$frame leap1 leap2 leap3 leap4 leap5 leap6 leap7 leap8 leap9 leap10
$frame leap11 leap12

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame death1 death2 death3 death4 death5 death6 death7 death8 death9

$frame attacka1 attacka2 attacka3 attacka4 attacka5 attacka6 attacka7 attacka8
$frame attacka9 attacka10 attacka11 attacka12 attacka13 attacka14 attacka15

void() monster_spikemine =
{
   if (deathmatch)
	{
		remove(self);
		return;
	}
   precache_model ("progs/demon.mdl");
   precache_model ("progs/h_demon.mdl");

   precache_sound ("demon/ddeath.wav");
   precache_sound ("demon/dhit2.wav");
   precache_sound ("demon/djump.wav");
   precache_sound ("demon/dpain1.wav");
   precache_sound ("demon/idle1.wav");
   precache_sound ("demon/sight2.wav");

   self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

   setmodel (self, "progs/demon.mdl");

   setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);

/*
   self.th_stand = gremlin_stand1;
   self.th_walk = gremlin_walk1;
   self.th_run = gremlin_run1;
   self.th_die = gremlin_die;
   self.th_melee = Gremlin_MeleeAttack;     // one of two attacks
   self.th_missile = Gremlin_MissileAttack; // check for random jump or firing of weapon
   self.th_pain = gremlin_pain;
   walkmonster_start();
*/
};
