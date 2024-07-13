/*-----------------------------REXX----------------------------------*\
 *  Create JCL to ship development packages to the Mplex for PPCM.   *
 *  Called from panel NDVRUSER.                                      *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

address ispexec

"vget (varsppkg ppschenv) profile"

if ppschenv = '' then ppschenv = 'QGEN' /* set default if never set  */

environ  = sysvar(sysenv) /* Foreground or Batch?                    */
sysuid   = sysvar(sysuid)
pkgid    = varsppkg
jcldsn   = 'TTMV.NENDEVOR.MJCL'
evlib    = 'PGEV.BASE'                   /* Endevor REXX dataset     */
rship    = ''                            /* restart from shipment    */
restart  = ''                            /* Job restart step name    */
msgid    = ''      /* panel message number                           */
cpos     = '1'     /* cursor position on the panel                   */
ppos     = 'pkgid' /* which field is the cursor in                   */
appr     = 'N'     /* No approval from PMFBCH required               */
ppuss    = 'N'     /* Does the package contain long name elements    */

/* check if user is an administrator                                 */
resourcename = 'PREW.PROD.PMENU.ENVRMENT'
classname    = 'FACILITY'
a = outtrap('rescheck.','*')
address tso "RESCHECK RESOURCE("resourcename") CLASS("classname")"
reschkrc = rc
a = outtrap('off')
if reschkrc = 0 then evlib = 'PREV.OEV1' /* Override library name    */

mainpanl:
address ispexec
/* Display the panel until the user exits                            */
"display panel(ppcmpkg) msg("msgid") cursor("ppos") csrpos("cpos")"
panel_rc  = rc
do while panel_rc <> 08

  stage = substr(pkgid,9,1) /* stage id from package name            */

  if pos(stage,'BDEF') = 0 then do /* must be a valid target stage   */
    msgid = 'PPCMP001'
    cpos  = '9'
    signal mainpanl /* back to the main panel                        */
  end /* pos(stage,'BDEF') = 0 */

  schenv = ',SCHENV='ppschenv','

  if rship = 'Y' then restart = ',RESTART=NDVRSHIP'
                 else restart = ''

  call packhead /* run csv report to get the package status          */
  call packdetl /* run the csv report to get the element names       */

  if ppuss = 'Y' then do  /* If there are USS elements               */
    region = '1024M'      /* then give the job a big                 */
    class  = '0'          /* region and put the output               */
    locn   = 'spool'      /* to spool                                */
  end /* ppuss = 'Y' */
  else do                 /* If there are no USS                     */
    region = '64M'        /* elements the give the job               */
    class  = 'Y'          /* a smaller region and put                */
    locn   = 'JMR'        /* the output to JMR                       */
  end /* else */

  trkid = 'F0'right(pkgid,6) /* job name for the process             */

  "display panel(ppcmpkgc)" /* display confirmation panel            */

  if rc ^= 8 then do
    call savejob /* save jcl                                         */
    msg = 'EV000304 SUBMIT JOB EVL6000D THROUGH CA7 FOR' trkid
    ADDRESS TSO "SEND '"msg"',OPERATOR(11)" /* submit jcl            */
  end /* rc ^= 8 */

  msgid = '' /* reset message and panel variables                    */
  cpos  = '1'
  ppos  = 'pkgid'
  signal mainpanl

end /* while panel_rc <> 08 */

