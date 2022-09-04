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

/* Clock QuickC program
   By Jim Dose'  11/25/96

*/

void() clock_setpos =
   {
   local float pos;
   local float ang;
   local float seconds;
   local string temp;

   // How much time has elapsed.
   seconds = time + self.cnt;

   // divide by time it takes for one revolution
   pos = seconds / self.count;

   // chop off non-fractional component
   pos = pos - floor( pos );

   ang = 360 * pos;
   if ( self.event )
      {
      if ( self.ltime > ang )
         {
         // past twelve
         temp = self.target;
         self.target = self.event;
         SUB_UseTargets();
         self.target = temp;
         }
      }

   self.angles_x = ang * self.movedir_x;
   self.angles_y = ang * self.movedir_y;
   self.angles_z = ang * self.movedir_z;
   RotateTargetsFinal();

   self.ltime = ang;
   };

void() clock_think =
	{
   clock_setpos();
   self.nextthink = time + 1;
   };

void() clock_firstthink =
   {
   LinkRotateTargets();
   self.think = clock_think;
   clock_think();
   };

/*QUAKED func_clock (0 0 0.5) (0 0 0) (32 32 32)
Creates one hand of a "clock".

Set the angle to be the direction the clock is facing.

"event" is the targetname of the entities to trigger when hand strikes 12.
"cnt" is the time to start at.
"count" is the # of seconds it takes to make a full revolution (seconds is 60, minutes 3600, hours 43200).  default is 60.
*/

void() func_clock =
	{
   local vector temp;

   self.classname = "clock";
   self.think = clock_firstthink;
   self.nextthink = time + 0.1;
   self.ltime = time;
   SetMovedir();
   temp = self.movedir;
   self.movedir_x = 0 - temp_y;
   self.movedir_y = 0 - temp_z;
   self.movedir_z = 0 - temp_x;

   if ( !self.count )
      {
      self.count = 60;
      }
   self.cnt = self.cnt * ( self.count / 12 );
   };
