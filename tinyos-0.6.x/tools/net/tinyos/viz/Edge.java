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

import edu.umd.cs.jazz.component.ZLine;

/**
 * This class represents and renders the edge between two mobile motes.
 * Currently it is being used by the SocialNetwork class
 */
public class Edge extends ZLine {

  private MobileMote from;
  private MobileMote to;
  private double weight;

  // creates mote centered at x, y
  /**
   * Constructor that creates an edge between two mobile motes, but does not render it
   *
   * @param m1 The source mobile mote
   * @param m2 The destination mobile mote
   * @param d The weight of the connection or edge between the mobile motes
   */
  public Edge(MobileMote m1, MobileMote m2, double d) {
    super();
    from = m1;
    to = m2;
    weight = d;
  }

  /**
   * Returns the source mobile mote
   *
   * @return Source mobile mote
   */
  public MobileMote getFromMote() {
    return from;
  }

  /**
   * Returns the destination mobile mote
   *
   * @return Destination mobile mote
   */
  public MobileMote getToMote() {
    return to;
  }

  /**
   * Returns the weight of the connection or edge between the mobile motes
   *
   * @return Weight of the connection or edge between the mobile motes
   */
  public double getWeight() {
    return weight;
  }

  /**
   * Sets the weight of the connection or edge between the mobile motes
   *
   * @param w Weight of the connection or edge between the mobile motes
   */
  public void setWeight(double w) {
    weight = w;
  }

  /**
   * Renders the edge on the screen with pen width 1.0
   */
  public void move() {
    setPenWidth(1.0);
    setLine(from.getX(), from.getY(), to.getX(), to.getY());
  }

  /**
   * Hides the edge on the screen by setting pen width to 0.0
   */
  public void hide() {
    setPenWidth(0.0);
  }
}