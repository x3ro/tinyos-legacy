/*
 * file:        Console.nc
 * description: interface - simple serial console for mote
 *
 * author:      Peter Desnoyers, UMass Computer Science Dept.
 * $Id: Console.nc,v 1.1 2011/08/14 16:37:54 dukenunee Exp $
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

interface Console {
    command result_t init();
    command void printf0(char *fmt);
    command void printf1(char *fmt, int16_t n);
    command void printf2(char *fmt, int16_t n1, int16_t n2);
    command void newline();
	event void input(char *str);
}
