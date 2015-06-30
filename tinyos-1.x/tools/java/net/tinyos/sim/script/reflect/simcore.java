// $Id: simcore.java,v 1.1 2004/01/26 01:52:06 mikedemmer Exp $

/*
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Michael Demmer
 * Date:        January 25, 2004
 * Desc:        simcore refelected module implementation
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import org.python.core.*;
import java.util.*;

public class simcore implements ClassDictInit {
  
  public static void classDictInit(PyObject dict) {
    /*
     * Don't reflect this method.
     */
    dict.__delitem__("classDictInit");
    
    /*
     * For each reflected class, bind the instance name that's
     * specified by the hash key to the object, and the unqualified
     * class name to the class.
     */
    Hashtable reflections = SimBindings.reflections;
    for (Enumeration e = reflections.keys() ; e.hasMoreElements() ;) {
      String name = (String)e.nextElement();
      Object obj  = reflections.get(name);
      String classname = obj.getClass().getName();
      classname = classname.substring(classname.lastIndexOf('.') + 1);
      
      PyJavaInstance pyInst = new PyJavaInstance(obj);
      PyJavaClass pyClass = PyJavaClass.lookup(obj.getClass());

      dict.__setitem__(name, pyInst);
      dict.__setitem__(classname, pyClass);
   }
  }

}
