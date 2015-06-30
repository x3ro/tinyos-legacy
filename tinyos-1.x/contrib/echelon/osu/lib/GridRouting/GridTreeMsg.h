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

#define CASE_22 1

enum{
	AM_REPORTEDMSG=10,	// report data to PC
	AM_UPDATEMSG=32,	// report periodic visualization info to PC
	AM_UPDATEMSG2=34,	// report on-demand visualization info to PC
	AM_GRIDTREEMSG=21,	// for connected msg
	AM_ROUTINGMSG=82,	// for data routing
	AM_PATHMSG=84,		// for vis-info routing
	AM_HIMSG=8			// for hi msg
};

enum{
	N=8,
	HEADER_LEN = 1,		// size of forward
	TREE_HOP=2,		// compute neighbor based on this value
	
	MAX_PATH=13,
	// vis: max number of motes in path msg
	NUM_INDEX=25
};

// define network parameter list here!!
typedef struct{
	int8_t type;
} netParam;		

// msg structure to report data msg to (0,0)
struct ReportedMsg{
  uint8_t src;
  uint16_t count;
  uint8_t type;
  uint32_t time;		// RobustMsg file
};

typedef struct{
	uint8_t x;
	uint8_t y;
} gpoint;

// msg structure of connected msg
typedef struct{
  uint8_t version1;
  int8_t type;
  gpoint id;
  int8_t bid;		// for April demo
  uint8_t version2;
  netParam nplist;
} ConnectedMsg;

// msg structure of application msg
typedef struct{
  uint8_t src;
  uint16_t count;
  uint8_t type;
  uint32_t time;
} AppMsg;

// msg structure of routing msg
typedef struct{
  //gpoint dst;	
  uint8_t forward;
  AppMsg am;	
} RouteMsg;		


/* -------------------------------------------*/

gpoint AddresstoID(uint16_t addr, uint16_t size)
{
	gpoint id;
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


// for new grid routing 
int isDominate(gpoint myID, gpoint nghid)
{
	if((myID.x >= nghid.x) && (myID.y >= nghid.y)) return 1;
	else return 0;
}

int compDistance(gpoint myID, gpoint nghid)
{
	int dist;
	dist= (myID.x-nghid.x) + (myID.y-nghid.y);

	return abs(dist);
}

int isMyHNgh(gpoint myID, gpoint nghid)
{
	// check if it dominates!
	if (isDominate(myID,nghid)) {
		// if it dominates, then compute the distance!
		if(compDistance(myID,nghid)<=TREE_HOP)	return 1;
	}

	return 0;
}

/************* for April Demo **************************/
#ifndef CASE_22
int ComputePrimBid(gpoint myid){
	int8_t myx;
	int8_t X,Y,Z;
	X=0;
	Y=1;
	Z=2;
	
	myx=myid.x;

	if(myx>=0 && myx<=4)	return X;	// A for X
	if(myx>=5 && myx<=9)	return Y;	// B for Y 
	if(myx>=10 && myx<=14)	return Y;	// C for Y
	if(myx>=15 && myx<=20)	return Z;	// D for Z

	//return 0;
}

// for April Demo
int ComputeSecBid(gpoint myid){
	int8_t myx;
	int8_t X,Y,Z;
	X=0;
	Y=1;
	Z=2;
	myx=myid.x;

	if(myx>=0 && myx<=4)	return Y;	// A for Y 
	if(myx>=5 && myx<=9)	return X;	// B for X 
	if(myx>=10 && myx<=14)	return Z;	// C for Z
	if(myx>=15 && myx<=20)	return Y;	// D for Y

	//return 0;
}

int ComputeMyBid(gpoint myid){
	int8_t myx,myy;
	myx=myid.x;
	myy=myid.y;

	// debug
	//if(myx==0 && myy==0) return 0;

	if(myx==0 && myy==2) return 0;
	if(myx==10 && myy==2) return 1;
	if(myx==20 && myy==2) return 2;
}

//MODIFY depending on topology!!!
//for April Demo!!!
int amIBaseStation(int8_t id){
	//if(id==0) return 1;
	//if(id==10) return 1;
	if(id==42 || id==52 || id==62) return 1;
	else return 0;
}

int amIPotentialBaseChild(int8_t id){

	if( id==0 ||
		id==1 ||
		id==9 ||
		id==10 ||
		id==11 ||
		id==19 ||
		id==20 ||
		id==21 ||
		id==22 ||
		id==29 ||
		id==30 ||
		id==31 ||
		id==32 ||
		id==39 ||
		id==40 ||
		id==43 ||
		id==44 ||
		id==50 ||
		id==51 ||
		id==53 ||
		id==54 ||
		id==60 ||
		id==61 ||
		id==63 ||
		id==64 ||
		id==71 ||
		id==72 ||
		id==73 ||
		id==74 ||
		id==81 ||
		id==82 ||
		id==84 ||
		id==85 ||
		id==93 ||
		id==94 ||
		id==95 ||
		id==103 ||
		id==104 )	return 1;

		return 0;
}
#endif

/************ case ONE *******************/
#ifdef CASE_22
int ComputePrimBid(gpoint myid){
	int8_t myx,myy;
	int8_t X,Y;
	int8_t half;
	X=0;
	Y=1;
	half=N/2;

	myx=myid.x;
	myy=myid.y;

	if(myx<half)	return X;
	else		return Y;

/*
	if(myx>=0 && myx<=4)	return X;	// A for X
	if(myx>=6 && myx<=10)	return Y;	// B for Y 
	if(myx==5){
		if(myy==0) return X;
		else return Y;
	}
*/

	//return 0;
}

int ComputeSecBid(gpoint myid){
	int8_t myx,myy;
	int8_t X,Y;
	int8_t half;
	X=0;
	Y=1;
	half= N/2;
	
	myx=myid.x;
	myy=myid.y;

	if(myx<half)	return Y;
	else		return X;

/*
	if(myx>=0 && myx<=4)	return Y;	// A for Y 
	if(myx>=6 && myx<=10)	return X;	// B for X 
	if(myx==5){
		if(myy==0) return Y;
		else return X;
	}
*/

	//return 0;
}

int ComputeMyBid(gpoint myid){
	int8_t myx,myy;
	myx=myid.x;
	myy=myid.y;

	if(myx==0 && myy==0) return 0;		// X	
	if(myx==N-1 && myy==1) return 1;	// Y

/*
	if(myx==0 && myy==0) return 0;	// X	
	if(myx==10 && myy==1) return 1;	// Y
*/
}

int amIBaseStation(int8_t id){
	if(id==0 || id==2*N-1) return 1;
	//if(id==0 || id==21) return 1;
	else return 0;
}

int amIPotentialBaseChild(int8_t id){

	int8_t half;
	gpoint gid=AddresstoID(id, N);
	half=N/2;


	if(gid.x<half){
		if(	id==N || 
		   	id==N+1 ||
		   	id==N+2 ||
		   	id==1 ||
		   	id==2 )		return 1;
		else	return 0;
	}
	else{
		if(	id==N-3 ||
			id==N-2	||
			id==N-1	||
			id==2*N-3 ||
			id==2*N-2 )	return 1;
		else	return 0;
	}

/*
	if(	id==1 ||
		id==2 ||
		id==8 ||
		id==9 ||
		id==10 ||
		id==11 ||
		id==12 ||
		id==13 ||
		id==19 ||
		id==20) 	return 1;
*/

	return 0;
}
#endif
