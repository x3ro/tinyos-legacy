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
 * DistanceMeasurementFileReader.java
 *
 * Created on July 11, 2003, 2:39 PM
 */

package isis.nest.acousticlocalization;

/**
 *
 * @author  sallai
 */
import java.util.*;
import java.io.*;

public class DistanceMeasurementFileReader {
    public static final int FILE_SOURCE = 0;
    public static final int String_SOURCE = 1;
       
    public DoubleList distances[][]    = null;
    public int             moteNum          = 0;
    public Vector          motes            = null;
    public Position        min              = null;
    public Position        max              = null;
    
    private HashMap id2indexMap = new HashMap();    
    
    /** Creates a new instance of DistanceMeasurementFileReader */
    public DistanceMeasurementFileReader() {
    }
    
    /** Creates a new instance of DistanceMeasurementFileReader */
    public DistanceMeasurementFileReader(String s, int source) throws IOException, FileFormatException {
        if(source == FILE_SOURCE) readFromFile(s);
        else readFromString(s);
    }
    
    public DistanceMeasurements getDistanceMeasurements() {
        DistanceMeasurements dm = new DistanceMeasurements();
        dm.setDistances((DoubleList[][])distances.clone());
        dm.setMoteNum(moteNum);
        
        Vector clonedMotes = new Vector(moteNum);
        for(int i=0; i<moteNum; i++) {
            clonedMotes.add(i,((MoteInfo)motes.get(i)).clone());
        }
        
        dm.setMotes(clonedMotes);
        return dm;
    }
    
    public Position getMin() {
        return min;
    }
    
    public Position getMax() {
        return max;
    }
    
    public Vector getMotes() {
        return motes;
    }
    
    public void readFromFile( String filename ) throws IOException, FileFormatException {
        readMotes(new FileReader( filename ));
        readSearchSpaceAndDistances(new FileReader( filename ));
    }

    public void readFromString( String str ) throws IOException, FileFormatException {
        readMotes(new StringReader( str ));
        readSearchSpaceAndDistances(new StringReader( str ));
    }
  
    public void readMotes(Reader reader) throws IOException, FileFormatException {
        int i;
        
        motes               = new Vector();

        
        // first pass: insert motes into motes vector (only id is filled)
        StreamTokenizer st = new StreamTokenizer( reader );
        for( i=0; i<6; ++i ) {
            st.nextToken();
        }
        while( st.ttype != st.TT_EOF ) {
            int moteIds = 2;
            
            // read type: 'pos' or 'dist'

            st.nextToken();
            if( st.ttype == st.TT_EOF )
                break;
            if(st.sval == null) throw new FileFormatException("Error with data format");
            if( st.sval.compareToIgnoreCase( "pos" ) == 0 || st.sval.compareToIgnoreCase( "startpos" ) == 0 )
                moteIds = 1;
            
            // check moteIds, insert if new found
            for( i=0; i<moteIds; ++i ) {
                st.nextToken();
                Integer moteId = new Integer( (int)st.nval );
                if( id2indexMap.get( moteId ) == null ) {
                    MoteInfo mote = new MoteInfo( moteId.intValue() );
                    motes.add( mote );
                    id2indexMap.put( moteId, new Integer(motes.size()-1) );
                }
            }
            st.nextToken();

            if( moteIds == 1 ) {
                st.nextToken();
                st.nextToken();
            }
        }
        reader.close();
        moteNum   = motes.size();
    }
    
