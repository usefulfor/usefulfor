/*
 * Protected.java - Dummy class with a "checkPassword()" method that will be 
 *   the target of our injection.
 *
 *    Daniel Martin Gomez <daniel@ngssoftware.com> - 24/Oct/2009
 *
 * usefulfor.com article:
 * http://usefulfor.com/security/2009/10/24/java-bytecode-injection/
 *
 * This file may be used under the terms of the GNU General Public License 
 * version 2.0 as published by the Free Software Foundation:
 *   http://www.gnu.org/licenses/gpl-2.0.html
 */

import java.util.Random;

class Protected
{

  public static boolean checkPassword(String password)
  {
    return String.valueOf( new Random().nextInt() ).equals(password);
  }

  public static void main(String[] argv)
  {
    if (argv.length != 1)
    {
      System.err.println("Please provide a password.");
      return;
    }

    if ( checkPassword(argv[0]) )
    {
      System.out.println("Success");
    }
    else
    {
      System.out.println("Failure");
    }
  }
}
