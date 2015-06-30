// $Id: EmpiricalModel.java,v 1.1 2003/10/17 01:53:35 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Phil Levis
 * Date:        October 11 2002
 * Desc:        A radio loss model based off of Alec Woo's empirical data.
 *
 */

/**
 * @author Phil Levis
 */


package net.tinyos.sim;

import java.util.*;

public class EmpiricalModel implements PropagationModel {

    private DataPoint[] packetRecvRates = new DataPoint[22];
    private double[] lossRates = new double[101];
    
    public EmpiricalModel() {
	packetRecvRates[0] = new DataPoint("0.000000e+000",
				  "1.0e-000",
				  "0.1e-009");
	packetRecvRates[1] = new DataPoint("2.0000000e+000",
				  "9.8642857e-001",
				  "3.6313652e-003");
	packetRecvRates[2] = new DataPoint("4.0000000e+000",
				  "9.8338235e-001",
				  "1.0129509e-002");
	packetRecvRates[3] = new DataPoint("6.0000000e+000",
				  "9.7375000e-001",
				  "1.1505927e-002"); 
	packetRecvRates[4] = new DataPoint("8.0000000e+000",
				  "9.6833333e-001",
				  "2.1549195e-002"); 
	packetRecvRates[5] = new DataPoint("1.0000000e+001",
				  "9.6200000e-001",
				  "1.1832160e-002"); 
	packetRecvRates[6] = new DataPoint("1.2000000e+001",
				  "9.3365385e-001",
				  "1.0900970e-001");
	packetRecvRates[7] = new DataPoint("1.4000000e+001",
				  "8.8125000e-001",
				  "1.7237314e-001");
	packetRecvRates[8] = new DataPoint("1.6000000e+001",
				  "6.8909091e-001",
				  "3.4195042e-001");  
	packetRecvRates[9] = new DataPoint("1.8000000e+001",
				  "7.5000000e-001",
				  "3.3297362e-001");  
	packetRecvRates[10] = new DataPoint("2.0000000e+001",
				  "5.9375000e-001",
				  "3.3440393e-001");  
	packetRecvRates[11] = new DataPoint("2.2000000e+001",
				   "5.5714286e-001",
				   "4.1689184e-001");
	packetRecvRates[12] = new DataPoint("2.4000000e+001",
				   "1.9222222e-001",
				   "3.3776176e-001"); 
	packetRecvRates[13] = new DataPoint("2.6000000e+001",
				   "4.5357143e-001",
				   "4.1638038e-001"); 
	packetRecvRates[14] = new DataPoint("2.8000000e+001",
				   "1.1250000e-002",
				   "2.1641010e-002"); 
	packetRecvRates[15] = new DataPoint("3.0000000e+001",
				   "6.5714286e-002",
				   "1.5051103e-001"); 
	packetRecvRates[16] = new DataPoint("3.2000000e+001",
				   "6.4666667e-002",
				   "1.4037535e-001"); 
	packetRecvRates[17] = new DataPoint("3.4000000e+001",
				   "0.0000000e+000",
				   "0.0000000e+000"); 
	packetRecvRates[18] = new DataPoint("3.6000000e+001",
				   "3.0357143e-002",
				   "1.0930663e-001"); 
	packetRecvRates[19] = new DataPoint("3.8000000e+001",
				   "0.0000000e+000",
				   "0.0000000e+000");
	packetRecvRates[20] = new DataPoint("4.0000000e+001",
				   "8.3333333e-004",
				   "2.8867513e-003");
	packetRecvRates[21] = new DataPoint("4.2000000e+001",
				   "0.0000000e+000",
				   "0.0000000e+000"); 
	populateLossRates();
    }

