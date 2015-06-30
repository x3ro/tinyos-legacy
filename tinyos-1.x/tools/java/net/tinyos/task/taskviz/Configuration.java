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

import net.tinyos.task.taskapi.TASKClientInfo;
import java.io.ByteArrayOutputStream;
import java.io.ByteArrayInputStream;
import java.io.DataOutputStream;
import java.io.DataInputStream;
import java.io.IOException;
import javax.swing.JFileChooser;
import java.io.File;

/**
 * This class holds the configuration information for a sensor network deployment
 */
public class Configuration {

  public static final String CONFIGURATION = "CONFIGURATION";

  private boolean needSave = false;
  private String name;
  private String imageName = null;
  private int imageHeight;
  private int imageWidth;
  private int minPixelX, minPixelY, maxPixelX, maxPixelY;
  private double minRealX, minRealY, maxRealX, maxRealY;

  /**
   * Empty constructor
   */
  public Configuration() {
  }

  /**
   * This constructor stores all the incoming parameters
   *
   * @param name Name of the configuration
   * @param imageName Name of the background image to render, if any
   * @param imageWidth Width of the image or background space to render onto
   * @param imageHeight Height of the image or background space to render onto
   * @param minPixelX Minimum pixel x coordinate to allow data to be rendered onto
   * @param minPixelY Minimum pixel y coordinate to allow data to be rendered onto
   * @param maxPixelX Maximum pixel x coordinate to allow data to be rendered onto
   * @param maxPixelY Maximum pixel y coordinate to allow data to be rendered onto
   * @param minRealX Minimum real world x coordinate to allow data to be rendered onto
   * @param minRealY Minimum real world y coordinate to allow data to be rendered onto
   * @param maxRealX Maximum real world x coordinate to allow data to be rendered onto
   * @param maxRealY Maximum real world y coordinate to allow data to be rendered onto
   */
  public Configuration(String name, String imageName, int imageWidth, int imageHeight, int minPixelX, int minPixelY, int maxPixelX,
                       int maxPixelY, double minRealX, double minRealY, double maxRealX, double maxRealY) {
    this.name = name;
    this.imageName = imageName;
    this.minPixelX = minPixelX;
    this.minPixelY = minPixelY;
    this.maxPixelX = maxPixelX;
    this.maxPixelY = maxPixelY;
    this.minRealX = minRealX;
    this.minRealY = minRealY;
    this.maxRealX = maxRealX;
    this.maxRealY = maxRealY;
    this.imageWidth = imageWidth;
    this.imageHeight = imageHeight;
  }

  /**
   * This method should be called when the configuration has been saved
   */
  public void saved() {
    needSave = false;
  }
 
  /**
   * This method indicates whether the current configuration has been saved or not
   *
   * @return true if the configuration needs saving or false if it does not
   */
  public boolean needsSave() {
    return needSave;
  }

  /**
   * This method should be called when a change has been made to the configuration
   */
  public void notSaved() {
    needSave = true;
  }

  /**
   * This method returns the name of the background image
   *
   * @return Name of the background image
   */
  public String getImageName() {
    return imageName;
  }

  /**
   * This method sets the name of the background image
   *
   * @param image Name of the background image
   */
  public void setImageName(String image) {
    imageName = image;
  }

  /**
   * This method returns whether a blank background image is being used
   *
   * @return true if a blank background image is being used
   */
  public boolean useBlankImage() {
    return ((imageName == null) || (imageName.equals("null")) || (imageName.length() ==0));
  }

  /**
   * This method returns the name of the configuration
   *
   * @return Name of the configuration
   */
  public String getName() {
    return name;
  }

  /**
   * This method sets the name of the configuration
   *
   * @param name Name of the configuration
   */
  public void setName(String name) {
    this.name = name;
  }

  /**
   * This method returns the height of the background image
   *
   * @return Height of the background image
   */
  public int getImageHeight() {
    return imageHeight;
  }