varsppkg = pkgid
"vput (varsppkg ppschenv) profile"

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Run CSV reports on the package to establish status                */
/*-------------------------------------------------------------------*/
packhead:
 address tso
 test=msg(off)
 if environ = 'FORE' then do
   /* free incase there are hangovers. Do not code an exception call */
   "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"
 end /* environ = 'FORE' */
 test=msg(on)

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Build the input to the report execution                          */
 queue '  LIST PACKAGE ID' pkgid 'OPTIONS  NOCSV .'
 'execio' queued() 'diskw csvipt01 (finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 if environ = 'FORE' then do
   test=msg(off)
   "alloc f(c1msgsa) sysout(z)"
   if rc ^= 0 then call exception rc 'ALLOC of c1msgsa failed.'
   "alloc f(csvmsgs1) sysout(z)"
   if rc ^= 0 then call exception rc 'ALLOC of csvmsgs1 failed.'
   "alloc f(bsterr) sysout(z)"
   if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'

   /* invoke the program                                             */
   address "LINKMVS" 'BC1PCSV0'
   lnk_rc = rc
   address tso
   "free f(bsterr c1msgsa csvmsgs1 csvipt01)"
   if rc ^= 0 then call exception rc 'FREE of files failed.'

   if lnk_rc = 8 then do /* package not found                        */
     "free f(apiextr)"
     msgid = 'PPCMP010'
     cpos  = '1'
     ppos  = 'pkgid'
     signal mainpanl
   end /* lnk_rc = 8 */

   test=msg(on)
 end /* environ = 'FORE' */
 else do /* running in batch                                         */
   "CALL *(NDVRC1) 'BC1PCSV0'"
   lnk_rc = rc
 end /* else do */

 if lnk_rc > 0 then do /* error found in running the routine         */
   "free f(apiextr)"
   call exception lnk_rc 'Call to NDVRC1 failed'
 end /* lnk_rc > 4 */

 g = listdsi(apiextr file)

 /* listdsi didn't show the file exists                              */
 if g > 0 then call exception g 'LISTDSI of APIEXTR file failed'
 else do
   address tso "execio 1 diskr apiextr"
   pull record
   address tso "execio 0 diskr apiextr (finis"
   status = substr(record,116,12)

   /* If restart from shipment is requested and the package has not  */
   /* been executed then return to panel                             */
   if rship = 'Y' & left(status,4) ^= 'EXEC' then do
     msgid = 'PPCMP008'
     cpos  = '1'
     ppos  = 'RSHIP'
     signal mainpanl
   end /* rship = 'Y' & left(status,4) ^= 'EXEC' */

   select /* can we progress based on the package status             */
     when left(status,7) = 'IN-EDIT' then do
       msgid = 'PPCMP006'
       cpos  = '1'
       signal mainpanl
     end /* left(status,7) = 'IN-EDIT' */

     /* package approved or has failed                               */
     when left(status,7) = 'APPROVE' | ,
          left(status,7) = 'IN-EXEC' | ,
          left(status,7) = 'EXEC-FA' then do
       appr = 'N'
       return
     end /* left(status,7) = ...... */

     when left(status,7) = 'IN-APPR' then do /* needs approval       */
       appr = 'Y'
       return
     end /* left(status,7) = 'IN-APPR' */

     when left(status,7) = 'COMMITE' then do
       msgid = 'PPCMP006'
       cpos  = '1'
       signal mainpanl
     end /* left(status,7) = 'COMMITE' */

     when left(status,7) = 'EXECUTE' & rship = 'N' then do
       msgid = 'PPCMP006'
       cpos  = '1'
       signal mainpanl
     end /* left(status,7) = 'EXECUTE' & rship = 'N' */

     when left(status,7) = 'EXECUTE' & rship = 'Y' then do
       appr = 'N'
       return
     end /* left(status,7) = 'EXECUTE' & rship = 'Y' */

     otherwise do
       msgid = 'PPCMP009' /* unknown status                          */
       cpos  = '1'
       signal mainpanl
     end /* otherwise */
 end /* else do */

return /* packrep */