    // These numbers were generated from C program that used the
    // equation below to determine the bit error rates that lead to a
    // given packet loss rate.
    private void populateLossRates() {
	lossRates[0] = 0.000000;
	lossRates[1] = 0.000899;
	lossRates[2] = 0.001576;
	lossRates[3] = 0.002147;
	lossRates[4] = 0.002653;
	lossRates[5] = 0.003114;
	lossRates[6] = 0.003541;
	lossRates[7] = 0.003942;
	lossRates[8] = 0.004322;
	lossRates[9] = 0.004685;
	lossRates[10] = 0.005034;
	lossRates[11] = 0.005370;
	lossRates[12] = 0.005696;
	lossRates[13] = 0.006013;
	lossRates[14] = 0.006322;
	lossRates[15] = 0.006624;
	lossRates[16] = 0.006919;
	lossRates[17] = 0.007209;
	lossRates[18] = 0.007494;
	lossRates[19] = 0.007775;
	lossRates[20] = 0.008052;
	lossRates[21] = 0.008325;
	lossRates[22] = 0.008595;
	lossRates[23] = 0.008863;
	lossRates[24] = 0.009127;
	lossRates[25] = 0.009390;
	lossRates[26] = 0.009650;
	lossRates[27] = 0.009909;
	lossRates[28] = 0.010166;
	lossRates[29] = 0.010422;
	lossRates[30] = 0.010677;
	lossRates[31] = 0.010931;
	lossRates[32] = 0.011184;
	lossRates[33] = 0.011436;
	lossRates[34] = 0.011688;
	lossRates[35] = 0.011940;
	lossRates[36] = 0.012191;
	lossRates[37] = 0.012443;
	lossRates[38] = 0.012694;
	lossRates[39] = 0.012946;
	lossRates[40] = 0.013198;
	lossRates[41] = 0.013451;
	lossRates[42] = 0.013705;
	lossRates[43] = 0.013959;
	lossRates[44] = 0.014214;
	lossRates[45] = 0.014470;
	lossRates[46] = 0.014728;
	lossRates[47] = 0.014986;
	lossRates[48] = 0.015247;
	lossRates[49] = 0.015508;
	lossRates[50] = 0.015772;
	lossRates[51] = 0.016038;
	lossRates[52] = 0.016305;
	lossRates[53] = 0.016575;
	lossRates[54] = 0.016847;
	lossRates[55] = 0.017122;
	lossRates[56] = 0.017400;
	lossRates[57] = 0.017680;
	lossRates[58] = 0.017964;
	lossRates[59] = 0.018251;
	lossRates[60] = 0.018542;
	lossRates[61] = 0.018836;
	lossRates[62] = 0.019135;
	lossRates[63] = 0.019438;
	lossRates[64] = 0.019745;
	lossRates[65] = 0.020058;
	lossRates[66] = 0.020375;
	lossRates[67] = 0.020699;
	lossRates[68] = 0.021028;
	lossRates[69] = 0.021364;
	lossRates[70] = 0.021707;
	lossRates[71] = 0.022058;
	lossRates[72] = 0.022416;
	lossRates[73] = 0.022783;
	lossRates[74] = 0.023159;
	lossRates[75] = 0.023545;
	lossRates[76] = 0.023942;
	lossRates[77] = 0.024351;
	lossRates[78] = 0.024773;
	lossRates[79] = 0.025208;
	lossRates[80] = 0.025660;
	lossRates[81] = 0.026128;
	lossRates[82] = 0.026614;
	lossRates[83] = 0.027122;
	lossRates[84] = 0.027653;
	lossRates[85] = 0.028211;
	lossRates[86] = 0.028798;
	lossRates[87] = 0.029419;
	lossRates[88] = 0.030079;
	lossRates[89] = 0.030786;
	lossRates[90] = 0.031547;
	lossRates[91] = 0.032373;
	lossRates[92] = 0.033279;
	lossRates[93] = 0.034286;
	lossRates[94] = 0.035423;
	lossRates[95] = 0.036736;
	lossRates[96] = 0.038299;
	lossRates[97] = 0.040253;
	lossRates[98] = 0.042902;
	lossRates[99] = 0.047195;
	lossRates[100] = 0.330052;

    }
    
    private DataPoint getClosestFit(double distance) {
	for (int i = 0; i < packetRecvRates.length; i++) {
	    if (distance <= packetRecvRates[i].distance) {
		return packetRecvRates[i];
	    }
	}
	return packetRecvRates[packetRecvRates.length - 1];
    }

