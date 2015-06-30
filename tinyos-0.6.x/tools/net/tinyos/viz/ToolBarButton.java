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

import java.awt.*;
import javax.swing.*;

/**
 * This class implements a toggle button to be used on a toolbar. It displays an image and 
 * can also display text.
 */
public class ToolBarButton extends JToggleButton {

  /**
   * Margins for the tool bar button
   */
  private static final Insets margins = new Insets(0, 0, 0, 0);

  /**
   * Constructor that creates the toolbar button from an icon
   *
   * @param icon Icon to display in toolbar button
   */
  public ToolBarButton(Icon icon) {
    super(icon);
    setMargin(margins);
    setVerticalTextPosition(BOTTOM);
    setHorizontalTextPosition(CENTER);
  }

  /**
   * Constructor that creates the toolbar button from an image
   *
   * @param imageFile Name of the image to display in toolbar button
   */
  public ToolBarButton(String imageFile) {
    this(new ImageIcon(imageFile));
  }

  /**
   * Constructor that displays a toolbar button with an image and text
   *
   * @param imageFile Name of the image to display in toolbar button
   * @param text Text to display in toolbar button
   */
  public ToolBarButton(String imageFile, String text) {
    this(new ImageIcon(imageFile));
    setText(text);
  }
}