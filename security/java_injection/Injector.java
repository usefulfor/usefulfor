/*
 * Injector.java - Java bytecode injection using Javassist proof of concept
 *    Daniel Martin Gomez <daniel@ngssoftware.com> - 24/Oct/2009
 *
 * usefulfor.com article:
 * http://usefulfor.com/security/2009/10/24/java-bytecode-injection/
 *
 * This file may be used under the terms of the GNU General Public License 
 * version 2.0 as published by the Free Software Foundation:
 *   http://www.gnu.org/licenses/gpl-2.0.html
 */

// http://www.csg.is.titech.ac.jp/~chiba/javassist/
import javassist.*;

class Injector
{

  public static void main(String[] argv) throws Exception
  {

    // Load the 'Protected' class representation
    ClassPool pool = ClassPool.getDefault();
    CtClass cc = pool.get("Protected");

    // Find the method we want to patch and rename it (we will be creating
    // a new method with the original name.
    CtMethod m_old = cc.getDeclaredMethod("checkPassword");
    m_old.setName( "checkPassword$impl" );

    // Create a new method with the same name as the old one
    CtMethod m_new = CtNewMethod.copy(m_old, "checkPassword", cc, null);

    // Provide the new method's implementation
    StringBuilder sb = new StringBuilder();
    sb.append( "{ return true; }" );
    m_new.setBody( sb.toString() );

    // Add the new method to the class. Patch the .class file
    cc.addMethod( m_new );
    cc.writeFile();

    System.out.println("Injection  complete. Methods in class Protected:");
    CtMethod[] methods = cc.getDeclaredMethods();
    for( int i=0; i<methods.length ; i++)
    {
      System.out.println( "\t" + methods[i].getLongName() );
    }
  }
}
