// $Id: CC1000Const.h,v 1.19 2004/04/14 20:46:50 jpolastre Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Phil Buonadonna
 *              David Moss - added many frequencies
 * Date last modified:  2/16/05
 *
 */

/**
 * @author Phil Buonadonna
 */



#ifndef _CC1KCONST_H
#define _CC1KCONST_H

#include <avr/pgmspace.h>
/* Constants defined for CC1K */
/* Register addresses */

#define CC1K_MAIN            0x00
#define CC1K_FREQ_2A         0x01
#define CC1K_FREQ_1A         0x02
#define CC1K_FREQ_0A         0x03
#define CC1K_FREQ_2B         0x04
#define CC1K_FREQ_1B         0x05
#define CC1K_FREQ_0B         0x06
#define CC1K_FSEP1           0x07
#define CC1K_FSEP0           0x08
#define CC1K_CURRENT         0x09
#define CC1K_FRONT_END       0x0A //10
#define CC1K_PA_POW          0x0B //11
#define CC1K_PLL             0x0C //12
#define CC1K_LOCK            0x0D //13
#define CC1K_CAL             0x0E //14
#define CC1K_MODEM2          0x0F //15
#define CC1K_MODEM1          0x10 //16
#define CC1K_MODEM0          0x11 //17
#define CC1K_MATCH           0x12 //18
#define CC1K_FSCTRL          0x13 //19
#define CC1K_FSHAPE7         0x14 //20
#define CC1K_FSHAPE6         0x15 //21
#define CC1K_FSHAPE5         0x16 //22
#define CC1K_FSHAPE4         0x17 //23
#define CC1K_FSHAPE3         0x18 //24
#define CC1K_FSHAPE2         0x19 //25
#define CC1K_FSHAPE1         0x1A //26
#define CC1K_FSDELAY         0x1B //27
#define CC1K_PRESCALER       0x1C //28
#define CC1K_TEST6           0x40 //64
#define CC1K_TEST5           0x41 //66
#define CC1K_TEST4           0x42 //67
#define CC1K_TEST3           0x43 //68
#define CC1K_TEST2           0x44 //69
#define CC1K_TEST1           0x45 //70
#define CC1K_TEST0           0x46 //71

// MAIN Register Bit Posititions
#define CC1K_RXTX		7
#define CC1K_F_REG		6
#define CC1K_RX_PD		5
#define CC1K_TX_PD		4
#define CC1K_FS_PD		3
#define CC1K_CORE_PD		2
#define CC1K_BIAS_PD		1
#define CC1K_RESET_N		0

// CURRENT Register Bit Positions
#define CC1K_VCO_CURRENT	4
#define CC1K_LO_DRIVE		2
#define CC1K_PA_DRIVE		0

// FRONT_END Register Bit Positions
#define CC1K_BUF_CURRENT	5
#define CC1K_LNA_CURRENT	3
#define CC1K_IF_RSSI		1
#define CC1K_XOSC_BYPASS	0

// PA_POW Register Bit Positions
#define CC1K_PA_HIGHPOWER	4
#define CC1K_PA_LOWPOWER	0

// PLL Register Bit Positions
#define CC1K_EXT_FILTER		7
#define CC1K_REFDIV		3
#define CC1K_ALARM_DISABLE	2
#define CC1K_ALARM_H		1
#define CC1K_ALARM_L		0

// LOCK Register Bit Positions
#define CC1K_LOCK_SELECT	4
#define CC1K_PLL_LOCK_ACCURACY	3
#define CC1K_PLL_LOCK_LENGTH	2
#define CC1K_LOCK_INSTANT	1
#define CC1K_LOCK_CONTINUOUS	0

// CAL Register Bit Positions
#define CC1K_CAL_START		7
#define CC1K_CAL_DUAL		6
#define CC1K_CAL_WAIT		5
#define CC1K_CAL_CURRENT	4
#define CC1K_CAL_COMPLETE	3
#define CC1K_CAL_ITERATE	0

// MODEM2 Register Bit Positions
#define CC1K_PEAKDETECT		7
#define CC1K_PEAK_LEVEL_OFFSET	0

// MODEM1 Register Bit Positions
#define CC1K_MLIMIT		5
#define CC1K_LOCK_AVG_IN	4
#define CC1K_LOCK_AVG_MODE	3
#define CC1K_SETTLING		1
#define CC1K_MODEM_RESET_N	0

