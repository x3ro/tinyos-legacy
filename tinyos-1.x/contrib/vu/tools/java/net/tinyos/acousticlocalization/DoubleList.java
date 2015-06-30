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

import java.util.ArrayList;
public class DoubleList implements Cloneable {
    private ArrayList list = new ArrayList();
    
    public DoubleList() {}
    
    public DoubleList(double[] l) {
        for(int i=0; i<l.length; i++) add(l[i]);
    }
    
    public double get(int i) {
        return ((Double)list.get(i)).doubleValue();
    }
    
    public void add(double d) {
        list.add(new Double(d));
    }
    
    public int size() {
        return list.size();
    }
    
    public double[] toArray() {
        double[] rval = new double[size()];
        for(int i=0; i<size(); i++) rval[i] = get(i);
        return rval;
    }

     public String toString() {
        String rval = new String();
        for(int i=0; i<size(); i++) rval = rval+get(i)+" ";
        return rval;
    }
}
