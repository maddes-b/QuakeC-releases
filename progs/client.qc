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

// updated to quake v1.06 10/8/96

// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void() player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;

void(entity targ, entity attacker) dmatch_score;

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



void() SetChangeParms =
{
	if (self.health <= 0 || deathmatch)
	{
		SetNewParms ();
		parm14 = self.steam;	// Save the current team of the player
		return;
	}

// remove items
	self.items = self.items - (self.items & (IT_KEY1 | IT_KEY2 |
								IT_INVULNERABILITY | IT_SUIT |
								IT_QUAD | IT_INVISIBILITY) );

	self.items2 = self.items2 - (self.items2 &
					(IT2_ANTIGRAV | IT2_SHIELD | IT2_SUPERHEALTH));
	self.gravity = 1.0;

// cap super health
	if (self.health > self.max_health)
		self.health = self.max_health;

	if (self.health < self.max_health / 2)
		self.health = self.max_health / 2;

	teamplay = cvar ( "teamplay" );
	if (teamplay >= TEAM_CTF)	// don't carry items between levels in CTF
		SetNewParms();
	else
	{
		parm1 = self.items;
		parm2 = self.health;
		parm3 = self.armorvalue;
		if (self.ammo_shells1 < 25)
			parm4 = 25;
		else
			parm4 = self.ammo_shells1;
		parm5 = self.ammo_nails1;
		parm6 = self.ammo_rockets1;
		parm7 = self.ammo_cells1;
		parm8 = self.weapon;
		parm9 = self.armortype * 100;
		parm10 = self.items2;
		parm11 = self.ammo_lava_nails;
		parm12 = self.ammo_multi_rockets;
		parm13 = self.ammo_plasma;
	}
	parm14 = self.steam; // save team setting
};

void() SetNewParms =
{
//ZOID--
	if (deathmatch && teamplay >= TEAM_CTF) {
		parm1 = IT_SHOTGUN | IT_AXE | IT_GRAPPLE;
		parm10 = IT2_ARMOR1;
		parm3 = 50;
		parm9 = 30;
	} else {
		parm1 = IT_SHOTGUN | IT_AXE;
		parm3 = 0;
		parm9 = 0;
		parm10 = 0;
	}
//--ZOID
	if (skill == 3 && !deathmatch)
		parm2 = 50;
	else
		parm2 = 100;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 1;
	parm11 = 0;
	parm12 = 0;
	parm13 = 0;
//ZOID--
	parm14 = -1; 		// CTF: reset current team selection
//--ZOID
};

void() DecodeLevelParms =
{
	if (serverflags)
	{
		if (world.model == "maps/start.bsp")
			SetNewParms ();		// take away all stuff on starting new episode
	}
	if (world.model == "maps/r2m1.bsp" && !deathmatch)
		SetNewParms ();
	// PGM - 01/29 change to have level 8 reset all your stuff.

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells1 = parm4;
	self.ammo_nails1 = parm5;
	self.ammo_rockets1 = parm6;
	self.ammo_cells1 = parm7;
	// cute bug, if grapple was selected, it still will be on level change
	if (parm8 == IT_GRAPPLE && teamplay < TEAM_CTF)
		self.weapon = IT_AXE;
	else
		self.weapon = parm8;
	self.armortype = parm9 * 0.01;
	self.items2 = parm10;
	self.ammo_lava_nails = parm11;
	self.ammo_multi_rockets = parm12;
	self.ammo_plasma = parm13;
//ZOID--
	if (TeamColorIsLegal(parm14)) {
		self.steam = parm14;
		TeamSetSkin();
	}
//--ZOID
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

		else if (world.model == "maps/r1m7.bsp")
		{
			WriteByte (MSG_ALL, SVC_FINALE);
//-------------------------------------   end here
			WriteString (MSG_ALL, "$qc_finale_r1");
			return;
		}

		if (coop && mapname == "r2m8" )
		{
			localcmd("menu_credits\n");
			localcmd("disconnect\n");
			return;
		}
		else
		{
			GotoNextMap();
		}
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

	if (coop)
	{
		if ( mapname == "r2m8" )
		{
			localcmd("menu_credits\n");
			localcmd("disconnect\n");
			return;
		}
	}
	else
	{
		GotoNextMap();
	}
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
		other = find (other, classname, "player");
	}

	WriteByte (MSG_ALL, SVC_INTERMISSION);

	if (campaign && world.model == "maps/r1m7.bsp")
	{
		WriteByte (MSG_ALL, SVC_ACHIEVEMENT);
		WriteString(MSG_ALL, "ACH_COMPLETE_R1M7");
	}
};