// MODEM0 Register Bit Positions
#define CC1K_BAUDRATE		4
#define CC1K_DATA_FORMAT	2
#define CC1K_XOSC_FREQ		0

// MATCH Register Bit Positions
#define CC1K_RX_MATCH		4
#define CC1K_TX_MATCH		0

// FSCTLR Register Bit Positions
#define CC1K_DITHER1		3
#define CC1K_DITHER0		2
#define CC1K_SHAPE		1
#define CC1K_FS_RESET_N		0

// PRESCALER Register Bit Positions
#define CC1K_PRE_SWING		6
#define CC1K_PRE_CURRENT	4
#define CC1K_IF_INPUT		3
#define CC1K_IF_FRONT		2

// TEST6 Register Bit Positions
#define CC1K_LOOPFILTER_TP1	7
#define CC1K_LOOPFILTER_TP2	6
#define CC1K_CHP_OVERRIDE	5
#define CC1K_CHP_CO		0

// TEST5 Register Bit Positions
#define CC1K_CHP_DISABLE	5
#define CC1K_VCO_OVERRIDE	4
#define CC1K_VCO_AO		0

// TEST3 Register Bit Positions
#define CC1K_BREAK_LOOP		4
#define CC1K_CAL_DAC_OPEN	0


/* 
 * CC1K Register Parameters Table
 *
 * This table follows the same format order as the CC1K register 
 * set EXCEPT for the last entry in the table which is the 
 * CURRENT register value for TX mode.
 *  
 * NOTE: To save RAM space, this table resides in program memory (flash). 
 * This has two important implications:
 *	1) You can't write to it (duh!)
 *	2) You must read it using the PRG_RDB(addr) macro. IT CANNOT BE ACCESSED AS AN ORDINARY C ARRAY.  
 * 
 * Add/remove individual entries below to suit your RF tastes.
 * 
 */
#define CC1K_433_002_MHZ 0
#define CC1K_915_998_MHZ 1
#define CC1K_434_845_MHZ 2
#define CC1K_914_077_MHZ 3
#define CC1K_315_178_MHZ 4

#define CC1K_850_032_MHZ 5
#define CC1K_851_991_MHZ 6
#define CC1K_854_054_MHZ 7
#define CC1K_856_009_MHZ 8
#define CC1K_858_027_MHZ 9
#define CC1K_860_002_MHZ 10
#define CC1K_862_030_MHZ 11
#define CC1K_863_996_MHZ 12
#define CC1K_866_044_MHZ 13
#define CC1K_868_033_MHZ 14
#define CC1K_870_140_MHZ 15
#define CC1K_871_983_MHZ 16
#define CC1K_874_110_MHZ 17
#define CC1K_876_038_MHZ 18
#define CC1K_878_039_MHZ 19
#define CC1K_879_970_MHZ 20
#define CC1K_882_050_MHZ 21
#define CC1K_883_964_MHZ 22
#define CC1K_886_020_MHZ 23
#define CC1K_887_958_MHZ 24
#define CC1K_889_990_MHZ 25
#define CC1K_892_258_MHZ 26
#define CC1K_893_960_MHZ 27
#define CC1K_895_945_MHZ 28
#define CC1K_897_993_MHZ 29
#define CC1K_900_158_MHZ 30

#define CC1K_902_089_MHZ 31
#define CC1K_902_580_MHZ 32
#define CC1K_902_982_MHZ 33
#define CC1K_903_601_MHZ 34
#define CC1K_904_055_MHZ 35
#define CC1K_904_546_MHZ 36
#define CC1K_904_993_MHZ 37
#define CC1K_905_529_MHZ 38
#define CC1K_905_951_MHZ 39
#define CC1K_906_477_MHZ 40
#define CC1K_907_004_MHZ 41
#define CC1K_907_531_MHZ 42
#define CC1K_908_057_MHZ 43
#define CC1K_908_478_MHZ 44
#define CC1K_909_015_MHZ 45
#define CC1K_909_462_MHZ 46
#define CC1K_909_953_MHZ 47
#define CC1K_910_407_MHZ 48
#define CC1K_910_974_MHZ 49
#define CC1K_911_541_MHZ 50
#define CC1K_911_919_MHZ 51
#define CC1K_912_534_MHZ 52 
#define CC1K_913_036_MHZ 53
#define CC1K_913_455_MHZ 54
#define CC1K_913_850_MHZ 55
#define CC1K_914_377_MHZ 56
#define CC1K_914_991_MHZ 57
#define CC1K_915_511_MHZ 58
#define CC1K_916_015_MHZ 59
#define CC1K_916_483_MHZ 60
#define CC1K_917_010_MHZ 61
#define CC1K_917_536_MHZ 62
#define CC1K_918_063_MHZ 63
#define CC1K_918_473_MHZ 64
#define CC1K_918_985_MHZ 65
#define CC1K_919_481_MHZ 66
#define CC1K_920_048_MHZ 67
#define CC1K_921_012_MHZ 68
#define CC1K_921_750_MHZ 69
#define CC1K_922_487_MHZ 70
#define CC1K_922_978_MHZ 71
#define CC1K_923_451_MHZ 72
#define CC1K_924_018_MHZ 73
#define CC1K_924_514_MHZ 74
#define CC1K_925_026_MHZ 75
#define CC1K_925_436_MHZ 76
#define CC1K_925_963_MHZ 77
#define CC1K_926_489_MHZ 78
#define CC1K_927_016_MHZ 79
#define CC1K_927_484_MHZ 80 
#define CC1K_927_988_MHZ 81

