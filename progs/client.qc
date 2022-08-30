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

// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void(entity attacker, float damage) player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;

float	modelindex_eyes, modelindex_player;

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float	intermission_running;
float	intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};



float reset_flag;

void() SetChangeParms =
{
    if(reset_flag)
    {
        setspawnparms(self);
        return;
	}

	if (self.health <= 0 || deathmatch)
	{
		SetNewParms ();
		return;
	}

// remove items
	self.items = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );

// cap super health
	if (self.health > self.max_health)
		self.health = self.max_health;

	if (self.health < self.max_health / 2)
		self.health = self.max_health / 2;

	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.armorvalue;

	if (self.ammo_shells < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells;

	parm5 = self.ammo_nails;
	parm6 = self.ammo_rockets;
	parm7 = self.ammo_cells;
	parm8 = self.weapon;
	parm9 = self.armortype * 100;
};

void() SetNewParms =
{
	parm1 = IT_SHOTGUN | IT_AXE;
	if (skill == 3 && !deathmatch)
		parm2 = 50;
	else
		parm2 = 100;
	parm3 = 0;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 1;
	parm9 = 0;
};

void() DecodeLevelParms =
{
	if (serverflags)
	{
		if (world.model == "maps/start.bsp")
			SetNewParms ();		// take away all stuff on starting new episode
	}

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = parm8;
	self.armortype = parm9 * 0.01;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local	entity spot;
	local	float cyc;

	// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");

			if (!spot)
				spot = find (spot, classname, "info_intermission");

			cyc = cyc - 1;
		}

		return spot;
	}

	// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

	// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	objerror ("FindIntermission: no spot");
	return world;
};


string nextmap;
void() GotoNextMap =
{
	if (cvar("samelevel"))	// if samelevel is set, stay on same level
		changelevel (mapname);
	else
		changelevel (nextmap);
};


void() ExitIntermission =
{
	// skip any text in deathmatch
	if (deathmatch)
	{
		GotoNextMap ();
		return;
	}

	intermission_exittime = time + 1;
	intermission_running = intermission_running + 1;

//
// run some text if at the end of an episode
//
	if (intermission_running == 2)
	{
		if (world.model == "maps/e1m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			if (!cvar("registered"))
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "$qc_finale_e1_shareware");
			}
			else
			{
				WriteByte (MSG_ALL, SVC_FINALE);
				WriteString (MSG_ALL, "$qc_finale_e1");
			}

			return;
		}
		else if (world.model == "maps/e2m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "$qc_finale_e2");
			return;
		}
		else if (world.model == "maps/e3m6.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "$qc_finale_e3");
			return;
		}
		else if (world.model == "maps/e4m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_CDTRACK);
			WriteByte (MSG_ALL, 2);
			WriteByte (MSG_ALL, 3);

			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "$qc_finale_e4");
			return;
		}

		GotoNextMap();
	}

	if (intermission_running == 3)
	{
		if (!cvar("registered"))
		{	// shareware episode has been completed, go to sell screen
			WriteByte (MSG_ALL, SVC_SELLSCREEN);
			return;
		}

		if ( (serverflags&15) == 15)
		{
			WriteByte (MSG_ALL, SVC_FINALE);
			WriteString (MSG_ALL, "$qc_finale_all_runes");
			return;
		}

	}

	GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;

	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;

	// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);

	pos = FindIntermission ();

	other = find (world, classname, "player");

	while (other != world)
	{
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE;		// turn this way immediately
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		setorigin (other, pos.origin);

		if (skill == 3)
		{
			// [NDS] haleyjd: achieve if completed E1M1 Nightmare Tyson style (axe only)
			if (other.fired_weapon == 0 && world.model == "maps/e1m1.bsp")
			{
				msg_entity = other;
				WriteByte (MSG_ONE, SVC_ACHIEVEMENT);
				WriteString(MSG_ONE, "ACH_PACIFIST"); // emphasis on "fist", I guess.
			}

			// [NDS] haleyjd: achieve if completed E4M6 Nightmare without taking damage
			if (other.took_damage == 0 && world.model == "maps/e4m6.bsp")
			{
				msg_entity = other;
				WriteByte (MSG_ONE, SVC_ACHIEVEMENT);
				WriteString(MSG_ONE, "ACH_PAINLESS_MAZE"); // emphasis on "fist", I guess.
			}
		}

		other = find (other, classname, "player");
	}

	WriteByte (MSG_ALL, SVC_INTERMISSION);

	if (campaign && world.model == "maps/e1m7.bsp")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_COMPLETE_E1M7");
	}
	else if (campaign && world.model == "maps/e2m6.bsp")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_COMPLETE_E2M6");
	}
	else if (campaign && world.model == "maps/e3m6.bsp")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_COMPLETE_E3M6");
	}
	else if (campaign && world.model == "maps/e4m7.bsp")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_COMPLETE_E4M7");
	}

	if (world.model == "maps/e1m4.bsp" && nextmap == "e1m8")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_FIND_E1M8");
	}
	else if (world.model == "maps/e2m3.bsp" && nextmap == "e2m7")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_FIND_E2M7");
	}
	else if (world.model == "maps/e3m4.bsp" && nextmap == "e3m7")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_FIND_E3M7");
	}
	else if (world.model == "maps/e4m5.bsp" && nextmap == "e4m8")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_FIND_E4M8");
	}

};


