/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Kamin Whitehouse

includes common_structs;
includes polynomial; //these should not be necessary (for declared reflections in ranging)
includes moving_average;//these should not be necessary
includes Localization;
includes Neighborhood;
includes AnchorHood;
includes SomeCmd;

//!! AnchorHood = CreateNeighborhood( 5, MostConfidentRssiAnchors, GenericCommBackend, 150 );
//!! LocationAttr = CreateAttribute[TinyVizLocationAttribute:X_pos_ADC_channel=112,Y_pos_ADC_channel=113,X_stdv_ADC_channel=114,Y_stdv_ADC_channel=115]( location_t = { pos:{x:0, y:0, z:0}, stdv:{x:65534, y:65534, z:65534}, coordinate_system:0 } );
// !! LocationAttr = CreateAttribute( location_t = { pos:{x:0, y:0, z:0}, stdv:{x:65535, y:65534, z:65534}, coordinate_system:0 } );

//!! LocationRefl = CreateReflection( AnchorHood, LocationAttr, TRUE, 200, 201 );
//!! SomeCmd = CreateCommand( AnchorHood, uint16_t, uint16_t, FALSE, TRUE );


module LocalizationByMultilaterationM
{
  provides
  {
    interface StdControl;
    interface Localization;
  }
  uses
  {
    interface LocationAttr;
	command void readLocationFromTinyViz();
    interface LocationAttrReflection as LocationRefl;
    interface DistanceAttrReflection as DistanceRefl; //this is defined in the ranging component that you use
    interface Neighborhood as AnchorHood;

    interface StdControl as LocationAttrControl;
    interface StdControl as AnchorHoodControl;

    interface LeastSquares;
//    interface LinearSystem;

    interface Leds;
  }
}

