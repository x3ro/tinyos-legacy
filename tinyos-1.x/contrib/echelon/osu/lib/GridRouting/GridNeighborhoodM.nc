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

includes GridTreeMsg;

// Topology for April Demo
// Base station   : (0,2), (10,2) and (20,2)
// Base station ID: 42,    52,    and 62    , respectively

module GridNeighborhoodM
{
  provides{
  	interface Neighborhood;
	interface StdControl;
  }
}
implementation
{
  command result_t StdControl.init() {
  	return SUCCESS;
  	//return call CommControl.init();
  }

  command result_t StdControl.start() {
  	//return call CommControl.start();
  	return SUCCESS;
  }

  command result_t StdControl.stop() {
  	//return call CommControl.stop();
  	return SUCCESS;
  }

/******************* April Demo *********************/
#ifndef CASE_22
  // only for April Demo
  int isMyPrimaryParent(gpoint myid, gpoint nghid){
    int8_t myx,myy,nx,ny;

  	myx=myid.x;
  	myy=myid.y;
	nx=nghid.x;
	ny=nghid.y;

  	if (myy==0)	{// 1st row
  		if(myx>=0 && myx<= 1){
  			if(nx==0 && ny==2)	return 1;	// 1st stargate
  			else return 0;
  		}
  		else if(myx>=9 && myx<= 11){
  			if(nx==10 && ny==2)	return 1;	// 2nd stargate
  			else return 0;
  		}
  		else if(myx>=19 && myx<= 20){
  			if(nx==20 && ny==2)	return 1;	// 3rd stargate
  			else return 0;
  		}
  		else if((myx>=5 && myx<=8)||(myx>=15 && myx<=18)){ // B and D
  			if((myx+2==nx && myy==ny)||
                 (myx+1==nx && myy+1==ny)||
  			   (myx+1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=2 && myx<=4)||(myx>=12 && myx<=14)){	// A and C
  			if((myx-2==nx && myy==ny)||
  			   (myx-2==nx && myy+1==ny)||
  			   (myx-1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==1){	// 2nd row
  		if(myx>=0 && myx<=1){		// 1st S
  			if(nx==0 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=8 && myx<= 11){ // 2nd S
  			if(nx==10 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=18 && myx<= 19){ // 3rd S
  			if(nx==20 && ny==2)	return 1;
  			else return 0;
  		}
  		else if((myx>=5 && myx<=7)||(myx>=15 && myx<=17)){ // B,D
  			if((myx+2==nx && myy==ny)||
                 (myx+2==nx && myy+1==ny)||
  			   (myx+1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=2 && myx<=4)||(myx>=12 && myx<=14)){ // A,C
  			if((myx-2==nx && myy==ny)||
  			   (myx-1==nx && myy+1==ny)||
  			   (myx-1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==2)	{// 3rd (middle) row
  		if(myx>=0 && myx<= 2){		// 1st S
  			if(nx==0 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=8 && myx<= 12){
  			if(nx==10 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=18 && myx<= 20){
  			if(nx==20 && ny==2)	return 1;
  			else return 0;
  		}
  		else if((myx>=5 && myx<=7)||(myx>=15 && myx<=17)){	// B,D
  			if((myx+2==nx && myy==ny)||
  			   (myx+1==nx && myy+1==ny)||
  			   (myx+1==nx && myy-1==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=3 && myx<=4)||(myx>=13 && myx<=14)){ // A,C
  			if((myx-2==nx && myy==ny)||
  			   (myx-2==nx && myy+1==ny)||
  			   (myx-2==nx && myy-1==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==3){	// 4th row
  		if(myx>=0 && myx<= 1){	// 1st S
  			if(nx==0 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=8 && myx<= 11){	// 2nd S
  			if(nx==10 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=18 && myx<= 19){	// 3rd S
  			if(nx==20 && ny==2)	return 1;
  			else return 0;
  		}
  		else if((myx>=5 && myx<=7)||(myx>=15 && myx<=17)){	// B,D
  			if((myx+2==nx && myy==ny)||
  			   (myx+2==nx && myy-1==ny)||
  			   (myx+1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=2 && myx<=4)||(myx>=12 && myx<=14)){ // A,C
  			if((myx-2==nx && myy==ny)||
  			   (myx-1==nx && myy-1==ny)||
  			   (myx-1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==4){// 5th row
  		if(myx>=0 && myx<= 1){	// 1st S
  			if(nx==0 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=9 && myx<= 11){	// 2nd S
  			if(nx==10 && ny==2)	return 1;
  			else return 0;
  		}
  		else if(myx>=19 && myx<= 20){	// 3rd S
  			if(nx==20 && ny==2)	return 1;
  			else return 0;
  		}
  		else if((myx>=5 && myx<=8)||(myx>=15 && myx<=18)){	// B,D
  			if((myx+2==nx && myy==ny)||
  			   (myx+1==nx && myy-1==ny)||
  			   (myx+1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=2 && myx<=4)||(myx>=12 && myx<=14)){	// A,C
  			if((myx-2==nx && myy==ny)||
  			   (myx-2==nx && myy-1==ny)||
  			   (myx-1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  	}

	return 0;

  }

  // only for April Demo
  int isMySecondaryParent(gpoint myid, gpoint nghid){
    int8_t myx,myy,nx,ny;

  	myx=myid.x;
  	myy=myid.y;
	nx=nghid.x;
	ny=nghid.y;
  
  	if (myy==0)	{// 1st row
  		if((myx>=5 && myx<=9)||(myx>=15 && myx<=20)){ // B and D
  			if((myx-2==nx && myy==ny)||
                 (myx-2==nx && myy+1==ny)||
  			   (myx-1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=0 && myx<=4)||(myx>=10 && myx<=14)){	// A and C
  			if((myx+2==nx && myy==ny)||
  			   (myx+1==nx && myy+1==ny)||
  			   (myx+1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==1){	// 2nd row
  		if((myx>=5 && myx<=9)||(myx>=15 && myx<=19)){ // B,D
  			if((myx-2==nx && myy==ny)||
                 (myx-1==nx && myy+1==ny)||
  			   (myx-1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=0 && myx<=4)||(myx>=10 && myx<=14)){ // A,C
  			if((myx+2==nx && myy==ny)||
  			   (myx+2==nx && myy+1==ny)||
  			   (myx+1==nx && myy+2==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==2)	{// 3rd (middle) row
  		if((myx>=5 && myx<=9)||(myx>=15 && myx<=20)){	// B,D
  			if((myx-2==nx && myy==ny)||
  			   (myx-2==nx && myy+1==ny)||
  			   (myx-2==nx && myy-1==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=0 && myx<=4)||(myx>=10 && myx<=14)){ // A,C
  			if((myx+2==nx && myy==ny)||
  			   (myx+1==nx && myy+1==ny)||
  			   (myx+1==nx && myy-1==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==3){	// 4th row
  		if((myx>=5 && myx<=9)||(myx>=15 && myx<=19)){	// B,D
  			if((myx-2==nx && myy==ny)||
  			   (myx-1==nx && myy-1==ny)||
  			   (myx-1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=0 && myx<=4)||(myx>=10 && myx<=14)){ // A,C
  			if((myx+2==nx && myy==ny)||
  			   (myx+2==nx && myy-1==ny)||
  			   (myx+1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  	}
  	else if (myy==4){// 5th row
  		if((myx>=5 && myx<=9)||(myx>=15 && myx<=20)){	// B,D
  			if((myx-2==nx && myy==ny)||
  			   (myx-2==nx && myy-1==ny)||
  			   (myx-1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  		else if((myx>=0 && myx<=4)||(myx>=10 && myx<=14)){	// A,C
  			if((myx+2==nx && myy==ny)||
  			   (myx+1==nx && myy-1==ny)||
  			   (myx+1==nx && myy-2==ny))
  				return 1;
  			else return 0;
  		}
  	}

	return 0;
  }
#endif

/******************* case ONE *********************/
#ifdef CASE_22
  int isMyPrimaryParent(gpoint myid, gpoint nghid){
	int myx,myy,nx,ny;
	int8_t half;
	myx=myid.x;
	myy=myid.y;
	nx=nghid.x;
	ny=nghid.y;

	half=N/2;

	if(myx<half){
		if(	TOS_LOCAL_ADDRESS==N ||
			TOS_LOCAL_ADDRESS==N+1 ||
			TOS_LOCAL_ADDRESS==N+2 ||
			TOS_LOCAL_ADDRESS==1 ||
			TOS_LOCAL_ADDRESS==2	){
			if(nx==0 && ny==0)	return 1;
			else return 0;
		}
		else{
			if((nx+1==myx || nx+2==myx) && myy==ny)
				return 1;
			else return 0;
		}
	}
	else{
		if(	TOS_LOCAL_ADDRESS==N-3 ||
			TOS_LOCAL_ADDRESS==N-2 ||
			TOS_LOCAL_ADDRESS==N-1 ||
			TOS_LOCAL_ADDRESS==2*N-3 ||
			TOS_LOCAL_ADDRESS==2*N-2	){
			if(nx==N-1 && ny==1)	return 1;
			else return 0;
		}
		else{
			if((nx-1==myx || nx-2==myx) && myy==ny)
				return 1;
			else return 0;
		}
	}
	

/*
	if(myx>=0 && myx<=2){
		if(nx==0 && ny==0)	return 1;
		else return 0;
	}

	if(myx>=8 && myx<=10){
		if(nx==10 && ny==1)	return 1;
		else return 0;
	}

	if(myx==3 || myx==4 || (myx==5 && myy==0)){
		if((nx==myx-2 || nx==myx-1) && ny==myy) return 1;
		else return 0;
	}

	if(myx==6 || myx==7 || (myx==5 && myy==1)){
		if((nx==myx+2 || nx==myx+1) && ny==myy) return 1;
		else return 0;
	}

	return 0;
*/
  }

  int isMySecondaryParent(gpoint myid, gpoint nghid){
	int myx,myy,nx,ny;
	int8_t half;
	myx=myid.x;
	myy=myid.y;
	nx=nghid.x;
	ny=nghid.y;

	half=N/2;

	if(myx>=0 && myx<half){
		if((nx==myx+2 || nx==myx+1) && ny==myy) return 1;
		else return 0;
	}

	if(myx>=half && myx<=N-1){
		if((nx==myx-2 || nx==myx-1) && ny==myy) return 1;
		else return 0;
	}
	
/*
	if((myx>=0 && myx<=4) || (myx==5 && myy==0)){
		if((nx==myx+2 || nx==myx+1) && ny==myy) return 1;
		else return 0;
	}

	if((myx>=6 && myx<=10) || (myx==5 && myy==1)){
		if((nx==myx-2 || nx==myx-1) && ny==myy) return 1;
		else return 0;
	}
*/

	return 0;
  }
#endif


  command int8_t Neighborhood.isPrimaryParent(gpoint myid, gpoint nghid){
    return isMyPrimaryParent(myid, nghid);
  	//return isMyHNgh(myid, nghid);
  }

  command int8_t Neighborhood.isSecondaryParent(gpoint myid, gpoint nghid){
    return isMySecondaryParent(myid, nghid);
  	//return isMyHNgh(myid, nghid);
  }

}
