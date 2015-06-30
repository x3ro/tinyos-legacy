/* "Copyright (c) 2001 and The Regents of the University  
* of California.  All rights reserved. 
* 
* Permission to use, copy, modify, and distribute this software and its 
* documentation for any purpose, without fee, and without written agreement is 
* hereby granted, provided that the above copyright notice and the following 
* two paragraphs appear in all copies of this software. 
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
* 
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001 
*/

package Surge.PacketAnalyzer.Location;

import javax.vecmath.*;
import java.util.*;

public class KalmanFilter
{
    protected static final int DISTANCE  = 0; //the index into the 2 element GVector that returns the distance
    private   static final boolean DEBUG = false;
    
//this class will be used as a super class for all kalman Filters
//the following are the basic equations explaining the Kalman Filter

	/* here's a list of all of the "tweakable" variables we want to make sliders for
	rd = signalNoiseStdev [0:100000:Signal Noise Stdev]
	xIntercept = signalXIntercept [0:20000:Signal X-Intercept] 
	initialDistance [0:30ft:initial distance]
	initialVelocity[0:10ft/s:initial velocity]
	initialCertainty[0.0001:10:initial certainty]
	effectOfVelocity[0.0001:10:effect of velocity]
	velocityDamping[0.0001:10:velocity damping]
	velocityNoiseStdev[0.0001:10:Velocity Noise stdev]
	kalmanFilterSlope[10000:-10000:Slope of Kalman Filter]
	*/
	
	// here are the tweakable declarations with the values initially specified
	protected double SIGNAL_NOISE_STDEV   = 2000;
	protected double X_INTERCEPT          = 16290;
	protected double INITIAL_DISTANCE     = 0;
	protected double INITIAL_VELOCITY     = 0;
	protected double INITIAL_CERTAINTY    = 1;
	protected double EFFECT_OF_VELOCITY   = .01;
	protected double VELOCITY_DAMPING     = 11;
	protected double VELOCITY_NOISE_STDEV = .1;
	protected double KALMAN_FILTER_SLOPE  = -1000;
	
	protected int reneNumber;
	protected int renePosition;
	protected int wecNumber;
    
	protected GMatrix am = new GMatrix(2,2); // state transition matrix
	protected GMatrix gm = new GMatrix(2,2); // matrix to multiply noise by
	protected GVector cv = new GVector(2); // state to sensor transition matrix
	protected GMatrix qm = new GMatrix(2,2); // covariance of state->state noise
	protected double  rd = 75; // [0:100000:Signal Noise Stdev] covariance of state->signal noise
	protected double  xIntercept  = 256; // [0:20000:Signal X-Intercept] additive factor to ss (sort of tweakable)

	protected GVector xEstimateV  = new GVector(2);   // estimate of state X based on previous X
	protected GVector xCorrectedV = new GVector(2);   // estimate of X corrected by Sensor readings
	protected GMatrix pEstimateM  = new GMatrix(2,2); // estimate of sigma
	protected GMatrix pCorrectedM = new GMatrix(2,2); // sigma corrected by sensor readings