void() changelevel_touch =
{
	local entity	pos;

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

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("chagnelevel trigger doesn't have map");

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
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn
		PutClientInServer ();
		// set the skin correctly.
		TeamSetSkin();
	}
	else
	{	// restart the entire server
		cvar_set("campaign", ftos(campaign));
		localcmd ("restart\n");
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
	local entity	vSphere;

// ZOID--
	if (self.suicide_count > 3)
	{
		sprint(self, "$qc_suicided_too_much");
		return;
	}
    TeamDropFlagOfPlayer(self);
	self.suicide_count = self.suicide_count + 1;
// --ZOID

	if ( tag_token_owner == self)
	{
		self.health = 0;
		self.solid = SOLID_NOT;
		tag_token_drop();
	}

	if ( self.items2 & IT2_V_SPHERE)
	{
		vSphere = find ( world, classname, "Vengeance");
		while (vSphere)
		{
			if ( vSphere.owner == self )
			{
				remove (vSphere);
			}
			vSphere = find(vSphere, classname, "Vengeance");
		}
	}

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
entity() SelectSpawnPointRogue =
{
	local	entity	spot;
	local	entity 	thing;
	local	float	pcount;
//ZOID--
	local	entity	startspot;
	local	float	t;
//--ZOID

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch)
	{
		startspot = spot = lastspawn;
		t = 0;
		if (!self.ctf_killed && teamplay >= TEAM_CTF)
		{
			if (self.steam == TEAM1)
			{
				startspot = spot = team1_lastspawn;
				t = TEAM1;
			}
			else if (self.steam == TEAM2)
			{
				startspot = spot = team2_lastspawn;
				t = TEAM2;
			}
		}

		while (1)
		{
			if (t == TEAM1)
				spot = find(spot, classname, "info_player_team1");
			else if (t == TEAM2)
				spot = find(spot, classname, "info_player_team2");
			else
				spot = find(spot, classname, "info_player_deathmatch");

			if (spot != world)
			{
				if (spot == startspot)
					return startspot;
				pcount = 0;
				thing = findradius(spot.origin, 32);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					if (t == TEAM1)
						team1_lastspawn = spot;
					else if (t == TEAM2)
						team2_lastspawn = spot;
					else
						lastspawn = spot;
					return spot;
				}
			}
			else
				t = 0;
			// pgm fix for ctf in levels w/o ctf support
		}
	}

	if (serverflags)
	{	// return with a rune to start
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}

	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");

	return spot;
};