    public void readSearchSpaceAndDistances( Reader reader) throws IOException {
        int i,j;
     
        // create distance matrix
        distances = new DoubleList[moteNum][moteNum];
        for( i=0; i<moteNum; ++i )
            for( j=0; j<moteNum; ++j )
                distances[i][j] = new DoubleList();
        
        // second pass
        StreamTokenizer st = new StreamTokenizer( reader );
        
        // read min, max
        min = new Position();
        max = new Position();
        min.read( st );
        max.read( st );
        
        // read mote data
        while( st.ttype != st.TT_EOF ) {
            st.nextToken();
            if( st.ttype == st.TT_EOF )
                break;
            if( st.sval.compareToIgnoreCase( "pos" ) == 0 ) {
                st.nextToken();
                MoteInfo mote = (MoteInfo)motes.get(((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue());
                for( i=0; i<3; ++i ) {
                    st.nextToken();
                    if( st.ttype == StreamTokenizer.TT_NUMBER ) {
                        mote.getFixedMask()[i] = true;
                        mote.getPosition().coord[i] = st.nval;
                    }
                    else
                        mote.getFixedMask()[i] = false;
                }
            }
            else if( st.sval.compareToIgnoreCase( "startpos" ) == 0 ) {
                st.nextToken();
                MoteInfo mote = (MoteInfo)motes.get(((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue());
                mote.setStartPosition(new Position());
                for( i=0; i<3; ++i ) {
                    st.nextToken();
                    mote.getStartPosition().coord[i] = st.nval;
                }
            }
            else if( st.sval.compareToIgnoreCase( "dist" ) == 0 ) {
                st.nextToken();
                int moteind1 = ((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue();
                st.nextToken();
                int moteind2 = ((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue();
                st.nextToken();
                
                //System.out.println("dist "+moteind1+" "+moteind2+" "+st.nval);
                distances[moteind1][moteind2].add(st.nval);
                
            }
            else {
                throw new IOException();
            }
        }
        
        reader.close();
    }
    
    public void read2( Reader reader1,  Reader reader2) throws IOException {
        // file format:
        // minx miny minz
        // maxx maxy maxz
        // 'pos'  moteid1   x1   y1   z1   // coordinate can by 'x' which meens it can must be optimized
        // 'pos'  moteid2   x2   y2   z2
        // ...
        // 'startpos' moteid1   x1  y1  z1
        // ...
        // 'dist' moteid11  motid12    dist1
        // 'dist' moteid21  motid22    dist2
        // ...
        int i,j;
        
        HashMap id2indexMap = new HashMap();
        motes               = new Vector();
        
        // first pass: insert motes into motes vector (only id is filled)
        StreamTokenizer st = new StreamTokenizer( reader1 );
        for( i=0; i<6; ++i )
            st.nextToken();
        while( st.ttype != st.TT_EOF ) {
            int moteIds = 2;
            
            // read type: 'pos' or 'dist'
            st.nextToken();
            if( st.ttype == st.TT_EOF )
                break;
            if( st.sval.compareToIgnoreCase( "pos" ) == 0 || st.sval.compareToIgnoreCase( "startpos" ) == 0 )
                moteIds = 1;
            
            // check moteIds, insert if new found
            for( i=0; i<moteIds; ++i ) {
                st.nextToken();
                Integer moteId = new Integer( (int)st.nval );
                if( id2indexMap.get( moteId ) == null ) {
                    MoteInfo mote = new MoteInfo( moteId.intValue() );
                    motes.add( mote );
                    id2indexMap.put( moteId, new Integer(motes.size()-1) );
                }
            }
            st.nextToken();
            if( moteIds == 1 ) {
                st.nextToken();
                st.nextToken();
            }
        }
        reader1.close();
        
        // create distance matrix
        moteNum   = motes.size();
        distances = new DoubleList[moteNum][moteNum];
        for( i=0; i<moteNum; ++i )
            for( j=0; j<moteNum; ++j )
                distances[i][j] = new DoubleList();
        
        // second pass
        st = new StreamTokenizer( reader2 );
        
        // read min, max
        min = new Position();
        max = new Position();
        min.read( st );
        max.read( st );
        
        // read mote data
        while( st.ttype != st.TT_EOF ) {
            st.nextToken();
            if( st.ttype == st.TT_EOF )
                break;
            if( st.sval.compareToIgnoreCase( "pos" ) == 0 ) {
                st.nextToken();
                MoteInfo mote = (MoteInfo)motes.get(((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue());
                for( i=0; i<3; ++i ) {
                    st.nextToken();
                    if( st.ttype == StreamTokenizer.TT_NUMBER ) {
                        mote.getFixedMask()[i] = true;
                        mote.getPosition().coord[i] = st.nval;
                    }
                    else
                        mote.getFixedMask()[i] = false;
                }
            }
            else if( st.sval.compareToIgnoreCase( "startpos" ) == 0 ) {
                st.nextToken();
                MoteInfo mote = (MoteInfo)motes.get(((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue());
                mote.setStartPosition(new Position());
                for( i=0; i<3; ++i ) {
                    st.nextToken();
                    mote.getStartPosition().coord[i] = st.nval;
                }
            }
            else if( st.sval.compareToIgnoreCase( "dist" ) == 0 ) {
                st.nextToken();
                int moteind1 = ((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue();
                st.nextToken();
                int moteind2 = ((Integer)id2indexMap.get(new Integer((int)st.nval))).intValue();
                st.nextToken();
                
                //System.out.println("dist "+moteind1+" "+moteind2+" "+st.nval);
                distances[moteind1][moteind2].add(st.nval);
                
            }
            else {
                throw new IOException();
            }
        }
        
        reader2.close();
        // fill the fixed flag
        for( i=0; i<moteNum; ++i ) {
            MoteInfo m = (MoteInfo)motes.get(i);
        }
    }
    
}
