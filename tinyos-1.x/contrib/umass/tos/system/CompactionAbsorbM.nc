/*
 * file:        CompactionAbsorbM.nc
 * description: A dummy component that absorbs the Compaction interface
 */

includes sizes;

module CompactionAbsorbM {
    provides interface Compaction;
}

implementation
{
    command result_t Compaction.compact(uint8_t againgHint)
    {
        return (SUCCESS);
    }
}
