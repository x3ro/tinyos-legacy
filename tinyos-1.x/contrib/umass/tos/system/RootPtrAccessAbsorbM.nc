/*
 * file:        CompactionAbsorbM.nc
 * description: A component that absorbs the Compaction interface
 */

includes sizes;

module RootPtrAccessAbsorbM {
    uses interface RootPtrAccess;
}

implementation
{
    void dummy()
    {
        flashptr_t ptr;
        call RootPtrAccess.getPtr(&ptr);
    }
}
