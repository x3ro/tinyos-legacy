/**
 * Handles conversion to engineering units of SkyeRead Mini packets.
 *
 * @file      MiniResponse.c
 * @author    Michael Li
 *
 * @version   2004/9/14    mli      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: MiniResponse.c,v 1.1 2005/03/31 07:51:06 husq Exp $
 */


#include "../xsensors.h"
#include "MiniResponse.h"
#include <math.h>
#include "ResponseData.h"


char getDigit( char c )
{
   if ( ( c >= '0' ) && ( c <= '9' ) )
      return( c - '0' );
   if ( ( c >= 'a' ) && ( c <= 'f' ) )
      return( c - 'a' + 10 );
   if ( ( c >= 'A' ) && ( c <= 'F' ) )
      return( c - 'A' + 10 );
   return( -1 );
}


void getTagSpecs (uint8_t *tagInfo, uint8_t *idx)
{
   uint8_t i, type, typeExt1, typeExt2, typeExt3;
   tagType_t *tag = (tagType_t *) tagInfo;

   // convert ascii tag types into hex digits
   type   = getDigit (tag->type[0]);
   type <<= 4;
   type  |= getDigit (tag->type[1]);

   typeExt1   = getDigit (tag->typeExt1[0]);
   typeExt1 <<= 4;
   typeExt1  |= getDigit (tag->typeExt1[1]);

   typeExt2   = getDigit (tag->typeExt2[0]);
   typeExt2 <<= 4;
   typeExt2  |= getDigit (tag->typeExt2[1]);

   typeExt3   = getDigit (tag->typeExt3[0]);
   typeExt3 <<= 4;
   typeExt3  |= getDigit (tag->typeExt3[1]);


   // use taginfo in lookup table for tag specs
   for (i=0; i < NUM_TAG_TYPE_SPECS; i++)
   {
      if ((type     == RFIDtags[i].type) &&
          (typeExt1 == RFIDtags[i].typeExt1) &&
          (typeExt2 == RFIDtags[i].typeExt2) &&
          (typeExt3 == RFIDtags[i].typeExt3))
         break;

   }

   // tag type not found in database
   if (i==NUM_TAG_TYPES)
     i=0;

   // get index
   *idx = i;
}





void skyeread_mini_print_parsed (uint8_t *packet) 
{
    int i=0;
    uint8_t length=0;
    
    Payload *p = (Payload *) (packet + XPACKET_DATASTART_STANDARD);  // parse off TOS_Msg data

    length = MSG_PAYLOAD - (TOS_PACKET_LENGTH - packet[XPACKET_LENGTH]);

    printf ("\n"); 
    printf ("Parsed Packet Data\n");
    printf ("------------------\n");
    printf ("signal strength : %04X\n", p->SG);
    printf ("length          : %i bytes\n", length);
    printf ("packet data     : ");

    for (i=0; i < length; i++)
    {
        printf ("%02X ", p->data[i]);

        if((i%MSG_PAYLOAD+1) == 0)	
	    printf ("\n");  
    }
    printf ("\n\n");
}




void skyeread_mini_print_cooked (uint8_t *packet) 
{
    int i=0;
    uint16_t sg;
    uint8_t r_code; 
    uint8_t t_type; 
    uint8_t data_offset=0;
    uint8_t length=0;

    Payload *p = (Payload *) (packet + XPACKET_DATASTART_STANDARD);  // parse off TOS_Msg data

    length = MSG_PAYLOAD - (TOS_PACKET_LENGTH - packet[XPACKET_LENGTH]);

    // This needs to be expanded.  Is there a way to determine if optional fields are present from the command??? (MLL) 
    // Possibly add the command parameters in the "Payload information"?

    // Signal Strength Parsing
    sg = p->SG;

    // if first packet, parse response code, and tag type.  Otherwise just print data. 
    if ((p->num == 1) && (p->pidx == 0))
    {

      // Response Code Parsing
      r_code = getDigit (p->data[0]);
      r_code <<= 4;
      r_code &= 0xF0;
      r_code |= getDigit (p->data[1]);

      for (i=0; i<NUM_RESPONSE_CODES; i++)
      {
          if (r_code == response_codes[i].code)
          {
               r_code = i;
               break;
          }
      }
      if (i>=NUM_RESPONSE_CODES) 
          r_code = 0;  // invalid response code


      // Tag Type Parsing
      t_type = getDigit (p->data[2]); 
      t_type <<= 4; 
      t_type &= 0xF0; 
      t_type |= getDigit (p->data[3]); 

      for (i=0; i<NUM_TAG_TYPES; i++)
      {
          if (t_type == tag_types[i].code)
          {
               t_type = i;
               break;
          }
      }
      if (i>=NUM_TAG_TYPES) 
          t_type = 0x07;  // (tag types >= 0x09) == RFU 

      printf ("\n");
      printf ("SkyeTek Protocol V.2 Conversion\n"); 
      printf ("-------------------------------\n");
      printf ("signal strength  : %i\n", sg);
      printf ("response         : %s\n", response_codes[r_code].description);
   
      // greater than 4 is non-select command (does not require tag type on response) 
      if (r_code > 4)
      {
        data_offset = 2;

        if (r_code < 10) // 10 and greater are commands responses that don't have data 
          printf ("Data             : "); 
      }
      else 
      {
        uint8_t i=0; 
        data_offset = 4;
        getTagSpecs (&p->data[2], &i);
        printf ("tag description  : %s %s\n", tag_types[t_type].description,
										      RFIDtags[i].description);  

        if (i != 0)  // if tag specs are found, print it
        {
          printf ("tag block size   : %i bytes\n", RFIDtags[i].blockSize);
          printf ("number of blocks : %i blocks\n", RFIDtags[i].numBlocks);
          printf ("memory size      : %i bytes\n", RFIDtags[i].blockSize * RFIDtags[i].numBlocks);
        }
        printf ("TID              : "); 
      }

    }
    else  // continuation of data
    {
      data_offset = 0;
      printf ("Data             : "); 
    }

    for (i=data_offset; i < length; i+=2)  
    {
        if ((((p->data[i]   > 0x2F) && (p->data[i]   < 0x3A)) ||     // if p[i] is a digit 
             ((p->data[i]   > 0x40) && (p->data[i]   < 0x47)) ) &&   // if p[i] is a capital letter (hex letters only)
            (((p->data[i+1] > 0x2F) && (p->data[i+1] < 0x3A)) ||     // if p[i+1] is a digit
             ((p->data[i+1] > 0x40) && (p->data[i+1] < 0x47)) ))     // if p[i+1] is a capital letter (hex letters only)
             printf ("%c%c ", p->data[i], p->data[i+1]);
    }
    printf ("\n\n");
}


XPacketHandler skyeread_mini_packet_handler =
{
    AMTYPE_RFID,
    "$Id: MiniResponse.c,v 1.1 2005/03/31 07:51:06 husq Exp $",
    NULL,
    NULL,
    NULL,
    NULL,
};

void skyeread_mini_initialize() {
    xpacket_add_type(&skyeread_mini_packet_handler);
}