	public KalmanFilter() 
	{
	    //state = [distance, velocity]
        // next distance = current distance + velocity
        // next velocity = current velocity + noise
   //-->
        //X(t+1) = A*X(t) + G*w(t), where w is noise, X is state at time t
	    //Y(t)   = xIntercept + C*X(t) + v(t), where v is noise, Y is the sensor reading
	                        //q -->covariance matrix of v(T)
	                        //r -->covariance matrix of w(T)
   
	    GMatrix tempM = new GMatrix(2,2);

        xEstimateV.setElement(0,0); // 
	    xEstimateV.setElement(1,0); // 

	    pEstimateM.setIdentity();                     
	    pEstimateM.setScale(0);

		xCorrectedV.setElement(0,256); // [0:30ft:initial distance]initial condition: x -->distance
		xCorrectedV.setElement(1,-1); // [0:10ft/s:initial velocity] initial condition: dx --> velocity
                                     //***psuedo-tweakable: initial conditions for x state
	    pCorrectedM.setIdentity();
		tempM.setScale(1); //***tweakable: [0.0001:10:initial certainty]initial conditions for certainty (sigma)
	    pCorrectedM.mul(tempM); 

	    am.setElement(0,0,1);                     // next distance = current distance + velocity
		am.setElement(0,1,0.1); //tweakable: [0.0001:10:effect of velocity] def of velocity                    
	    am.setElement(1,0,0);                     
		am.setElement(1,1,.9); //***tweakable: [0.0001:10:velocity damping] multiplier to get new velocity from old velocity, i.e. damping factor 
	   
	    gm.setElement(0,0,0);                     //no noise for new distance	
	    gm.setElement(0,1,0); 	
	    gm.setElement(1,0,0); 	                  //small noise for new velocity
		gm.setElement(1,1,1); //***tweakable: [0.0001:10:Velocity Noise stdev](FT/sec velocity noise i.e. how much velofity changes btwn t --> t+1		
	    
	    qm.setIdentity();
	    tempM.setScale(0.5);
		qm.mul(tempM);         //*** not-tweakable: sdtdev of noise on transitions of state x
	    
		cv.setElement(0,-1);  //*** psuedo-tweakable: [10000:-10000:Slope of Kalman Filter] coefficient of x in above equation
        cv.setElement(1,0);                        //signal strength does not depend on velocity in eqn above

	    
	 }
    
	public double estimateNewDistance(int SS) 
	{
	    
	    //System.out.print("old y is:        " + y);
	    double y = (double)SS;
	    double yOld = y;
        y = y-xIntercept;
    	
    	GVector kv = new GVector(2);
    	
		xEstimateV.mul(am, xCorrectedV);// xEstimate = a*xCorrected;

		                        //pEstimate = a*pCorrected*a'+g*q*g';
		pEstimateM.mul(am,pCorrectedM); 
        pEstimateM.mulTransposeRight(pEstimateM,am);
        GMatrix tempM = new GMatrix(gm);
        tempM.mul(qm);
        tempM.mulTransposeRight(tempM, gm);
        pEstimateM.add(tempM);

		                        //k = pEstimate*c'*inverse(c*pEstimate*c'+r);
        kv.mul(pEstimateM, cv); 
        GVector tempV = new GVector(2);
        tempV.mul(cv,pEstimateM);
        double tempd = tempV.dot(cv);
        tempd  = tempd + rd;
        kv.scale(1/tempd);

		//xCorrected = xEstimate + k*(Y'-c*xEstimate);
		//           = xEstimate + k*( y' - c*xEstimate );
        tempV = new GVector(kv);
        tempV.scale(y - cv.dot(xEstimateV));
		xCorrectedV.add(xEstimateV, tempV);
		
        // pCorrected = pEstimate - k*c*pEstimate;
        //p_half(:,:,time) - k*c*p_half(:,:,time);
        tempV.mul(cv, pEstimateM);
        tempM.mul(kv, tempV);
        pCorrectedM.sub(pEstimateM, tempM);
        
        ValueSigmaPair dist = new ValueSigmaPair(xCorrectedV.getElement(DISTANCE),
                                                 pCorrectedM.getElement(DISTANCE,DISTANCE));

/*        if (dist.value > 90) 
        {
            System.out.println("estimateNewDistance: value is >90, returning null");
            return -1;
        }*/
        
/*        if (dist.value < 0 ) 
        { */
            // if we have a negative value that differs from the estimate by less than 3%
            // of the st dev then update our xIntercept.
            // this will allow the system to adapt to genuine difference but not spurious ones.
          //  System.out.println("xInte: "+xIntercept+", strength: "+yOld+", distance: "+dist.value);
           /* if ((Math.abs(y - cv.dot(xEstimateV))) < .03*rd ) {
                if (yOld > xIntercept) {xIntercept = yOld;
                  xCorrectedV.setElement(0,0);
                  xCorrectedV.setElement(1,0);
                }
            } else {*/
/*                if (DEBUG) System.out.println("estimateNewDistance: value is <0, returning null");
                return -1;*/
          //  }
          //  if ((xIntercept>16900)||(xIntercept<16200)) System.out.println("WHUTTHEFUCKWHUTTHEFUCKWHUTTHEFUCKWHUTTHEFUCKWHUTTHEFUCKWHUTTHEFUCKWHUTTHEFUCK");
/*        }*/
        
//        System.out.println("xIntcp: "+xIntercept+", SS: "+yOld+", distance: "+dist.value);
          
	    return dist.value;
	}


