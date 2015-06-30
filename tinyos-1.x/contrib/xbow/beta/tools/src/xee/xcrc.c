/**
 * Calculates the CRC code of a TinyOS packet
 *
 * @file      xcrc.c
 * @author    Martin Turon
 * @version   2004/10/3    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: xcrc.c,v 1.1 2004/11/15 05:42:44 husq Exp $
 */

typedef unsigned char  uint8_t;
typedef unsigned short uint16_t;

uint16_t xcrc_byte(uint16_t crc, uint8_t b)
{
  uint8_t i;
  
  crc = crc ^ b << 8;
  i = 8;
  do
    if (crc & 0x8000)
      crc = crc << 1 ^ 0x1021;
    else
      crc = crc << 1;
  while (--i);

  return crc;
}

int xcrc_calc(char *packet, int index, int count) {
    int crc = 0;
    
    while (count > 0) {
	crc = xcrc_byte(crc, packet[index++]);
	count--;
    }
    return crc;
}

void xcrc_set(char *packet, int length) {
    // skip first byte (0x7e), account for 2 bytes crc at end.
    int crc = xcrc_calc(packet, 1, length - 3);
    
    packet[length - 2] = (char) (crc & 0xFF);
    packet[length - 1] = (char) ((crc >> 8) & 0xFF);
}


