// $Id: DiscModel.java,v 1.3 2003/12/26 21:04:44 scipio Exp $

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

  public double getInterferenceRange() {
    return radius;
  }
  
  public String toString() {
    return "Fixed radius ("+radius+")";
  }
    
}