#define CC1K_930_044_MHZ 82
#define CC1K_931_958_MHZ 83
#define CC1K_934_038_MHZ 84
#define CC1K_935_968_MHZ 85
#define CC1K_937_970_MHZ 86
#define CC1K_939_898_MHZ 87
#define CC1K_942_024_MHZ 88
#define CC1K_943_868_MHZ 89
#define CC1K_945_974_MHZ 90
#define CC1K_947_964_MHZ 91
#define CC1K_950_012_MHZ 92
#define CC1K_951_978_MHZ 93
#define CC1K_954_006_MHZ 94
#define CC1K_955_980_MHZ 95
#define CC1K_957_999_MHZ 96
#define CC1K_959_954_MHZ 97
#define CC1K_962_016_MHZ 98
#define CC1K_963_976_MHZ 99
#define CC1K_965_986_MHZ 100
#define CC1K_967_997_MHZ 101
#define CC1K_970_008_MHZ 102



#ifdef CC1K_DEFAULT_FREQ
#define CC1K_DEF_PRESET (CC1K_DEFAULT_FREQ)
#endif
#ifdef CC1K_MANUAL_FREQ
#define CC1K_DEF_FREQ (CC1K_MANUAL_FREQ)
#endif

#ifndef CC1K_DEF_PRESET
#define CC1K_DEF_PRESET	(CC1K_914_077_MHZ)
#endif 


//#define CC1K_SquelchInit        0x02F8 // 0.90V using the bandgap reference
#define CC1K_SquelchInit        0x138
#define CC1K_SquelchTableSize   9     
#define CC1K_MaxRSSISamples     5
#define CC1K_Settling           1
#define CC1K_ValidPrecursor     2
#define CC1K_SquelchIntervalFast 128
#define CC1K_SquelchIntervalSlow 2560
#define CC1K_SquelchCount       30
#define CC1K_SquelchBuffer      0

#define CC1K_LPL_STATES         7

#define CC1K_LPL_PACKET_TIME    16

// duty cycle         max packets        effective throughput
// -----------------  -----------------  -----------------
// 100% duty cycle    42.93 packets/sec  12.364kbps
// 35.5% duty cycle   19.69 packets/sec   5.671kbps
// 11.5% duty cycle    8.64 packets/sec   2.488kbps
// 7.53% duty cycle    6.03 packets/sec   1.737kbps
// 5.61% duty cycle    4.64 packets/sec   1.336kbps
// 2.22% duty cycle    1.94 packets/sec   0.559kbps
// 1.00% duty cycle    0.89 packets/sec   0.258kbps
static const prog_uchar CC1K_LPL_PreambleLength[CC1K_LPL_STATES*2] = {
    0, 8,      //28
    0, 94,      //94
    0, 250,     //250
    0x01, 0x73, //371,
    0x01, 0xEA, //490,
    0x04, 0xBC, //1212
    0x0A, 0x5E  //2654
};

static const prog_uchar CC1K_LPL_SleepTime[CC1K_LPL_STATES*2] = {
    0, 0,       //0
    0, 20,      //20
    0, 85,      //85
    0, 135,     //135
    0, 185,     //185
    0x01, 0xE5, //485
    0x04, 0x3D  //1085
};