void() changelevel_touch =
{
	if (other.classname != "player")
		return;

	if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
	{
		T_Damage (other, self, self, 50000);
		return;
	}

	if (coop || deathmatch)
	{
		bprint("$qc_exited", other.netname);

	}

	nextmap = self.map;

	SUB_UseTargets ();

	if ( (self.spawnflags & 1) && (deathmatch == 0) )
	{	// NO_INTERMISSION
		GotoNextMap();
		return;
	}

	self.touch = SUB_Null;

	// we can't move people right now, because touch functions are called
	// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*
QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.
Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("changelevel trigger doesn't have map");

	self.netname = "changelevel";
	self.killstring = "$qc_ks_tried_leave";

	InitTrigger ();
	self.touch = changelevel_touch;
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQueue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQueue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn
		PutClientInServer ();
	}
	else
	{
		// restart the entire server
//		cvar_set("campaign", ftos(campaign));
//		localcmd ("restart\n");

		// put serverflags back to map's initial setting
		serverflags = startingserverflags;
		// request a reset to the parms
		reset_flag = TRUE;
		// "change" to the same level
		localcmd ("changelevel ");
		localcmd(mapname);
		localcmd("\n");
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
	bprint("$qc_suicides", self.netname);
	set_suicide_frame ();
	self.modelindex = modelindex_player;
	self.frags = self.frags - 2;	// extra penalty
	respawn ();
};

/*
============
PlayerVisibleToSpawnPoint

Returns true if player can see this point
============
*/
float PlayerVisibleToSpawnPoint( entity point ) {
	local vector spot1, spot2;
	local entity player = find( world, classname, "player" );
	while ( player ) {
		if ( player.health > 0 ) {
			spot1 = point.origin + player.view_ofs;
			spot2 = player.origin + player.view_ofs;

			traceline( spot1, spot2, TRUE, point );
			if ( trace_fraction >= 1.0f ) {
				return TRUE;
			}
		}

		player = find( player, classname, "player" );
	}

	return FALSE;
}

