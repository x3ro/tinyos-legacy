/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Internal file used for initialization of the external storage.
 * Please do not modify.
 */
configuration MainBlockStorageC {
}
implementation {
  components new MainControlC();
  components MainSTM25PC;
  components StorageManagerC;
  MainControlC.StdControl -> StorageManagerC;
}