implementation
{
	bool isAnchor;
	
  command result_t StdControl.init()
  {
    call LocationAttrControl.init();
    call AnchorHoodControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call LocationAttrControl.start();
    call AnchorHoodControl.start();
	if( (TOS_LOCAL_ADDRESS == 1)
		|| (TOS_LOCAL_ADDRESS == 2)
		|| (TOS_LOCAL_ADDRESS == 3)
		|| (TOS_LOCAL_ADDRESS == 4)
		)
		isAnchor=TRUE;
	else
		isAnchor=FALSE;	
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call LocationAttrControl.stop();
    call AnchorHoodControl.stop();
    return SUCCESS;
  }

  location_t estimateLocation();

  /**This command is here as a wrapper for the task
	because NesC doesn't support putting tasks in interfaces
  */
  command void Localization.estimateLocation()
  {
	estimateLocation();
  }

  float inline square(float f){ return f*f;}


//this command will take a number of anchor nodes and the
//distances to them and will estimate your own position.
location_t estimateLocation(){
  uint8_t count, numAnchors;
  location_t positionEstimate;

  numAnchors=call AnchorHood.numNeighbors();
  if(isAnchor){
	dbg(DBG_USR2,"LOCALIZATION: is anchor\n");
	call readLocationFromTinyViz();
	positionEstimate = call LocationAttr.get();
  }
  else if(numAnchors<3){
    location_t currentPosition = call LocationAttr.get();
    dbg(DBG_USR2,"LOCALIZATION : not enough anchors\n");
	positionEstimate.pos.x=currentPosition.pos.x;
	positionEstimate.pos.y=currentPosition.pos.y;
	positionEstimate.stdv.x=65534;
	positionEstimate.stdv.y=65534;
  }
  else{
    location_t anchorLocation,firstAnchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(0));
    distance_t anchorDistance,firstAnchorDistance=call DistanceRefl.get(call AnchorHood.getNeighbor(0));

    //all of the following matrix contruction is because I can't f**king malloc
    //and I need to use least squares, which should be able to take a variable
    //sized array (i.e. a float**) but c is dumb about multidimensional pointers

	//also, all arrays are 1-indexed in this section because nr is dumb
    float x[MAX_MEMBERS_AnchorHood], y[MAX_MEMBERS_AnchorHood], sig[MAX_MEMBERS_AnchorHood], a[3], w[3], chisq;
    float uData[MAX_MEMBERS_AnchorHood][3], vData[3][3], covMatData[3][3];
    float *uPointerArray[MAX_MEMBERS_AnchorHood],*vPointerArray[3], *covMatPointerArray[3];
    float **u,**v, **covMat;

  u=uPointerArray;
  v=vPointerArray;
  covMat=covMatPointerArray;
  for(count=0;count<numAnchors;count++){
	u[count]=&uData[count][0];
  }
  for(count=0;count<3;count++){
	v[count]=&vData[count][0];
	covMat[count]=&covMatData[count][0];
  }

  dbg(DBG_USR2,"LOCALIZATION : making the x and y (and sig) matrices\n");
  for(count=1;count<=numAnchors-1;count++){
   anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(count));
   anchorDistance=call DistanceRefl.get(call AnchorHood.getNeighbor(count));
   x[count]=count;//this is the multidimensional trick mentioned in nr
   y[count]=(float)(square( anchorDistance.distance)
    -square( firstAnchorDistance.distance)
    -square( anchorLocation.pos.x)
    +square( firstAnchorLocation.pos.x)
    -square( anchorLocation.pos.y)
    +square( firstAnchorLocation.pos.y));
   sig[count]=anchorLocation.stdv.x+1;;
  }

  dbg(DBG_USR2,"LOCALIZATION : solving linear system\n");
  if(call LeastSquares.solve(x,y,sig,numAnchors-1,a,2,u,v,w,&chisq)==SUCCESS){
	dbg(DBG_USR2,"LOCALIZATION : finished solving linear system\n");
    positionEstimate.pos.x=(uint16_t)a[1];
    positionEstimate.pos.y=(uint16_t)a[2];

//	call LeastSquares.getCovarianceMatrix(v,2,w,covMat);
//    positionEstimate.stdv.x=sqrt(covMat[1][1]);
//    positionEstimate.stdv.y=sqrt(covMat[2][2]);
    //for now, we will estimate the location error to be the max of the errors used in locating it
    positionEstimate.stdv.x=0;
    positionEstimate.stdv.y=0;
	for(count=0;count<numAnchors;count++){
      anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(count));
      anchorDistance=call DistanceRefl.get(call AnchorHood.getNeighbor(count));
      positionEstimate.stdv.x= positionEstimate.stdv.x > anchorDistance.stdv? (
		  positionEstimate.stdv.x > anchorLocation.stdv.x? (
			  positionEstimate.stdv.x > anchorLocation.stdv.y?
			  positionEstimate.stdv.x
			  : anchorLocation.stdv.y)
		      : anchorLocation.stdv.x)
    		  : anchorDistance.stdv;
	  positionEstimate.stdv.y=positionEstimate.stdv.x;
    }
  }
  else{
    location_t currentPosition = call LocationAttr.get();
    dbg(DBG_USR2,"LOCALIZATION : linear system failed to solve\n");
	positionEstimate.pos.x=currentPosition.pos.x;
	positionEstimate.pos.y=currentPosition.pos.y;
	positionEstimate.stdv.x=65534;
	positionEstimate.stdv.y=65534;
  }
  }
  dbg(DBG_USR2,"LOCALIZATION: x= %d xStdv= %d y= %d yStdv= %d\n",positionEstimate.pos.x, positionEstimate.stdv.x, positionEstimate.pos.y, positionEstimate.stdv.y);
  call LocationAttr.set(positionEstimate);
  return positionEstimate;
}
 
  event void LeastSquares.evaluateBasisFunctions(float x, float p[], int pSize){
    location_t firstAnchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(0));
    location_t anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(x));
    p[1]=(float)(-2*(anchorLocation.pos.x-firstAnchorLocation.pos.x));
    p[2]=(float)(-2*(anchorLocation.pos.y-firstAnchorLocation.pos.y));
  }
	  

  

