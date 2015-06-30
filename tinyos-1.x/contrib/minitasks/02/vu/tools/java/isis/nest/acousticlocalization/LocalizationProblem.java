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
 * Created on Apr 3, 2003
 *
 * To change the template for this generated file go to
 * Window>Preferences>Java>Code Generation>Code and Comments
 */
package isis.nest.acousticlocalization;

import java.io.*;
import java.util.*;

/**
 * @author bogyom
 *
 * To change the template for this generated type comment go to
 * Window>Preferences>Java>Code Generation>Code and Comments
 */
public class LocalizationProblem {
    public int          moteNum     = 0;
    public Vector       motes       = null;
    public double[][]   distances   = null;
    public int[][]      measurementCount = null;
    public Position     min         = null;
    public Position     max         = null;
    
    private Random      rand        = new Random();
    
    //public    double                   m_radius;
    
    public Object clone() {
        LocalizationProblem lp = new LocalizationProblem();
        lp.moteNum = moteNum;
        
        lp.motes = new Vector(moteNum);
        for(int i=0; i<moteNum; i++) {
            lp.motes.add(i,((MoteInfo)motes.get(i)).clone());
        }
        //lp.motes = (Vector)motes.clone();
        
        lp.distances = (double[][])distances.clone();
            /*lp.distances = new double[moteNum][moteNum];
            for (int i=0; i< moteNum; i++)
                for (int j=0; j< moteNum; j++)
                    lp.distances[i][j] = distances[i][j];*/
        
        if(lp.measurementCount!=null) lp.measurementCount = (int[][])measurementCount.clone();
        lp.min = (Position)min.clone();
        lp.max = (Position)max.clone();
        return lp;
    }
    
    public int neighborCount(int moteIndex) {
        int rval = 0;
        
        for( int j=0; j<moteNum; j++) {
            if(distances[moteIndex][j]>0) rval++;
        }
        return rval;
    }
    
    public MoteInfo getMoteInfoByID(int moteID) {
        for(int i=0; i<motes.size(); i++) {
            if(((MoteInfo)motes.get(i)).getMoteID() == moteID) return (MoteInfo)motes.get(i);
        }
        return null;
    }
    
    public int getMoteIndexByID(int moteID) {
        for(int i=0; i<motes.size(); i++) {
            if(((MoteInfo)motes.get(i)).getMoteID() == moteID) return i;
        }
        return -1;
    }

    public void removeMotesWithLessThan3Neighbor() {
        int oldMoteNum;
        
        do {
            oldMoteNum = motes.size();
            removeMotesWithLessThan3Neighbors();
        } while(oldMoteNum!=moteNum);
    }
    
    public void removeMotesWithLessThan3Neighbors() {
        
        // build a new vector of motes
        Vector newMotes = new Vector();
        for(int i=0; i<moteNum; i++) {
            if(neighborCount(i)>2) {
                newMotes.add(motes.get(i));
            }
        }
        
        // build a new table of distances
        double[][] newDistances = new double[newMotes.size()][newMotes.size()];
        for(int i=0; i<newMotes.size(); i++) {
            for(int j=0; j<newMotes.size(); j++) {
                    newDistances[i][j] = distances[getMoteIndexByID(((MoteInfo)newMotes.get(i)).getMoteID())][getMoteIndexByID(((MoteInfo)newMotes.get(j)).getMoteID())];
            }
        }
       
        distances = newDistances;
        motes = newMotes;
        moteNum = motes.size();
    }
        
    public void random() {
        for( int i=0; i<moteNum; ++i ) {
            MoteInfo m = (MoteInfo)motes.get(i);
            if( m.getStartPosition() != null ) {
                m.setPosition(m.getStartPosition());
            }
            else {
                for( int j=0; j<3; ++j )
                    if( !m.getFixedMask()[j] )
                        m.getPosition().coord[j] = min.coord[j] + rand.nextDouble() * (max.coord[j]-min.coord[j]);
            }
        }
    }
    
    public double calcDistanceError( Vector motes ) {
        int i,j;
        double avg = 0;
        double max = 0;
        int    n   = 0;
        int    m1  = 0;
        int    m2  = 0;
        for( i=0; i<moteNum-1; ++i ) {
            for( j=i+1; j<moteNum; ++j ) {
                if( distances[i][j] > 0 ) {
                    MoteInfo mote1 = (MoteInfo)motes.get(i);
                    MoteInfo mote2 = (MoteInfo)motes.get(j);
                    double d = Math.abs(distances[i][j] - mote1.getPosition().calcDistance(mote2.getPosition()));
                    /*if( d > max )
                    {
                        max = d;
                        m1 = i;
                        m2 = j;
                    }*/
                    avg += d;
                    n++;
                }
            }
        }
        avg /= n;
        //System.out.println( max + "\t" + avg + "\t" + m1 + "\t" + m2 );
        return avg;
    }
    
    public double calcDistanceError2() {
        int i,j;
        double avg = 0;
        double max = 0;
        double n   = 0;
        int    m1  = 0;
        int    m2  = 0;
        double weight;
        for( i=0; i<moteNum-1; ++i ) {
            for( j=i+1; j<moteNum; ++j ) {
                if( distances[i][j] > 0 ) {
                    MoteInfo mote1 = (MoteInfo)motes.get(i);
                    MoteInfo mote2 = (MoteInfo)motes.get(j);
                    double d = Math.abs(distances[i][j] - mote1.getPosition().calcDistance(mote2.getPosition()));
                    if( d > max ) {
                        max = d;
                        m1 = i;
                        m2 = j;
                    }
                    weight = 1.0; //errorWeight(i, j);
                    avg += d * weight;
                    n+=weight;
                }
            }
        }
        avg /= n;
        //System.out.println( max + "\t" + avg + "\t" + m1 + "\t" + m2 );
        //System.out.println( avg );
        return avg;
    }
  
