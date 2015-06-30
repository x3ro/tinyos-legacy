/*									tab:4
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
package net.tinyos.script;

import java.io.*;
import java.util.*;
import net.tinyos.script.DFStatement;
import net.tinyos.script.DFTokenizer;
import net.tinyos.script.Context;
import net.tinyos.script.Capsule;

public class VMDescription {
  private String name = null;
  private Vector primitives = new Vector();
  private Vector functions = new Vector();
  private Vector contexts = new Vector();
  private Vector paths = new Vector();
  
  private String description = null;
  private String sensorboard = null;
  private Language language = null;
  private VMOptions options = null;
  
  public VMDescription() {}
  
  public VMDescription(String name) {
    this.name = name;
  }
  
  public String getDescription() {return this.description;}
  public String getName() {return this.name;}
  public String getSensorboard() {return this.sensorboard;}
  public Vector getPrimitives() {return new Vector(language.getPrimitives());}
  public Vector getFunctions() {return new Vector(this.functions);}
  public Vector getContexts() {return new Vector(this.contexts);}
  public Vector getPaths() {return new Vector(paths);}
  public Language getLanguage() {return this.language;}
  public VMOptions getVMOptions() {return this.options;}

  public int getMessageSize() {
    int context = contexts.size() * 4;
    
    int buffer = Integer.parseInt(options.getBufLen()) * 2 + 2;
    int def = 36;
    if (def > context &&
	  def > buffer) {
      return def;
    }
    else if (context > buffer) {
      return context;
    }
    else {
      return buffer;
    }
  }
  
  public void setName(String name) {this.name = name;}
  public void setSensorboard(String name) {this.sensorboard = name;}
  
  public void setDescription(String description) {
    this.description = description;
  }
  public void setFunctions(Vector functions) {
    this.functions = functions;
  }
  public void setContexts(Vector contexts) {
    this.contexts = contexts;
  }
  public void setPaths(Vector paths) {
    this.paths = paths;
  }
  public void setLanguage(Language language) {
    this.language = language;
  }
  public void setVMOptions(VMOptions options) {
    this.options = options;
  }
  
  public void addFunction(Function fn) {functions.addElement(fn);}
  public void addContext(Context bc) {contexts.addElement(bc);}
  public void addPath(String path) {
    boolean absolute = (path.charAt(0) == '/');
    if (!absolute) {
      File file = new File(path);
      path = file.getAbsolutePath();
    }
    
    path = path.replace('\\', '/');
    paths.addElement(path);
  }
}
