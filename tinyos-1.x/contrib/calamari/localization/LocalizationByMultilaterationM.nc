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

//!! AnchorHood = CreateNeighborhood( 4, MostConfidentMultihopAnchors, BroadcastBackend, 150 );
//!! LocationAttr = CreateAttribute[TinyVizLocationAttribute:X_pos_ADC_channel=112,Y_pos_ADC_channel=113,X_stdv_ADC_channel=114,Y_stdv_ADC_channel=115]( location_t = { pos:{x:65535u, y:65535u}, stdv:{x:65534u, y:65534u} } );
// !! LocationAttr = CreateAttribute( location_t = { pos:{x:65535, y:65535}, stdv:{x:65534u, y:65534u} } );

//!! LocationRefl = CreateReflection( AnchorHood, LocationAttr, FALSE, 200, 201 );

//!! DistanceAttr = CreateAttribute( distance_t = {distance:0, stdv:65535u} );
//!! DistanceRefl = CreateReflection( AnchorHood, DistanceAttr, FALSE, 211, 212 );

//!! ShortestPathAttr = CreateAttribute( distance_t = {distance:0, stdv:65535u} ); 
//!! ShortestPathRefl = CreateReflection( AnchorHood, ShortestPathAttr, FALSE, 213, 214 );

//!! HopCountAttr = CreateAttribute( uint8_t = 0 ); 
//!! HopCountRefl = CreateReflection( AnchorHood, HopCountAttr, FALSE, 215, 216 );

//!! TxDelayAttr = CreateAttribute( uint16_t = 0 ); 
//!! TxDelayRefl = CreateReflection( AnchorHood, TxDelayAttr, FALSE, 217, 218 );

//!! TxRetryAttr = CreateAttribute( uint8_t = 0 ); 
//!! TxRetryRefl = CreateReflection( AnchorHood, TxRetryAttr, FALSE, 219, 220 );

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
    interface AnchorHood_private;

    interface StdControl as LocationAttrControl;
    interface StdControl as AnchorHoodControl;

    interface LeastSquares; //    interface LinearSystem;
    interface Config_LocationInfo;
    
//    interface SendMsg;
    interface DiagMsg;
    interface Leds;
    
//    interface EvaderDemoStore;
  }
}

implementation
{

  bool oldIsAnchor = FALSE;
  
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
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call LocationAttrControl.stop();
    call AnchorHoodControl.stop();
    return SUCCESS;
  }

  event void Config_LocationInfo.updated() {
    if(G_Config.LocationInfo.isAnchor){
      AnchorHood_t me= G_default_node_AnchorHood;
      me.id = TOS_LOCAL_ADDRESS;
      me.data_DistanceRefl.distance=0;
      me.data_DistanceRefl.stdv=0;
      me.data_ShortestPathNodeRefl=TOS_LOCAL_ADDRESS;
      call readLocationFromTinyViz();
      me.data_LocationRefl = call LocationAttr.get();
      me.data_HopCountRefl = 0;
      call AnchorHood_private.changeID(call AnchorHood.getNeighbor(0), TOS_LOCAL_ADDRESS, &me);
    }

    
    if(!(G_Config.LocationInfo.isAnchor) && oldIsAnchor) {
      call AnchorHood_private.removeID(TOS_LOCAL_ADDRESS);
      call Localization.resetLocation();		  
    }

    oldIsAnchor = G_Config.LocationInfo.isAnchor;
    
//    call EvaderDemoStore.setIsAnchor(G_Config.LocationInfo.isAnchor);
    G_Config.LocationInfo.localizedLocation = call LocationAttr.get();
//    call EvaderDemoStore.setRealLoc(G_Config.LocationInfo.realLocation);
//    call EvaderDemoStore.setLocalizedLoc(G_Config.LocationInfo.localizedLocation);

  }
  
  location_t estimateLocation();

  /**This command is here as a wrapper for the task
	because NesC doesn't support putting tasks in interfaces
  */
  command void Localization.estimateLocation() {
    estimateLocation();
  }

  command void Localization.resetLocation() {
    location_t position;

    position.pos.x=65535u;
    position.pos.y=65535u;
    position.stdv.x=65534u;
    position.stdv.y=65534u;
    call LocationAttr.set(position);
    G_Config.LocationInfo.localizedLocation = position;
//    call EvaderDemoStore.setLocalizedLoc(position);
  }
  
  float inline square(float f){ return f*f;}
  
  task void less3anchors()
  {
    if(G_Config.positionDebug) {
      if( call DiagMsg.record() == SUCCESS ) {
	call DiagMsg.str("<3 anchors");
	call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	call DiagMsg.uint8(call AnchorHood.numNeighbors());
	call DiagMsg.send();
      }
    }
  }
  
