/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2002 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.viz;

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