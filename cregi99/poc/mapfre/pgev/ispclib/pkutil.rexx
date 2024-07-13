/*-----------------------------REXX----------------------------------*\
 *  Package inspect, cast, reset utility.                            *
 *  Used in the Endevor ISPF panels using the following commands:    *
 *    PKU HELP                                                       *
 *    PKU INSPECT <pkgid>  r PKU I  <pkgid>                          *
 *    PKU BUILD   <pkgid> or PKU B  <pkgid>                          *
 *    PKU CAST    <pkgid> or PKU C  <pkgid>                          *
 *    PKU RESET   <pkgid> or PKU R  <pkgid>                          *
 *    PKU RC      <pkgid> or PKU RC <pkgid> (reset and cast)         *
 *  Can also be used with point and shoot for the package id or      *
 *  if you leave the package id blank you will be prompted for it.   *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg parm

valid_actions = 'HELP INSPECT BUILD CAST RESET RC'
action        = word(parm,1)
uid           = sysvar('sysuid')

/* Is the action a prefix of a valid action ?                        */
do i = 1 to words(valid_actions)
  if action = substr(word(valid_actions,i),1,length(action)) then do
    action = word(valid_actions,i)
    leave
  end /* action = substr(word(valid_actions,i),length(action)) */
end /* i = 1 to words(valid_actions) */

if wordpos(action,valid_actions) = 0 then do
  say ' Invalid action entered:' action
  say '   Valid actions are:' valid_actions
  exit
end /* pos(word(parm,1),valid_actions) = 0 */

if action = '' | action = 'HELP' then do
  say 'Valid actions are:' valid_actions
  say
  say 'To run in foreground:-'
  say ' From Endevor enter "PKU <action>"'
  say '           or enter "PKU <action> <pkgid>"'
  say '           or enter "PKU <action>" and point and shoot to the' ,
      'package id'
  say
  say 'To run in batch:-'
  say ' From Endevor enter "PKU <action> BATCH"'
  say '           or enter "PKU <action> <pkgid> BATCH"'
  say '           or enter "PKU <action> BATCH" and point and shoot to',
                           'the package id'
  exit 8
end /* action = 'HELP' */

select
  when word(parm,2) = 'BATCH' then do
    pkgid = ''
    bflag = 'BATCH'
  end /* word(parm,2) = 'BATCH' */
  when word(parm,2) = 'TEST' then do
    pkgid = ''
    bflag = ''
  end /* word(parm,3) = 'TEST' */
  otherwise do
    pkgid  = word(parm,2)
    bflag  = word(parm,3)
  end /* otherwise */
end /* select */

if pkgid = '' then do
  /* First check for point and shoot to a valid package id           */
  address ispexec 'VGET (ZSCREENI,ZSCREENC)' /* Extract screen image */
  delims = "&<>()=', " || '"'
  curpos = zscreenc + 1
  do x = curpos to 1 by -1 /* Find the start of the field            */
    if pos(substr(zscreeni,x,1),delims) ^= 0 then do
      start = x + 1
      leave
    end /* pos(substr(zscreeni,x,1),delims) ^= 0 */
  end /* x = curpos to 1 by -1 */
  do x = curpos to length(zscreeni) /* Find the end of the field     */
    if pos(substr(zscreeni,x,1),delims) ^= 0 then do
      len = x - start
      if len > 0 then do
        paspkgid = substr(zscreeni,start,len)
        upper paspkgid
        if left(paspkgid,2) = 'C0'        | ,
           left(paspkgid,2) = left(uid,2) then
          pkgid = paspkgid
        leave
      end /* len > 0 */
    end /* pos(substr(zscreeni,x,1),delims) ^= 0 */
  end /* x = curpos to length(zscreeni) */
end /* pkgid = '' */

if action = 'BUILD' then
  call build_pkg
else do
  if pkgid = '' then do
    say ' Please enter the package id (or blank to quit):'
    pull pkgid
  end /* pkgid = '' */

  if pkgid = '' | pkgid = 'EXIT' | pkgid = 'QUIT' then do
    say ' Package id not specified'
    exit 8
  end /* pkgid = '' */

  if bflag = 'BATCH' then call batch_util
                     else call foreground_run