  /**
   * This method sets the height of the background image
   *
   * @param height Height of the background image
   */
  public void setImageHeight(int height) {
    imageHeight = height;
  }

  /**
   * This method returns the width of the background image
   *
   * @return Width of the background image
   */
  public int getImageWidth() {
    return imageWidth;
  }

  /**
   * This method sets the width of the background image
   *
   * @param width Width of the background image
   */
  public void setImageWidth(int width) {
    imageWidth = width;
  }

  /**
   * This method sets the minimum x coordinate of the image to render onto
   *
   * @param x Minimum x coordinate of the image to render onto
   */
  public void setMinimumPixelX(int x) {
    minPixelX = x;
  }

  /**
   * This method returns the minimum x coordinate of the image to render onto
   *
   * @return Minimum x coordinate of the image to render onto
   */
  public int getMinimumPixelX() {
    return minPixelX;
  }

  /**
   * This method sets the minimum y coordinate of the image to render onto
   *
   * @param y Minimum y coordinate of the image to render onto
   */
  public void setMinimumPixelY(int y) {
    minPixelY = y;
  }

  /**
   * This method returns the minimum y coordinate of the image to render onto
   *
   * @return Minimum y coordinate of the image to render onto
   */
  public int getMinimumPixelY() {
    return minPixelY;
  }

  /**
   * This method sets the maximum x coordinate of the image to render onto
   *
   * @param x Maximum x coordinate of the image to render onto
   */
  public void setMaximumPixelX(int x) {
    maxPixelX = x;
  }

  /**
   * This method returns the maximum x coordinate of the image to render onto
   *
   * @return Maximum x coordinate of the image to render onto
   */
  public int getMaximumPixelX() {
    return maxPixelX;
  }

  /**
   * This method sets the maximum y coordinate of the image to render onto
   *
   * @param y Maximum y coordinate of the image to render onto
   */
  public void setMaximumPixelY(int y) {
    maxPixelY = y;
  }

  /**
   * This method returns the maximum y coordinate of the image to render onto
   *
   * @return Maximum y coordinate of the image to render onto
   */
  public int getMaximumPixelY() {
    return maxPixelY;
  }

  /**
   * This method returns the minimum x coordinate of the real world coordinate system to render onto
   *
   * @return Minimum x coordinate of the real world coordinate system to render onto
   */
  public double getMinimumRealX() {
    return minRealX;
  }

  /**
   * This method sets the minimum x coordinate of the real world coordinate system to render onto
   *
   * @param x Minimum x coordinate of the real world coordinate system to render onto
   */
  public void setMinimumRealX(double x) {
    minRealX = x;
  }

  /**
   * This method returns the minimum y coordinate of the real world coordinate system to render onto
   *
   * @return Minimum y coordinate of the real world coordinate system to render onto
   */
  public double getMinimumRealY() {
    return minRealY;
  }

  /**
   * This method sets the minimum y coordinate of the real world coordinate system to render onto
   *
   * @param y Minimum y coordinate of the real world coordinate system to render onto
   */
  public void setMinimumRealY(double y) {
    minRealY = y;
  }

  /**
   * This method returns the maximum x coordinate of the real world coordinate system to render onto
   *
   * @return Maximum x coordinate of the real world coordinate system to render onto
   */
  public double getMaximumRealX() {
    return maxRealX;
  }

  /**
   * This method sets the maximum x coordinate of the real world coordinate system to render onto
   *
   * @param x Maximum x coordinate of the real world coordinate system to render onto
   */
  public void setMaximumRealX(double x) {
    maxRealX = x;
  }

  /**
   * This method returns the minimum y coordinate of the real world coordinate system to render onto
   *
   * @return Maximum y coordinate of the real world coordinate system to render onto
   */
  public double getMaximumRealY() {
    return maxRealY;
  }

