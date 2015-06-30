/*
 * file:        Crc8M.nc
 * description: Crc implementation
 */

/* 
 * 8 bit CRC
 */
module Crc8M {
    provides interface Crc8;
}
implementation 
{
    uint8_t CrcByte (uint8_t inCrc, uint8_t inData)
    {
        uint8_t i;
        uint8_t data;

        data = inCrc ^ inData;
  
	    for (i=0; i < 8; i++) 
        {
            if ((data & 0x80) != 0)
            {
                data <<= 1;
                data ^= 0x07;
            }
            else
                data <<= 1;
    	}

    	return data;
    }
    
    command uint8_t Crc8.crc8(uint8_t *ptr, uint16_t len, uint8_t crc_)
    {
        uint8_t crc;

        crc = crc_;

        while (len > 0)
        {
            crc = CrcByte (crc, *ptr++);
            len--;
        }

        return crc;
    }
}
