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

import java.util.Vector;

/**
 * This class maintains the list of all the edges between mobile motes
 */
public class Edges extends Vector {

  private double maxWeight = Double.MIN_VALUE;
  private double minWeight = Double.MAX_VALUE;

  /**
   * Simple constructor that creates an empty edges list
   */
  public Edges() {
    super();
  }

  /**
   * Simple constructor that sets creates an empty edges list with a default initial size
   *
   * @param size Default initial size of the edges list
   */
  public Edges(int size) {
    super(size);
  }

  /**
   * Adds an edge to the edges list
   *
   * @param e Edge being added
   */
  public void addEdge(Edge e) {
    // adjust maximum and minimum weights for the edges
    if (e.getWeight() > maxWeight) {
      maxWeight = e.getWeight();
    }
    if (e.getWeight() < minWeight) {
      minWeight = e.getWeight();
    }
    addElement(e);
  }

  /**
   * Adds an edge to the edges list
   *
   * @param from Source mobile mote
   * @param to Destination mobile mote
   * @param weight Weight of the edge between the mobile motes
   */
  public void addEdge(MobileMote from, MobileMote to, double weight) {
    addEdge(new Edge(from, to, weight));
  }

  /**
   * Returns the number of edges in the list
   *
   * @return Number of edges in the list
   */
  public int numEdges() {
    return size();
  }

  /**
   * Sets the minimum edge weight in the list
   *
   * @param weight Minimum edge weight
   */
  public void setMinWeight(double weight) {
    minWeight = weight;
  }

  /**
   * Returns the minimum edge weight in the list
   *
   * @return Minimum edge weight
   */
  public double getMinWeight() {
    return minWeight;
  }

  /**
   * Returns the maximum edge weight in the list
   *
   * @return Maximum edge weight
   */
  public double getMaxWeight() {
    return maxWeight;
  }

  /**
   * Normalizes the edge weights to be a number between 50 and 250
   */
  public void normalize() {
    for (int i=0; i<size(); i++) {
      Edge e = (Edge)elementAt(i);
      double weight = (maxWeight - e.getWeight()) / (maxWeight - minWeight);
      weight = weight * 200.0 +50.0;
      e.setWeight(weight);
    }
  }
}