entity SelectSpawnPointEX(float forceSpawn) {
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

entity SelectSpawnPoint(float forceSpawn) {
	// use the original rogue spawn logic in tctf
	if (teamplay >= TEAM_CTF) {
		return SelectSpawnPointRogue();
	} else {
		return SelectSpawnPointEX(forceSpawn);
	}
}

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;

void() player_touch;

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

	self.shield_finished = 0;
	self.antigrav_finished = 0;

//ZOID--
	self.ctf_lastreturnedflag = -10;
	self.ctf_lastfraggedcarrier = -10;
	self.ctf_flagsince = -10;
	self.ctf_lasthurtcarrier = -10;
//--ZOID

	if ( coop ) {
		self.team = TEAM_HUMANS;
	}

	DecodeLevelParms ();

	// spawn selection must be after DecodeLevelParms because of team stuff
	spot = SelectSpawnPoint ();

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;

//	spot = SelectSpawnPoint ();

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

	self.touch = player_touch;

// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	player_stand1 ();

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	//Grapple stuff
	self.on_hook = FALSE;
	self.hook_out = FALSE;

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
	SpawnRunes();
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

	if (mapname == "start")
	{
/*
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
*/
		// PGM 03/02/97 - make it always go to rogue level1 when in our progs
		mapname = "r1m1";
		o = spawn();
		o.map = mapname;
	}
	else
	{
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		// go back to start if no trigger_changelevel
		if (!o)
		{
			mapname = "start";
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

//ZOID--
	// update team scores?
	TeamCheckUpdate();
//--ZOID
};

//============================================================================

void() PlayerDeathThink =
{
	local entity	old_self;
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
	local vector start, end;

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

// play swiming sound
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
//dprint (ftos(self.waterlevel));
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
	makevectors (self.angles);
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
	local	float	mspeed, aspeed;
	local	float	r;

	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	if (earthquake_active)
	{
		if ( self.flags & FL_ONGROUND )
		{
			self.velocity_x = self.velocity_x +
								(random() * earthquake_intensity * 2) -
								earthquake_intensity;
			self.velocity_y = self.velocity_y +
								(random() * earthquake_intensity * 2) -
								earthquake_intensity;
			self.velocity_z = self.velocity_z +
								(random() * earthquake_intensity * 2) -
								earthquake_intensity;
		}
	}

	makevectors (self.v_angle);		// is this still used

//ZOID--
	// TeamCheckLock performs all necessary teamlock checking, and performs all
	// actions needed.
	TeamCheckLock();
//--ZOID

	CheckMOTD();
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

	if (self.items2 & IT2_ANTIGRAV)
	{
		if ( time > self.AGping )
		{
			sound ( self, CHAN_AUTO, "belt/use.wav", 0.4, ATTN_NORM);
			self. AGping = time + 3;
			if(self. AGping >= (self.antigrav_finished - 3))
				self. AGping = self.antigrav_finished + 3;
		}
	}

	RuneApplyElder(self); // regeneration rune

	// Track the grapple
	if (self.hook_out)
		GrappleService();
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

	if(self.shield_finished)
	{
		if ( self.shield_finished < time + 3)
		{
			if (self.shield_time == 1)
			{
				sprint (self, "$qc_shield_failing");
				sound (self, CHAN_AUTO, "shield/fadeout.wav", 1, ATTN_NORM);
				self.shield_time = 0;
			}
			if (self.shield_time < time)
			{
				self.shield_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if ( self.shield_finished < time)
		{
			sprint (self, "$qc_shield_lost");
			self.shield_finished = 0;
			self.items2 = self.items2 - IT2_SHIELD;
		}
	}

	if(self.antigrav_finished)
	{
		if ( self.antigrav_finished < time + 3)
		{
			if (self.antigrav_time == 1)
			{
				sprint (self, "$qc_antigrav_failing");
				self.antigrav_time = 0;
				sound (self, CHAN_AUTO, "belt/fadeout.wav", 1, ATTN_NORM);
			}
			if (self.antigrav_time < time)
			{
				self.antigrav_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if ( self.antigrav_finished < time)
		{
			sprint (self, "$qc_antigrav_lost");
			self.antigrav_finished = 0;
			self.items2 = self.items2 - IT2_ANTIGRAV;
			self.gravity = 1.0;
		}
	}
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() xpackEnding;

void() PlayerPostThink =
{
	local	float	mspeed, aspeed;
	local	float	r;

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
	if (self.deadflag)
		return;

	if (cutscene_running)
	{
		xpackEnding();
	}

// do weapon stuff

	W_WeaponFrame ();

// check to see if player landed and play landing sound
	if ((self.jump_flag < -300) &&
			(self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5);
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			self.deathtype = "falling";
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	CheckPowerups ();
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

//ZOID--
	self.suicide_count = 0;
	self.ctf_killed = 0;

	SetMOTD();

 	// If this is our first connection, parm14 is < 0
 	// Set lastteam negative.
 	if (parm14 < 0 && teamplay > 0)
	{
		if (cvar("gamecfg") & GAMECFG_USE_COLOR)
			self.steam = self.team; // accept joining players color if legal
		else
			self.steam = -50; // always reassign
		TeamCheckLock();
	}
//--ZOID

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

	sphere_remove(self);
	if ( tag_token_owner == self)
		tag_token_drop();

//ZOID--
    TeamDropFlagOfPlayer(self);
	self.steam = -50;
	self.team = 0;
//--ZOID

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
	local	string deathstring, deathstring2;
	rnum = random();

	if (targ.classname == "player")
	{
// ZOID--
		TeamResetCarrier(targ);
// --ZOID

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
				else if (rnum < 0.50)
					bprint("$qc_suicide_bored", targ.netname);

//ZOID--
//gibbed for changing teams
				else if (teamplay && (targ.team != targ.steam))
				{
					if (cvar("gamecfg") & GAMECFG_ALLOW_CHG)
						bprint("$qc_changed_teams", targ.netname);
					else
						bprint("$qc_tried_change_teams", targ.netname);
				}
//--ZOID

				else
					bprint("$qc_suicide_loaded", targ.netname);

				return;
			}
			else if ( (teamplay == 2) && (targ.team > 0)&&(targ.team == attacker.team) )
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
				if (teamplay == TEAM_DMATCH_TAG)
					dmatch_score (targ, attacker);
				else
				{
					attacker.frags = attacker.frags + 1;
//ZOID--
					TeamAssists(targ, attacker);
//--ZOID
				}

				rnum = attacker.weapon;
				if (rnum == IT_AXE)
				{
					bprint("$qc_death_ax", targ.netname, attacker.netname);
					return;
				}
//ZOID--
				if (rnum == IT_GRAPPLE)
				{
					bprint("$qc_death_grappled", targ.netname, attacker.netname);
					return;
				}
//--ZOID
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

				if (rnum == IT_LAVA_NAILGUN || rnum == IT_LAVA_SUPER_NAILGUN)
				{
					bprint("$qc_death_burned", targ.netname, attacker.netname);
					return;
				}
				else if (rnum == IT_PLASMA_GUN)
				{
					bprint("$qc_death_fused", targ.netname, attacker.netname);
					return;
				}
				else if (rnum == IT_MULTI_GRENADE || rnum == IT_MULTI_ROCKET)
				{
					bprint("$qc_death_blasted", targ.netname, attacker.netname);
					return;
				}
			}
			return;
		}
		else
		{
			targ.frags = targ.frags - 1;

			// killed by a montser?
			if (attacker.flags & FL_MONSTER)
			{
				if (attacker.classname == "monster_army")
					bprint ("$qc_ks_grunt", targ.netname);
				if (attacker.classname == "monster_demon1")
					bprint ("$qc_ks_fiend", targ.netname);
				if (attacker.classname == "monster_dog")
					bprint ("$qc_ks_rottweiler", targ.netname);
				if (attacker.classname == "monster_dragon")
					bprint ("$qc_ks_dragon1", targ.netname);
				if (attacker.classname == "monster_dragon_dead")
					bprint ("$qc_ks_dragon2", targ.netname);
				if (attacker.classname == "monster_enforcer")
					bprint ("$qc_ks_enforcer", targ.netname);
				if (attacker.classname == "monster_fish")
					bprint ("$qc_ks_rotfish", targ.netname);
				if (attacker.classname == "monster_hell_knight")
					bprint ("$qc_ks_deathknight", targ.netname);
				if (attacker.classname == "monster_knight")
					bprint ("$qc_ks_knight", targ.netname);
				if (attacker.classname == "monster_ogre")
					bprint ("$qc_ks_ogre", targ.netname);
				if (attacker.classname == "monster_oldone")
					bprint ("$qc_ks_shub", targ.netname);
				if (attacker.classname == "monster_shalrath")
					bprint ("$qc_ks_vore", targ.netname);
				if (attacker.classname == "monster_shambler")
					bprint ("$qc_ks_shambler", targ.netname);
				if (attacker.classname == "monster_tarbaby")
					bprint ("$qc_ks_spawn", targ.netname);
				if (attacker.classname == "monster_vomit")
					bprint ("$qc_ks_vomitus", targ.netname);
				if (attacker.classname == "monster_wizard")
					bprint ("$qc_ks_scrag", targ.netname);
				if (attacker.classname == "monster_zombie")
					bprint ("$qc_ks_zombie", targ.netname);

				if (attacker.classname == "monster_eel")
					bprint ("$qc_ks_eel", targ.netname);
				if (attacker.classname == "monster_wrath")
					bprint ("$qc_ks_wrath", targ.netname);
				if (attacker.classname == "monster_super_wrath")
					bprint ("$qc_ks_overlord", targ.netname);
				if (attacker.classname == "monster_sword")
					bprint ("$qc_ks_swordsman", targ.netname);
				if (attacker.classname == "monster_lava_man")
					bprint ("$qc_ks_hephaestus", targ.netname);
				if (attacker.classname == "monster_morph")
					bprint ("$qc_ks_guardian", targ.netname);
				if (attacker.classname == "monster_mummy")
					bprint ("$qc_ks_mummy", targ.netname);

				return;
			}

			// tricks and traps
			if (attacker.classname == "explo_box")
			{
				bprint ("$qc_ks_blew_up", targ.netname);
				return;
			}
			if (attacker.solid == SOLID_BSP && attacker != world)
			{
				bprint ("$qc_death_squish", targ.netname);
				return;
			}
			if (attacker.classname == "trap_shooter" || attacker.classname == "trap_spikeshooter")
			{
				bprint ("$qc_ks_spiked", targ.netname);
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint ("$qc_ks_lavaball", targ.netname);
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint ("$qc_ks_tried_leave", targ.netname);
				return;
			}

			if (attacker.classname == "ltrail_start" ||
				attacker.classname == "ltrail_relay")
			{
				bprint ("$qc_ks_rode_lightning", targ.netname);
				return;
			}
			if (attacker.classname == "pendulum")
			{
				bprint ("$qc_ks_cleaved", targ.netname);
				return;
			}
			if (attacker.classname == "buzzsaw")
			{
				bprint ("$qc_ks_sliced", targ.netname);
				return;
			}
			if (attacker.classname == "plasma")
			{
				bprint ( "$qc_ks_plasma", targ.netname);
				return;
			}
			if (attacker.classname == "Vengeance")
			{
				// vengeance sphere doesn't count as a negative frag
				targ.frags = targ.frags + 1;
				bprint ( "$qc_death_vengeance", targ.netname);
				return;
			}
			if (attacker.classname == "power_shield")
			{
				// shield attacks should count for frags too..
				// shield death doesn't count as a negative frag
				targ.frags = targ.frags + 1;
				attacker.owner.frags = attacker.owner.frags + 1;
				TeamAssists(targ, attacker.owner);			//PGM

				bprint("$qc_death_smashed", targ.netname, attacker.owner.netname);
				return;
			}

			// in-water deaths
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