float IDEAL_DIST_FROM_DM_SPAWN_POINT = 384;
float MIN_DIST_FROM_DM_SPAWN_POINT = 84;

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity SelectSpawnPoint(float forceSpawn) {
	local   entity spot, thing;
	local   float   numspots, totalspots;
	local   float   pcount;
	local entity spots;

	numspots = 0;
	totalspots = 0;

	// testinfo_player_start is only found in regioned levels
	spot = find( world, classname, "testplayerstart" );
	if ( spot )
		return spot;

	// choose a info_player_deathmatch point
	if ( coop ) {
		lastspawn = find( lastspawn, classname, "info_player_coop" );

		if ( lastspawn == world ) {
			lastspawn = find( lastspawn, classname, "info_player_start" );
		}

		if ( lastspawn != world ) {
			return lastspawn;
		}
	} else if ( deathmatch ) {

		// find all spots that don't have visible players nearby
		spots = world;
		spot = find( world, classname, "info_player_deathmatch" );

		while( spot ) {
			totalspots = totalspots + 1;

			thing = findradius( spot.origin, IDEAL_DIST_FROM_DM_SPAWN_POINT );
			pcount = 0;

			while( thing ) {
				if ( thing.classname == "player" && thing.health > 0 ) {
					pcount = pcount + 1;
				}

				thing = thing.chain;
			}

			if ( pcount == 0 ) {
				if ( PlayerVisibleToSpawnPoint( spot ) ) {
					pcount = pcount + 1;
				}
			}

			if ( pcount == 0 ) { // good spot!
				spot.goalentity = spots;
				spots = spot;
				numspots = numspots + 1;
			}

			// Get the next spot in the chain
			spot = find( spot, classname, "info_player_deathmatch" );
		}

		totalspots = totalspots - 1;

		// on small maps with few spawn points, our "ideal" spawn conditions may not be possible to meet
		// so fallback to just trying to pick a point without a player on top of it, so we don't start
		// a spawn frag loop
		if ( numspots == 0 ) {
			spot = find( world, classname, "info_player_deathmatch" );

			while( spot ) {
				thing = findradius( spot.origin, MIN_DIST_FROM_DM_SPAWN_POINT );
				pcount = 0;

				while( thing ) {
					if ( thing.classname == "player" && thing.health > 0 ) {
						pcount = pcount + 1;
					}

					thing = thing.chain;
				}

				if ( pcount == 0 ) { // good spot!
					spot.goalentity = spots;
					spots = spot;
					numspots = numspots + 1;
				}

				// Get the next spot in the chain
				spot = find( spot, classname, "info_player_deathmatch" );
			}
		}

		// uncomment to force a deferred spawn
		// if (forceSpawn == FALSE) return world;

		if ( !numspots ) {
			if (forceSpawn == FALSE) {
				return world;
			}

			// no spots available so just pick one at random
			totalspots = rint( ( random() * totalspots ) );
			spot = find( world, classname, "info_player_deathmatch" );

			while( totalspots > 0 ) {
				totalspots = totalspots - 1;
				spot = find( spot, classname, "info_player_deathmatch" );
			}
			return spot;
		}

		// Generate a random number between 1 and numspots
		numspots = numspots - 1;

		numspots = rint( ( random() * numspots ) );

		spot = spots;
		while( numspots > 0 ) {
			spot = spot.goalentity;
			numspots = numspots - 1;
		}

		return spot;
	}

	if ( serverflags ) { // return with a rune to start
		spot = find( world, classname, "info_player_start2" );

		if ( spot ) {
			return spot;
		}
	}

	spot = find( world, classname, "info_player_start" );

	if ( !spot ) {
		error( "PutClientInServer: no info_player_start on level" );
	}

	return spot;
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;


void() PutClientInServer =
{
	local	entity spot;

	self.classname = "player";
	if (skill == 3 && !deathmatch)
		self.health = 50;
	else
		self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	if (skill == 3 && !deathmatch)
		self.max_health = 50;
	else
		self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	self.healthrot_nextcheck = 0;
	self.fired_weapon = 0; // [NDS] haleyjd
	self.took_damage = 0;  // [NDS] haleyjd
	self.team = TEAM_NONE;

	if ( coop ) {
		self.team = TEAM_HUMANS;
	}

	DecodeLevelParms ();

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
	// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;

	local float shouldTelefrag;

	if (self.spawn_deferred > 0 && time >= self.spawn_deferred) {
		dprint("forcing telefrag on this spawn\n");
		shouldTelefrag = TRUE;
	} else {
		shouldTelefrag = FALSE;
	}
	spot = SelectSpawnPoint(shouldTelefrag);
	if (spot == world) {
		self.takedamage = DAMAGE_NO;
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_NONE;
		self.deadflag = DEAD_DEAD;
		setmodel(self, "");
		self.view_ofs = '0 0 1'; // not 0 because PlayerPreThink would return out
		self.velocity = '0 0 0';

		if (self.spawn_deferred == 0) {
			dprint("no spawns available! deferring\n");
			self.spawn_deferred = time + 5;
		}

		spot = FindIntermission();
		self.angles = self.v_angle = spot.mangle;
		self.fixangle = TRUE;
		self.origin = spot.origin;
		self.weaponmodel = "";
		self.weaponframe = 0;
		self.weapon = 0;

		return;
	}

	self.spawn_deferred = 0;

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

	// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';
	self.velocity = '0 0 0';	// 1998-07-21 Player moves after respawn fix by Xian

	player_stand1 ();

	if (deathmatch || coop)
	{
		makevectorsfixed(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	spawn_tdeath (self.origin, self);

	stuffcmd(self, "-attack\n"); // prevent shooting after respawning
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
*/
void() NextLevel =
{
	local entity o;

	if (nextmap != string_null)
		return; // already done

	if (mapname == "start")
	{
		if (!cvar("registered"))
		{
			mapname = "e1m1";
		}
		else if (!(serverflags & 1))
		{
			mapname = "e1m1";
			serverflags = serverflags | 1;
		}
		else if (!(serverflags & 2))
		{
			mapname = "e2m1";
			serverflags = serverflags | 2;
		}
		else if (!(serverflags & 4))
		{
			mapname = "e3m1";
			serverflags = serverflags | 4;
		}
		else if (!(serverflags & 8))
		{
			mapname = "e4m1";
			serverflags = serverflags - 7;
		}

		o = spawn();
		o.map = mapname;
	}
	else
	{
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		if (!o || mapname == "start")
		{       // go back to same map if no trigger_changelevel
			o = spawn();
			o.map = mapname;
		}
	}

	nextmap = o.map;
	gameover = TRUE;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
	local	float		timelimit;
	local	float		fraglimit;

	if (gameover)	// someone else quit the game already
		return;

	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");

	if (timelimit && time >= timelimit)
	{
		NextLevel ();
		return;
	}

	if (fraglimit && self.frags >= fraglimit)
	{
		NextLevel ();
		return;
	}
};

//============================================================================

void() PlayerDeathThink =
{
	local float		forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;

		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize(self.velocity);
	}

	if (self.spawn_deferred)
	{
		local entity spot;

		spot = SelectSpawnPoint(FALSE);
		//dprint("time {} >= self.spawn_deferred {}\n", ftos(time), ftos(self.spawn_deferred));
		if (spot != world || time >= self.spawn_deferred) {
			respawn();
		}

		return;
	}

	// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;

		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

	// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};


void() PlayerJump =
{
	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

		// play swimming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;

			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk

	self.button2 = 0;
	// player jumping sound
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};


/*
===========
WaterMove

============
*/
.float	dmgtime;

void() WaterMove =
{
	if (self.movetype == MOVETYPE_NOCLIP)
		return;

	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);

		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;

			if (self.dmg > 15)
				self.dmg = 10;

			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}

	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}

		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			T_Damage (self, world, world, 10*self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4*self.waterlevel);
		}
	}

	if ( !(self.flags & FL_INWATER) )
	{

		// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);

		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);

		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}

	if (! (self.flags & FL_WATERJUMP) )
		self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
};

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectorsfixed(self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);

	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);

		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	makevectors (self.v_angle);		// is this still used

	if (deathmatch || coop)
		CheckRules ();

	WaterMove ();

	if (self.waterlevel == 2)
		CheckWaterJump ();

	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}

	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	if (self.button2)
	{
		PlayerJump ();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;

	// teleporters can force a non-moving pause time
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	if(time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_AXE)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.health <= 0)
		return;

	// invisibility
	if (self.invisible_finished)
	{
		// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}


		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint(self, "$qc_ring_fade");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}

	// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
	}
	else
		self.modelindex = modelindex_player;	// don't use eyes

	// invincibility
	if (self.invincible_finished)
	{
	// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint(self, "$qc_protection_fade");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
		if (self.invincible_finished > time)
			self.effects = self.effects | EF_PENTALIGHT;
		else
			self.effects = self.effects - (self.effects & EF_PENTALIGHT);
	}

	// super damage
	if (self.super_damage_finished)
	{

		// sound and screen flash when items starts to run out
		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint(self, "$qc_quad_fade");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		if (self.super_damage_finished > time)
			self.effects = self.effects | EF_QUADLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_QUADLIGHT);
	}

	// suit
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

		// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint(self, "$qc_biosuit_fade");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}

};

