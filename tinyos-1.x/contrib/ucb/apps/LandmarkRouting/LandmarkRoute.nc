includes ERBcast;
includes SpanTree;
includes LandmarkRouting;

interface LandmarkRoute {
  command void reinit();

  command SpanTreeStatus_t getStatus();

  command void getRouteData(SpanTreeStatusConcise_t* val);

}
