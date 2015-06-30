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

import java.io.File;
import javax.swing.*;
import javax.swing.filechooser.*;

/**
 * This class displays special images for files of type jpg, gif or tiff to be used in a filechooser
 */
public class ImageFileView extends FileView {
  ImageIcon jpgIcon = new ImageIcon("images/jpgIcon.gif");
  ImageIcon gifIcon = new ImageIcon("images/gifIcon.gif");
  ImageIcon tiffIcon = new ImageIcon("images/tiffIcon.gif");
    
  /**
   * This method does nothing. Leaving for the Look & Feel FilveView to handle
   */
  public String getName(File f) {
    return null; // let the L&F FileView figure this out
  }
    
  /**
   * This method does nothing. Leaving for the Look & Feel FilveView to handle
   */
  public String getDescription(File f) {
    return null; // let the L&F FileView figure this out
  }
    
  /**
   * This method does nothing. Leaving for the Look & Feel FilveView to handle
   */
  public Boolean isTraversable(File f) {
    return null; // let the L&F FileView figure this out
  }
    
  /**
   * This method returns a description of the type of the given file
   *
   * @param f File to get description of
   */
  public String getTypeDescription(File f) {
    String extension = Utils.getExtension(f);
    String type = null;

    if (extension != null) {
      if (extension.equals(Utils.jpeg) || extension.equals(Utils.jpg)) {
        type = "JPEG Image";
      } 
      else if (extension.equals(Utils.gif)) {
        type = "GIF Image";
      } 
      else if (extension.equals(Utils.tiff) || extension.equals(Utils.tif)) {
        type = "TIFF Image";
      } 
    }
    return type;
  }
    
  /**
   * This method gets the image for a particular file type. 
   *
   * @param f File to get the image for
   */
  public Icon getIcon(File f) {
    String extension = Utils.getExtension(f);
    Icon icon = null;

    if (extension != null) {
      if (extension.equals(Utils.jpeg) || extension.equals(Utils.jpg)) {
        icon = jpgIcon;
      } 
      else if (extension.equals(Utils.gif)) {
        icon = gifIcon;
      } 
      else if (extension.equals(Utils.tiff) || extension.equals(Utils.tif)) {
        icon = tiffIcon;
      } 
    }
    return icon;
  }
}