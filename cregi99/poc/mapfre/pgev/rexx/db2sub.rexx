/*-REXX--------------------------------------------------------------*\
 *  Build DB2 JCL for Stored Procedure processing and DB2 BINDs      *
 *                                                                   *
 *  Is used by Cjobs where NDVEDIT has found DB2 trigger datasets    *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

/* Write the header                                                  */
parse arg changeid specific
say "--- D B 2 S U B ---"   date() time()
say rexxname":" changeid specific
say rexxname":"
say rexxname": PROCESSING GSI BIND"
say rexxname":"

/* Read the //LOOKUP file to set the SCHENV for the job              */
/* e.g. "SCHENV.DPA0 = 'DPAY'"                                       */
"execio * diskr lookup  (stem lookup. finis"
if rc > 0 then call exception rc 'DISKR of DDname LOOKUP failed'

/* set up schenv                                                     */
do i = 1 to lookup.0
  interpret lookup.i
end /* i = 1 to lookup.0 */

/* Read the //CONTROL file which contains all the target DB2         */
/* subsystems and actions to be performed.                           */
/* e.g. TARGET DPA SYSTEM PD ACTIONS BIND SP WLM .                   */
"execio * diskr control  (stem card. finis"
if rc > 0 then call exception rc 'DISKR of CONTROL failed.'

/* Loop through the control statements                               */
 do i = 1 to card.0

   /* Validate the control statements                                */
   /* e.g. TARGET x SYSTEM yy ACTIONS bind sp                        */
   if WORD(card.i,1) <> 'TARGET' then
     call exception 11 'Word 1 of the control statement is not TARGET'
   if WORD(card.i,3) <> 'SYSTEM' then
     call exception 13 'Word 3 of the control statement is not SYSTEM'
   if WORD(card.i,5) <> 'ACTIONS' then
     call exception 15 'Word 5 of the control statement is not ACTIONS'

   dobind = ''
   dospdr = ''
   dospcr = ''
   dowlm  = ''
   target = word(card.i,2)
   db2sub = substr(target,1,3)'0'
   system = word(card.i,4)
   actions= subword(card.i,6)

   if pos('BIND',actions) > 0 then
     dobind = 'yes'
   if pos('SPDR',actions) > 0 then
     dospdr = 'yes'
   if pos('SPCR',actions) > 0 then
     dospcr = 'yes'
   if pos('WLM',actions) > 0 then
     dowlm  = 'yes'

   if schenv.target.system = 'SCHENV.'target'.'system then
     schenv.target.system = schenv.target.default
   if schenv.target.system = 'SCHENV.'target'.DEFAULT' then
     call exception 15 'No DB2SUBS entry in lookup table SCHENV='target

   say rexxname":"
   say rexxname": BIND TARGET......:" target
   say rexxname": BIND SUBSYSTEM...:" db2sub
   say rexxname":"
   say rexxname": ENDEVOR SYSTEM...:" system
   say rexxname": SCHENV...........:" schenv.target.system
   say rexxname":"
   say rexxname": DDNAMES:"

   if dospdr = 'yes' then
     say rexxname": SP drops       : SPDR"target
   if dospcr = 'yes' then
     say rexxname": SP creates     : SPCR"target
   if dobind = 'yes' then
     say rexxname": BINDs          : BIND"target
   if dowlm = 'yes' then
     say rexxname": SP WLM refresh : SPRF"target

   say rexxname":"

   jobname = "EVDB"substr(target,1,3)'0'
   jcllines = 0

/* temp code ready for DL Domestic using GINUK for binding           *\
   /* DL Domestic should use GINUK for binding                       */
   if db2sub = 'DPD0' then
     user = 'GINUK'
