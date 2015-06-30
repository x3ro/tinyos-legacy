// This is special-cased to the butterfly's LCD, rather than being a general
// Atmega 169 display driver

module LCDC {
  provides interface StdControl;
  provides interface LCD;
}
implementation {
  // Look-up table used when converting ASCII to
  // LCD display data (segment control)
  uint16_t PROGMEM LCD_character_table[] = {
    0x0A51,     // '*' (?)
    0x2A80,     // '+'
    0x0000,     // ',' (Not defined)
    0x0A00,     // '-'
    0x0A51,     // '.' Degree sign
    0x0000,     // '/' (Not defined)
    0x5559,     // '0'
    0x0118,     // '1'
    0x1e11,     // '2
    0x1b11,     // '3
    0x0b50,     // '4
    0x1b41,     // '5
    0x1f41,     // '6
    0x0111,     // '7
    0x1f51,     // '8
    0x1b51,     // '9'
    0x0000,     // ':' (Not defined)
    0x0000,     // ';' (Not defined)
    0x0000,     // '<' (Not defined)
    0x0000,     // '=' (Not defined)
    0x0000,     // '>' (Not defined)
    0x0000,     // '?' (Not defined)
    0x0000,     // '@' (Not defined)
    0x0f51,     // 'A' (+ 'a')
    0x3991,     // 'B' (+ 'b')
    0x1441,     // 'C' (+ 'c')
    0x3191,     // 'D' (+ 'd')
    0x1e41,     // 'E' (+ 'e')
    0x0e41,     // 'F' (+ 'f')
    0x1d41,     // 'G' (+ 'g')
    0x0f50,     // 'H' (+ 'h')
    0x2080,     // 'I' (+ 'i')
    0x1510,     // 'J' (+ 'j')
    0x8648,     // 'K' (+ 'k')
    0x1440,     // 'L' (+ 'l')
    0x0578,     // 'M' (+ 'm')
    0x8570,     // 'N' (+ 'n')
    0x1551,     // 'O' (+ 'o')
    0x0e51,     // 'P' (+ 'p')
    0x9551,     // 'Q' (+ 'q')
    0x8e51,     // 'R' (+ 'r')
    0x9021,     // 'S' (+ 's')
    0x2081,     // 'T' (+ 't')
    0x1550,     // 'U' (+ 'u')
    0x4448,     // 'V' (+ 'v')
    0xc550,     // 'W' (+ 'w')
    0xc028,     // 'X' (+ 'x')
    0x2028,     // 'Y' (+ 'y')
    0x5009      // 'Z' (+ 'z')
  };

  enum {
    LCD_BYTES = 20
  };

  uint8_t LCD_Data[LCD_BYTES];
  bool update;

  command result_t StdControl.init() {
    outp(0xf, LCDCCR);
    outp(1 << LCDCS | 3 << LCDMUX0 | 7 << LCDPM0, LCDCRB);
    outp(7 << LCDCD0, LCDFRR);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    outp(1 << LCDEN | 1 << LCDAB | 1 << LCDIE, LCDCRA);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    outp(0, LCDCRA);
    return SUCCESS;
  }

  TOSH_SIGNAL(SIG_LCD) {
    if (update) 
      {
	memcpy((void *)&LCDDR0, LCD_Data, sizeof LCD_Data);
	update = FALSE;
      }
  }

  /////////////////////// Low-level commands ///////////////////////

  command result_t LCD.update() {
    atomic update = TRUE;
    return SUCCESS;
  }

  command result_t LCD.clear() {
    memset(LCD_Data, 0, sizeof LCD_Data);
    return SUCCESS;
  }    

  command result_t LCD.setSegment(uint8_t segment, bool state) {
    uint8_t mask = 1 << (segment & 3); // nibble mask
    uint8_t offset = 5 * ((segment >> 2) & 3) + (segment >> 5);
    uint8_t *lcd_data = LCD_Data + offset;

    if (segment & 1 << 4) // bit 4 set: select high nibble
      mask <<= 4;

    if (state)
      *lcd_data |= mask;
    else
      *lcd_data &= ~mask;
  }

  /***************************************************************************
   *   Function name:LCD_WriteDigit(char c, char digit)
   *   Returns :     None
   *   Parameters :  Inputs
   *                 c: The symbol to be displayed in a LCD digit
   *                 digit: In which digit (0-5) the symbol should be displayed
   *                 Note: Digit 0 is the first used digit on the LCD,
   *                 i.e LCD digit 2
   *   Purpose :     Stores LCD control data in the LCD_displayData buffer.
   *                 (The LCD_displayData is latched in the LCD_SOF interrupt.)
   ***************************************************************************/
  command result_t LCD.displayChar(char c, uint8_t digit) {
    unsigned int seg = 0x0000;                  // Holds the segment pattern
    uint8_t nibble, mask;
    char *ptr;
    uint8_t i;

    if (c >= 'a' && c <= 'z')
      c &= ~0x20;

    //Lookup character table for segment data
    if (c >= '*' && c <= 'Z')
      {
	uint8_t *entry = (uint8_t *)&LCD_character_table[c - '*'];

	seg = PRG_RDB(entry) | PRG_RDB(entry + 1) << 8;
      }

    // Adjust mask according to LCD segment mapping
    if (digit & 0x01)
      mask = 0x0F;                // Digit 1, 3, 5
    else
      mask = 0xF0;                // Digit 0, 2, 4

    ptr = LCD_Data + (digit >> 1);  // digit = {0,0,1,1,2,2}

    for (i = 0; i < 4; i++)
      {
        nibble = seg & 0x000F;
        seg >>= 4;
        if (digit & 0x01)
	  nibble <<= 4;
        *ptr = (*ptr & mask) | nibble;
        ptr += 5;
      }
    return SUCCESS;
  }

  ///////////////// High-level commands ///////////////////

  command result_t LCD.display(char *s) {
    uint8_t digit;

    call LCD.clear();
    for (digit = 0; *s && digit <= 5; digit++)
      call LCD.displayChar(*s++, digit);

    call LCD.update();
    return SUCCESS;
  }
}
