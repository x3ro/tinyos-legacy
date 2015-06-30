
module SpanningTreePolicyM
{
    provides
    {
        interface FloodingPolicy;
    }
    uses
    {
        interface SpanningTreeParameters;
    }
}

implementation {

    /*
     * CHANGES:
     *  1. "inline"d
     *  2. Returned the conditiong being checked for.
     */
    
    inline result_t isRoot()
    {
        return (call FloodingPolicy.getLocation() == (uint16_t) 0xFFFE);
    }
    
    inline result_t closer(uint16_t location)
    {
        return (location == call SpanningTreeParameters.getGGParent() ||
                location == call SpanningTreeParameters.getGGGParent());
    }
    
    inline result_t farther(uint16_t location)
    {
        return (location == call SpanningTreeParameters.getParent() ||
                location == TOS_LOCAL_ADDRESS);
    }
    
    inline result_t atSameLevel(uint16_t location)
    {
        return (location == call SpanningTreeParameters.getGParent());
    }
    
    /* end changes */
    
    /* CHANGES:
     *  1. Changed (expression == TRUE) to (expression)
     */

    command uint16_t FloodingPolicy.getLocation()
    {
        return call SpanningTreeParameters.getGParent();
    }

    command uint8_t FloodingPolicy.sent(uint8_t priority)
    {        
        if(isRoot())
        {
            return 0x07;
        }
        else if((priority & 0x01) == 0x00)
        {
            return (priority + 1);
        }
        return priority; // ?
    }

    command result_t FloodingPolicy.accept(uint16_t location) {
        if(call SpanningTreeParameters.isInTree() == FALSE){
            return FALSE;
        }
        return (isRoot() ||
               (location == TOS_LOCAL_ADDRESS) ||
               (location == call SpanningTreeParameters.getParent()) ||
               (location == call SpanningTreeParameters.getGParent()) ||
               (location == call SpanningTreeParameters.getGGParent()) ||
               (location == call SpanningTreeParameters.getGGGParent()));
    }

    command uint8_t FloodingPolicy.received(uint16_t location, uint8_t priority)
    {        
        if(isRoot())
        {
            if((priority >= 0x09) &&
               (priority <= 0x1f))
            {
                return 0x06;
            }
        }
        else if(atSameLevel(location))
        {
            switch(priority)
            {
                case 0x00:
                    return 0x01;
                case 0x01:
                case 0x02:
                    return 0x03;
                case 0x03:
                case 0x05:
                case 0x06:
                    return 0x07; 
                default:
                    if(priority >= 0x09 &&
                       priority <= 0x1f)
                    {
                        return 7;
                    }
                    return priority; // ?
            }
        }
        else if(closer(location))
        {
            return 0x07;
        }
        else if(farther(location))
        {
            if(priority >= 0x09 && 
               priority <= 0x1f)
            {
                return 0x07;
            }
        }
        return priority; // ?
    }
    
    command uint8_t FloodingPolicy.age(uint8_t priority)
    {
        if(isRoot())
        {
            if(priority == 0x06)
            {
                return 0x07;
            }
            else if((priority >= 0x07) &&
                     (priority < 0x1f))
            {
                return (priority + 2);
            }
            else if(priority >= 0x1f)
            {
                return 0xFF;
            }
        }
        if((priority >= 0x07) &&
           (priority < 0x1f))
        {
            return (priority + 2);
        }
        else
        {
            switch(priority)
            {
                case 0x01:
                    return 0x02;
                case 0x03:
                    return 0x05;
                case 0x05:
                    return 0x06;
                case 0x01f:
                    return 0xFF;
            }
        }
        return priority; //?
    }
    
    /* end changes */
}