  /**
   * This method sets the maximum y coordinate of the real world coordinate system to render onto
   *
   * @param y Maximum y coordinate of the real world coordinate system to render onto
   */
  public void setMaximumRealY(double y) {
    maxRealY = y;
  }

  /**
   * This method creates a printable version of Configuration
   */
  public String toString() {
    return name+": "+imageName+", "+imageHeight+", "+imageWidth+", "+
           "("+minPixelX+", "+minPixelY+", "+maxPixelX+", "+maxPixelY+"), "+
           "("+minRealX+", "+minRealY+", "+maxRealX+", "+maxRealY+")";
  }

  /**
   * This method converts a Configuration to a TASKClientInfo
   *
   * @return TASKClientInfo containing Configuration information
   */
  public TASKClientInfo toTASKClientInfo() {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      DataOutputStream dos = new DataOutputStream(baos);
      dos.writeInt(imageHeight);
      dos.writeInt(imageWidth);
      dos.writeInt(minPixelX);
      dos.writeInt(minPixelY);
      dos.writeInt(maxPixelX);
      dos.writeInt(maxPixelY);
      dos.writeDouble(minRealX);
      dos.writeDouble(minRealY);
      dos.writeDouble(maxRealX);
      dos.writeDouble(maxRealY);
      if (imageName != null) {
        dos.writeInt(imageName.length());
        dos.writeChars(imageName);
      }
      else {
        dos.writeInt(0);
      }
    } catch (IOException ioe) {
        System.out.println("Configuration toASKClientInfo IOE: "+ioe);
    }
    return new TASKClientInfo(name, CONFIGURATION, baos.toByteArray());
  }

    public void verifyFileName(java.awt.Frame parent) {
      //check to see that this file exists -- if not, prompt for new file
      File f = new File(imageName);
      if (!f.exists()) {
	  JFileChooser chooser = new JFileChooser();
	  // Note: source for ExampleFileFilter can be found in FileChooserDemo,
	  // under the demo/jfc directory in the Java 2 SDK, Standard Edition.
	  chooser.addChoosableFileFilter(new ImageFilter());
	  chooser.setDialogTitle("Image in configuration not found.  Please select a new file.");
	  chooser.setAccessory(new ImagePreview(chooser));
	  chooser.setFileView(new ImageFileView());

	  int returnVal = chooser.showOpenDialog(parent);
	  if(returnVal == JFileChooser.APPROVE_OPTION) {
	      File file = chooser.getSelectedFile();
	      imageName = file.getAbsolutePath();
	  } 
      }
    }

  /**
   * Constructor that creates Configuration object from TASKClientInfo object
   *
   * @param info converts TASKClientInfo object into Configuration
   */
  public Configuration(TASKClientInfo info) {
    this.name = info.name;
    try {
      ByteArrayInputStream bais = new ByteArrayInputStream(info.data);
      DataInputStream dis = new DataInputStream(bais);
      this.imageHeight = dis.readInt();
      this.imageWidth = dis.readInt();
      this.minPixelX = dis.readInt();
      this.minPixelY = dis.readInt();
      this.maxPixelX = dis.readInt();
      this.maxPixelY = dis.readInt();
      this.minRealX = dis.readDouble();
      this.minRealY = dis.readDouble();
      this.maxRealX = dis.readDouble();
      this.maxRealY = dis.readDouble();
      System.out.println(minRealX+","+minRealY+","+maxRealX+","+maxRealY);

      int length = dis.readInt();
      if (length == 0) {
		this.imageName = null;
		System.out.println("imagename is null: "+imageName);
      }
      else {
	  StringBuffer sb = new StringBuffer();
	  for (int i=0; i<length; i++) {
	      sb.append(dis.readChar());
	  }
	  this.imageName = sb.toString();
      }
    } catch (IOException ioe) {
        System.out.println("Configuration constructor IOE: "+ioe);
    }    
  }   
}
