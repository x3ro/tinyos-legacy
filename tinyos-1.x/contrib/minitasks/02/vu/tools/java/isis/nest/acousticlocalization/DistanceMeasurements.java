/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
/*
 * DistanceMeasurements.java
 *
 * Created on July 11, 2003, 10:37 AM
 */

package isis.nest.acousticlocalization;

/**
 *
 * @author  sallai
 */
import java.io.*;
import java.util.*;

public class DistanceMeasurements {
    
    public DoubleList distances[][]    = null;
    public int             moteNum          = 0;
    public Vector          motes            = null;
    
    /** Creates a new instance of DistanceMeasurements */
    public DistanceMeasurements() {
    }
    
    public void setMoteNum(int moteNum) {
        this.moteNum = moteNum;
    }
    
    public void setDistances(DoubleList[][] distances) {
        this.distances = distances;
    }
    
    public void setMotes(Vector motes) {
        this.motes = motes;
    }
    
    
    public int neighborCount(int moteIndex) {
        int rval = 0;

        for( int j=0; j<moteNum; j++) {
            // as actuator
            if(distances[moteIndex][j].size()>0) rval++;
            // as sensor
            if(distances[j][moteIndex].size()>0) rval++;
        }
        
        return rval;
    }
    
    public double avg(double[] list) {
        double rval = 0;
        for(int i=0; i<list.length; i++) rval+=list[i];
        return rval/list.length;
    }
    
    public double variance(double[] list) {
        if(list.length < 2) return 0;
        double avg = avg(list);
        double rval = 0;
        for(int i=0; i<list.length; i++) rval+=(list[i] - avg)*(list[i] - avg);
        return rval/(list.length - 1);
    }
    
    public double stddev(double[] list) {
        return Math.sqrt(variance(list));
    }
    
    public double[] dropOutliers(double[] list) {
        if (list.length == 0) return list;
        
        System.out.println();
        for(int i=0; i<list.length; i++) System.out.print(" "+list[i]);
        System.out.println();
        
        double avg = avg(list);
        double dev = stddev(list);
        System.out.println("avg="+avg);
        System.out.println("stddev="+dev);
        double[] tmp = new double[list.length];
        int j = 0;
        
        for(int i=0; i<list.length; i++)
            if(Math.abs(list[i]-avg)<=dev) tmp[j++] = list[i];
        
        double[] rval = new double[j];
        System.arraycopy(tmp,0,rval,0,j);
        
        for(int i=0; i<rval.length; i++) System.out.print(" "+rval[i]);
        System.out.println();
        return rval;
    }
    
    public void dropOutliers() {
        for(int i=0; i<moteNum; i++)
            for(int j=0; j<moteNum; j++)
        {
            distances[i][j] = new DoubleList(dropOutliers(distances[i][j].toArray()));
        }
    }
    
    public void removePointsWithLessThan3Neighbors() {
        Vector newMotes = new Vector();
        for(int i=0; i<moteNum; i++) {
            if(neighborCount(i)>2) {
                newMotes.add(motes.get(i));
            } else {
                System.out.println("Removing mote "+i);
                // remove data about mote i from the new distances table
                for(int j=i+1; j<moteNum; j++)
                    for(int k=0; k<moteNum; k++) {
                        distances[j-1][k] = distances[j][k];
                    }
                
                for(int k=i+1; k<moteNum; k++)
                    for(int j=0; j<moteNum; j++) {
                        distances[j][k-1] = distances[j][k];
                    }
            }
        }
        motes = newMotes;
        moteNum = motes.size();
    }

    public double[][] getSymmetricDistancesArray() {
        double[][] rval = new double[moteNum][moteNum];
        for(int i=0; i<moteNum; i++) {
            rval[i][i] = -1;
            for(int j=i+1; j<moteNum; j++) {
                double avgij = avg(distances[i][j].toArray());
                double avgji = avg(distances[j][i].toArray());
                int values = 0;
                rval[i][j] = 0;
                if(!Double.isNaN(avgij)) {
                    rval[i][j] += avgij;
                    values++;
                }
                
                if(!Double.isNaN(avgji)) {
                    rval[i][j] += avgji;
                    values++;
                }
                
                if(values==0) 
                    rval[i][j] = -1;
                else
                    rval[i][j] /= values;
                
                rval[j][i] = rval[i][j];
                //System.out.print("i="+i+" j="+j+" distances={"+distances[i][j]+"} avg="+avg(distances[i][j].toArray())+" distances={"+distances[j][i]+"} avg="+avg(distances[j][i].toArray())+",");
                //System.out.print("i="+i+" j="+j+" distances={"+distances[i][j]+"} distances={"+distances[j][i]+" rval="+rval[i][j]+"}"+",");
                //System.out.print(" i="+i+" j="+j);
                //System.out.print(" avgij="+avgij);
                //System.out.print(" avgji="+avgji);
                //System.out.print(" values="+values);
                //System.out.print(" rval[i][j]="+rval[i][j]);
            }
            //System.out.println();
        }
        return rval;
    }
}


