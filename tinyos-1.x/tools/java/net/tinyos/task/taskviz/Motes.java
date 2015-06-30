/*
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


package net.tinyos.task.taskviz;

import java.util.Hashtable;
import java.util.Vector;
import java.util.Enumeration;

/**
 * This class maintains the list of all the static motes
 */
public class Motes extends Hashtable {

  private Hashtable ids = new Hashtable();
  private boolean needSave = false;

  /**
   * Simple constructor that creates an empty motes list
   */
  public Motes() {
    super();
  }

  /**
   * Adds a mote to the list
   *
   * @param mote Mote being added
   */
  public void addMote(Mote mote) {
    put(mote.getEllipse(), mote);
    ids.put(new Integer(mote.getId()), mote);
    needSave = true;
  }

  /**
   * Removes a mote from the list
   *
   * @param mote Mote being removed
   */
  public void removeMote(Mote mote) {
    remove(mote.getEllipse());
    ids.remove(new Integer(mote.getId()));
    needSave = true;
  }

  /**
   * Returns the number of motes in the list
   *
   * @return Number of motes in the list
   */
  public int numMotes() {
    return size();
  }

  /**
   * Returns whether the given id has already been used
   *
   * @param id Id to check
   * @return Whether the id has already been used
   */
  public boolean idExists(int id) {
    return ids.containsKey(new Integer(id));
  }

  /**
   * Returns the mote with the given integer id
   * 
   * @param id Integer id of the mote to return
   * @return Mote with the given id
   */
  public Mote getMote(int id) {
    for (Enumeration e=elements(); e.hasMoreElements(); ) {
      Mote m = (Mote)e.nextElement();
      if (m.getId() == id) {
        return m;
      }
    }
    return null;
//    return (Mote)ids.get(new Integer(id));
  }

  /**
   * This method should be called when the motes list has been saved
   */
  public void saved() {
    needSave = false;
  }

  /**
   * This method indicates whether the motes list needs saving or not
   * 
   * @return Whether the motes list needs saving or not
   */
  public boolean needsSave() {
    return needSave;
  }
}
