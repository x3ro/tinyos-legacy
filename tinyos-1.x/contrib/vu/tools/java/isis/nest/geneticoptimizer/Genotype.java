package isis.nest.geneticoptimizer;

/**
 * Genotype is a base class for different solution representations of 
 * optmization problems.
 *  
 */

public class Genotype implements Comparable 
{
    /**
     * Fitness of the representetd solution. The higher the value, the 
     * better the solution is.
     */
    public double fitness;
    

    /**
     * Derives this solution from two parents. Genetic operators should be
     * implemented in the function.
     * 
     * Typically the two parens are corossed over and some additional
     * mutations are done.
     * 
     * @param parent1 First parent
     * @param parent2 Second parent
     */
    public void derive( Genotype parent1, Genotype parent2 )
    {
    }
    
    /**
     * Generates a uniform distribution random soluition over the 
     * search space.
     *
     */
    public void random()
    {
    }
    
    /**
     * Compares two soultions based on fitness.
     */
    public int compareTo(Object arg0)
    {
        Genotype a = (Genotype)arg0;        
        if( a.fitness < fitness )
            return -1;
        else
            return 1;
    }
}
