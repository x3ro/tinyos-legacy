/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/**
 * Baseband - reflects the Baseband module in blueware.
 *
 * <p>This module handles all operations related to the Baseband.</p>
 *
 * <p>It simulates the following from the Bluetooth baseband specifications.</p>
 * <ul>
 * <li>Frequency Hopping Kernel (79 hop)</li>
 * <li>Error Model</li>
 * <li>Inquiry and Paging procedures</li>
 * <li>Transmission and reception of baseband packets</li>
 * <li>Some HCI commands   </li>
 * </ul> */
interface BTBaseband
{
  command result_t init();
  command result_t start();
  command result_t stop();

  command enum state_progress_t getSessionInProg();
  command void beginSession(enum state_progress_t prog, int ticks, struct LMP* lmp);
  command void endSession(enum state_progress_t prog);
 

  /**
   * Get the bdAddr.
   *
   * \return the bdaddrs. */
  command btaddr_t bd_addr()
;
  command bool isSessionAvail(linkid_t lid);

  /**
   * Checks if this host is the master on a given linkid.
   *
   * \param lid the linkid to check
   * @return whether or not this host is a master on the linkid. */
  command bool isMasLink(linkid_t lid);

  /** Get the masters natural clock (wall clock) for a specific link id.
   * 
   * \param lid the linkid to get the clock for
   * \return the master clock for the piconet of the specified link id */
  command int mclkn(linkid_t lid);
     
  /** Get the natural clock for this host.
   *
   * \return the natural clock for this host  */
  command int clkn();

  command void holdLink(linkid_t lid, int intv, int mclk, bool bRcvd);
  command void roleChangeInProg(bool b);
  command void sendSlotOffset(linkid_t lid);
  command void recvSlotOffset(btaddr_t slv_addr);
  command void switchSlaveRole(amaddr_t am_addr);
  command void detach(struct LMP* linkq);
  command struct BTPacket* allocPkt(enum btpacket_t pktType, amaddr_t addr);

  command void event_recv_create(event_t* fevent, int mote, long long ftime, struct BTPacket* data);

  /* Bluetooth commands used by HCICore... */


  /** 
   * Tell the baseband to do an inquiry.
   * 
   * @param inqlen The length of the inquiry in ticks (312.5usec).
   * @param num_responses The number of responses, 0 for unlimited
   * @param iac The Inquiry Access Code. Uses <code>setIac</code> and 
   *        <code>getIac</code> to set and get the code. */
  command void inquire(int inqlen, int num_responses, int iac);

    /** 
   * Tell the baseband to do a page.
   * 
   * <p>The implementation works by filling in the bt.request_q_ structure and 
   * the PAGE_TM timer...</p>
   * 
   * @param addr the addr to page
   * @param clock_offset I suppose this is the clock offset of the receiver
   * @param pageto the page timeout, I reckon. */
  command void page(int addr, int clock_offset, int pageto);

  /**
   * Perform inquiry or page scan.
   *
   * <p>TODO: I think this procedure starts a scan, that is, sets the baseband in
   * scan mode. I have no idea what the actual consequenses are...</p>
   *
   * @param scan_state one of INQ_SCAN or PAGE_SCAN
   * @return wheter the scan mode was changed succesfully */
  command bool scan(enum state_t scan_state);

  /**
   * End the scan started with scan.
   *
   * <p>TODO: Ends the scan started with scan by...</p>
   *
   * @param state one of INQ_SCAN and PAGE_SCAN */
  command void endScan(enum state_t state);
}
