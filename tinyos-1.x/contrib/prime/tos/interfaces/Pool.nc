/*									tab:4
 * Lin Gu <lingu@cs.virginia.edu>
 * Date last modified:  12/2/2002
 */

includes MSG_POOL;
includes PktDef;

interface Pool {
  command result_t init();
  command char alloc();
  command char free(CellPtr pmsgToFree);
  command CellPtr copy(CellPtr pmsgSrc);
  command PoolInfoPtr getInfo();
}
