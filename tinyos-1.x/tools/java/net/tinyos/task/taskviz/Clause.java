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

import net.tinyos.task.taskapi.TASKOperators;
import net.tinyos.task.taskapi.TASKOperExpr;
import net.tinyos.task.taskapi.TASKAggExpr;
import net.tinyos.task.taskapi.TASKAttrExpr;
import net.tinyos.task.taskapi.TASKConstExpr;
import net.tinyos.task.taskapi.TASKExpr;

public class Clause {

  private String attribute;
  private String aggregator;
  private int operator;
  private int operand;
  private int arg1, arg2;

  public final static int ATTRIBUTE = 0;
  public final static int AGGREGATOR = 1;
  public final static int PREDICATE = 2;
  public final static int BOTH = 3;

  public Clause(String attribute, String aggregator, int operator, int operand) {
    this.attribute = attribute;
    this.aggregator = aggregator;
    this.operator = operator;
    this.operand = operand;
    arg1 = AttributeDialog.NO_ARGUMENT;
    arg2 = AttributeDialog.NO_ARGUMENT;
  }

  public Clause(String attribute, String aggregator, int operator, int operand, int arg1, int arg2) {
    this.attribute = attribute;
    this.aggregator = aggregator;
    this.operator = operator;
    this.operand = operand;
    this.arg1 = arg1;
    this.arg2 = arg2;
  }

  public Clause(TASKExpr expr) {
    if (expr instanceof TASKAttrExpr) {
      attribute = ((TASKAttrExpr)expr).getAttrName();
      aggregator = "No Aggregator";
      arg1 = AttributeDialog.NO_ARGUMENT;
      arg2 = AttributeDialog.NO_ARGUMENT;
      operand = -1;
    }
    else if (expr instanceof TASKAggExpr) {
      TASKAggExpr agg = (TASKAggExpr)expr;
      attribute = agg.getAttrName();
      aggregator = agg.getName();
      Integer i = agg.getConst1();
      if (i != null) {
        arg1 = i.intValue();
      }
      else {
        arg1 = AttributeDialog.NO_ARGUMENT;
      }
      i = agg.getConst2();
      if (i != null) {
        arg2 = i.intValue();
      }
      else {
        arg2 = AttributeDialog.NO_ARGUMENT;
      }
    }
    else if (expr instanceof TASKOperExpr) {
      TASKOperExpr oper = (TASKOperExpr)expr;
      operator = oper.getOperType();
      attribute = ((TASKAttrExpr)oper.getLeftExpr()).getAttrName(); 
      TASKConstExpr right = (TASKConstExpr)oper.getRightExpr();
      operand = ((Integer)right.getConstValue()).intValue();
      aggregator = "No Aggregator";
      arg1 = AttributeDialog.NO_ARGUMENT;
      arg2 = AttributeDialog.NO_ARGUMENT;
    }
  }

  public String getAttribute() {
    return attribute;
  }

  public String getAggregator() {
    return aggregator;
  }

  public int getOperator() {
    return operator;
  }

  public int getOperand() {
    return operand;
  }

  public int getArg1() {
    return arg1;
  }

  public int getArg2() {
    return arg2;
  }

  public String toString() {
    boolean started = false;
    StringBuffer sb = new StringBuffer();
    if (!aggregator.equals("No Aggregator")) {
      sb.append(aggregator+"("+attribute+", ");
      if (arg1 >= 0) {
        sb.append(arg1+", ");
      }
      else if (arg1 == AttributeDialog.BAD_ARGUMENT) {
        sb.append("BAD, ");
      }
      else if (arg1 == AttributeDialog.NO_ARGUMENT) {
        sb.append("NO, ");
      }
      if (arg2 >= 0) {
        sb.append(arg2+")");
      }
      else if (arg2 == AttributeDialog.BAD_ARGUMENT) {
        sb.append("BAD)");
      }
      else if (arg2 == AttributeDialog.NO_ARGUMENT) {
        sb.append("NO)");
      }
      started = true;
    }
    if (operand != -1) {
      if (started) {
        sb.append(", ");
      }
      sb.append(attribute+TASKOperators.OperName[operator]+operand);
      started = true;
    }
    if (!started) {
      sb.append(attribute);
    }
    return sb.toString();
  }

  public int getType() {
    if (aggregator.equals("No Aggregator")) {
      if (operand == -1) {
        return ATTRIBUTE;
      }
      else {
        return PREDICATE;
      }
    }
    else {
      if (operand == -1) {
        return AGGREGATOR;
      }
      else {
        return BOTH;
      }
    }
  } 

  public boolean isValid() {
    int type = getType();
    if ((type == AGGREGATOR) || (type == BOTH)) {
      if ((arg1 == AttributeDialog.BAD_ARGUMENT) || (arg2 == AttributeDialog.BAD_ARGUMENT)) {
        return false;
      }
    }
    return true;
  }
}
