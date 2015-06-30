
/**
 * DelugeStableStoreC.nc - Provides stable storage services to Deluge.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

includes DelugeStableStore;
includes XnpImg;

configuration DelugeStableStoreC {
  provides {
    interface DelugeImgStableStore as ImgStableStore;
    interface DelugeMetadataStableStore as MetadataStableStore;
    interface StdControl;
  }
}
implementation {
  components
    DelugeStableStoreM as StableStore,
    PageEEPROMC as Flash,
    XnpImgC as BootImg;
  
  StdControl = StableStore;
  StdControl = Flash;
  StdControl = BootImg;
  ImgStableStore = StableStore;
  MetadataStableStore = StableStore;
  StableStore.Flash -> Flash.PageEEPROM[unique("PageEEPROM")];
  StableStore.BootImg -> BootImg;
}
