/*-----------------------------REXX----------------------------------*\
 *  Scan output from zfsadm command and then build some              *
 *  IDCAMS statements for the ZFS reorg initialise step.             *
\*-------------------------------------------------------------------*/
trace n

arg zfshlqs

say
say 'ZFSPACE:' Date() Time()
say 'ZFSPACE:'
say 'ZFSPACE: ZFS HLQS...............:' zfshlqs
say 'ZFSPACE:'

"execio * diskr INFILE (stem in. finis)"
if rc ^= 0 then call exception rc 'DISKR of INFILE failed'

/* Process all records in the input file                             */
do i = 1 to in.0

  if pos(zfshlqs,word(in.i,1)) > 0 then do

    dsn   = word(in.i,1)  /* name of the ZFS                         */
    free  = word(in.i,4)  /* number of free bytes                    */
    total = word(in.i,10) /* number of allocated bytes               */

    /* calculate how many trks are in use & then how much is needed  */
    used = total - free /* number of kilobytes allocated             */
    meg  = trunc(used / 1024 + 0.6) /* number of megabytes used      */
    cyl  = trunc(meg / 0.85 + 0.6)  /* number of cylinders used      */
    trk  = trunc(cyl * 15)          /* number of tracks    used      */
    pri  = trunc(trk * 1.2) /* no. of primary tracks to be allocated */
    If pri < 15 then pri = 15       /* do not not allow 0 cylinders  */
    sec  = trunc(pri / 10) /* no. of secondary tracks to be allocated*/

    /* Build IDCAMS statements                                       */
    queue ' DELETE' dsn'.NEW PURGE CLUSTER'
    queue
    queue ' SET MAXCC = 0'
    queue
    queue ' DELETE' dsn'.SMGEVOLD PURGE CLUSTER'
    queue
    queue ' SET MAXCC = 0'
    queue
    queue ' DEFINE CL(NAME('dsn'.NEW) -'
    queue '          TRK('pri sec')                -'
    queue '          MODEL('dsn'))                  '

  end /* pos(zfshlqs,word(in.i,1)) > 0 */

end /* i = 1 to in.0 */

/* Write the CA7 output to display all text that was processed       */
"execio" queued() "diskw OUTFILE (finis)"
if rc ^= 0 then call exception rc 'DISKW to OUTFILE failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
