// $Id: DiscModel.java,v 1.1 2003/10/17 01:53:35 mikedemmer Exp $

package net.tinyos.sim;

public class DiscModel implements PropagationModel {
  private double radius;

  public DiscModel(double radius) {
    this.radius = radius;
  }

  public double getPacketLossRate(double distance, double scalingFactor) {
    if (distance * scalingFactor <= radius) return 0.0;
    else return 1.0;
  }

  public double getBitLossRate(double packetLossRate) {
    return packetLossRate;
  }
  
  public String toString() {
    return "Fixed radius ("+radius+")";
  }
    
}