/*-------------------------------------------------------------------*/
/* Run CSV reports on the package to establish contents              */
/*-------------------------------------------------------------------*/
packdetl:
 address tso
 test=msg(off)
 if environ = 'FORE' then do
   /* free incase there are hangovers. Do not code an exception call */
   "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"
 end /* environ = 'FORE' */
 test=msg(on)

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Build the input to the report execution                          */
 queue "  LIST PACKAGE ACTION FROM PACKAGE ID" pkgid
 queue "  OPTIONS NOCSV . "
 'execio' queued() 'diskw csvipt01 (finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 if environ = 'FORE' then do
   test=msg(off)
   "alloc f(c1msgsa) sysout(z)"
   if rc ^= 0 then call exception rc 'ALLOC of c1msgsa failed.'
   "alloc f(csvmsgs1) sysout(z)"
   if rc ^= 0 then call exception rc 'ALLOC of csvmsgs1 failed.'
   "alloc f(bsterr) sysout(z)"
   if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'

   /* invoke the program                                             */
   address "LINKMVS" 'BC1PCSV0'
   lnk_rc = rc
   address tso
   "free f(bsterr c1msgsa csvmsgs1 csvipt01)"
   if rc ^= 0 then call exception rc 'FREE of files failed.'

   test=msg(on)
 end /* environ = 'FORE' */
 else do /* running in batch                                         */
   "CALL *(NDVRC1) 'BC1PCSV0'"
   lnk_rc = rc
 end /* else */

 if lnk_rc > 0 then do /* error found in running the routine         */
   "free f(apiextr)"
   call exception lnk_rc 'Call to NDVRC1 failed'
 end /* lnk_rc > 4 */

 g = listdsi(apiextr file)

 /* listdsi didn't show the file exists                              */
 if g > 0 then call exception g 'LISTDSI of APIEXTR file failed'
 else do
   address tso "execio * diskr apiextr (STEM REP. FINIS"

   do a = 1 to rep.0
     if substr(rep.a,217,6) = 'DEPLOY' | ,
        substr(rep.a,217,4) = 'WSDL'   | ,
        substr(rep.a,217,3) = 'EAR'    | ,
        substr(rep.a,217,3) = 'BAR' then do
       ppuss = 'Y'
       return
     end /* substr(rep.a,217,6) = */
   end /* a = 1 to rep.0 */

 end /* else */

return /* packdetl: */

/*-------------------------------------------------------------------*/
/* SAVEJOB - saves the JCL with file tailoring and edits             */
/*-------------------------------------------------------------------*/
savejob:

 currdt   = Date(S)
 currtm   = Substr(time(),1,2) || Substr(time(),4,2) || ,
            Substr(time(),7,2)'00'
 shortd   = Substr(currdt,3,6)
 shortm   = Substr(currtm,1,6)

 test=msg(off)
 address tso "free f(ispfile)"
 test=msg(on)

 ADDRESS TSO "ALLOC DA('"jcldsn"') SHR F(ISPFILE)"
 if rc ^= 0 then call exception rc 'ALLOC of' jcldsn 'failed.'
 address ispexec 'ftopen'
 if rc ^= 0 then call exception rc 'FTOPEN of ISPFILE failed.'
 address ispexec 'ftincl PPCMPKG'
 if rc ^= 0 then call exception rc 'FTINCL of PPCMPKG failed.'
 address ispexec 'ftclose name('trkid')'
 if rc ^= 0 then call exception rc 'FTCLOSE of' trkid 'failed.'

 if reschkrc = 0 then do
   address ispexec 'lminit dataid(did) ddname(ispfile)'
   if rc ^= 0 then call exception rc 'LMINIT of ISPFILE failed.'
   /* don't call exception for the next two commands as an aborted   */
   /* submission will raise a non zero return code                   */
   address ispexec 'edit dataid('did') member('trkid')'
   address ispexec 'lmclose dataid('did')'

   address ispexec 'lmfree  dataid('did')'
   if rc ^= 0 then call exception rc 'LMFREE of ISPFILE failed.'
   address tso "free f(ispfile)"
 end /* if reschkrc = 0 then do */

return /* savejob: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')
 address ispexec "FTCLOSE"      /* Close any FTOPENed files          */
 address tso "FREE F(FILENAME)" /* Free files that may be open       */
 address tso 'delstack'         /* Clear down the stack              */
 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code