static const prog_uchar CC1K_LPL_SleepPreamble[CC1K_LPL_STATES] = {
    0, 
    8,
    8,
    8, 
    8,
    8,
    8
};


static const prog_uchar CC1K_Params[103][31] = {
  // (0) 433.002 MHz channel, 19.2 Kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x58,0x00,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x57,0xf6,0x85,    //XBOW
    // FSEP1, FSEP0     0x07-0x08
    0x03,0x55,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((4<<CC1K_VCO_CURRENT) | (1<<CC1K_LO_DRIVE)),	
    // FRONT_END  0x0a
    ((1<<CC1K_IF_RSSI)),
    // PA_POW  0x0b
    ((0x0<<CC1K_PA_HIGHPOWER) | (0xf<<CC1K_PA_LOWPOWER)), 
    // PLL  0x0c
    ((12<<CC1K_REFDIV)),		
    // LOCK  0x0d
    ((0xe<<CC1K_LOCK_SELECT)),
    // CAL  0x0e
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    // MODEM2  0x0f
    ((0<<CC1K_PEAKDETECT) | (28<<CC1K_PEAK_LEVEL_OFFSET)),
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    // MATCH  0x12
    ((0x7<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    // FSCTRL 0x13
    ((1<<CC1K_FS_RESET_N)),			
    // FSHAPE7 - FSHAPE1   0x14-0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((8<<CC1K_VCO_CURRENT) | (1<<CC1K_PA_DRIVE)),
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE
  },

  // (1) 914.9988 MHz channel, 19.2 Kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x7c,0x00,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x7b,0xf9,0xae,					
    // FSEP1, FSEP0     0x07-0x8
    0x02,0x38,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((8<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE
  },

  // (2) 434.845200 MHz channel, 19.2 Kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x51,0x00,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x50,0xf7,0x4F,    //XBOW
    // FSEP1, FSEP0     0x07-0x08
    0X03,0x0E,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((4<<CC1K_VCO_CURRENT) | (1<<CC1K_LO_DRIVE)),	
    // FRONT_END  0x0a
    ((1<<CC1K_IF_RSSI)),
    // PA_POW  0x0b
    ((0x0<<CC1K_PA_HIGHPOWER) | (0xf<<CC1K_PA_LOWPOWER)), 
    // PLL  0x0c
    ((11<<CC1K_REFDIV)),		
    // LOCK  0x0d
    ((0xe<<CC1K_LOCK_SELECT)),
    // CAL  0x0e
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    // MODEM2  0x0f
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    // MATCH  0x12
    ((0x7<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    // FSCTRL 0x13
    ((1<<CC1K_FS_RESET_N)),			
    // FSHAPE7 - FSHAPE1   0x14-0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((8<<CC1K_VCO_CURRENT) | (1<<CC1K_PA_DRIVE)),
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE
  },

 
  // (3) 914.077 MHz channel, 19.2 Kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xe0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xdb,0x42,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (4) 315.178985 MHz channel, 38.4 Kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x45,0x60,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x45,0x55,0xBB,
    // FSEP1, FSEP0     0x07-0x08
    0X03,0x9C,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (0<<CC1K_LO_DRIVE)),	
    // FRONT_END  0x0a
    ((1<<CC1K_IF_RSSI)),
    // PA_POW  0x0b
    ((0x0<<CC1K_PA_HIGHPOWER) | (0xf<<CC1K_PA_LOWPOWER)), 
    // PLL  0x0c
    ((13<<CC1K_REFDIV)),		
    // LOCK  0x0d
    ((0xe<<CC1K_LOCK_SELECT)),
    // CAL  0x0e
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    // MODEM2  0x0f
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (0<<CC1K_XOSC_FREQ)),
    // MATCH  0x12
    ((0x7<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    // FSCTRL 0x13
    ((1<<CC1K_FS_RESET_N)),			
    // FSHAPE7 - FSHAPE1   0x14-0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((8<<CC1K_VCO_CURRENT) | (1<<CC1K_PA_DRIVE)),
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE
  },



////////////////////////////////////////////
  // (56) 850.032 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x56,0x54,0x5d,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x56,0x57,0x70,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (57) 851.991 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x56,0x87,0x62,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x56,0x8a,0x75,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (58) 854.054 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x56,0xbd,0x17,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x56,0xc0,0x2a,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (59) 856.009 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x56,0xf0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x56,0xf3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (60) 858.027 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x57,0x24,0x92,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x57,0x27,0xa5,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (61) 860.002 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x57,0x58,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x57,0x5b,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (62) 862.030 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x57,0x8c,0xcd,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x57,0x8f,0xdf,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (63) 863.996 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x57,0xc0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x57,0xc3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (64) 866.044 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x57,0xf5,0x55,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x57,0xf8,0x68,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (65) 868.033 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x58,0x29,0x25,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x58,0x2c,0x37,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (66) 870.140 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x58,0x60,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x58,0x63,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (67) 871.983 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x58,0x90,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x58,0x93,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (68) 874.110 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x58,0xc7,0x62,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x58,0xca,0x75,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (69) 876.038 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x58,0xf9,0x9a,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x58,0xfc,0xac,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (70) 878.039 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x59,0x2d,0xb7,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x59,0x30,0xca,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (71) 879.970 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x59,0x60,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x59,0x63,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (72) 882.050 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x59,0x96,0x27,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x59,0x99,0x3a,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },



  // (73) 883.964 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x59,0xc8,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x59,0xcb,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (74) 886.020 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x59,0xfd,0x8a,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x59,0x00,0x9d,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (74) 887.958 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5a,0x30,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x59,0x33,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (75) 889.990 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5a,0x64,0xec,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5a,0x67,0xff,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (76) 892.258 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5a,0xa0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5a,0xa3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (77) 893.960 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5a,0xcc,0x4f,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5a,0xcf,0x61,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (77) 895.945 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0x00,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0x03,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (78) 897.993 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0x35,0x55,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0x38,0x68,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (79) 900.158 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0x6d,0xb7,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0x70,0xca,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

///////////////////////////////////////////////
  // (5) 902.089 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xa0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xa3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (6) 902.580 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xac,0xcd,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xaf,0xdf,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (7) 902.982 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xb7,0x46,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xba,0x58,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (8) 903.601 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xc7,0x62,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xca,0x75,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (9) 904.055 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xd3,0x33,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xd6,0x46,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (10) 904.546 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xe0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xe3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (11) 904.993 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xeb,0xa3,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xee,0xb6,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (12) 905.529 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5b,0xf9,0x9a,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5b,0xfc,0xac,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (13) 905.951 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x04,0x92,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x07,0xa5,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (14) 906.477 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x12,0x49,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x15,0x5c,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (15) 907.004 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x20,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x23,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (16) 907.531 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x2d,0xb7,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x30,0xca,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (17) 908.057 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x3b,0x6e,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x3e,0x80,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (18) 908.478 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x46,0x66,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x49,0x79,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (19) 909.015 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x54,0x5d,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x57,0x70,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (20) 909.462 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x60,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x63,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (21) 909.953 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x6c,0xcd,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x6f,0xdf,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (22) 910.407 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x78,0x9e,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x7b,0xb0,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (23) 910.974 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x87,0x62,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x8a,0x75,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (24) 911.541 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0x96,0x27,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0x99,0x3a,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (25) 911.919 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xa0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xa3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (26) 912.534 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xb0,0x00,				
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xb3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (27) 913.036 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xbd,0x17,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xc0,0x2a,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (28) 913.455 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xc8,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xcb,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (29) 913.850 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xd2,0x49,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xd5,0x5c,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (30) 914.377 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xe0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xe3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (31) 914.991 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xf0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5c,0xf3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (32) 915.511 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5c,0xfd,0x8a,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x00,0x9d,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (33) 916.015 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x0a,0xab,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x0d,0xbd,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (34) 916.483 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x16,0xdb,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x19,0xee,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (35) 917.010 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x24,0x92,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x27,0xa5,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (36) 917.536 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x32,0x49,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x35,0x5c,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (37) 918.063 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x40,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x43,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (38) 918.473 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x4a,0xab,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x4d,0xbd,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (39) 918.985 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x58,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x5b,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (40) 919.481 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x64,0xec,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x67,0xff,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (41) 920.048 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x73,0xb1,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x76,0xc4,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (42) 921.012 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0x8c,0xcd,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0x8f,0xdf,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (43) 921.75 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xa0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xa3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (44) 922.487 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xb3,0x33,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xb6,0x46,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (45) 922.978 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xc0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xc3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (46) 923.451 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xcc,0x4f,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xcf,0x61,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (47) 924.018 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xdb,0x14,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xde,0x26,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (48) 924.514 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xe8,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xeb,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (49) 925.026 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5d,0xf5,0x55,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5d,0xf8,0x68,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (50) 925.436 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x00,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x03,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (51) 925.963 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x0d,0xb7,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x10,0xca,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (52) 926.489 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x1b,0x6e,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x1e,0x80,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (53) 927.016 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x29,0x25,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x2c,0x37,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (54) 927.484 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x35,0x55,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x38,0x68,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (55) 927.988 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x42,0x76,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x45,0x89,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

////////////////////////////////////////////////
  // (80) 930.044 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0x78,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0x7b,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (80) 931.958 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0xa9,0xd9,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0xac,0xeb,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (81) 934.038 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5e,0xe0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5e,0xe3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (82) 935.968 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5f,0x12,0x49,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5f,0x15,0x5c,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (83) 937.970 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5f,0x46,0x66,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5f,0x49,0x79,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (84) 939.898 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5f,0x78,0x9e,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5f,0x7b,0xb0,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (85) 942.024 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5f,0xb0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5f,0xb3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (86) 943.868 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x5f,0xe0,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x5f,0xe3,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (87) 945.974 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x60,0x16,0xdb,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x60,0x19,0xee,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (88) 947.964 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x60,0x4a,0xab,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x60,0x4d,0xbd,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (89) 950.012 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x60,0x80,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x60,0x83,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (90) 951.978 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x60,0xb3,0x33,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x60,0xb6,0x46,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (91) 954.006 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x60,0xe8,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x60,0xeb,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (92) 955.980 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x61,0x1b,0x6e,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x61,0x1e,0x80,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (93) 957.999 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x61,0x50,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x61,0x53,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (94) 959.954 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x61,0x82,0xe9,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x61,0x85,0xfb,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (95) 962.016 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x61,0xb8,0x9e,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x61,0xbb,0xb0,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (96) 963.976 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x61,0xeb,0xa3,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x61,0xee,0xb6,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


  // (97) 965.986 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x62,0x20,0x00,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x62,0x23,0x13,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (98) 967.997 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x62,0x54,0x5d,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x62,0x57,0x70,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },

  // (99) 970.008 MHz channel, 19.2 kbps data, Manchester Encoding, High Side LO
  { // MAIN   0x00 
    0x31,
    // FREQ2A,FREQ1A,FREQ0A  0x01-0x03
    0x62,0x88,0xba,					
    // FREQ2B,FREQ1B,FREQ0B  0x04-0x06
    0x62,0x8b,0xcd,					
    // FSEP1, FSEP0     0x07-0x8
    0x01,0xAA,
    // CURRENT (RX MODE VALUE)   0x09 (also see below)
    ((8<<CC1K_VCO_CURRENT) | (3<<CC1K_LO_DRIVE)),
    //0x8C,	
    // FRONT_END  0x0a
    ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | (1<<CC1K_IF_RSSI)),
    //0x32,
    // PA_POW  0x0b
    ((0x8<<CC1K_PA_HIGHPOWER) | (0x0<<CC1K_PA_LOWPOWER)), 
    //0xff,
    // PLL  0xc
    ((6<<CC1K_REFDIV)),		
    //0x40,
    // LOCK  0xd
    ((0x1<<CC1K_LOCK_SELECT)),
    //0x10,
    // CAL  0xe
    ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)),	
    //0x26,
    // MODEM2  0xf
    ((1<<CC1K_PEAKDETECT) | (33<<CC1K_PEAK_LEVEL_OFFSET)),
    //0xA1,
    // MODEM1  0x10
    ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | (CC1K_Settling<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N)), 
    //0x6f, 
    // MODEM0  0x11
    ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | (1<<CC1K_XOSC_FREQ)),
    //0x55,
    // MATCH 0x12
    ((0x1<<CC1K_RX_MATCH) | (0x0<<CC1K_TX_MATCH)),
    //0x10,
    // FSCTRL  0x13
    ((1<<CC1K_FS_RESET_N)),			
    //0x01,
    // FSHAPE7 - FSHAPE1   0x14..0x1a
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,	
    // FSDELAY   0x1b
    0x00,	
    // PRESCALER    0x1c
    0x00,
    // CURRENT (TX MODE VALUE)  0x1d
    ((15<<CC1K_VCO_CURRENT) | (3<<CC1K_PA_DRIVE)),
    //0xf3,
    // High side LO  0x1e (i.e. do we need to invert the data?)
    TRUE 
  },


};

#endif /* _CC1KCONST_H */