//this command will take a number of anchor nodes and the
//distances to them and will estimate your own position.
/*
  location_t estimateLocation(){
  uint8_t count, numAnchors;
  location_t positionEstimate;

  //if there are not enough anchor nodes, return very high error estimate
//  call AnchorHood.refresh; //this basically confirms that all anchor nodes still have distance estimates in the DistanceHood
  numAnchors=call AnchorHood.numNeighbors();
  if( (TOS_LOCAL_ADDRESS == 1) || (TOS_LOCAL_ADDRESS == 2) || (TOS_LOCAL_ADDRESS == 3)){
	dbg(DBG_USR2,"LOCALIZATION: is anchor\n");
	positionEstimate = call LocationAttr.get();
  }
  else if(numAnchors<3){
    location_t currentPosition = call LocationAttr.get();
    dbg(DBG_USR2,"LOCALIZATION : not enough anchors\n");
	positionEstimate.pos.x=currentPosition.pos.x;
	positionEstimate.pos.y=currentPosition.pos.y;
	positionEstimate.stdv.x=65534;
	positionEstimate.stdv.y=65534;
  }
  else {
    uint16_t lastNodeID=call AnchorHood.getNeighbor(numAnchors-1);
    location_t anchorLocation,lastAnchorLocation=call LocationRefl.get(lastNodeID);
    distance_t anchorDistance, lastAnchorDistance=call DistanceRefl.get(lastNodeID);

    //all of the following matrix contruction is because I can't f**king malloc
    //and I need to use least squares, which should be able to take a variable
    //sized array (i.e. a float**) but c is dumb about multidimensional pointers
    float aData[MAX_MEMBERS_AnchorHood-1][2];
    float bData[MAX_MEMBERS_AnchorHood-1][1];
    float *aPointerArray[MAX_MEMBERS_AnchorHood-1],*bPointerArray[MAX_MEMBERS_AnchorHood-1];
    float **a,**b;


  a=aPointerArray;
  b=bPointerArray;
  for(count=0;count<MAX_MEMBERS_AnchorHood-1;count++){
	a[count]=&aData[count][0];
	b[count]=&bData[count][0];
  }

  //formulate the a and b matrices using all anchor nodes  
  dbg(DBG_USR2,"LOCALIZATION : making the A and B matrices\n");
  for(count=0;count<numAnchors-1;count++){
   anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(count));
   anchorDistance=call DistanceRefl.get(call AnchorHood.getNeighbor(count));
   a[count][0]=(float)(-2*(anchorLocation.pos.x-lastAnchorLocation.pos.x));
   a[count][1]=(float)(-2*(anchorLocation.pos.y-lastAnchorLocation.pos.y));
   b[count][0]=(float)(square( anchorDistance.distance)
    -square( lastAnchorDistance.distance)
    -square( anchorLocation.pos.x)
    +square( lastAnchorLocation.pos.x)
    -square( anchorLocation.pos.y)
    +square( lastAnchorLocation.pos.y));
  }

  //normally, we would use least squares, but here we are only using 
  //the first three anchor nodes and using gauss-jordan elimination
  //if(LeastSquares.solve(a,numAnchors_,b,1)==SUCCESS)
  dbg(DBG_USR2,"LOCALIZATION : solving linear system\n");
  if(call LinearSystem.solve(a,2,b,1)==SUCCESS){
	dbg(DBG_USR2,"LOCALIZATION : finished solving linear system\n");
    positionEstimate.pos.x=(uint16_t)b[0][0];
    positionEstimate.pos.y=(uint16_t)b[1][0];
  
    //for now, we will estimate the location error to be the max of the errors used in locating it
    positionEstimate.stdv.x=0;
    positionEstimate.stdv.y=0;
	for(count=0;count<numAnchors;count++){
      anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(count));
      anchorDistance=call DistanceRefl.get(call AnchorHood.getNeighbor(count));
      positionEstimate.stdv.x= positionEstimate.stdv.x > anchorDistance.stdv? (
		  positionEstimate.stdv.x > anchorLocation.stdv.x? (
			  positionEstimate.stdv.x > anchorLocation.stdv.y?
			  positionEstimate.stdv.x
			  : anchorLocation.stdv.y)
		      : anchorLocation.stdv.x)
    		  : anchorDistance.stdv;
	  positionEstimate.stdv.y=positionEstimate.stdv.x;
    }
  }
  else{
    location_t currentPosition = call LocationAttr.get();
    dbg(DBG_USR2,"LOCALIZATION : linear system failed to solve\n");
	positionEstimate.pos.x=currentPosition.pos.x;
	positionEstimate.pos.y=currentPosition.pos.y;
	positionEstimate.stdv.x=65534;
	positionEstimate.stdv.y=65534;
  }
  }
  dbg(DBG_USR2,"LOCALIZATION: x= %d xStdv= %d y= %d yStdv= %d\n",positionEstimate.pos.x, positionEstimate.stdv.x, positionEstimate.pos.y, positionEstimate.stdv.y);
  call LocationAttr.set(positionEstimate);
  return positionEstimate;
}
*/

  event void LocationAttr.updated( ){
  }

  event void LocationRefl.updated( nodeID_t id, location_t value ){
  }

  event void DistanceRefl.updated( nodeID_t id, distance_t value ){
  }

  event void AnchorHood.removingNeighbor( nodeID_t id ){}
  event void AnchorHood.addedNeighbor( nodeID_t id ){}


}















