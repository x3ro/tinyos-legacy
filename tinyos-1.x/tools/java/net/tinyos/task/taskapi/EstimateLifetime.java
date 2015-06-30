// $Id: EstimateLifetime.java,v 1.2 2003/10/07 21:46:05 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.task.taskapi;

public class EstimateLifetime {
  
    public static final double msXmit = 32;  //time to xmit a sample, in mS
    public static final double mahCapacity = 5800; //capacity of a pair of AA batteries, in mAh
    public static final double maxVReading = 985; //maximum voltage reading of voltage attribute
    public static final double minVReading = 370; //minimum reading of voltage attribute
    public static final double Vdraw = 3;  //voltage of device
    public static final double sPerSample = 1; //"active time" per sample / transmission
    public static final double uaActive = 16900; //active ua load -- measured experimentally
    public static final double uaXmit = 17320;  //ua load in transmission
    public static final double uaSleep = 220; //sleep ua load -- measured experimentally, disputed by Joe

    /** Given a desired lifetime in seconds, return an epoch duration which will achieve this lifetime.
	Return -1 if the lifetime is unobtainable.  
	@param lifetimeSecs The desired lifetime in seconds
	@param curVReading The current voltage of the device in question, in raw ADC units 
	                   (should be between maxVReading and minVReading)
	@param ujSampleCost The (average) cost to obtain a sample from the sensors used in the query (light & temp ~= 90mj)
	@param numSamples The number of samples taken in this query
	@param numMsgs The number of messages sent per epoch
    */
    public static long lifetimeToSamplePeriod(long lifetimeSecs, long curVReading, long ujSampleCost, long numSamples, long numMsgs) {
	double lifetimeHoursRem = lifetimeSecs / (60 * 60); //convert to hours
	double ujXmitCost= ((uaXmit * msXmit * Vdraw))/(1000); //uj per transmission
	double mahRemaining = ((curVReading - minVReading)* mahCapacity)/(maxVReading - minVReading); //mah of capacity remaining
	double uaAvg = ((mahRemaining * 1000)/lifetimeHoursRem); //avg ma / hour that are available
	double uaAvgActive = (ujSampleCost*numSamples + ujXmitCost*numMsgs)/(Vdraw * sPerSample) + uaActive; //avg ma/h when active
	double dutyCycle = ((uaAvg - uaSleep))/(uaAvgActive - uaSleep); // % of time when we can be active
	double epochDur;

	if (uaAvg < uaSleep)
	    epochDur = -1;
	else {
	    epochDur = (sPerSample * 1000)/(dutyCycle);
	    //if (epochDur < sPerSample * 1000)
	    //	epochDur = sPerSample * 1000;
	}
	
	return (long)epochDur;
    }

    /** Given a sample period (epoch duration) in ms, return a lifetime for the device in seconds.
	Note that lifetime is rounded to the nearest hour
	@param samplePeriodMs Epoch duration, in mS.
	@param curVReading The current voltage of the device in question, in raw ADC units 
	                   (should be between maxVReading and minVReading)
	@param ujSampleCost The (average) cost to obtain a sample from the sensors used in the query (light & temp ~= 90mj)
	@param numSamples The number of samples taken in this query
	@param numMsgs The number of messages sent per epoch
    */
    public static long samplePeriodToLifetime(long samplePeriodMs, long curVReading, long ujSampleCost, long numSamples, long numMsgs) {
	double ujXmitCost= ((uaXmit * msXmit * Vdraw))/(1000); //uj per transmission
	double mahRemaining = ((curVReading - minVReading)* mahCapacity)/(maxVReading - minVReading); //mah of capcity remaining
	double uaAvgActive = (ujSampleCost*numSamples + ujXmitCost*numMsgs)/(Vdraw * sPerSample) + uaActive; //avg ma/h when active
	double dutyCycle = (sPerSample  * 1000)/(samplePeriodMs); //duty cycle given sample period
	double uaAvg = (dutyCycle * (uaAvgActive - uaSleep)) + uaSleep; //avg ma / h we should have
	double lifetimeHoursRem = (mahRemaining * 1000)/uaAvg; //duty cycle that will give this average
	return (long)(lifetimeHoursRem * (60 * 60)); //convert from hours to seconds
    }

    public static void main(String argv[]) {
	long curV = 900;
	long ujSampleCost = 90;
	long numSamples = 1;
	long numMsgs = 1;
	long lifetime1Mo = 80735635; //60 * 60 * 24 * 30;
	long epochDur = lifetimeToSamplePeriod(lifetime1Mo, curV, ujSampleCost, numSamples, numMsgs);
	long compLifetime = samplePeriodToLifetime(epochDur, curV, ujSampleCost, numSamples, numMsgs);


	System.out.println("Lifetime (in secs)= " + lifetime1Mo + ", epochDur = " + epochDur + ", computed lifetime = " + compLifetime);
	
	for (int i = 6000000; i < 6000100; i += 100) {
	    compLifetime = samplePeriodToLifetime(i, curV, ujSampleCost, numSamples, numMsgs);
	    long days = compLifetime / (60 * 60 * 24);
	    long hours = (compLifetime - (days * 24 * 60 * 60)) / (60 * 60);
	    long mins = (compLifetime - (days * 24 * 60 * 60) - (hours * 60 * 60)) / (60);
	    System.out.println("Lifetime (in secs), for sample period = " + i + " = " + compLifetime + "(" + days + " d, " + 
			       hours + " h, " + mins + " m)");
	}
    }

}
