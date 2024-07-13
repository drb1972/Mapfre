/*-----------------------------REXX----------------------------------*\
 *  Called by TSO WIZ                                                *
 *  Builds wizard jcl for add, move & create package                 *
\*-------------------------------------------------------------------*/
trace i
say 'estoy en el rexxx wiz0401d'
parse arg change c1system scladd sclmov sclpkg c1env ove caller

if ove = 'Y' then over = 'OVERRIDE SIGNOUT'
             else over = ''

address ispexec "vget (zuser zprefix)"
if zprefix ^= 'TTOS' then do /* For the DBAs                         */
  wizlib   = "TT"right(zprefix,2)"."ZUSER"."change".WIZCNTL"
  mask     = 'TT'right(zprefix,2)'.'change
  wizprgrp = 'WIZARD'right(zprefix,2)
end /* zprefix ^= 'TTOS' */
else do /* For Batch Services                                        */
  wizlib   = "TT"c1system"."ZUSER"."change".WIZCNTL"
  mask     = 'TT'c1system'.'change
  wizprgrp = 'WIZARD'
end /* else */

/* Start - Check that the WIZCNTL dataset exists                     */

check = sysdsn("'"wizlib"'")
select
  when check = 'DATASET NOT FOUND' then do
    "ALLOC DA('"wizlib"') NEW
           TRACKS SPACE(10,10) DIR(50) LRECL(80) RECFM(F B)"
    if rc ^= 0 then call exception rc 'ALLOC of' wizlib 'failed.'
    zedsmsg = wizlib
    zedlmsg = wizlib 'ALLOCATED'
    address ispexec 'SETMSG MSG(ISRZ001)'
    "FREE DA('"wizlib"')"
  end /* check = 'DATASET NOT FOUND' */
  when check = 'OK' then nop
  otherwise do
    zedsmsg = check
    zedlmsg = wizlib check
    address ispexec 'SETMSG MSG(ISRZ001)'
  end /* otherwise */
end /* select */

/* End   - Check that the WIZCNTL dataset exists                     */

/* Start - Get list of all types from wizcmds dataset into endevor.  */

a = OUTTRAP('listds.')
"LISTDS '"wizlib"' members"
a = OUTTRAP('OFF')
if rc <> 0 then do
  zedsmsg = listds.2
  zedlmsg = wizlib listds.1
  address ispexec 'SETMSG MSG(ISRZ001)'
  return
end /* rc <> 0 */

/* read the members in wizcntl and check that a source dataset exists*/
types = 0
do i = 7 to listds.0
  member = word(listds.i,1)
  wizcmds = wizlib"("member")"
  "allocate fi(wizcmds) da('"wizcmds"') SHR REUSE"
  if rc ^= 0 then call exception rc 'ALLOC of' wizcmds 'failed.'
  "execio * diskr WIZCMDS (stem wizcmds. finis"
  if rc ^= 0 then call exception rc 'DISKR of' wizcmds 'failed.'
  "free fi(wizcmds)"
  do j = 1 to wizcmds.0
    if word(wizcmds.j,1) = 'COPY' then do /* check source lib exists */
      srcdsn = mask'.'member
      check = sysdsn("'"srcdsn"'")
      if check <> 'OK' then do
        dsn = word(dsnlist.j,1)
        zedsmsg = check
        zedlmsg = srcdsn check
        address ispexec 'SETMSG MSG(ISRZ001)'
        exit
      end /* check <> 'OK' */
      leave j
    end /* word(wizcmds.i,1) = 'COPY' */
  end /* do i = 1 to wizcmds.0 */
  types = types + 1
  endevor.types = member
end /* do i = 7 to listds.0 */

/* End   - Get list of all types from wizcmd datasets into Endevor.  */

if types = 0 then do
  zedsmsg = 'No wizcntl members selected'
  zedlmsg = '$DSNS IN' wizlib 'IS EMPTY'
  address ispexec 'SETMSG MSG(ISRZ001)'
  exit
end /* types = 0 */

/* Start - check types selected are wizard types                     */

do i = 1 to types
  if substr(endevor.i,1,3) = 'BTP' then iterate
  cmpdsn = "PREV.E"c1system"1."endevor.i".CMPARM"
  check = sysdsn("'"cmpdsn"'")
  if check <> 'OK' then do
    srcdsn  = mask'.'endevor.i
    zedsmsg = endevor.i 'not a wizard type'
    zedlmsg = endevor.i 'is not a wizard type, rename' srcdsn ,
                        'and use standard endevor'
    address ispexec 'SETMSG MSG(ISRZ001)'
    exit
  end /* check <> 'OK' */
end /* do i = 1 to types */

/* End   - check types selected are wizard types                     */

/* Start - Write JCL                                                 */

address ispexec
"FTOPEN temp"
initial = length(zuser) - 1
jobname = zprefix'WZ'substr(zuser,initial,1) || left(zuser,1)
"FTINCL WZJOB1"
if rc ^= 0 then call exception rc 'FTINCL of WZJOB1 failed.'
do i = 1 to types
  c1type = endevor.i
  "FTINCL WZJOB2"
  if rc ^= 0 then call exception rc 'FTINCL of WZJOB2 failed.'
end /* i = 1 to types */
"FTINCL WZJOB3"
if rc ^= 0 then call exception rc 'FTINCL of WZJOB3 failed.'

if scladd = 'Y' then do
  "FTINCL WZADDJCL"
  if rc ^= 0 then call exception rc 'FTINCL of WZADDJCL failed.'
  do i = 1 to types
    if substr(endevor.i,1,3) = 'BTP' then procgrp = 'BTERM'
    else procgrp = wizprgrp
    c1type = endevor.i
    "FTINCL WZADDSCL"
    if rc ^= 0 then call exception rc 'FTINCL of WZADDSCL failed.'
  end /* i = 1 to types */
  "FTINCL WZADDCHK"
  if rc ^= 0 then call exception rc 'FTINCL of WZADDCHK failed.'
end /* scladd = 'Y' */

if sclmov = 'Y' then do
  "FTINCL WZMOVJCL"
  if rc ^= 0 then call exception rc 'FTINCL of WZMOVJCL failed.'
  do i = 1 to types
    c1type = endevor.i
    "FTINCL WZMOVSCL"
    if rc ^= 0 then call exception rc 'FTINCL of WZMOVSCL failed.'
  end /* i = 1 to types */
  "FTINCL WZMOVCHK"
  if rc ^= 0 then call exception rc 'FTINCL of WZMOVCHK failed.'
end /* sclmov = 'Y' */

if sclpkg = 'Y' then do
  "FTINCL WZPKGJCL"
  if rc ^= 0 then call exception rc 'FTINCL of WZPKGJCL failed.'
  do i = 1 to types
    c1type = endevor.i
    "FTINCL WZPKGSCL"
    if rc ^= 0 then call exception rc 'FTINCL of WZPKGSCL failed.'
  end /* i = 1 to types */
  "FTINCL WZPKGCHK"
  if rc ^= 0 then call exception rc 'FTINCL of WZPKGCHK failed.'
end /* sclmov = 'Y' */

"FTCLOSE"

/* Submit or edit the job                                            */
if caller = 'WIZNOW' then do
  "vget (ztempf) shared"
  address tso "submit '"ztempf"'"
end /* caller = 'WIZNOW' */
else do
  "vget (ztempn)"
  "lminit dataid(did) ddname("ztempn")"
  "view dataid("did") macro(wizmac)"
  "lmclose dataid("did")"
  "lmfree  dataid("did")"
end /* else */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller
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
