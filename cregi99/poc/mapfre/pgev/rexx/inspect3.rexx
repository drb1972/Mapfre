/*-----------------------------REXX----------------------------------*\
 *  This routine analyses the Package Inspect report, and builds     *
 *  a summary file of all errors which is then emailed to the        *
 *  support mailbox.                                                 *
 *  Runs in EVHTASKD                                                 *
 *                                                                   *
 *  DDNAME REPIN : Inspect report (C1MSGS1)                          *
 *                                                                   *
 *  DDNAME REPOUT: Summary of inspect errors.                        *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

say rexxname':' Date() Time()
say rexxname':'

exit_rc = 0

"execio * diskr REPIN (stem rep. finis"
if rc ^= 0 then call exception rc 'DISKR of REPIN failed'

say rexxname':'
say rexxname': Here is the report output that is being processed'
say rexxname':'
do a = 1 to rep.0 /* loop through report and say each line           */
  say substr(rep.a,2,131)
end /* do a = 1 to rep.0 */

do c = 1 to rep.0
  /* If this is a new Statement in the Package Inspect list          */
  /* store the details in varibales for use later.                   */
  if pos('STATEMENT #',rep.c) > 0 then
    call get_scl_details(strip(word(rep.c,2),,'#'))

  msgid = word(rep.c,2)

  if msgid = 'ENMP090I' then do
    /* A New Package so clear all variables, i.e. fresh start.       */
    package  = strip(word(rep.c,7),,"'")
    elmname. = ''
    sysname. = ''
    elmtype. = ''
  end /* msgid = 'ENMP090I' */

  select
    when msgid = 'C1G0167E' then nop /* Element signed out           */
    when msgid = 'SMGR116E' then call msg_SMGR116E
    when msgid = 'C1G0503E' then call msg_C1G0503E
    when msgid = 'C1X0104E' then call msg_C1X0104E
    when msgid = 'PKMR513E' then call msg_PKMR513E
    when msgid = 'PKMR509E' then call msg_PKMR509E
    when msgid = 'ENBP001E' then nop /* Package not found            */
    when msgid = 'ENBP062E' then nop /* Package executed or reset    */
    when pos(':',word(rep.c,1)) > 0 & ,
         (right(msgid,1) = 'E'      | ,
          right(msgid,1) = 'S')     then call msg_unknown
    otherwise nop
  end /* select */
end /* c = 1 to rep.0 */

"execio "queued()" diskw REPOUT (finis)"
if rc ^= 0 then call exception rc 'DISKW to REPOUT failed'

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* This Subroutine assigns 3 variables elmname.n, sysname.n and      */
/* elmtype.n (n = statement number from the Package)                 */
/*-------------------------------------------------------------------*/
get_scl_details:
 arg stmt .

 do x = c+1 to rep.0
   if strip(rep.x) = 'SET STOPRC 16 .' then leave x
   if strip(rep.x) = '.'               then leave x
   if wordpos('ELEMENT',rep.x)     > 0 then
     elmname.stmt = Strip(word(rep.x,wordpos('ELEMENT',rep.x)+1),,"'")
   if wordpos('ENVIRONMENT',rep.x) > 0 then
     envname.stmt = Strip(word(rep.x,wordpos('ENVIRONMENT',rep.x)+1),,"'")
   if wordpos('SYSTEM',rep.x)      > 0 then
     sysname.stmt = Strip(word(rep.x,wordpos('SYSTEM',rep.x)+1),,"'")
   if wordpos('SUBSYSTEM',rep.x)   > 0 then
     subname.stmt = Strip(word(rep.x,wordpos('SUBSYSTEM',rep.x)+1),,"'")
   if wordpos('TYPE',rep.x)        > 0 then
     elmtype.stmt = Strip(word(rep.x,wordpos('TYPE',rep.x)+1),,"'")
   if wordpos('STAGE',rep.x)       > 0 then
     stgname.stmt = Strip(word(rep.x,wordpos('STAGE',rep.x)+1),,"'")
 end /* x = c+1 to rep.0 */

return /* get_scl_details: */

/*-------------------------------------------------------------------*/
/* Element has SYNC errors, write details to the summary file.       */
/*-------------------------------------------------------------------*/
msg_SMGR116E:
 estmt   = word(value('rep.'||c+1),8)
 exit_rc = 1
 queue package': ELEMENT' ,
       envname.estmt'/'sysname.estmt'/'subname.estmt'/' || ,
       elmname.estmt'/'elmtype.estmt'/'stgname.estmt
 queue copies(' ',length(package))': HAS A SYNC ERROR '

return /* msg_SMGR116E: */

/*-------------------------------------------------------------------*/
/* Two Packages clashes, write details to the summary file.          */
/*-------------------------------------------------------------------*/
msg_C1G0503E:
 estmt   = word(value('rep.'||c+1),8)
 exit_rc = 1
 queue package' CONFLICTS WITH PACKAGE' word(rep.c,10)
 queue 'FOR ELEMENT' ,
       envname.estmt'/'sysname.estmt'/'subname.estmt'/' || ,
       elmname.estmt'/'elmtype.estmt'/'stgname.estmt
 queue copies(' ',length(package))': PLEASE INVESTIGATE'

return /* msg_C1G0503E: */

/*-------------------------------------------------------------------*/
/* Element has JUMP errors, write details to the summary file.       */
/*-------------------------------------------------------------------*/
msg_C1X0104E:
 estmt   = word(value('rep.'||c+1),8)
 exit_rc = 1
 queue package': ELEMENT' ,
       envname.estmt'/'sysname.estmt'/'subname.estmt'/' || ,
       elmname.estmt'/'elmtype.estmt'/'stgname.estmt
 queue copies(' ',length(package))': HAS A JUMP ERROR'

return /* msg_C1X0104E: */

/*-------------------------------------------------------------------*/
/* Element has LVL errors, write details to the summary file.        */
/*-------------------------------------------------------------------*/
msg_PKMR513E:
 estmt   = word(value('rep.'||c+1),8)
 exit_rc = 1
 queue package': ELEMENT LVL FOR' ,
       envname.estmt'/'sysname.estmt'/'subname.estmt'/' || ,
       elmname.estmt'/'elmtype.estmt'/'stgname.estmt
 queue copies(' ',length(package))': HAS CHANGED SINCE PACKAGE CAST'

return /* msg_PKMR513E: */

/*-------------------------------------------------------------------*/
/* Element has disappeared, write details to the summary file.       */
/*-------------------------------------------------------------------*/
msg_PKMR509E:
 estmt   = word(value('rep.'||c+2),8)
 exit_rc = 1
 queue package': ELEMENT' elmname.estmt 'NOT FOUND AT:' || ,
       word(rep.c,9)

return /* msg_PKMR509E: */

/*-------------------------------------------------------------------*/
/* Unknown error message, write all details to the summary file.     */
/*-------------------------------------------------------------------*/
msg_unknown:
 estmt   = word(value('rep.'||c+2),8)
 exit_rc = 1
 queue package': ELEMENT' elmname.estmt 'UNKNOWN ERROR:'
 queue package':' strip(value('rep.'||c))
 queue package':' strip(value('rep.'||c+1))
 queue package':' strip(value('rep.'||c+2))

return /* msg_unknown: */

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

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
