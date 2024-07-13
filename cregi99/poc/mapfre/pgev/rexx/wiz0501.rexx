/*-----------------------------REXX----------------------------------*\
 *  Called by TSO WIZ                                                *
 *  Builds delete elements and package jcl                           *
\*-------------------------------------------------------------------*/

parse arg change c1system ove
if ove = 'Y' then over = 'OVERRIDE SIGNOUT'
             else over = ''

address ispexec "vget (zuser zprefix)"

/* Start - Write JCL                                                 */
"alloc dd(ispfile) unit(vio) lrecl(80) blksize(23440)
       recfm( f b) space(5,5) tracks new reuse"
if rc ^= 0 then call exception rc 'ALLOC of ISPFILE failed.'

address ispexec
"FTOPEN"
if rc ^= 0 then call exception rc 'FTOPEN failed.'
initial = length(zuser) - 1
jobname = zprefix'WZ'substr(zuser,initial,1) || left(zuser,1)
"FTINCL WZDELALL"
if rc ^= 0 then call exception rc 'FTINCL of WZDELALL failed.'
"FTCLOSE"
if rc ^= 0 then call exception rc 'FTCLOSE failed.'

"LMINIT  DATAID(XYZ) DDNAME(ISPFILE)"
if rc ^= 0 then call exception rc 'LMINIT of XYZ failed.'
"LMOPEN  DATAID("xyz")"
if rc ^= 0 then call exception rc 'LMOPEN of' xyz 'failed.'
"VIEW    DATAID("xyz") MACRO(WIZMAC)"
if rc ^= 0 then call exception rc 'VIEW of' xyz 'failed.'
"LMCLOSE DATAID("xyz")"
if rc ^= 0 then call exception rc 'LMCLOSE of' xyz 'failed.'

address tso "FREE F(ISPFILE)"

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address ispexec "FTCLOSE"        /* Close any FTOPENed files      */
   address tso "FREE F(ISPFILE)"    /* Free files that may be open   */
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
