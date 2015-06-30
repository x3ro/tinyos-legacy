/* $Id: SimpleMac.nc,v 1.1 2005/01/31 21:05:29 freefrag Exp $ */
/** SimpleMac interface. Wrapper around Freescale SMAC library.

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

/* Include needed c structures. */
includes simplemac;

/** SimpleMac interface.
 *
 * <p>Provides an interface to the operations exposed by the Freescale
 * Simple MAC (SMAC) library.</p>
 *
 * <p>The hardware is put in receive mode upon initialization. By
 * disabling receive, you can go to idle mode. Hibernate and doze is
 * currently not supported. </p>
 */
interface SimpleMac {
  
  /**
   * Initialize interface.
   *
   * <p>Initialize the interface and sets it up for receiving (always on).
   * If receiving always is not what you want, call disableReceive.</p>
   *
   * @return SUCCESS or FAIL. If FAIL is returned, it means that the
   * radio could not be set in receive mode, and is in idle mode.
   */
  command result_t init();

  /** 
   * Reset event.
   * 
   * <p>This event is signalled if the MC13192 is reset.</p>
   * 
   * <p>TODO: I have no idea at this moment what to do about that,
   * really. Perhaps calling init is the best choice. The
   * documentation is absolutely unclear about why resets would
   * happen.</p>
   */
  event void reset();

  /** 
    * Set the physical channel for receiving and transmitting.
    *
    * <p>This eventually calls SMAC <code>MLME_set_channel_request</code>.
    * Note that the semantics of this call is slightly different</p>
    *
    * @param channel Value between 0-15.
    * @return SUCCESS if valid parameter, FAIL otherwise
    */
   command result_t setChannel(uint8_t channel);

  /**
   * Send a packet.
   *
   * <p>If the function returns success, expect a sendDone signal.</p>
   *
   * <p>This function eventually calls the SMAC
   * <code>MCPS_data_request</code> function.</p>
   * 
   * @param data The data to be send.
   * @return SUCCESS if the buffer will be sent, FAIL if not. 
   */
   command result_t send(tx_packet_t * packet);

   /**
    * SendDone event
    * 
    * <p>Will be signalled by send.</p>
    * 
    * @param packet the packet that was used as a parameter for send
    */
   event void sendDone(tx_packet_t * packet);

   /**
    * Disable receive mode/go to idle mode.
    * 
    * <p>Disable receive, put the chip into idle mode.</p>
    *
    * @return This call always succeds.
    */
   command void disableReceive();

   /**
    * Enable receive.
    *
    * <p>Enables receive, puts the chip in always on mode. It takes
    * 144 us for the chip to change modes - I am unsure what
    * implications, if any, that have on us as users.</p>
    *
    * @return SUCCESS if receive mode was entered, FAIL otherwise.
    */
   command result_t enableReceive();

   /**
    * Data arriving event.
    * 
    * <p>This function is called from SMAC using the
    * <code>MCPS_data_indication</code> callback.</p>
    *
    * @param data The data that has been received
    * @return A new (or the same) buffer for the SimpleMac layer to use
    */
   event rx_packet_t * receive(rx_packet_t * packet);

   /* **********************************************************************
    * Please ignore everything below this line.
    * *********************************************************************/



   
   /** 
    * Enable receive. OBSOLOTED!
    *
    * <p>You must call this command, with a carefully setup packet,
    * before you will get any receive events. The data field of packet
    * must point to a valid buffer and the maxDatalength field must be
    * set to the size of the buffer. You will have to call this command </p>
    *
    * <p>This command calls SMAC <code>MLME_RX_enable_request</code>.</p>
    * 
    * @param packet Structure that defines the memory wherein a
    * received packet should be put.
    * @param timeout Maximum time to wait, before the radio shuts
    * off. No unit is given in documentation. 0 means no timeout.
    */
   // command result_t enableReceive(rx_packet_t * packet, uint32_t timeout);

   /**
    * Disable receive */
   // int MLME_RX_disable_request(void);


 
   
   /* The following are not yet exposed - but may be. */

   /* Reset */
   // int MLME_MC13192_soft_reset(void);
      
   /* Sleep/doze/wakeup */
   // int MLME_hibernate_request(void);
   // int MLME_doze_request(void);
   // int MLME_wake_request(void); 
  
   /* Clock related */
   // int MLME_set_MC13192_clock_rate(__uint8__);
   // int MLME_MC13192_xtal_adjust(__uint8__);
   // int MLME_set_MC13192_tmr_prescale (__uint8__);

   /* Related to channel energy, adjustment, measurement */
   // __uint8__ MLME_energy_detect(void);
   // __uint8__ MLME_link_quality (void);
   // int MLME_MC13192_FE_gain_adjust(__uint8__);
   // int MLME_MC13192_PA_output_adjust(__uint8__);

   /* Not documented */
   // __uint8__ MLME_get_rfic_version(void);

}
