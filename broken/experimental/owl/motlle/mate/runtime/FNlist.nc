configuration FNlist {
  provides {
    interface MateBytecode as Cons;
    interface MateBytecode as Car;
    interface MateBytecode as Cdr;
    interface MateBytecode as PairP;
    interface MateBytecode as ListP;
    interface MateBytecode as NullP;
    interface MateBytecode as SetCarB;
    interface MateBytecode as SetCdrB;
    interface MateBytecode as List;
  }
}
implementation {
  components FNlistM, MProxy;

  Cons = FNlistM.Cons;
  Car = FNlistM.Car;
  Cdr = FNlistM.Cdr;
  PairP = FNlistM.PairP;
  ListP = FNlistM.ListP;
  NullP = FNlistM.NullP;
  SetCarB = FNlistM.SetCarB;
  SetCdrB = FNlistM.SetCdrB;
  List = FNlistM.List;

  FNlistM.S -> MProxy;
  FNlistM.T -> MProxy;
  FNlistM.E -> MProxy;
  FNlistM.V -> MProxy;
  FNlistM.GC -> MProxy;
}