    /*
    public double errorWeight(int m1, int m2) {
        MoteInfo mote1 = (MoteInfo)motes.get(m1);
        MoteInfo mote2 = (MoteInfo)motes.get(m2);
        
        if(m1==m2) return 0.0;
        if(mote1.isFixed() && mote2.isFixed()) return 1.0;
        if(mote1.isFixed() || mote2.isFixed()) return 2.0;
        
        return 1.0;
    }
    */
    
    /*
    public int fixPointsIn2Hops(int m) {
        int rval = 0;
        for(int i=0; i<moteNum; i++)
            if(distances[m][i]>0 && ((MoteInfo)motes.get(i)).fixed) rval++;
        return rval;
    }
    */
    public double calcDistanceErrorOfOneMote( int moteInd ) {
        int    i;
        double avg = 0;
        double    n   = 0;
        MoteInfo mote = (MoteInfo)motes.get(moteInd);
        for( i=0; i<moteNum-1; ++i ) {
            if( distances[i][moteInd] > 0 ) {
                MoteInfo mote2 = (MoteInfo)motes.get(i);
                double d = Math.abs(distances[i][moteInd] - mote.getPosition().calcDistance(mote2.getPosition()));
                avg += d;
                n++;
            }
        }
        avg /= n;
        return avg;
    }
    
    double power( double distance ) {
        return 2 / ( 1 + Math.exp(distance) ) - 1;
    }
    
        /*public void solve( int n )
        {
                double s = 5;
         
                for( int i=0; i<n; ++i )
                {
                        double learningrate = s * Math.pow( 0.0001/s, i/(double)n );
                        step( learningrate );
                        if( i%100 == 0 )
                        {
                                //v.update( solv );
                                calcDistanceError();
                        }
                }
        }*/
    
    public void step( double alpha ) {
        /*step1( alpha );
        step2( alpha );
        step2( alpha );*/
        step1( alpha );
        //step1( alpha );
        //step1( alpha );
        //step2( alpha );
    }
    
    public void step1( double alpha ) {
        double beta   = alpha * min.calcDistance(max);
        int    altNum = 20;
        Vector org    = motes;
        Vector best   = motes;
        double bestError = calcDistanceError(motes);
        for( int i=0; i<altNum; ++i ) {
            Vector newPos = new Vector();
            for( int j=0; j<moteNum; ++j ) {
                MoteInfo orgMote = (MoteInfo)org.get(j);
                MoteInfo m = (MoteInfo)orgMote.clone(); //MoteInfo( orgMote.moteID );//
                newPos.add( m );
                //if( rand.nextDouble() > 0.7 )
                {
                    for( int k=0; k<3; ++k ) {
                        if( !m.getFixedMask()[k] ) {
                            m.getPosition().coord[k] += beta * rand.nextGaussian();
                            if( m.getPosition().coord[k] < min.coord[k] )
                                m.getPosition().coord[k] = min.coord[k];
                            if( m.getPosition().coord[k] > max.coord[k] )
                                m.getPosition().coord[k] = max.coord[k];
                        }
                    }
                }
            }
            double error = calcDistanceError(newPos);
            if( error < bestError ) {
                bestError = error;
                best = newPos;
            }
        }
        motes = best;
    }
    
    public void step2( double alpha ) {
        double beta = alpha * min.calcDistance(max);
        
        // select a random mote
        int      moteInd = rand.nextInt( moteNum );
        MoteInfo mote    = (MoteInfo)motes.get(moteInd);
        if( mote.isFixed() )
            return;
        
        // create randomly changed positions (include the original one)
        int i,j,k;
        Position bestPos = mote.getPosition();
        double bestError = calcDistanceErrorOfOneMote(moteInd);
        for( i=0; i<5; ++i ) {
            Position newPos = new Position();
            for( j=0; j<3; ++j ) {
                newPos.coord[j] = mote.getPosition().coord[j] + beta * rand.nextGaussian();
                if( newPos.coord[j] < min.coord[j] )
                    newPos.coord[j] = min.coord[j];
                if( newPos.coord[j] > max.coord[j] )
                    newPos.coord[j] = max.coord[j];
            }
            mote.setPosition(newPos);
            double error = calcDistanceErrorOfOneMote(moteInd);
            if( error < bestError ) {
                bestError = error;
                bestPos = newPos;
            }
        }
        mote.setPosition(bestPos);
    }
    
    public void step3( double alpha ) {
        // select a random mote
        int      moteInd = rand.nextInt( moteNum );
        MoteInfo mote    = (MoteInfo)motes.get(moteInd);
        
        double dx = 0;
        double dy = 0;
        for( int i=0; i<moteNum; ++i ) {
            if( i != moteInd ) {
                double measuredDist = distances[moteInd][i];
                if( measuredDist > 0 && rand.nextDouble() > 0.8 ) {
                    MoteInfo m = (MoteInfo)motes.get(i);
                    double dist = mote.getPosition().calcDistance(m.getPosition());
                    
                    // calculate power
                    double pow = power( measuredDist - dist );
                    if( m.isFixed() )   // weight up fixed motes
                        pow *= 4;
                    
                    for( int j=0; j<3; ++j ) {
                        if( !mote.getFixedMask()[j] ) {
                            mote.getPosition().coord[j] += alpha * pow * (m.getPosition().coord[j] - mote.getPosition().coord[j]);
                            if( mote.getPosition().coord[j] < min.coord[j] )
                                mote.getPosition().coord[j] = min.coord[j];
                            if( mote.getPosition().coord[j] > max.coord[j] )
                                mote.getPosition().coord[j] = max.coord[j];
                        }
                    }
                }
            }
        }
    }
}

