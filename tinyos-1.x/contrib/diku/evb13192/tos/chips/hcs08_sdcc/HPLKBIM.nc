/*
	HPLKBI implementation for HCS08
	
	Author:			Jacob Munk-Stander <jacobms@diku.dk>
	Last modified:	May 24, 2005
*/
module HPLKBIM
{
	provides interface HPLKBI as KBI;
}

implementation
{
	enum { SW_MASK	= 0x3C };
	
	enum
	{	
		SW_1 = 0x04,
		SW_2 = 0x08,
		SW_3 = 0x10,
		SW_4 = 0x20
	};

	uint8_t sw = 0x00;

	async command result_t KBI.init()
	{
		atomic
		{
			PTAPE = PTAPE | 0x3C; // Pullups for 2-5
			PTADD = PTADD & 0xC3; // 2-5 inputs

			// Keyboard Pin Enable			
			KBIPE_KBIPE2 = 1;	// SW01
			KBIPE_KBIPE3 = 1;	// SW02
			KBIPE_KBIPE4 = 1;	// SW03
			KBIPE_KBIPE5 = 1;	// SW04

			// Keyboard Edge Select, 1 = Rising edges/high levels
			//                       0 = Falling edges/low levels
			KBISC_KBEDG4 = 0;	
			KBISC_KBEDG5 = 0;	
			KBISC_KBEDG6 = 0;
			KBISC_KBEDG7 = 0;
			
			KBISC_KBIMOD = 0;	// Keyboard Detection Mode, 1 = Edge-and-level detection
								//                          0 = Edge-only detection
			KBISC_KBACK = 1;	// Keyboard Interrupt Acknowledge, just to be sure
			KBISC_KBIE = 1;		// Keyboard Interrupt Enable
		}
		
		return SUCCESS;
	}
	
	// Atomic not needed as we won't get an interrupt until we acknowledge
	TOSH_SIGNAL(KEYBOARD)
	{
		sw = PTAD; // The switch pressed is kept in PTAD, bits 2-5
		
		// "jitter"-detection, wait 500 microseconds
		TOSH_uwait(500);
			
		if(sw == PTAD)
		{
			// TODO: implement a fancy bit-shift-with-a-twist instead of this switch
			switch(~sw & SW_MASK)
			{
				case SW_1:
					signal KBI.switchDown(1);
					break;

				case SW_2:
					signal KBI.switchDown(2);
					break;

				case SW_3:
					signal KBI.switchDown(3);
					break;

				case SW_4:
					signal KBI.switchDown(4);
					break;
			}
		}
		
		KBISC_KBACK = 1; // Keyboard Interrupt Acknowledge
	}
}
