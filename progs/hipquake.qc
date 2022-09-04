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

/* Earthquake QuickC program
   By Jim Dose'  9/13/96
*/
//JIM
float       earthquake;
float quakeactive;

void() StopEarthQuake =
   {
   earthquake = 0;
   };

void( float value ) EarthQuakeTime =
   {
   value = value + time;
   if ( value > earthquake )
      {
      earthquake = value;
      }
   };

void() earthquake_prethink =
   {
//   if ( lastearthquake )
//      {
//      self.view_ofs_z = self.savedz;
//      lastearthquake = 0;
//      }
   };

void() earthquake_postthink =
	{
	if ( earthquake > time )
		{
      if (quakeactive == 0)
         {
         sound (self, CHAN_VOICE, "misc/quake.wav", 1, ATTN_NONE);
         quakeactive = 1;
         }
//      lastearthquake = 1;
//      self.savedz = self.view_ofs_z;
		if ( self.flags & FL_ONGROUND )
			{
//         self.view_ofs_z = self.view_ofs_z - 5 + random() * 10;
         self.velocity = self.velocity + (random() * '0 0 150');
         }
		}
   else
      {
      if (quakeactive == 1)
         {
         sound (self, CHAN_VOICE, "misc/quakeend.wav", 1, ATTN_NONE);
         quakeactive = 0;
         }
      }
	};

void() earthquake_use =
	{
	EarthQuakeTime( self.dmg );
	};

/*QUAKED func_earthquake (0 0 0.5) (0 0 0) (32 32 32)
Causes an earthquake.  Triggers targets.

"dmg" is the duration of the earthquake.  Default is 0.8 seconds.
*/

void() func_earthquake =
	{
   quakeactive = 0;
   precache_sound("misc/quake.wav");
   precache_sound("misc/quakeend.wav");
   self.classname = "earthquake";
	self.use = earthquake_use;
	self.think = SUB_Null;
	if ( !self.dmg )
	   {
	   self.dmg = 0.8;
	   }
	};
