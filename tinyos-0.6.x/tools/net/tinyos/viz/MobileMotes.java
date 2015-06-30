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
 * This class maintains the list of all the mobile motes
 */
public class MobileMotes extends Hashtable {

  private Hashtable ids = new Hashtable();

  /**
   * Simple constructor that creates an empty mobile motes list
   */
  public MobileMotes() {
    super();
  }

  /**
   * Adds a mobile mote to the list
   *
   * @param mote Mobile mote being added
   */
  public void addMobileMote(MobileMote mote) {
    put(mote.getName(), mote);
    ids.put(new Integer(mote.getId()), mote);
  }

  /**
   * Removes a mobile mote from the list
   *
   * @param mote Mobile mote being removed
   */
  public void removeMote(MobileMote mote) {
    remove(mote.getName());
    ids.remove(new Integer(mote.getId()));
  }

  /**
   * Returns the mobile mote with the given name
   *
   * @param name Name of the mobile mote to return
   * @return Mobile mote with the given name
   */
  public MobileMote getMote(String name) {
    return (MobileMote)get(name);
  }

  /**
   * Returns the mobile mote with the given integer id
   * 
   * @param id Integer id of the mobile mote to return
   * @return Mobile mote with the given id
   */
  public MobileMote getMote(int id) {
    return (MobileMote)ids.get(new Integer(id));
  }

  /**
   * Returns whether the given id has already been used
   *
   * @param id Id to check
   * @return Whether the id has already been used
   */
  public boolean contains(int id) {
    for (Enumeration e = ids.keys(); e.hasMoreElements(); ) {
      int i = ((Integer)e.nextElement()).intValue();
      if (id == i) {
        return true;
      }
    }
    return false;
  }

  /**
   * Sets the name of the mobile mote with the given id
   *
   * @param id Id of the mobile mote for which the name is being changed
   * @param name New name of the mobile mote
   */
  public void setMobileMote(int id, String name) {
     MobileMote mm = getMote(id);
     mm.setName(name);
  }

  /**
   * Returns the number of mobile motes in the list
   *
   * @return Number of mobile motes in the list
   */
  public int numMobileMotes() {
    return size();
  }
}