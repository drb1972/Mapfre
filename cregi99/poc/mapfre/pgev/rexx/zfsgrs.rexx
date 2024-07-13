/*-----------------------------REXX----------------------------------*\
 *  Display enqueues of ZFS dataset and wait until there are no      *
 *  active enqueues.                                                 *
\*-------------------------------------------------------------------*/
trace n

arg env zfshlqs /* This will dictate the cluster names we check      */

say
say 'ZFSGRS:' Date() Time()
say 'ZFSGRS:'
say 'ZFSGRS: Environment............:' env
say 'ZFSGRS: ZFS HLQS...............:' zfshlqs
say 'ZFSGRS:'

/* call the GRS subroutine for each dataset                          */
call do_grs zfshlqs'.'env'.SMGEVOLD'
call do_grs zfshlqs'.'env'.NEW'
call do_grs zfshlqs'.'env

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Use GRS to establish if the file is in use                        */
/*-------------------------------------------------------------------*/
do_grs:
 arg dsn

 do z = 1 to 10 /* just check 10 times for enqueues                  */

   say 'ZFSGRS: Looking for enqueues on' dsn
   say

   a = outtrap('GRSOUT.')
   "OC D GRS,RES=(*,"dsn")"

   do y = 1 to grsout.0 /* loop through output                       */
     say ' 'grsout.y
     if pos('NO REQUESTORS',grsout.y) > 0 then leave z
   end /* z = 1 to grsout.0 */

   if z = 10 then call exception 10 'Wait time exceeded'

   address syscall "sleep 60" /* wait 60 seconds                     */
 end /* z = 1 to 10 */

 say ' '

return /* do_grs */

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
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
