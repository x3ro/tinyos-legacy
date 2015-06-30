/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

import java.awt.* ;

public class Moteinfo
{

	private int x;
	private int y;
	private int quality_health;
	private int comm_health;
	private int count;
                   private long ts;
	private int lost;


	public Moteinfo(int x, int y, int quality, int comm, int count, int lost, long ts) 
	{
		this.x=x;
		this.y=y;
		this.quality_health=quality;
		this.comm_health=comm;
		this.count=count;
		this.lost=lost;
		this.ts=ts;
		
	}

	public void printer()
	{
		System.out.println(x);
	}

	public void set_count(int c)
	{
		count=c;
	}

	public void set_ts(long c)
	{
		ts=c;
	}

	public void add_lost(int l)
	{
		lost+=l;
	}

	
	public int getx()
	{
		return x;
	}

	public int gety()
	{
		return y;
	}

	public int get_quality_health()
	{
		return quality_health;
	}

	public int get_comm_health()
	{
		return comm_health;
	}

	public void dec_quality_health()
	{
		quality_health--;
	}

	public void dec_comm_health()
	{
		comm_health--;
	}

	public void inc_quality_health()
	{
		quality_health++;
	}

	public void reset_comm_health()
	{
		comm_health=10;
	}

	public int get_count()
	{
		return count;
	}

	public long get_ts()
	{
		return ts;
	}

	public int get_lost()
	{
		return lost;
	}


}