package isis.nest.geneticoptimizer.samples;

import isis.nest.geneticoptimizer.*;

import java.util.Random;

/**
 * SetGenoType is a general representation of subset selection problems.
 */
public class SetGenoType extends Genotype 
{
    public    static final double MUTATION_PROB = 0.01;
    
    /**
     * The set representation.
     */
    public    boolean[] gens;
    
    protected Random    rand;
    
    /**
     * The constructor. The dimension of the set is given. It initializes the 
     * set randomly.
     * @param dimension Dimesnion of the set.
     */
    public SetGenoType( int dimension )
    {
        rand = RandomSingleton.instance();
        gens = new boolean[dimension];
        random();
    }

    /**
     * Generate a random set.
     */    
    public void random()
    {
        for( int i=0; i<gens.length; ++i )
            gens[i] = (rand.nextDouble() > 0.5);
    }
    
    /**
     * Derives this set from two parents. 
     */
	public void derive(Genotype parent1, Genotype parent2) 
    {
        for( int i=0; i<gens.length; ++i )
        {
            if( rand.nextDouble() > MUTATION_PROB )
            {
                if( rand.nextDouble() > 0.5 )
                    gens[i] = ((SetGenoType)parent1).gens[i];
                else
                    gens[i] = ((SetGenoType)parent2).gens[i];
            }
            else
                gens[i] = (rand.nextDouble() > 0.5);
        }
	}
}
