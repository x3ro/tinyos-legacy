// $Id: GoldenImage.nc,v 1.1 2005/04/15 00:00:40 gtolle Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes Deluge;
includes GoldenImage;
includes TOSBoot;

configuration GoldenImage {
}

implementation {

  components
    Main,
    DelugeC,
    DelugeMetadataC as Metadata,
    DelugeStorageC as Storage,
    FlashWPC,
    GoldenImageM,
    InternalFlashC as IFlash,
    LedsC,
    NetProgC;

  components MgmtQueryC;
  components IdentC;
  components MSP430InternalSensorC;
  components MSP430InterruptCounterC;

  Main.StdControl -> GoldenImageM;

  GoldenImageM.DelugeControl -> DelugeC;
  GoldenImageM.MetadataControl -> Metadata;
  GoldenImageM.MgmtQueryControl -> MgmtQueryC;
  GoldenImageM.MgmtQueryControl -> IdentC;
  GoldenImageM.MgmtQueryControl -> MSP430InternalSensorC;

  GoldenImageM.DataWrite -> Storage.DataWrite[unique("DelugeDataWrite")];
  GoldenImageM.FlashWP -> FlashWPC;
  GoldenImageM.Metadata -> Metadata.Metadata[unique("DelugeMetadata")];
  GoldenImageM.IFlash -> IFlash;
  GoldenImageM.Leds -> LedsC;
  GoldenImageM.NetProg -> NetProgC;
  GoldenImageM.Storage -> Storage;

}
