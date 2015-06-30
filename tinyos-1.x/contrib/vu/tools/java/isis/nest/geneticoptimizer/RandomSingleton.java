package isis.nest.geneticoptimizer;

import java.util.Random;

/**
 * RandomSingleton makes possible singleton access to the random number 
 * generator .
 */
public class RandomSingleton
{
    private static java.util.Random rand = new Random();
   
    /**
     * Gives back the isntance of the Random number generator. 
     * @return The instance of the Random number generator.
     */ 
    static public Random instance()
    {
        return rand; 
    }
}
