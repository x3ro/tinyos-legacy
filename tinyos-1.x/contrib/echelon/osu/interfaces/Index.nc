/*
  I n d e x . n c

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

interface Index {
  command void init
    (uint8_t len,
     uint8_t *data, uint8_t *indexToData, uint8_t *dataToIndex,
     result_t *status);

  command void SwapIndex
    (uint8_t indexPos0, uint8_t indexPos1, result_t *status);
  command bool OutOfOrder
    (uint8_t indexPos0, uint8_t indexPos1, result_t *status);
} // Index
