package edu.mit.mers.localization;

/**
 * The Locator interface should be implemented by a class that can return the
 * location of a rover. The location socket server requires a Locator to
 * determine the location of a rover requested by a client. The class must
 * define a single method called getLocation that takes as its only argument a
 * rover name String and returns a String containing the position information.
 */
public interface Locator {
	
	/**
	 * This method is called by a class that needs to locate a rover, passing
	 * the name of the rover as the argument. If the Locator does not know the
	 * location of the rover, this method must return an empty String. If the
	 * position of the rover is known, this method must return a String of the
	 * form "X[x co-ordinate]Y[y co-ordinate]P[orientation]"
	 * (e.g. "X0.134Y0.755P0.0").
	 */
	public String getLocation(String roverName);
}
