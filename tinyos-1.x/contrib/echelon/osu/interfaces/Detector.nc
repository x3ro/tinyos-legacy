/*
  D e t e c t o r . n c

  (c) Copyright 2004 The MITRE Corporation (MITRE)

   Permission is hereby granted, without payment, to copy, use, modify,
   display and distribute this software and its documentation, if any,
   for any purpose, provided, first, that the US Government and any of
   its agencies will not be charged any license fee and/or royalties for
   the use of or access to said copyright software, and provided further
   that the above copyright notice and the following three paragraphs
   shall appear in all copies of this software, including derivatives
   utilizing any portion of the copyright software.  Use of this software
   constitutes acceptance of these terms and conditions.

   IN NO EVENT SHALL MITRE BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
   SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE
   OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MITRE HAS BEEN ADVISED
   OF THE POSSIBILITY OF SUCH DAMAGE.

   MITRE SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES
   INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
   NON-INFRINGEMENT.

   THE SOFTWARE IS PROVIDED "AS IS."  MITRE HAS NO OBLIGATION TO PROVIDE
   MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

*/
// 03/23/04 BPF Change numSamp to 16 bit integer.
// 03/30/04 BPF Expand Config to include MedianIndex arrays.
// 04/22/04 BPF Convert to component interface.

interface Detector {
  command result_t Config(uint16_t numSamp, uint8_t *samples,
    uint8_t median_len, uint8_t *med_buf, uint8_t *dev_buf,
    uint8_t *med_data_buf, uint8_t *med_index_buf,
    uint8_t *dev_data_buf, uint8_t *dev_index_buf,
    uint16_t period, uint16_t min_thresh);

  command result_t Start(uint16_t period);
  command void Stop();

  //Added by Hui Cao
  event void okStart();
  event void okStop();
  // End by Hui Cao
  event void TimeConflict();
} // Detector
