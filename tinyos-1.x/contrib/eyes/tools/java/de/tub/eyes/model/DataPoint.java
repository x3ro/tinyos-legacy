/*
 * Created on Sep 22, 2004 by Joachim Praetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.model;

/**
 * This models a Piece of data from a timeline. Therefor this class holds an x and a y value,
 * tigether witth an identifier to which data series it belongs (so multiple data series can be
 * represented by this object).
 * 
 * @author Joachim Praetorius
 *  
 */
public class DataPoint {
    private int dataSet;
    private double x, y;

    /** Empty Constructor */
    public DataPoint() {
    }

    /**
     * Creates a new DataPoint with the given values.
     * @param dataSet The data series the values belong to 
     * @param x The x value
     * @param y The y value
     */
    public DataPoint(int dataSet, double x, double y) {
        super();
        this.dataSet = dataSet;
        this.x = x;
        this.y = y;
    }

    /**
     * Returns the number of the data series this DataPoint belongs to.
     * @return the number of the data series
     */
    public int getDataSet() {
        return dataSet;
    }

    /**
     * Sets the DataSeries thisd DataPoint belongs to.
     * @param dataSet The number of the new data series
     */
    public void setDataSet(int dataSet) {
        this.dataSet = dataSet;
    }

    /**
     * Returns the x value
     * @return the value of x
     */
    public double getX() {
        return x;
    }

    /**
     * Sets the x value
     * @param x the new x value
     */
    public void setX(double x) {
        this.x = x;
    }

    /**
     * Returns the y value
     * @return the value of y
     */
    public double getY() {
        return y;
    }

    /**
     * Sets the y value
     * @param y the new y value
     */
    public void setY(double y) {
        this.y = y;
    }

    /**
     * Prints the Contents of the DataPoint as a String.
     * The String looks like: <pre>($DATASERIES |($X,$Y))</pre>.
     * @see java.lang.Object#toString()
     */
    public String toString() {
        StringBuffer buffer = new StringBuffer();
        buffer.append("(");
        buffer.append(dataSet);
        buffer.append("|(");
        buffer.append(x);
        buffer.append(",");
        buffer.append(y);
        buffer.append("))");
        return buffer.toString();

    }

}