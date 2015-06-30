includes AM;
interface ReactiveRouter {
    //  command uint8_t getSendMetric(wsnAddr dest); uncomment later
    command wsnAddr getNextHop(wsnAddr dest);	
    command result_t generateRoute(wsnAddr dest);
}
