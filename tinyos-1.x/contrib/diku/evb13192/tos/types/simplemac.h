/* $Id: simplemac.h,v 1.2 2005/07/18 11:39:07 janflora Exp $ */
/** Include file for Freescale Simple Mac (SMAC) 

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/* These types have been copied off Simple Media Access Controller User's Guide */

// TODO: Probably need some way to handle #define SUCCESS .... 

#ifdef ENVIRONMENT_USESMAC

/* Transmit structure */
typedef struct {
  uint8_t dataLength;  /* Length of data (surprise!) */
  uint8_t * data;      /* Data */
} tx_packet_t;

/* Receive structure */
typedef struct {
  uint8_t maxDataLength; /* Set before handing packet over to MAC layer */
  uint8_t dataLength;    /* Length of data when arriving */
  uint8_t * data;        /* Data */
  uint8_t status;        /* SUCCESS or TIMEOUT */
} rx_packet_t;

/* We _have_ to define these symbols for the linker. Now, kids, it is
   not nice to include c code in header files! */
// TODO: This does not work, TinyOS removes it, or something. 
volatile uint8_t rtx_mode;
// TODO: We need more here, the ports.... sigh.
rx_packet_t *drv_rx_packet;

/* Stub function definitions. These are resolved by the linker. */
int MLME_set_MC13192_clock_rate(uint8_t rate);
int MCPS_data_request(tx_packet_t * data);
int MLME_set_channel_request(uint8_t channel);
int MLME_RX_enable_request(rx_packet_t * packet, uint32_t timeout);
int MLME_RX_disable_request();

/* More function definitions. These are documented absolutely nowhere, but
   the example apps use them, and I think they are needed to at least get the
   MC13192 going. We call them from SimpleMac.init() */
int MLME_MC13192_PA_output_adjust(uint8_t);

void mcu_init();
void MC13192_init();
void use_external_clock(); /* Changes to MC13192 supplied clock (I think) */

/* This is a special one, undocumented, of course. It is declared as
   an interrupt. */
extern void irq_isr();

#endif /* SimpleMac */
