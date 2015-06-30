/*									tab:4
 * SchemaField.java
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:  Sam Madden

Java class to manage a single field from a schema.

 */
/*
C Structure: 
typedef struct {
  char version; //1
  char type;  //2
  char units; //3
  short min;  //4-5
  short max;  //6-7
  char bits;  //8
  float cost; //9-12
  float time; //13-16
  char input; //17
  char name[8];  //18-25
  char direction; //26
} Field;
*/

package net.tinyos.schema;

public class SchemaField {

  //type definitions
  public static final int BYTE = 0;
  public static final int INT = 1;
  public static final int LONG = 2;
  public static final int DOUBLE = 3;
  public static final int FLOAT = 4;
  public static final int STRING = 5;

  //direction definitions
  public static final int ON_DEMAND = 0;
  public static final int ON_CHANGE = 1;
  public static final int PERIODICALLY = 2;
  public static final int WHEN_OUTSIDE_RANGE = 3;

  
  //inputs array
  public static final String[] INPUTS = {"adc0", "adc1", "adc2", "adc3", "adc4", "adc5", "adc6", 
				  "mio0", "mio1", "mio2", "mio3", "mio4", "mio5", "mio6"};
  
  //units array
  public static final String[] UNITS = {"farenheight", "celsius", "amperes", "volts", "candela"};

  

    //offsets of fields in field data
  static final int VERSION_OFFSET = 0;
  static final int TYPE_OFFSET = 1;
  static final int UNITS_OFFSET = 2;
  static final int MIN_OFFSET = 3;
  static final int MIN_SIZE = 2;
  static final int MAX_OFFSET = 5;
  static final int MAX_SIZE = 2;
  static final int BITS_OFFSET = 7;
  static final int COST_OFFSET = 8;
  static final int COST_SIZE = 4;
  static final int TIME_OFFSET = 12;
  static final int TIME_SIZE = 4;
  static final int INPUT_OFFSET = 16;
  static final int NAME_OFFSET = 17;
  static final int NAME_SIZE = 8;
  static final int DIRECTION_OFFSET = 25;

  byte version, type, units,bits, input, direction;
  float cost, time;
  int min, max;
  String name;
  
  /** Initialize this field from a schema string returned as 
            a kSCHEMA_MESSAGE AM message
      Each such message corresponds to a single field
    */
  public SchemaField(String init) {
    int temp;

    version = (byte)init.charAt(VERSION_OFFSET);
    type = (byte)init.charAt(TYPE_OFFSET);
    units = (byte)init.charAt(UNITS_OFFSET);
    bits = (byte)init.charAt(BITS_OFFSET);
    input = (byte)init.charAt(INPUT_OFFSET);
    direction = (byte)init.charAt(DIRECTION_OFFSET);
    
    min = decodeBinaryInt(init, MIN_OFFSET, MIN_SIZE);
    max = decodeBinaryInt(init, MAX_OFFSET, MAX_SIZE);
    temp = decodeBinaryInt(init, TIME_OFFSET, TIME_SIZE);
    time = Float.intBitsToFloat(temp);
    temp = decodeBinaryInt(init, COST_OFFSET, COST_SIZE);
    cost = Float.intBitsToFloat(temp);

    name ="";
    for (int i = NAME_OFFSET; i < NAME_OFFSET + NAME_SIZE; i++)
	if (init.charAt(i) != 0)
	    name += init.charAt(i);
	else
	    break;

  }


    /** serious ugliness to take a c-encoded binary integer in a string
	and convert it to the representative integer 
    */
    int decodeBinaryInt(String str, int from, int len) {
	int value = 0;
	for (int i = 0; i < len; i++) {
	    value += (int)((int)str.charAt(from + i)) << ( 8 * i); 	    
	}
	//decode 2s complement
	if (value > Math.pow(2, (len * 8) - 1)) // 2^15 is maximum signed short, 2^31 max signed long
	    value = (int)((long)value - (long)Math.pow(2, (len * 8)));
	return value;
    }
  
  /** @return the version code for this field */
  public byte getVersion() {
    return version;
  }

  /** @return The type of this field (e.g. SchemaField.INTEGER, SchemaField.BYTE, etc. */
  public byte getType() {
    return type;
  }

  /** @return A string representation of the type of this field */
  public String getTypeString() {
      switch (type) {
      case BYTE:
	return "Byte";
      case INT:
	return "Integer";
      case LONG:
	return "Long";
      case DOUBLE:
	return "Double";
      case FLOAT:
	return "Float";
      case STRING:
	return "String";
      }
    return "Unknown";
  }

  /** @return An byte index into SchemaField.UNITS array indicating the units
    of this field
    */
  public byte getUnits() {
    return units;
  }

  /** @return a string based representation of the units of this field */
  public String getUnitsString() {
    return UNITS[units];
  }


  public byte getBits() {
    return bits;
  }

  public int getMin() {
    return min;
  }

  public int getMax() {
    return max;
  }

  public float getCost() {
    return cost;
  }

  public float getTime() {
    return time;
  }

  public byte getInput() {
    return input;
  }

  public String getInputString() {
    return INPUTS[input];
  }

  public String getName() {
    return name;
  }

  public byte getDirection() {
    return direction;
  }
  
  public String getDirectionString() {
    switch (direction) {
    case ON_DEMAND:
      return "ondemand";
    case ON_CHANGE:
      return "onchange";
    case PERIODICALLY:
      return "periodically";
    case WHEN_OUTSIDE_RANGE:
      return "whenoutsiderange";
    }
    return "Unknown";
  }
  
  public String toString() {
    String s = "";
    s += "Version : " + getVersion() + "\n";
    s += "Type : " + getType() + "\n";
    s += "Units : " + getUnits() + "\n";
    s += "Min : " + getMin() + "\n";
    s += "Max : " + getMax() + "\n";
    s += "Bits : " + getBits() + "\n";
    s += "Cost : " + getCost() + "\n";
    s += "Time : " + getTime() + "\n";
    s += "Input : " + getInput() + "\n";
    s += "Name : " + getName() + "\n";
    s += "Direction : " + getDirection();
    return s;
    
  }
    
}


