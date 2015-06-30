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

/**
 * This class returns the extension of a file
 */
public class Utils {

    /**
     * jpeg
     */
    public final static String jpeg = "jpeg";

    /**
     * jpg
     */
    public final static String jpg = "jpg";

    /**
     * gif
     */
    public final static String gif = "gif";

    /**
     * tiff
     */
    public final static String tiff = "tiff";

    /**
     * tif
     */
    public final static String tif = "tif";

    /**
     * png
     */
    public final static String png = "png";

    /**
     * Returns the extension of a file.
     *
     * @param f File to get extension of
     * @return Extension of the file
     */
   public static String getExtension(File f) {
     String ext = null;
     String s = f.getName();
     int i = s.lastIndexOf('.');

     if (i > 0 &&  i < s.length() - 1) {
       ext = s.substring(i+1).toLowerCase();
     }
     return ext;
  }
}
