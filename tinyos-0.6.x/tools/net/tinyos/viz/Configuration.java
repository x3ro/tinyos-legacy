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

/**
 * This class holds the configuration information for a sensor network deployment
 */
public class Configuration {

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
                       int maxPixelY, int minRealX, int minRealY, int maxRealX, int maxRealY) {
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
    return ((imageName == null) || (imageName.equals("null")));
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
}