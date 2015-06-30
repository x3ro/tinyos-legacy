/**
 * Copyright (c) 2003 - The University of Texas at Austin and
 *                      The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE
 * UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
 * INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS
 * SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS AT AUSTIN
 * AND THE OHIO STATE UNIVERSITY HAVE BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY
 * SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

/*
 *  Author/Contact: Young-ri Choi
 *                  yrchoi@cs.utexas.edu
 *
 *  This implementation is based on the design 
 *  by Mohamed G. Gouda, Young-ri Choi, Anish Arora and Vinayak Naik.
 *
 */

enum{
	AM_REPORTEDMSG=10,	// report data to PC
	AM_UPDATEMSG=32,	// report periodic visualization info to PC
	AM_UPDATEMSG2=34,	// report on-demand visualization info to PC
	AM_GRIDTREEMSG=21,	// for connected msg
	AM_ROUTINGMSG=82,	// for data routing
	AM_PATHMSG=84,		// for vis-info routing
	AM_HIMSG=8
};

enum{
	HEADER_LEN = 2,	// size of gpoint
	TREE_HOP=2,	// compute neighbor based on this value
	
	MAX_PATH=12,
	NUM_INDEX=25
};

struct ReportedMsg{
  uint8_t src;
  uint16_t count;
  uint8_t type;
  uint32_t time1;
  uint32_t time2;
  //uint16_t maxqid;
  //uint8_t maxqsize;
};

struct UpdateMsg{
  uint8_t type;
  int8_t state;
  uint8_t path[NUM_INDEX];
};

typedef struct{
	uint8_t x;
	uint8_t y;
} gpoint;

typedef struct{
  int8_t type;
  gpoint id;
  int8_t level;
  gpoint pid;
  uint8_t vis;
} ConnectedMsg;

struct PathMsg{
//typedef struct{
  //int8_t type;
  gpoint pid;	// dst		2 bytes
  int8_t num;	// 1 byte 
  uint8_t path[MAX_PATH]; //13
//} PathMsg;
} PathMsg;

typedef struct{
  uint8_t src;
  uint16_t count;
  uint8_t type;
  uint32_t time1;
  uint32_t time2;
  //uint16_t maxqid;
  //uint8_t maxqsize;
} AppMsg;

typedef struct{
  gpoint dst;	// 2 byte
  AppMsg am;	// 3 byte
} RouteMsg;		// 5 byte


typedef struct HiMsg{
	uint8_t type;
	int8_t flag;
	uint8_t vis;
} HiMsg;

gpoint AddresstoID(uint16_t addr, uint16_t size)
{
	gpoint id;
	if (addr > 100) addr = addr - 100;
	id.x = addr % size; // remainder
	id.y = addr / size;	// quotient

	return id;
}

uint16_t IDtoAddress(gpoint id, uint16_t size)
{
    uint16_t addr;
	addr = id.x + id.y*size;

	return addr;
}

int isMyNgh(gpoint myID, gpoint nghid, uint16_t size)
{
	int westX, eastX, southY, northY;
	
	if (TOS_LOCAL_ADDRESS < 100)
	{
	if(myID.x-TREE_HOP < 0) westX = 0;
	else westX= myID.x-TREE_HOP;

	if(myID.x+TREE_HOP >= size) eastX = size-1;
	else eastX= myID.x+TREE_HOP;

	if(myID.y-TREE_HOP < 0) southY = 0;
	else southY = myID.y-TREE_HOP;

	if(myID.y+TREE_HOP >= size) northY = size-1;
	else northY= myID.y+TREE_HOP;
	
	if (myID.x == 0){
		if (nghid.x == eastX && nghid.y == myID.y)	
			return 1;
	}
	else if(myID.x == size-1){
		if (nghid.x == westX && nghid.y == myID.y)	
			return 1;
	}
	else if(myID.x >0 && myID.x <size-1){
		if ((nghid.x == eastX || nghid.x == westX) 
		   && nghid.y == myID.y)
			return 1; 
	}

	if (myID.y == 0){
		if (nghid.y == northY && nghid.x == myID.x)	
			return 1;
	}
	else if(myID.y == size-1){
		if (nghid.y == southY && nghid.x == myID.x)	
			return 1;
	}
	else if(myID.y >0 && myID.y <size-1){
		if ((nghid.y == southY || nghid.y == northY) 
		   && nghid.x == myID.x)
			return 1;
	}

	return 0;
	}
	else
	{
		if (TOS_LOCAL_ADDRESS - IDtoAddress(nghid, size) == 100)	
			return 1;
		else return 0;
	}

}

