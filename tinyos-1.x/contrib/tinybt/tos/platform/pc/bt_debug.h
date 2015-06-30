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
#ifndef BT_DEBUG_H
#define BT_DEBUG_H

static char* hcicmdStr[] = {
  "HCI_INQ",
  "HCI_INQ_SCAN",
  "HCI_PAGE",
  "HCI_PAGE_SCAN",
  "NUM_HCI_CMD",
};

static char* TraceAcctStr = " +";


static char* StateTypeStr[] = {
     "STANDBY",
     //"NEW_CONNECTION", //unused
     "CONNECTION",
     "PAGE",
     "PAGE_SCAN",
     "SLAVE_RESP",
     "SLAVE_RESP_ID_SENT",
     "MASTER_RESP",
     "INQUIRY",
     "INQ_SCAN",
     "INQ_RESP",
     "INVALID_STATE",
};

static char* PacketTypeStr[] = {
     "BT_NULL",
     "BT_POLL",
     "BT_FHS",
     "BT_DM1",
     "BT_DH1",
     "BT_HV1",
     "BT_HV2",
     "BT_HV3",
     "BT_DV",
     "BT_AUX1",
     "BT_DM3",
     "BT_DH3",
     "BT_DM5",
     "BT_DH5",
     "BT_ID"
};


static char* ProgTypeStr[] = {
     "NONE_IN_PROG",
     "INQ_IN_PROG",
     "PAGE_IN_PROG",
     "LMP_IN_PROG",
     "HOLD_IN_PROG",
     "ROLE_SWITCH_IN_PROG",
     "HOST_IN_PROG",
     "NEW_CONN_IN_PROG",
     "SCHED_IN_PROG",
};

static char* TimerTypeStr[] = {
     "INQ_TM",
     "INQ_SCAN_TM",
     "INQ_BACKOFF_TM",
     "INQ_RESP_TM",
     "PAGE_TM",
     "PAGE_SCAN_TM",
     "PAGE_RESP_TM",
     "NEW_CONN_TM",
     //"ALL_SCAN_TM", //unused
     "HOST_TM",
     "INVALID_TM",
};

static char* LMPCommandStr[] = {
     "LMP_HOST_CONN_REQ",
     "LMP_QOS_REQ",
     "LMP_HOLD_REQ",
     "LMP_ACCEPTED",
     "LMP_HOLD",
     "LMP_SLOT_OFFSET",
     "LMP_SWITCH_REQ",
     "LMP_DETACH",
     "LMP_NOT_ACCEPTED",
};

static char* btmodeStr[] = {
     "Disconnected",
     "Active",
     "Hold",
     "Sniff",
};

enum TraceLevel {
     LEVEL_PACKET	= 0x00000001, // send and receive of packets
     LEVEL_FUNCTION	= 0x00000002, // begin and end of functions
     LEVEL_MEMORY	= 0x00000004, // memory related
     LEVEL_ERROR	= 0x00000008, // errors
     LEVEL_LOW		= 0x00000010, // low priority
     LEVEL_MED		= 0x00000020, // medium priority
     LEVEL_HIGH		= 0x00000040, // high prirority
     LEVEL_ACCT		= 0X00000080, // accounting info (for analysis)
     LEVEL_STATE	= 0X00000100, // state changes
     LEVEL_TIMER	= 0X00000200, // timer changes
     LEVEL_SCHED        = 0x00000400, // scheduling (hold, sniff) etc.

     LEVEL_SPEC1        = 0x00010000,
     LEVEL_SPEC2        = 0x00020000,
     LEVEL_SPEC3        = 0x00040000,
     LEVEL_SPEC4        = 0x00080000,
     LEVEL_SPEC5        = 0x00100000,
     LEVEL_SPEC6        = 0x00200000,
     LEVEL_SPEC7        = 0x00400000,
     LEVEL_SPEC8        = 0x00800000,
     LEVEL_SPEC9        = 0x01000000,
     LEVEL_SPEC10       = 0x02000000,
     LEVEL_SPEC11       = 0x04000000,
     LEVEL_SPEC12       = 0x08000000,
     LEVEL_SPEC13       = 0x10000000,
     LEVEL_SPEC14       = 0x20000000,
     LEVEL_SPEC15       = 0x40000000,
     LEVEL_SPEC16       = 0x80000000,

     LEVEL_NONE		= 0x00000000,
     LEVEL_ALL		= 0xFFFFFFFF
};


#endif
