/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 11/21/05
 */

enum{
    HOP_DELAY_TIME = 4000,
    NUMBER_SAMPLES = 255,
    ARITHM_BASE = 4,

    TUNE_STEP = 65,//Hz
    BASE_FREQ = 430105543L,//Hz
    CHAN_SEP  = 526629L,//Hz


};

enum{
    NOT_VALID  = 255,
    //data collection type
    NO_HOP     = 0,
    TUNE_2_VEE_HOPA  = 1,
    TUNE_2_VEE_HOPB  = 2,
    TUNE_VEE_HOP  = 3,
    FREQ_HOP   = 4,
    EXACT_FREQS = 5,
    
    //algorithm type
    RAW_DATA = 0,
    RSSI_DATA = 16,
    RIPS_DATA = 48,
};