/*
================
CheckHealthRot

Checks for taking off health points from a player
that recently used a Mega-Health.
================
*/
void CheckHealthRot() {
	if ( !( self.items & IT_SUPERHEALTH ) ) {
		return;
	}

	if ( self.healthrot_nextcheck > time ) {
		return;
	}

	if ( self.health > self.max_health ) {
		self.health = self.health - 1;
		self.healthrot_nextcheck = time + 1;
		return;
	}

	self.items = self.items - ( self.items & IT_SUPERHEALTH );
	self.healthrot_nextcheck = 0;
}

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
	if ( self.view_ofs == '0 0 0') {
		return;		// intermission or finale
	}

	if ( self.deadflag ) {
		return;
	}

	W_WeaponFrame (); // do weapon stuff

	// check to see if player landed and play landing sound
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5);
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			if (self.health <= 5)
				self.deathtype = "falling";
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	CheckPowerups();
	CheckHealthRot();
};

/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
	bprint("$qc_entered", self.netname);

	// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;

	// if the level end trigger has been activated, just return
	// since they aren't *really* leaving

	// let everyone else know
	bprint("$qc_left_game", self.netname, ftos(self.frags));

	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);

	self->effects = 0;
	set_suicide_frame ();
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{
	local	float rnum;

	// from GPL QW source
	local   float  attackerteam, targteam;

	attackerteam = attacker.team;
	targteam = targ.team;

	rnum = random();

	if (targ.classname == "player")
	{
		if (attacker.classname == "teledeath")
		{
			bprint("$qc_telefragged", targ.netname, attacker.owner.netname);

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint("$qc_satans_power", targ.netname);

			targ.frags = targ.frags - 1;
			return;
		}

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				// killed self
				attacker.frags = attacker.frags - 1;

				if (targ.weapon == 64 && targ.waterlevel > 1)
				{
					if (targ.watertype == CONTENT_SLIME)
						bprint("$qc_discharge_slime", targ.netname);

					else if (targ.watertype == CONTENT_LAVA)
						bprint("$qc_discharge_lava", targ.netname);

					else
						bprint("$qc_discharge_water", targ.netname);

					return;
				}
				if (targ.weapon == 16)
					bprint("$qc_suicide_pin", targ.netname);
				else if (rnum)
					bprint("$qc_suicide_bored", targ.netname);
				else
					bprint("$qc_suicide_loaded", targ.netname);
				return;
			}
			else if ( (teamplay == 2) && (targteam == attackerteam) &&
				(attackerteam != 0) )
			{
				if (rnum < 0.25)
					bprint("$qc_ff_teammate", attacker.netname);
				else if (rnum < 0.50)
					bprint("$qc_ff_glasses", attacker.netname);
				else if (rnum < 0.75)
					bprint("$qc_ff_otherteam", attacker.netname);
				else
					bprint("$qc_ff_friend", attacker.netname);

				attacker.frags = attacker.frags - 1;
				return;
			}
			else
			{
				attacker.frags = attacker.frags + 1;

				rnum = attacker.weapon;

				if (rnum == IT_AXE)
				{
					bprint("$qc_death_ax", targ.netname, attacker.netname);
					return;
				}

				if (rnum == IT_SHOTGUN)
				{
					bprint("$qc_death_sg", targ.netname, attacker.netname);
					return;
				}

				if (rnum == IT_SUPER_SHOTGUN)
				{
					bprint("$qc_death_dbl", targ.netname, attacker.netname);
					return;
				}

				if (rnum == IT_NAILGUN)
				{
					bprint("$qc_death_nail", targ.netname, attacker.netname);
					return;
				}

				if (rnum == IT_SUPER_NAILGUN)
				{
					bprint("$qc_death_sng", targ.netname, attacker.netname);
					return;
				}

				if (rnum == IT_GRENADE_LAUNCHER)
				{
					if (targ.health < -40)
					{
						bprint("$qc_death_gl1", targ.netname, attacker.netname);
						return;
					}
					else
					{
						bprint("$qc_death_gl2", targ.netname, attacker.netname);
						return;
					}
				}

				if (rnum == IT_ROCKET_LAUNCHER)
				{
					if (attacker.super_damage_finished > 0 && targ.health < -40)
					{
						rnum = random();

						if (rnum < 0.3)
						{
							bprint("$qc_death_rl_quad1", targ.netname, attacker.netname);
							return;
						}
						else if (rnum < 0.6)
						{
							bprint("$qc_death_rl_quad2", targ.netname, attacker.netname);
							return;
						}
						else
						{
							bprint("$qc_death_rl1", targ.netname, attacker.netname);
							return;
						}
					}
					else
					{
						if (targ.health < -40)
						{
							bprint("$qc_death_rl2", targ.netname, attacker.netname);
							return;
						}
						else
						{
							bprint("$qc_death_rl3", targ.netname, attacker.netname);
							return;
						}
					}
				}

				if (rnum == IT_LIGHTNING)
				{
					if (attacker.waterlevel > 1)
					{
						bprint("$qc_death_lg1", targ.netname, attacker.netname);
						if (attacker.invincible_finished)
						{
							msg_entity = attacker;
							WriteByte (MSG_ONE, SVC_ACHIEVEMENT);
							WriteString(MSG_ONE, "ACH_SURVIVE_DISCHARGE");
						}
					}
					else
						bprint("$qc_death_lg2", targ.netname, attacker.netname);

					return;
				}
			}
			return;
		}
		else
		{
			targ.frags = targ.frags - 1;		// killed self
			rnum = targ.watertype;

			if (rnum == -3)
			{
				if (random() < 0.5)
					bprint("$qc_death_drown1", targ.netname);
				else
					bprint("$qc_death_drown2", targ.netname);

				return;
			}
			else if (rnum == -4)
			{
				if (random() < 0.5)
					bprint("$qc_death_slime1", targ.netname);
				else
					bprint("$qc_death_slime2", targ.netname);

				return;
			}
			else if (rnum == -5)
			{
				if (targ.health < -15)
				{
					bprint("$qc_death_lava1", targ.netname);
					return;
				}

				if (random() < 0.5)
					bprint("$qc_death_lava2", targ.netname);
				else
					bprint("$qc_death_lava3", targ.netname);

				return;
			}

			if (attacker.solid == SOLID_BSP && attacker != world)
			{
				bprint("$qc_death_squish", targ.netname);
				return;
			}

			if(attacker.killstring)
			{
				bprint(attacker.killstring, targ.netname);
				return;
			}

			if (targ.deathtype == "falling")
			{
				targ.deathtype = string_null;
				bprint("$qc_death_fall", targ.netname);
				return;
			}

			bprint("$qc_death_died", targ.netname);
		}
	}
};