//this command will take a number of anchor nodes and the
//distances to them and will estimate your own position.
location_t estimateLocation(){
  uint8_t count, numAnchors;
  location_t positionEstimate;
  
  numAnchors=call AnchorHood.numNeighbors();
  if(G_Config.LocationInfo.isAnchor){
    dbg(DBG_USR2,"LOCALIZATION: is anchor\n");
    call readLocationFromTinyViz();
    positionEstimate = call LocationAttr.get();
  }
  else if(numAnchors<3){
    location_t currentPosition = call LocationAttr.get();
    dbg(DBG_USR2,"LOCALIZATION : not enough anchors\n");
    positionEstimate.pos.x=currentPosition.pos.x;
    positionEstimate.pos.y=currentPosition.pos.y;
    positionEstimate.stdv.x=65534u;
    positionEstimate.stdv.y=65534u;
    post less3anchors();
  }
  else {
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
    //for now, we will estimate the location error to Lbe the max of the errors used in locating it
      positionEstimate.stdv.x=0;
      positionEstimate.stdv.y=0;
      for(count=0;count<numAnchors;count++){
	anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(count));
	anchorDistance=call DistanceRefl.get(call AnchorHood.getNeighbor(count));
	positionEstimate.stdv.x =
	  positionEstimate.stdv.x >
	  anchorDistance.stdv? (positionEstimate.stdv.x >
				anchorLocation.stdv.x? (positionEstimate.stdv.x >
							anchorLocation.stdv.y?
							positionEstimate.stdv.x
							: anchorLocation.stdv.y)
				: anchorLocation.stdv.x)
	  : anchorDistance.stdv;
	positionEstimate.stdv.y=positionEstimate.stdv.x;
      }
      // HACKY crap to account for that positions are unsigned
      // if we get a negative number, then just make it zero since
      // we know we are on a grid 
      if(positionEstimate.pos.x > G_Config.negativeLocalizationUnsigned)
	positionEstimate.pos.x = 0;
      
      if(positionEstimate.pos.y > G_Config.negativeLocalizationUnsigned)
	positionEstimate.pos.y = 0;
      
      if(G_Config.positionDebug) {
	if( call DiagMsg.record() == SUCCESS ) {
	  call DiagMsg.str("position");
	  call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	  call DiagMsg.str("x");
	  call DiagMsg.uint16(positionEstimate.pos.x);
	  call DiagMsg.str("y");
	  call DiagMsg.uint16(positionEstimate.pos.y);
	  call DiagMsg.send();
	}
      }
    }
    else{
      location_t currentPosition = call LocationAttr.get();
      dbg(DBG_USR2,"LOCALIZATION : linear system failed to solve\n");
      positionEstimate.pos.x=currentPosition.pos.x;
      positionEstimate.pos.y=currentPosition.pos.y;
      positionEstimate.stdv.x=65534u;
      positionEstimate.stdv.y=65534u;

      if(G_Config.positionDebug) {
	if( call DiagMsg.record() == SUCCESS ) {
	  call DiagMsg.str("failed");
	  call DiagMsg.send();
	}
      }
    }
  }
  dbg(DBG_USR2,"LOCALIZATION: x= %d xStdv= %d y= %d yStdv= %d\n",positionEstimate.pos.x, positionEstimate.stdv.x, positionEstimate.pos.y, positionEstimate.stdv.y);
    
  call LocationAttr.set(positionEstimate);

  G_Config.LocationInfo.localizedLocation = positionEstimate;
//  call EvaderDemoStore.setLocalizedLoc(G_Config.LocationInfo.localizedLocation);

  return positionEstimate;
}
 
 event void LeastSquares.evaluateBasisFunctions(float x, float p[], int pSize){
   location_t firstAnchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(0));
   location_t anchorLocation=call LocationRefl.get(call AnchorHood.getNeighbor(x));
   p[1]=-2.0*((float)anchorLocation.pos.x-(float)firstAnchorLocation.pos.x);
   p[2]=-2.0*((float)anchorLocation.pos.y-(float)firstAnchorLocation.pos.y);
 }
       
 event void LocationAttr.updated( ){
 }
 
 event void LocationRefl.updated( nodeID_t id, location_t value ){
 }
 
 event void DistanceRefl.updated( nodeID_t id, distance_t value ){
 }
 
 event void AnchorHood.removingNeighbor( nodeID_t id ){}
 event void AnchorHood.addedNeighbor( nodeID_t id ){}
}















