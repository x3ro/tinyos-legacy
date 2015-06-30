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

package isis.nest.acousticlocalization;

public class MoteInfo implements Cloneable 
{
      
    // static attributes
    private  int           moteID;
    private  Position      position = new Position();   // position of center of board
    
    // localization stuff
    private  boolean[]     fixedMask = new boolean[3];   // mask fixed coordinates (x,y,z)
    private  Position      startPosition = null;
   
    public MoteInfo( int moteId )
    {
        this.moteID   = moteId;   
    }
    
    public void setMoteID(int p) {
        this.moteID = p;
    }
    
    public int getMoteID() {
        return this.moteID;
    }

    public void setPosition(Position p) {
        if(p==null) this.position = null;
        else this.position = (Position)p.clone();
    }
    
    public Position getPosition() {
        return this.position;
    }
    public void setFixedMask(boolean[] p) {
        if(p==null) this.fixedMask = null;
        else this.fixedMask = (boolean[])p.clone();
    }
    
    public boolean[] getFixedMask() {
        return this.fixedMask;
    }

    public void setStartPosition(Position p) {
        if(p==null) this.startPosition = null;
        else this.startPosition = (Position)p.clone();
    }
    
    public Position getStartPosition() {
        return this.startPosition;
    }
    
    public boolean isFixed() {
        if(fixedMask[0] && fixedMask[1] && fixedMask[2]) return true;
        else return false;
    }
    
    public boolean hasFixedCoord() {
        if(fixedMask[0] || fixedMask[1] || fixedMask[2]) return true;
        else return false;
    }
    
    
    public void setFixed() {
        fixedMask[0] = true;
        fixedMask[1] = true;
        fixedMask[2] = true;
    }

    public Object clone()
    {
        MoteInfo m = new MoteInfo( moteID );
        m.setPosition(position);
        m.setStartPosition(startPosition);
        m.setFixedMask(fixedMask);
      
        return m;
    }
    
}
