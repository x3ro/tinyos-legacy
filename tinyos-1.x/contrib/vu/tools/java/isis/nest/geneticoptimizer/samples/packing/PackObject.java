/*
 * Created on Dec 28, 2003
 *
 * To change the template for this generated file go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
package isis.nest.geneticoptimizer.samples.packing;

import isis.nest.geneticoptimizer.*;

/**
 * @author Owner
 *
 * To change the template for this generated type comment go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
public class PackObject 
{
    public double value;
    public double size;
    
    public PackObject()
    {
        value = 100 * RandomSingleton.instance().nextDouble();
        size  = 100 * RandomSingleton.instance().nextDouble();
    }
}
