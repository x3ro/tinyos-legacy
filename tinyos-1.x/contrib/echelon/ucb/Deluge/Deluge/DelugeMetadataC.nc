
/**
 * DelugeMetadataC.nc - Manages metadata.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

includes DelugePageTransfer;
includes DelugeMetadata;

configuration DelugeMetadataC {
  provides {
    interface DelugeMetadata as Metadata;
    interface StdControl;
  }
}
implementation {
  components
    DelugeMetadataM,
    BitVecUtilsC,
    DelugeStableStoreC as StableStore;

  StdControl = DelugeMetadataM;
  Metadata = DelugeMetadataM;

  DelugeMetadataM.BitVecUtils -> BitVecUtilsC;
  DelugeMetadataM.StableStore -> StableStore;
  DelugeMetadataM.StableStoreControl -> StableStore.StdControl;
}
