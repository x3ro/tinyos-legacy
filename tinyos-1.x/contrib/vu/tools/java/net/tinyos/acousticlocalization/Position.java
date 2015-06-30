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

package net.tinyos.acousticlocalization;

import java.util.Random;
import java.text.NumberFormat;
import java.io.StreamTokenizer;
import java.io.IOException;

public class Position implements Cloneable
{
    public double coord[] = new double[3];
    
    public Position()    
    {
        coord[0] = 0;
        coord[1] = 0;
        coord[2] = 0;
    }    
        
    public Position( double x, double y, double z )
    {
        coord[0] = x;
        coord[1] = y;
        coord[2] = z;
    }
    
    public double getX()
    {
        return coord[0];
    }
    
    public double getY()
    {
        return coord[1];
    }
    
    public double getZ()
    {
        return coord[2];
    }
    
    public void setX(double c) {
        coord[0] = c;
    }
    
    public void setY(double c) {
        coord[1] = c;
    }
    
    public void setZ(double c) {
        coord[2] = c;
    }
    
    public Position( Position min, Position max, Random rand )
    {
        generateRandom( min, max, rand );
    }
    
    public Object clone()
    {
        Position newPos = new Position();
        for( int i=0; i<3; ++i )
            newPos.coord[i] = coord[i];
        return newPos;
    }
    
    public void generateRandom( Position min, Position max, Random rand )
    {
        for( int i=0; i<3; ++i )
            coord[i] = min.coord[i] + rand.nextDouble() * (max.coord[i]-min.coord[i]);
    }
    
    public double calcDistance( Position p )
    {   
        double d = 0;
        for( int i=0; i<3; ++i )
            d += (p.coord[i] - coord[i]) * (p.coord[i] - coord[i]); 
        return Math.sqrt(d);     
    }
    
    public double calcDistance2D( Position p )
    {   
        double d = 0;
        for( int i=0; i<2; ++i )
            d += (p.coord[i] - coord[i]) * (p.coord[i] - coord[i]); 
        return Math.sqrt(d);     
    }
    
    public void add( Position p, double alfa )
    {
        for( int i=0; i<3; ++i )
            coord[i] += alfa * p.coord[i]; 
    }
    
    public void read( StreamTokenizer st ) throws IOException
    {
        for( int i=0; i<3; ++i )
        {
            st.nextToken();
            coord[i] = st.nval;
        }
    }
    
    public String toString()
    {
        NumberFormat nf = NumberFormat.getInstance();
        nf.setMaximumFractionDigits(2);
        return "(" + nf.format(coord[0]) + "," + nf.format(coord[1]) + "," + nf.format(coord[2]) + ")";
    }
    
    public String toString2()
    {
        return "" + coord[0] + "\t" + coord[1] + "\t" + coord[2];
    }        
}
