/*
    StdNull configurations - modulethat has a StdOut interface but just throw
    stuff away. 
    Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

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

/**
   This configuration provides an implementation of the StdOut interface
   that throws any message away.
*/

configuration StdNullC
{
    provides interface StdOut as StdOutUart;
}

implementation
{
  components StdNullM;
  StdOutUart = StdNullM;
}