end /* else */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Build_pkg - Build and cast the package                            */
/*-------------------------------------------------------------------*/
build_pkg:

 address ispexec

 if pkgid = '' then do
   "VGET (PKGID)"
   cursor = 'PKGID'
 end /* pkgid = '' */
 else
   cursor = 'PKGSY'

 "DISPLAY PANEL(PKBUILD) CURSOR("cursor")"
 if rc > 4 then return

 call check_pkg
 delpkg = ''
 if csv.0 > 0 then do
   pkgstat = substr(csv.1,116,12)
   if substr(pkgid,9,1) = 'P' then do
     invalid_status = 'IN-EXECUTION EXECUTED EXEC-FAILED COMMITTED'
     if wordpos(pkgstat,invalid_status) > 0 then do
       zedsmsg = 'Package Status' pkgstat
       zedlmsg = 'Can not reuse a package when it is' pkgstat
       "setmsg msg(ISRZ001)"
       signal build_pkg
     end /* wordpos(pkgstat,invalid_status) > 0 */
   end /* substr(pkgid,9,1) = 'P' */
   "ADDPOP"
   "DISPLAY PANEL(PKEXIST)"
   if rc     > 4   | ,
      delpkg = 'N' then do
     "REMPOP"
     signal build_pkg
   end /* rc > 4 */
 end /* csv.0 > 0 */
 if delpkg ^= 'N' then do
   ccid = left(pkgid,8)

   select
     when substr(pkgid,9,1) = 'P' then do
       env1 = 'ACPT'; stg1 = 'F'
       env2 = 'PROD'; stg2 = 'O'
     end /* substr(pkgid,9,1) = 'P' */
     when substr(pkgid,9,1) = 'F' then do
       env1 = 'SYST'; stg1 = 'D'
       env2 = 'ACPT'; stg2 = 'E'
     end /* substr(pkgid,9,1) = 'F' */
     when substr(pkgid,9,1) = 'D' then do
       env1 = 'UNIT'; stg1 = 'B'
       env2 = 'SYST'; stg2 = 'C'
     end /* substr(pkgid,9,1) = 'D' */
     when substr(pkgid,9,1) = 'B' then do
       env1 = 'UNIT'; stg1 = 'A'
       env2 = 'XXXX'; stg2 = 'X'
     end /* substr(pkgid,9,1) = 'B' */
     otherwise nop
   end /* select */

   "FTOPEN TEMP"
   if rc ^= 0 then call exception rc 'FTOPEN failed.'
   "FTINCL PKBUILD"
   if rc ^= 0 then call exception rc 'FTINCL of PKBUILD failed.'
   "FTCLOSE"
   if rc ^= 0 then call exception rc 'FTCLOSE failed.'
   "vget (ztempf) shared"
   address tso "submit '"ztempf"'"

 end /* delpkg ^= 'N' */
 else do
   zedsmsg = 'Package Already Exists'
   zedlmsg = 'Package' pkgid 'already exists.'
   "setmsg msg(ISRZ001)"
 end /* else */

return /* build_pkg: */

/*-------------------------------------------------------------------*/
/* Check_pkg - Check to see if the package exists                    */
/*-------------------------------------------------------------------*/
check_pkg:

 address tso
 /* Free incase there are hangovers. Do not code an exception call   */
 test = msg(off)
 "free f(CSVIPT01 CSVMSGS1 APIEXTR)"
 test = msg(on)

 "alloc f(CSVIPT01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVIPT01 failed.'

 /* Write the input for the CSV utility                              */
 inp.1 = '  LIST PACKAGE ID' pkgid 'OPTIONS NOCSV.'
 inp.0 = 1
 'execio' inp.0 'diskw CSVIPT01 (stem inp. finis)'
 if rc ^= 0 then call exception rc 'DISKW to CSVIPT01 failed.'

 /* Allocate the necessary datasets                                  */
 "alloc f(CSVMSGS1) new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVMSGS1 failed.'
 "alloc f(APIEXTR) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 /* Invoke the CSV utility                                           */
 if sysvar("sysenv") = 'FORE' then
   address "LINKMVS" 'BC1PCSV0'
 else
   "CALL   *(NDVRC1) 'BC1PCSV0'"
 lnk_rc = rc

 if lnk_rc > 8 then do
   "execio * diskr CSVMSGS1 (stem c1. finis"
   do i = 1 to c1.0
     say c1.i
   end /* i = 1 to c1.0 */
   call exception lnk_rc 'Call to BC1PCSV0 failed'
 end /* rc > 0 */

 "free f(CSVMSGS1 CSVIPT01)"

 csv.0 = 0
 g = listdsi(APIEXTR file) /* Check for output                       */
 if g = 0 then do
   "execio * diskr APIEXTR (stem csv. finis"
   if rc ^= 0 then call exception rc 'DISKR of APIEXTR failed.'
   "free f(APIEXTR)"
 end /* g = 0 */

