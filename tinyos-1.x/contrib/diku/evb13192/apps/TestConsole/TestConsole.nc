/*
    ConsoleTest program - tests the Console module somewhat.
    Copyright (C) 2002-2004 Mads Bondo Dydensborg <madsdyd@diku.dk>

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
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

includes defines;

configuration TestConsole
{
}

implementation
{
	components Main,
	           TestConsoleM,
	           LedsC,
	           ConsoleC,
	           SingleTimer;
	
	/* Connect Main with other components */           
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> TestConsoleM.StdControl;
	
	TestConsoleM.ConsoleIn -> ConsoleC.ConsoleIn;
	TestConsoleM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestConsoleM.Leds -> LedsC;
	TestConsoleM.Timer -> SingleTimer.Timer;
	LedsC.ConsoleOut -> ConsoleC.ConsoleOut;
  
	
	
}
