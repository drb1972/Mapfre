/*------------------------------ REXX -------------------------------*\
 * EVELIBCK - Reads the CSV report created in the monthly Elib       *
 * housekeeping and builds an e-mail to report which datasets need   *
 * some attention.                                                   *
 *                                                                   *
 * Is is called in procedure EVHELIB2                                *
\*-------------------------------------------------------------------*/
trace n

return_code = 0 /* set the initial return code to zero               */

/* Read in the results of the monthly housekeeping                   */
"EXECIO * DISKR REPORT (STEM LINE. FINIS)"
if rc ^= 0 then call exception rc 'DISKR of DDname REPORT failed'

/* loop through each line of the report                              */
do a = 1 to line.0

  parse value line.a with dsn.a ',' alc.a ',' usd.a ',' fre.a ',' ,
        mem.a ',' ovs.a ',' lng.a ',' ext.a ',' vsm.a ',' pgall.a ',',
        avgpgm.a ',' pgusd.a ',' dirpg.a ',' pgcyl.a ',' rest.a

  if left(dsn.a,4) ^= "PREV" then iterate /* ignore headings         */

  /* take an action depending on the data found                      */
  select
    when strip(alc.a) < 4 then nop /* if file < 4 cyls then do nowt  */

    /* If there are > 25 cyls spare then ignore                      */
    when strip(alc.a) - strip(usd.a) < 25 then nop

    /* calculate if the dataset is less than 80% used                */
    when trunc((usd.a * 100) / alc.a) < 80 then do
      free = strip(alc.a) - strip(usd.a)
      queue left(dsn.a,18) "is < 80% used, alloc="left(alc.a,6),
            "free="free"."
      return_code = 1
    end /* when trunc((pgusd.a * 100) / alc.a) < 80 then do */

    /* If there are > 2 extents then report and set return_code      */
    when ext.a > 2 then do
      queue left(dsn.a,18) "has" strip(ext.a) "library extends."
      return_code = 1
    end /* when ext.a > 2 then do */

    /* If there are dir overflows then report and set return_code    */
    when ovs.a > 0 then do
      queue left(dsn.a,18) "has" strip(ovs.a) "directory overflows."
      return_code = 1
    end /* when ovs.a > 0 then do */

    when pos(".LISTING",dsn.a) > 0 & pgcyl.a ^= 30 then do
      queue left(dsn.a,18) "has" strip(pgcyl.a,6) "pages/cylinder, needs reorg."
      return_code = 1
    end /* when pos('.LISTING',dsn.a) > 0 & pgcyl.a ^= 30 then do */

    otherwise nop

  end /* end select */

end /* do a=1 to line.0                                              */

"execio" queued() "diskw email (finis" /* write to email ddname      */
if rc ^= 0 then call exception rc 'DISKW of DDname EMAIL failed'

exit return_code

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
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
