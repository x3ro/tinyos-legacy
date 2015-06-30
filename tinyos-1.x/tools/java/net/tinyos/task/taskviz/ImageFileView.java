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