    // ACCESSOR METHODS
    public double getSignalNoiseStdv() {return rd;}
    public void   setSignalNoiseStdv(double r) {rd = r;}
	public double   getSignalNoiseStdvDefault() {return SIGNAL_NOISE_STDEV;}
	
	public double getXIntercept() {return xIntercept;} 	
	public void   setXIntercept(double x) {xIntercept = x;}
	public double   getXInterceptDefault() {return X_INTERCEPT;}
	
	public double getInitialDistance() {return xCorrectedV.getElement(0);}
	public void   setInitialDistance(double d) {xCorrectedV.setElement(0,d);}
	public double   getInitialDistanceDefault() {return INITIAL_DISTANCE;}
	
	public double getInitialVelocity() {return xCorrectedV.getElement(1);}
	public void   setInitialVelocity(double v) { xCorrectedV.setElement(1,v);}
	public double   getInitialVelocityDefault() { return INITIAL_VELOCITY;}
	
    public double getInitialCertainty() {return pCorrectedM.getElement(1,1);}
    public void   setInitialCertainty(double c) { 
        pCorrectedM.setElement(1,1,c); 
        pCorrectedM.setElement(2,2,c); 
    }
	public double   getInitialCertaintyDefault() {return INITIAL_CERTAINTY;}
    
    public double getEffectOfVelocity() {return am.getElement(0,1);}
    public void   setEffectOfVelocity(double e) {am.setElement(0,1,e);}
    public double   getEffectOfVelocityDefault() {return EFFECT_OF_VELOCITY;}
	
    public double getVelocityDamping() {return am.getElement(1,1);}
    public void   setVelocityDamping(double d) {am.setElement(1,1,d);}
    public double   getVelocityDampingDefault() { return VELOCITY_DAMPING;}
	
    public double getVelocityNoiseStdev() {return gm.getElement(1,1);}
    public void   setVelocityNoiseStdev(double n) {gm.setElement(1,1,n);}
    public double   getVelocityNoiseStdevDefault() {return VELOCITY_NOISE_STDEV;}
	
    public double getKalmanFilterSlope() {return cv.getElement(0);}    
    public void   setKalmanFilterSlope(double s)  { cv.setElement(0,s);}
	public double getKalmanFilterSlopeDefault()  { return KALMAN_FILTER_SLOPE;}
    
    public void   setDefaults() {
       rd = SIGNAL_NOISE_STDEV;
	    xIntercept = X_INTERCEPT;
	    xCorrectedV.setElement(0,INITIAL_DISTANCE);
	    xCorrectedV.setElement(1,INITIAL_VELOCITY);
	    pCorrectedM.setElement(0,0,INITIAL_CERTAINTY); 
       pCorrectedM.setElement(1,1,INITIAL_CERTAINTY);
	    am.setElement(0,1,EFFECT_OF_VELOCITY);
	    am.setElement(1,1,VELOCITY_DAMPING);
	    gm.setElement(1,1,VELOCITY_NOISE_STDEV); 
	    cv.setElement(0,KALMAN_FILTER_SLOPE);
	}

	public class ValueSigmaPair 
	{
		public double value; // rho is the distance between rene and wec
		public double sigma; // sigma is the standard deviation of that distance measurement
		  
		public ValueSigmaPair(double val, double sig) 
		{
    		value = val;
    		sigma = sig;
		}
	}
}