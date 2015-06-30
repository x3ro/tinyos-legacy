
/**************************************************************
*   Defines
*   MC13192 to MCU interconnects (hardware SPI assumed).
*   These are specific for the EVB13192.
**************************************************************/
/*
	// MC13192 SPI Chip Enable pin
	#define MC13192_CE                PTED_PTED2
	#define MC13192_CE_PORT           PTEDD_PTEDD2
	
	// MC13192 Attention pin
	#define MC13192_ATTN              PTCD_PTCD2
	#define MC13192_ATTN_PORT         PTCDD_PTCDD2
	
	// MC13192 Receive/Transmit pin
	#define MC13192_RXTXEN            PTCD_PTCD3
	#define MC13192_RXTXEN_PORT       PTCDD_PTCDD3
	
	// MC13192 Reset pin
	#define MC13192_RESET             PTCD_PTCD4
	#define MC13192_RESET_PORT        PTCDD_PTCDD4
	#define MC13192_RESET_PULLUP      PTCPE_PTCPE4

	// MC13192 Antenna Switch pin
	#define MC13192_ANT_CTRL          PTBD_PTBD6
	#define MC13192_ANT_CTRL_PORT     PTBDD_PTBDD6
	
	// MC13192 LNA pin (Not mounted on EVB13192)
	#define MC13192_LNA_CTRL          PTBD_PTBD0
	#define MC13192_LNA_CTRL_PORT     PTBDD_PTBDD0
	
	// MC13192 PA pin (Not applicable for EVB13192)
	#define MC13192_PA_CTRL
	#define MC13192_PA_CTRL_PORT
	
	// MC13192 Out-of-idle pin (Used in stream mode)
	#define MC13192_OOI               PTBD_PTBD4
	#define MC13192_OOI_PORT          PTBDD_PTBDD4
	#define MC13192_OOI_PULLUP        PTBPE_PTBPE4
	
	// MC13192 CRC pin (Used in stream mode)
	#define MC13192_CRC               PTBD_PTBD5
	#define MC13192_CRC_PORT          PTBDD_PTBDD5
	#define MC13192_CRC_PULLUP        PTBPE_PTBPE5
*/	
	// MCU Interrupt control.
	#define MC13192_IRQ_SOURCE        IRQSC
	#define MC13192_IRQ_MOD_BIT       IRQSC_IRQMOD
	#define MC13192_IRQ_PE_BIT        IRQSC_IRQPE
	#define MC13192_IRQ_IE_BIT        IRQSC_IRQIE
	#define MC13192_IRQ_ACK_BIT       IRQSC_IRQACK
	#define MC13192_IRQ_FLAG_BIT		IRQSC_IRQF

/**************************************************************
*   Defines
*   Macros for communicating with the MC13192.
**************************************************************/

	// Macros for setting up MCU output ports.
	#define SETUP_IRQ_PIN             MC13192_IRQ_PE_BIT = 1
/*	#define SETUP_ATTN_PORT           MC13192_ATTN_PORT = 1 //Output port
	#define SETUP_RXTXEN_PORT         MC13192_RXTXEN_PORT = 1 // Output port
	#define SETUP_RESET_PORT          MC13192_RESET_PORT = 1 // Output port
	#define SETUP_CE_PORT             MC13192_CE_PORT = 1 // Output port
	#define SETUP_ANT_CTRL_PORT       MC13192_ANT_CTRL_PORT = 1 // Output port
	#define SETUP_LNA_CTRL_PORT       MC13192_LNA_CTRL_PORT = 1 // Output port
	#define SETUP_PA_CTRL_PORT
	#define SETUP_CRC_PORT            MC13192_CRC_PORT = 0; MC13192_CRC_PULLUP = 1 // Input port
	#define SETUP_OOI_PORT            MC13192_OOI_PORT = 0; MC13192_OOI_PULLUP = 1 // Input port
*/	
	// Macros for communication between MCU and MC13192.
/*	#define ASSERT_CE                 MC13192_CE = 0 // Asserts the MC13192 CE pin
	#define DEASSERT_CE               MC13192_CE = 1 // Deasserts the MC13192 CE pin
	#define ASSERT_ATTN               MC13192_ATTN = 0
	#define DEASSERT_ATTN             MC13192_ATTN = 1
	#define ASSERT_RXTXEN             MC13192_RXTXEN = 1
	#define DEASSERT_RXTXEN           MC13192_RXTXEN = 0
	#define ASSERT_RESET              MC13192_RESET = 0
	#define DEASSERT_RESET            MC13192_RESET = 1
	#define DISABLE_RESET_PULLUP      MC13192_RESET_PULLUP = 0
	#define ENABLE_RX_ANTENNA         MC13192_ANT_CTRL = 0
	//#define DISABLE_ANT_CTRL          MC13192_ANT_CTRL = 0
	#define ENABLE_TX_ANTENNA         MC13192_ANT_CTRL = 1
	//#define DISABLE_ANT_CTRL2         MC13192_ANT_CTRL2 = 0
	#define ENABLE_LNA_CTRL           MC13192_LNA_CTRL = 1
	#define DISABLE_LNA_CTRL          MC13192_LNA_CTRL = 0
	#define ENABLE_PA_CTRL
	#define DISABLE_PA_CTRL	*/

	#define ACK_IRQ                   MC13192_IRQ_ACK_BIT = 1 // Dependent upon interrupt source chosen.
	#define ENABLE_IRQ                MC13192_IRQ_IE_BIT = 1
	#define DISABLE_IRQ               MC13192_IRQ_IE_BIT = 0
	#define IRQ_LEVEL_EDGE            MC13192_IRQ_MOD_BIT = 1
	#define IRQ_EDGE_ONLY             MC13192_IRQ_MOD_BIT = 0
	#define IRQ_FLAG_SET              MC13192_IRQ_FLAG_BIT
