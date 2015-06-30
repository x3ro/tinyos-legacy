/*									tab:4
 * schema.h
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

 Data type and constants to represent mote schemas.

 */

#ifndef __SCHEMA__
#define __SCHEMA__ 

#define kMAX_FIELDS 4

typedef enum {
  kBYTE = 0, 
  kINT = 1, 
  kLONG = 2, 
  kDOUBLE = 3, 
  kFLOAT = 4, 
  kSTRING =5
} SchemaFieldType;

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

typedef struct { 
  short cnt;
  Field fields[kMAX_FIELDS];
} SchemaRecord;

#endif