    private double sample(DataPoint point) {
	if (point.stdDev < 0.0000001) {return (1.0 - point.mean);}
	// Box-Muller Transformation
	double r1 = Math.random();
	double r2 = Math.random();
	double z = Math.sqrt( -2.0 * Math.log(r1) ) * Math.cos(2.0 * Math.PI * r2);
	double p = Math.max(0.0, (1.0 - (point.mean + (point.stdDev * z))));
	p = Math.min(1.0, p);
	return p;
    }


    private double packetErrorToBitError(double packet) {
	/* The loss table comes from this analysis: The probability of
	 * a packet failing can be decomposed into the probability the
	 * start symbol will not be detected and the probability there
	 * will be a double bit error in a data byte (such that SecDed
	 * can't recover and there will be a CRC error).
	 *
	 * This can be alternatively thought of as the probability of
	 * a packet succeeding (Pr) is the product of the probability the
	 * start symbol is detected correctly (Ps) and the probability
	 * there is not an unrecoverable bit error (Pe). So,
	 *
	 *       Pr = Ps * Pe
	 *
	 * Let Pb be the bit error rate.
	 * 
	 * Ps is simply the probability that there will not be a
	 * single bit error in the start symbol. The start symbol is
	 * nine bits long; the probability that it will be received
	 * correctly is equal to (1 - Pb)^9.
	 *
	 * Pe is the probability that every data byte is received
	 * correctly. There are 36 data bytes, which are in a 3:1
	 * encoding of which one bit in each byte is not examined (a
	 * 21:8 encoding, efffectively). This encoding is composed of
	 * 8 data bits and 13 parity bits. It succeeds if:
	 *
	 * 1) there are no data bit errors, or
	 * 2) there is one data bit error and there are no errors
	 *    in 5 specific parity bits
	 *
	 *
	 * Pe is equal to the probability of zero or one bit errors,
	 * or:
	 *
	 *      (1 - Pb)^8   +   8 * (Pb * (1 - Pb)^7 * (1 - Pb)^5)
	 *      (1 - Pb)^8   +  8 * Pb * (1 - Pb)^12
	 *     (zero errors)          (one error)
	 *
	 *     (((1 - Pb)^8   +  (8 * (1 - Pb)^12)^36
	 *
	 *
	 * The final equation is therefore
	 *
	 *     ((1 - Pb)^8   +  ((8 * Pb * (1 - Pb)^12)^36 * (1 - Pb)^9)
	 *
	 * The table was generated by iterating through bit error
	 * rates at a granularity of .0001% and finding the bit error
	 * rate that best fits a packet error rate.
	 *
	 */
	
	if (packet == 0.0) {return 0.0;}
	int percent = (int)(packet * 100.0);
	if (percent <= 0) {return 0.0;}
	else if (percent >= 100) {return 0.5;}
	else {return lossRates[percent];}
    }

    public double getPacketLossRate(double distance, double scalingFactor) {
	//System.out.println("EmpiricalModel: in sampleLossRate [distance "+distance+"] [radiusConstant "+radiusConstant+"]");
	DataPoint closestFit = getClosestFit(distance * scalingFactor);
	//System.err.println("Generating loss rate for distance of " + distance * radiusConstant + " inches (rounded to " + closestFit.distance + ")");
	double loss = sample(closestFit);
	//System.err.println("Sampled packet loss rate: " + (loss * 100.0) + "%");
	return loss;
    }

    public double getBitLossRate(double packetLossRate) {
	packetLossRate = packetErrorToBitError(packetLossRate);
	//System.err.println("Derived bit error rate: " + (loss * 100.0) + "%");
	return packetLossRate;
    }

    private class DataPoint {
	protected double distance;
	protected double mean;
	protected double stdDev;

	public DataPoint(double distance,
			 double mean,
			 double stdDev) {
	    this.distance = distance;
	    this.mean = mean;
	    this.stdDev = stdDev;
	}

	public DataPoint(String distance,
			 String mean,
			 String stdDev) {
	    Double dis = new Double(distance);
	    Double mn = new Double(mean);
	    Double st = new Double(stdDev);

	    this.distance = dis.doubleValue();
	    this.mean = mn.doubleValue();
	    this.stdDev = st.doubleValue();
	}
    }

    public String toString() {
	return "Empirical";
    }
}