\* else                                                              */
     user = 'GRP'

   /* The VF system needs more time for complicated binds            */
   if system = 'VF' then
     job_time = ',TIME=60'
   else
     job_time = ''

   call addline "//"jobname "JOB CLASS=N,MSGCLASS=Y,SCHENV=" || ,
                schenv.target.system',USER='user||job_time
   call addline "/*JOBPARM SYSAFF=ANY"
   call addline "//SETVAR   SET ID=PR,BNK=R,TLQ="
   call addline "//JCLLIB   JCLLIB ORDER=(PGOS.BASE.PROCLIB)"
   call addline "//*"
   call addline "//*   Change" changeid "DB2 Processing"
   call addline "//*"
   call addline "//*   JCL Built by DB2SUB"
   call addline "//*   JCL stored in PGEV.PEV1.BINDJCL"

   /* Add Stored Procedure drop JCL                                  */
   if dospdr = 'yes' then do

     call addline "//*"
     call addline "//* Drop Stored Procedures for" db2sub
     call addline "//*"
     call addline "//DROP     EXEC PGM=IKJEFT1B,PARM='%DB2DROP" db2sub"'"
     call addline "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.REXX"
     call addline "//STEPLIB  DD DISP=SHR,DSN=SYSDB2."target".SDSNEXIT.DECP"
     call addline "//         DD DISP=SHR,DSN=SYSDB2."target".SDSNLOAD  "
     call addline "//SYSTSPRT DD SYSOUT=*"
     call addline "//SYSTSIN  DD DUMMY"
     call addline "//DROPS    DD *"

     call readmems 'SPDR'

     call addspwarn 'DROP'

   end /* dospdr = 'yes' */

   if dospcr = 'yes' then do
     call addline "//*"
     call addline "//* Create Stored Procedures for" target
     call addline "//*"
     call addline "//CREATE   EXEC @DB2SQL,SYSTEM="target
     call addline "//STEP010.SYSIN DD"
     call addline "//              DD *,DLM=##"

     call readmems 'SPCR'

     call addline "##"
   end /* dospcr = yes */

   /* Add BIND JCL                                                   */
   if dobind = 'yes' then do
     if specific <> 'G' then
       dbrmlib = "PG"system"."changeid".DBRM"
     else
       dbrmlib = "PG"system".BASE.DBRM"

     call addline "//*"
     call addline "//* Binds for" target
     call addline "//*"
     call addline "//BIND     EXEC PGM=IKJEFT1B"
     call addline "//STEPLIB  DD DISP=SHR,DSN=SYSDB2."target".SDSNEXIT.DECP"
     call addline "//         DD DISP=SHR,DSN=SYSDB2."target".SDSNLOAD  "
     call addline "//SYSTSPRT DD SYSOUT=*"
     call addline "//DBRMLIB  DD DISP=SHR,DSN="dbrmlib
     call addline "//SYSTSIN  DD *"
     call addline "  DSN SYSTEM("db2sub")"

     call readmems 'BIND'

     call addline " END"

     call addline "/*"

     call addspwarn 'BIND'

   end /* dobind = 'yes' */

   /* Add WLM Refresh JCL                                            */
   if dowlm = 'yes' then do
     call addline "//*"
     call addline "//* DB2 WLM Refresh"
     call addline "//*"
     call addline "//WLMRFRS  EXEC PGM=IKJEFT1B"
     call addline "//SYSTSPRT DD  SYSOUT=*"
     call addline "//SYSTSIN  DD  *"

     call readmems 'SPRF'

     call addline "/*"

     call addspwarn 'WLMRFRS'

   end /* dowlm = 'yes' */

   call addimpl /* final step of the job                             */

   say rexxname':'
   say rexxname':  TOP OF JCL SUBMITTED '

   do s = 1 to jcllines
     say jclline.s
   end /* s = 1 to jcllines */

   say rexxname':  END OF JCL SUBMITTED'
   say rexxname':'

   /* write out the job stream                                       */
   "execio" jcllines "diskw SUBMIT (stem" jclline.
   if rc > 0 then call exception rc 'DISKW of DDname SUBMIT failed'

 end /* i = 1 to card.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Read members from staging dataset                                 */
/*-------------------------------------------------------------------*/
readmems:
 arg type
 ddname = type || target
 z = listdsi(ddname file)
 if z ^= 0000 then do
   say rexxname':'
   say rexxname': SYSREASON=' SYSREASON
   say rexxname':' SYSMSGLVL1
   say rexxname':' SYSMSGLVL2
   exit z
 end /* z ^= 0000 */

 say rexxname': Processing DDNAME:' ddname
 say rexxname':   DSNAME:' sysdsname

 t = outtrap('TSOOUT.')
 "listds '"sysdsname"' members"
 if rc > 0 then call exception rc 'Error on listds command'

 wlms = ''
 do t = 7 to tsoout.0
   mem = STRIP(tsoout.t)
   "alloc fi("mem") da('"sysdsname"("mem")') shr"
   if rc > 0 then call exception rc 'Error on alloc of' mem sysdsname

   say rexxname':   Reading Member:' mem
   "execio * diskr" mem "(stem cards. finis"
   if rc > 0 then call exception rc 'DISKR of DDname' mem 'failed'

   if type ^= 'SPRF' then /* drops, creates & binds                  */
     do v = 1 to cards.0
       call addline cards.v
     end /* v = 1 to cards.0 */
   else do                /* SP refreshes                            */
     do v = 1 to cards.0
       if pos(word(cards.v,5),wlms) = 0 then do
         call addline " SEND '"strip(cards.v)"'"
         wlms = wlms word(cards.v,5)
       end /* pos(word(cards.v,5),wlms) = 0 */
     end /* v = 1 to cards.0 */
   end /* else */
   "free fi("mem")"
 end /* tsoout */

return /* readmems: */

/*-------------------------------------------------------------------*/
/* Add the SPWARN step                                               */
/*-------------------------------------------------------------------*/
addspwarn:
 arg step

 call addline "//* SET CMR TO IMPLFAIL AND ABEND IF JOB FAILS"
 call addline "//*"
 call addline "//CHECKIT  IF (ABEND OR" step".RC NE 0) THEN"
 call addline "//*"
 call addline "//IMPLFAIL EXEC PGM=IKJEFT1B,COND=EVEN"
 call addline "//SYSTSPRT DD SYSOUT=*"
 call addline "//SYSTSIN  DD *"
 call addline " SEND 'EV000202 ENDEVOR CJOB:" changeid || ,
              " COMPLETED - STATUS: IMPLFAIL'"
 call addline "/*"
 call addline "//SPWARN   EXEC @SPWARN"
 call addline "//CHECKIT  ENDIF"
 call addline "//*"
return /* addspwarn: */

/*-------------------------------------------------------------------*/
/* Add the IMPL step                                                 */
/*-------------------------------------------------------------------*/
addimpl:
 call addline "//* SET CMR TO IMPL IF JOB WORKS"
 call addline "//*"
 call addline "//IMPL     EXEC PGM=IKJEFT1B"
 call addline "//SYSTSPRT DD SYSOUT=*"
 call addline "//SYSTSIN  DD *"
 call addline " SEND 'EV000202 ENDEVOR CJOB:" changeid || ,
              " COMPLETED - STATUS: IMPL'"
 call addline "/*"
 call addline "//"
return /* addimpl: */

/*-------------------------------------------------------------------*/
/* Add JCL line to queue                                             */
/*-------------------------------------------------------------------*/
addline:
 parse arg text

 jcllines = jcllines + 1
 jclline.jcllines = text

return /* addline: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso 'delstack' /* Clear down the stack                      */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
