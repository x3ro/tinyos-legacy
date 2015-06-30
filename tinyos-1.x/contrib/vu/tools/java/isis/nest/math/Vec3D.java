/*
 * Copyright (c) 2006, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Gyorgy Balogh, gyorgy.balogh@vanderbilt.edu
 */

package isis.nest.math;

public class Vec3D
{
    public double x;
    public double y;
    public double z;
    
    public Vec3D()
    {
        x = 0;
        y = 0;
        z = 0;
    }
    
    public Vec3D( double x, double y, double z )
    {
        this.x = x;
        this.y = y;
        this.z = z;
    }
        
    public Vec3D( Vec3D v )
    {
        x = v.x;
        y = v.y;
        z = v.z;
    }
    
    public void copy( Vec3D v )
    {
        x = v.x;
        y = v.y;
        z = v.z;        
    }
    
    public String toString()
    {
        return x + "\t" + y + "\t" + z;
    }
    
    public double getAzimuth()
    {
        double a = Math.atan2(y,x);
        if( a<0 )
            a+=2*Math.PI;
        return a;
    }
    
    public double getAzimuthInDegrees()
    {
        return getAzimuth() / Math.PI * 180;
    }
    
    public double getElevation()
    {
        return Math.asin(z/length());
    }
    
    public double getElevationInDegrees()
    {
        return getElevation() / Math.PI * 180;        
    }
        
    public Vec3D add( Vec3D b )
    {
        return new Vec3D(x+b.x, y+b.y, z+b.z);       
    }
        
    public Vec3D sub( Vec3D b )
    {
        return new Vec3D(x-b.x, y-b.y, z-b.z );
    }
        
    public static double calcAngle( Vec3D a, Vec3D b )
    {        
        return Math.acos(a.dot(b) / (a.length()*b.length()));
    }
    
    public double length()
    {
        return Math.sqrt(x*x+y*y+z*z);
    }
    
    public void norm()
    {
        double l = length();
        x /= l;
        y /= l;
        z /= l;
    }        
    
    public double dot( Vec3D b )
    {
        return x*b.x + y*b.y + z*b.z;
    }
    
    public Vec3D scale( double a )
    {               
        return new Vec3D(a*x, a*y, a*z );
    }
    
    public double distance( Vec3D b )
    {
        return Math.sqrt((b.x-x)*(b.x-x)+(b.y-y)*(b.y-y)+(b.z-z)*(b.z-z));   
    }
        
    public Vec3D rotateAroundZ( double a )
    {
        return new Vec3D(x*Math.cos(a)+y*Math.sin(a),
                -x*Math.sin(a)+y*Math.cos(a),z);         
    }
}
