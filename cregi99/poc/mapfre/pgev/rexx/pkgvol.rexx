/*-----------------------------REXX----------------------------------*\
 *  Build a DFDSS PRINT statement for the package dataset index      *
 *  when XPEHOST issues a IDAI1001E message.                         *
 *  This rexx will be run by job EVGXPEAI and the diagnostics        *
 *  will be sent to IBM.                                             *
\*-------------------------------------------------------------------*/
trace n

dsn = 'PGEV.ENDEVOR.PACKAGE.INDEX'

x = listdsi("'"dsn"'")
say 'PKGVOL:' dsn '-' sysvolume

queue '  PRINT DATASET('dsn') INDYNAM('sysvolume')'

"execio 1 diskw out (finis"
if rc ^= 0 then call exception rc 'DISKW to OUT failed.'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
