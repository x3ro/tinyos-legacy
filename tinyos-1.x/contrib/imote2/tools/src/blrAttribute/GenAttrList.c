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
/**
 * @file GenAttrList.h
 * @author Junaith Ahemed Shahabdeen
 * 
 * This file is mainly used for generating attribute binary.
 * 
 */
#include <BLAttributeVal.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define ATTR_FILE_NAME "attributes.bin"

FILE* AttrFile;

unsigned char Attr_buffer [BL_TABLE_SIZE];

/**
 * Gen_Attr_Address_Table
 *
 * Generate Address table and dump to the binary file. 
 */
int Gen_Attr_Address_Table ()
{
  int i = 0;
  int curlen = 0;
  Attribute* attr;
  /* Initialize the buffer */
  memset (Attr_buffer, 0xFF, BL_TABLE_SIZE);

  for (i=0;i<BL_ATTR_ADDRESS_TABLE_NUM;i++)
  {
    attr = (Attribute*) (Attr_buffer + curlen);
    attr->AttrType = Gen_ATTR_Addr_Table [i][0];
    attr->AttrValidity = BL_VALID_ATTR; /* Valid (all set to 1)*/
    attr->AttrLength = Gen_ATTR_Addr_Table [i][1];
    attr->AttrValidAddr = 0xFFFFFFFF;
    memcpy (attr->AttrValue, 
           &Gen_ATTR_Addr_Table_Data [i], 
           attr->AttrLength);
    curlen += sizeof (Attribute) + attr->AttrLength;
  }

  fwrite (&Attr_buffer, BL_TABLE_SIZE, 1, AttrFile);
  return 0;
}

/**
 * Gen_Attr_Bootloader_Table
 *
 * Generate bootloader table and dump to the binary file.
 */
int Gen_Attr_Bootloader_Table ()
{
  int i = 0;
  int curlen = 0;
  Attribute* attr;
  /* Initialize the buffer */
  memset (Attr_buffer, 0xFF, BL_TABLE_SIZE);

  for (i=0;i<BL_ATTR_BOOTLOADER_TABLE_NUM;i++)
  {
    attr = (Attribute*) (Attr_buffer + curlen);
    attr->AttrType = Gen_ATTR_Bootloader_Table [i][0];
    attr->AttrValidity = BL_VALID_ATTR; /* Valid (all set to 1)*/
    attr->AttrLength = Gen_ATTR_Bootloader_Table [i][1];
    attr->AttrValidAddr = 0xFFFFFFFF;
    memcpy (attr->AttrValue, 
           &Gen_ATTR_Bootloader_Table_Data [i], 
           attr->AttrLength);
    curlen += sizeof (Attribute) + attr->AttrLength;
  }

  fwrite (&Attr_buffer, BL_TABLE_SIZE, 1, AttrFile);
  return 0;
}

/**
 * Gen_Attr_Shared_Table
 *
 * Shared Table.
 */
int Gen_Attr_Shared_Table ()
{
  int i = 0;
  int curlen = 0;
  Attribute* attr;
  /* Initialize the buffer */
  memset (Attr_buffer, 0xFF, BL_TABLE_SIZE);

  for (i=0;i<ATTR_SHARED_TABLE_NUM;i++)
  {
    attr = (Attribute*) (Attr_buffer + curlen);
    attr->AttrType = Gen_ATTR_Shared_Table [i][0];
    attr->AttrValidity = BL_VALID_ATTR; /* Valid (all set to 1)*/
    attr->AttrLength = Gen_ATTR_Shared_Table [i][1];
    attr->AttrValidAddr = 0xFFFFFFFF;
    memcpy (attr->AttrValue, 
           &ATTR_Shared_Table_Data [i], 
           attr->AttrLength);
    curlen += sizeof (Attribute) + attr->AttrLength;
  }

  fwrite (&Attr_buffer, BL_TABLE_SIZE, 1, AttrFile);
  return 0;  
}

int Tst_Gen_Attr_Address_Table ()
{
  int i = 0;
  int curlen = 0;
  int data;
  Attribute* attr;
  AttrFile = fopen(ATTR_FILE_NAME,"r");
  if (!AttrFile)
  {
    fprintf (stderr, "Error opening file for reading\n");
    return 1;
  }
  if ((fread (&Attr_buffer, BL_TABLE_SIZE, 1, AttrFile)) <= 0)
  {
    fprintf (stderr, "Error reading from file\n");
    return 1;
  }
  for (i=0;i<BL_ATTR_ADDRESS_TABLE_NUM;i++)
  {
    attr = (Attribute*) (Attr_buffer + curlen);
    printf ("Type %d \n Validity %d \n Length %d \n Validity %d \n",
             attr->AttrType, attr->AttrValidity, attr->AttrLength, attr->AttrValidAddr);
    curlen += sizeof (Attribute);
    memcpy (&data, Attr_buffer + curlen, attr->AttrLength);
    printf ("%d \n\n",data);
    curlen += attr->AttrLength;
  }
  fclose (AttrFile);
  return 0;
}


int main ()
{
  int table = 1;
  AttrFile = fopen(ATTR_FILE_NAME,"w");
  if (!AttrFile)
  {
    printf ("Error opening file %s for writing.\n",ATTR_FILE_NAME);
    exit (0);
  }
  else
  {
    int  result = fseek (AttrFile, 0, SEEK_SET);
    if (result)
      fprintf(stderr, "Fseek failed" );	    
  }

  for (table = 1; table <=BL_ATTR_ADDRESS_TABLE_NUM; table++)
  {
    switch (table)
    {
      case BL_ATTR_TYP_ADDRESS_TABLE:
        fprintf (stdout, "Generating Address Table \n");
        Gen_Attr_Address_Table ();
      break;
      case BL_ATTR_TYP_DEF_BOOTLOADER:
        fprintf (stdout, "Generating Default Bootloader Table.\n");
        Gen_Attr_Bootloader_Table ();
      break;
      case BL_ATTR_TYP_BOOTLOADER:
        fprintf (stdout, "Generating Bootloader Tables.\n");
        Gen_Attr_Bootloader_Table ();
        Gen_Attr_Bootloader_Table ();
        //Gen_Attr_Address_Table ();
      break;
      case BL_ATTR_TYP_DEF_SHARED:
        fprintf (stdout, "Generating Default Shared Table.\n");
        Gen_Attr_Shared_Table ();
      break;
      case BL_ATTR_TYP_SHARED:
        fprintf (stdout, "Generating Shared Tables.\n");
        Gen_Attr_Shared_Table ();
        Gen_Attr_Shared_Table ();
      break;
      default:
        fprintf (stdout, "Unkown Table option. \n");
      break;
    }
  }
  fclose (AttrFile);
  //Tst_Gen_Attr_Address_Table ();
  return 0;
}
