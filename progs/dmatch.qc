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

// dmatch - general deathmatch additions

// =======================================
// =======================================
void() tag_token_respawn =
{
	local entity spawnPoint;
	local entity tagToken;

	tagToken = find (world, classname, "dmatch_tag_token");
	if(tagToken == world)
		return;

	spawnPoint = SelectSpawnPoint();
	setorigin(tagToken, spawnPoint.origin);
	tag_token_owner = world;
	tagToken.solid = SOLID_TRIGGER;
	tagToken.touch = tag_token_touch;
	tagToken.think = SUB_Null;
	tagToken.owner = world;
	tagToken.tag_frags = 0;
	droptofloor();
};

// =======================================
// =======================================
void() tag_token_fall =
{
	self.tag_frags = 0;
	self.think = tag_token_respawn;
	self.nextthink = time + 30;
	droptofloor();
};

// =======================================
// =======================================
void() tag_token_drop =
{
	local entity tagToken;

	tagToken = find (world, classname, "dmatch_tag_token");
	if(tagToken == world)
		return;

	bprint("$qc_lost_token", tagToken.owner.netname);
	tagToken.tag_frags = 0;
	tagToken.solid = SOLID_TRIGGER;
	tagToken.owner = world;
	tagToken.touch = tag_token_touch;
	tagToken.think = tag_token_fall;
	tagToken.nextthink = time + 0.1;
};

// =======================================
// =======================================
void() tag_token_think =
{
	if ( self.owner.health > 0)
	{
		if ( self.tag_message_time < time )
		{
			bprint("$qc_has_token", self.owner.netname);
			self.tag_message_time = time + 30;
		}

		setorigin ( self, self.owner.origin + '0 0 48');
		self.think = tag_token_think;
		self.nextthink = time + 0.1;
	}
	else
	{
		tag_token_drop();
	}
};

// =======================================
// =======================================
void() tag_token_touch =
{
	if (other.classname != "player")
		return;

	tag_token_owner = other;
	self.tag_frags = 0;

	sound ( self, CHAN_AUTO, "runes/end1.wav", 1, ATTN_NORM);

	bprint("$qc_got_token", other.netname);
	self.tag_message_time = time + 30;

	self.owner = other;
	self.solid = SOLID_NOT;
	self.touch = SUB_Null;
	self.think = tag_token_think;
	self.nextthink = time + 0.1;
};

/*QUAKED dmatch_tag_token (1 1 0) (-16 -16 -16) (16 16 16)
The deathmatch tag token.
*/
void() dmatch_tag_token =
{
	if ( cvar("teamplay") != TEAM_DMATCH_TAG )
	{
		remove (self);
		return;
	}

	precache_model ("progs/sphere.mdl");
	precache_sound ("runes/end1.wav");
	setmodel(self, "progs/sphere.mdl");
	self.skin = 1;
	setsize (self, '-16 -16 -16', '16 16 16');
	self.touch = tag_token_touch;
	self.effects = self.effects | EF_DIMLIGHT;
	StartItem();
};

// =======================================
// =======================================
void(entity targ, entity attacker) dmatch_score =
{
	local entity tagToken;

	if ( teamplay == TEAM_DMATCH_TAG )
	{
		tagToken = find (world, classname, "dmatch_tag_token");
		if(tagToken == world)
		{
			attacker.frags = attacker.frags + 1;
			return;
		}

		if ( attacker == tag_token_owner)
		{
			tagToken.tag_frags = tagToken.tag_frags + 1;
			attacker.frags = attacker.frags + 3;
			if ( tagToken.tag_frags == 5 )
			{
				sprint (attacker, "$qc_got_quad");
				attacker.items = attacker.items | IT_QUAD;
				stuffcmd (attacker, "bf\n");
				sound (attacker,CHAN_VOICE,"items/damage.wav", 1, ATTN_NORM);
				attacker.super_time = 1;
				attacker.super_damage_finished = time + 30;
			}
			else if (tagToken.tag_frags == 10)
			{
				bprint("$qc_lost_token", attacker.netname);
				tagToken.solid = SOLID_TRIGGER;
				tagToken.tag_frags = 0;
				tagToken.touch = tag_token_touch;
				tag_token_respawn();
			}
		}
		else
		{
			if (targ == tag_token_owner)
			{
				attacker.frags = attacker.frags + 5;
				sound ( self, CHAN_AUTO, "runes/end1.wav", 1, ATTN_NORM);
				if (attacker.classname == "player")
				{
					tag_token_owner = attacker;

					tagToken.tag_frags = 0;
					tagToken.tag_message_time = time + 0.5;
					tagToken.owner = attacker;
					tagToken.solid = SOLID_NOT;
					tagToken.touch = SUB_Null;
					tagToken.think = tag_token_think;
					tagToken.nextthink = time + 0.1;
				}
			}
			else
				attacker.frags = attacker.frags + 1;
		}
	}
};
