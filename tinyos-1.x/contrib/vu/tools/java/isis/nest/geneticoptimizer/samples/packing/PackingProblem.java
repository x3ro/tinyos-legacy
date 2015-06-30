package isis.nest.geneticoptimizer.samples.packing;

import isis.nest.geneticoptimizer.*;
import isis.nest.geneticoptimizer.samples.*;

/**
 * PackingProblem is a simple packign problem representation.
 */
public class PackingProblem implements Problem 
{
    class PackObject 
    {
        public double value;
        public double size;
    
        public PackObject()
        {
            value = 100 * RandomSingleton.instance().nextDouble();
            size  = 100 * RandomSingleton.instance().nextDouble();
        }
    }
     
    protected PackObject[] objects;
    protected double sizeThreshold;
    
    /**
     * The constructor. Creates a random packing problem with the given 
     * number of obejcts.
     * @param num_of_objects Number of objects.
     */
    public PackingProblem( int num_of_objects )
    {
        objects = new PackObject[num_of_objects];
        sizeThreshold = 0;
        for( int i=0; i<objects.length; ++i )
        {
            objects[i] = new PackObject();
            sizeThreshold += objects[i].size;
        }
        sizeThreshold = 0.2 * sizeThreshold;
    }
    
    /**
     * Createas a random solution of the packing problem. In this case
     * it is a SetGenoType instance which represents a random subset.
     */
	public Genotype createRandomSolution() 
    {
        return new SetGenoType( objects.length );
	}

    /**
     * Evalutate the given SetGenoType solution. It put the obejcts that are
     * in the subset into the bag and calculates the sum value. It stops
     * packing if size overflows.
     */
	public double evaluteSolution(Genotype sol) 
    {
        SetGenoType s = (SetGenoType)sol;
        double value = 0;
        double size  = 0;
        for( int i=0; i<objects.length; ++i )
        {
            if( s.gens[i] && size + objects[i].size <= sizeThreshold )
            {
                value += objects[i].value;
                size  += objects[i].size;
                if( size > sizeThreshold )
                    break;
            }
        }
		return value;
	}
}