return /* check_pkg: */

/*-------------------------------------------------------------------*/
/* Batch_util - Submit a batch job to do the action                  */
/*-------------------------------------------------------------------*/
batch_util:

 address ispexec
 "DISPLAY PANEL(JOBCARD)" /* Get the jobcard                         */
 if rc > 4 then return

 if action = 'RC' then do
   scl1 = '  RESET PACKAGE' pkgid '.'
   scl2 = '  CAST  PACKAGE' pkgid '.'
 end /* action = 'RC' */
 else do
   scl1 = ' ' action 'PACKAGE' pkgid '.'
   scl2 = ' '
 end /* action = 'RC' */

 "FTOPEN TEMP"
 if rc ^= 0 then call exception rc 'FTOPEN failed.'
 "FTINCL PKUTIL"
 if rc ^= 0 then call exception rc 'FTINCL of PKUTIL failed.'
 "FTCLOSE"
 if rc ^= 0 then call exception rc 'FTCLOSE failed.'
 "VGET (ZTEMPF) SHARED"
 address tso "submit '"ztempf"'"

return /* batch_util: */

/*-------------------------------------------------------------------*/
/*  Foreground_run - Do the action in foreground                     */
/*-------------------------------------------------------------------*/
foreground_run:

  /*  Prepare SCL                                                   */
  address tso
  test=msg(off)
  "free f(ENPSCLIN C1MSGS1 SYSPRINT PKGRPT1A)"
  test=msg(on)

  "alloc f(ENPSCLIN) new space(2  2) cylinders recfm(f b) lrecl(80)"
  if rc ^= 0 then call exception rc 'ALLOC of ENPSCLIN failed'
  if action = 'RC' then do
    queue '  RESET PACKAGE' pkgid '.'
    queue '  CAST  PACKAGE' pkgid '.'
  end /* action = 'RC' */
  else
    queue ' ' action 'PACKAGE' pkgid '.'
  "execio" queued() "diskw ENPSCLIN (finis)"
  if rc ^= 0 then call exception rc 'DISKW to ENPSCLIN failed'

  /*  Process SCL                                                    */
  "alloc f(C1MSGS1)  new space(2  2) cylinders recfm(f b) lrecl(133)"
  if rc ^= 0 then call exception rc 'ALLOC of C1MSGS1  failed'
  "alloc f(SYSPRINT) sysout(a)"
  if rc ^= 0 then call exception rc 'ALLOC of SYSPRINT failed'

  address "LINKMVS" 'ENBP1000'
  linkrc   = rc
  zedsmsg  = action 'RC='linkrc
  zedlmsg  = 'The' action 'was successful for package' pkgid
  if rc > 4 then do
    if rc > 8 then
      zedlmsg  = 'The' action 'failed for package' pkgid
    /* Copy C1MSGS1 to PKGRPT1A and then browse the output.          */
    /* PKGRPT1A is used so that the cast report anaylser can find it */
    "execio * diskr C1MSGS1 (stem c1msgs1. finis"
    if rc ^= 0 then call exception rc 'DISKR of C1MSGS1 failed'
    "alloc f(PKGRPT1A) new space(5 15) tracks recfm(f b) lrecl(133)"
    if rc ^= 0 then call exception rc 'ALLOC of PKGRPT1A failed'
    "execio * diskw PKGRPT1A (stem c1msgs1. finis"
    if rc ^= 0 then call exception rc 'DISKW to PKGRPT1A failed'
    address ispexec
    "lminit dataid(cid) ddname(PKGRPT1A)" /* Initialise rpt for edit */
    if rc ^= 0 then call exception rc 'LMINIT of PKGRPT1A failed'
    signal off error
    "browse dataid(&cid)"
    if rc ^= 0 then call exception rc 'BROWSE of PKGRPT1A failed'
    "lmfree dataid(&cid)"
  end /* else */

  address "ISPEXEC" "SETMSG MSG(ISRZ001)"

  test=msg(off)
  address tso "free f(ENPSCLIN C1MSGS1 SYSPRINT PKGRPT1A)"

return /* foreground_run: */

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
   address ispexec "FTCLOSE"
   address tso "free f(ENPSCLIN C1MSGS1 SYSPRINT PKGRPT1A CSVIPT01" ,
               "APIEXTR CSVMSGS1)"
   address tso 'delstack' /* Clear down the stack                    */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
