configuration ChildrenCache {
  provides {
    interface Children;
  }
}
implementation {
  components Main, ChildrenCacheM, BitArrayC;
  ChildrenCacheM.BitArray -> BitArrayC;
  Main.StdControl -> ChildrenCacheM.StdControl;
  Children = ChildrenCacheM.Children;
}
