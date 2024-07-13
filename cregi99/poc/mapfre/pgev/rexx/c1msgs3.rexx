/*-----------------------------REXX----------------------------------*\
 *  This routine scans the Endevor job output and creates a ddname   *
 *  called C1MSGS3 for all non informational messages.               *
 *  It also analyses Endevor actions and reports inefficient use.    *
\*-------------------------------------------------------------------*/
trace n

/* Optionally specify the jobname & number you want to scan          */
/* or set jobname=ALL to scan all class 3 jobs                       */
arg jobname jobnum

false    = 0
true     = 1
/* Set up some variables for SDSF calls                              */
rc       = isfcalls('ON')
isfowner = "*"
headers  = 0

if jobname = 'ALL' then
  call all_st
else
  call one_job

if warn_backout = true & ,
   (left(jobname,2) = 'R0' | jmr = true) then
  call email_warning

rc = isfcalls("Off")

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* All_st - Processes all output from Class 3                        */
/*-------------------------------------------------------------------*/
all_st:

isffilter  = 'jclass eq 3'
cmd        = 'ST'
jobscan    = 'ALL'
send_email = false

call sdsfcall "ISFEXEC" cmd /* start getting the job data from SDSF  */

/* Loop through all the ST jobs to find Endevor ones                 */
do n = 1 to jname.0
  call find_c1msgs1
end

return /* all_st */

/*-------------------------------------------------------------------*/
/* One_job - process one job - by default, the current one           */
/*-------------------------------------------------------------------*/
one_job:

 send_email = true
 if jobname = '' then do
   /* Get the output for the current job (this job)                  */
   job       = mvsvar('SYMDEF','JOBNAME')
   isfprefix = job
   cmd       = 'DA OJOB'
 end /* jobname = '' */
 else do
   /* Get the output for a specific job on the queue                 */
   isfprefix  = jobname
   cmd        = 'ST'
   send_email = false
 end /* else */

 if jobnum ^= '' then
   isffilter = 'jobid eq' jobnum

 call sdsfcall "ISFEXEC" cmd /* start getting the job data from SDSF */

 if jname.0 = 0 then do
   if jobnum = '' then
     say 'C1MSGS3:' jobname 'not found on spool'
   else
     say 'C1MSGS3:' jobname 'not found on spool with number' jobnum
   exit 4
 end /* jname.0 = 0 */

 n = 1

 call find_c1msgs1

return /* one_job */

/*-------------------------------------------------------------------*/
/* Find_c1msgs1 find endevor output, if it exists                    */
/*-------------------------------------------------------------------*/
find_c1msgs1:

 jobnum  = jobid.n
 jobname = jname.n
 jowner  = ownerid.n

 output        = false
 z             = 0
 c             = 0
 send_to_admin = false
 c1msgs1_found = false
 quickedit     = false
 badmin        = false /* batch admin flag                           */

 call sdsfcall "ISFACT" cmd "TOKEN('"token.n || ,
               "') PARM(NP ?) (PREFIX JDS_"

 do jx = 1 to jds_token.0

   if jds_ddname.jx = 'JMRPRINT' then jmr = true

   /* if the DDname is C1MSGS1 or EN$DPMSG then get the data         */
   if jds_ddname.jx = 'C1MSGS1'  | ,
      jds_ddname.jx = 'JMRPRINT' | ,
      jds_ddname.jx = 'EN$DPMSG' then do
     jstepn = jds_stepn.jx
     if (left(jobname,2) = 'R0' & ,
         jstepn         ^= 'PACKEXEC') | ,
        (left(jobname,2) = 'F0' & ,
         jstepn         ^= 'NDVRPACK') then
       iterate
     c1msgs1_found = true
     say right(n,4) left(jobname,8) left(jobnum,8) left(jowner,8)
     if jstepn = 'NDVRQEDT' then quickedit = true
     call extract
   end /* jds_ddname.jx = 'C1MSGS1' */

 end /* jx = 1 to jds_token.0 */

 if ^c1msgs1_found then do
   say right(n,4) left(jobname,8) left(jobnum,8) left(jowner,8) ,
       '** non Endevor job **'
 end /* ^c1msgs1_found */
 else do
   /* Write a split line to C1MSGS3                                  */
   if output then do
     queue ' '
     "EXECIO 1 DISKW C1MSGS3"
     if rc ^= 0 then call exception rc 'DISKW of C1MSGS3 failed'
   end /* output */

   if ^quickedit then call bad_practice
 end /* else */

return /* find_c1msgs1 */

/*-------------------------------------------------------------------*/
/* Extract some SDSF output                                          */
/*-------------------------------------------------------------------*/
extract:

 call sdsfcall "ISFACT" cmd "TOKEN('"jds_token.jx"') PARM(NP SA)"

 cap.0    = 0
 hirc     = 0
 element  = ''
 type     = ''
 elmtype  = ''
 env      = ''
 sys      = ''
 sub      = ''
 type     = ''
 stg      = ''
 stcno    = ''
 /* Variables for bad practice analysis                              */
 package    = false /* Is this a package execution?                  */
 elt_change = true  /* Has the element been changed?                 */
 pg_change  = false /* Has the processr group been changed?          */
 bindelt    = true  /* Does the associated bind element exist?       */
 progro     = false /* Has the processor group been specified?       */
 autogen    = false /* Has autogen been set?                         */
 prgrp      = 'N/S' /* The processsor group of the current element   */
 copyback   = false /* Generate with copyback?                       */
 new_elt    = false /* new element                                   */

 do forever

   "EXECIO 1 DISKR" isfddname.1
   if rc > 0 then leave

   parse pull msgs1

   select
     when subword(msgs1,1,2) = 'Batch Environment' then do
       badmin = true
       iterate
     end /* subword(msgs1,1,2) = 'Batch Environment' */

     otherwise nop /* nothing to do                                  */
   end /* select */

   parse var msgs1 hh ':' mm ':' ss mcode guff

   select

     when mcode = 'ECAP011I' then do
       thiscap = cap.0 + 1
       cap.thiscap = word(msgs1,9) word(msgs1,8)
       cap.0 = thiscap
     end /* mcode = 'ECAP011I' */

     when mcode = 'ECAP060I' then
       parse var guff . 'BY' stcname '- STC ' stcno .

     when mcode = 'PKMR500I' then
       package = true

     when mcode = 'C1G0202I' then do
       parse var guff . 'ACTION #'actno' / STMT #'stmt .
       actno = strip(actno)
       stmt  = strip(stmt)
     end /* mcode = 'C1G0202I' */

     when mcode = 'ENBE001I' then do

       parse var guff . 'Statement 'actno' Object 'stmt .
       actno = strip(actno)
       stmt  = strip(stmt)
       /* get next record to determine action type                   */
       "EXECIO 1 DISKR" isfddname.1
       if rc ^= 0 then call exception rc 'DISKR of' isfddname.1 'failed'
       parse pull msgs1
       /* set action variable content                                */
       act = strip(word(msgs1,1))

     end /* mcode = 'ENBE001I' */

     when mcode = 'C1G0203I' then
       parse var guff act 'ELEMENT ' element .

     when mcode = 'C1G0220I' then do
       parse var guff act 'MEMBER ' element .
       /* type and stage have no meaning for this sort of action     */
       type = '?'
       stg  = '?'
     end /* mcode = 'C1G0220I' */

     when mcode = 'C1G0204I' then
       parse var guff 1 . ' ENVIRONMENT: ' Env . ,
                      1 . ' SYSTEM:' Sys . ,
                      1 . ' SUBSYSTEM: ' Sub . ,
                      1 . ' TYPE: ' Type . ,
                      1 . ' STAGE ID: ' Stg .

     when mcode = 'C1G0226I' then
       parse var guff 1 . ' ENVIRONMENT: ' Env . ,
                      1 . ' SYSTEM:' Sys . ,
                      1 . ' SUBSYSTEM: ' Sub . ,
                      1 . ' TYPE: ' Type . ,
                      1 . ' STAGE #: ' Stg .

     when mcode = 'C1G0200I' then do
       call log_action
       element = ''
     end /* mcode = 'C1G0200I' */

     when mcode              = 'SMGR121I' & ,
          subword(msgs1,3,1) = 'ELEMENT'  then
       new_elt = true

     when mcode = 'SMGR122W' then elt_change = false

     when mcode = 'C1G0129E' then
       if subword(msgs1,3,4) = 'STEP RELATE RC (0004)' then
         bindelt = false

     when mcode = 'C1X0010I' then
       if subword(msgs1,3,2) = 'STEP RELATE' then
         bindelt = true

     when mcode = 'C1X0012I' then
       parse var guff 1 . ' STEP ' procstep .

     when mcode = 'C1G0012W' then do
       pg_change    = true
       warn_backout = true
     end /* mcode = 'C1G0012W' */

     when mcode = 'C1G0232I' then
       select
         when subword(msgs1,3,2)    = 'PROCESSOR GROUP:' then
           progro   = true
         when subword(msgs1,4,2)    = 'PROCESSOR GROUP:' then
           progro   = true
         when pos('AUTOGEN',msgs1)  > 0                  then
           autogen  = true
         when pos('COPYBACK',msgs1) > 0                  then
           copyback = true
         otherwise nop
       end /* select */

     when mcode = 'C1G0265I' then
       prgrp = word(msgs1,5)

     otherwise nop

   end /* select */

   act = strip(act)

   if ^badmin then do
     if hh = '' | mm = '' | ss = '' | ,
        mcode = '' | element = '' | mcode = 'PAGE' then iterate
   end /* ^badmin */
   else do
     if hh = '' | mm = '' | ss = '' | ,
        mcode = '' | mcode = 'PAGE' then iterate
   end /* else */

   incode = right(mcode,1)
   if pos(incode,'WECS') > 0 then call logit

 end /* do forever */

 if cap.0 > 0 then call list_CAP_STC

return /* extract: */

/*-------------------------------------------------------------------*/
/* log the action for bad practice analysis                          */
/*-------------------------------------------------------------------*/
log_action:

 z        = z + 1
 action.z = '    '           ,
            left(element,20) ,
            left(type,8)     ,
            left(prgrp,8)    ,
            left(act,8)      ,
            stg              ,
            right(actno,4)   ,
            right(stmt,4)    ,
            progro elt_change pg_change autogen bindelt copyback ,
            new_elt
 say action.z

 /* Reset variables for the next action                              */
 elt_change = true
 bindelt    = -1
 pg_change  = false
 progro     = false
 autogen    = false
 prgrp      = 'N/S'
 copyback   = false
 new_elt    = false

return /* log_action: */

/*-------------------------------------------------------------------*/
/* queue the output for later writing                                */
/*-------------------------------------------------------------------*/
logit:

 output = true
 rows   = 0

 /* if this is the first output pass the write header                */
 if ^headers then do

   /* write out the headers for the report & columns                 */
   queue ' '
   queue 'Summary of non Informational & Warning messages'
   queue ' '

   queue,
   left('Action',8),
   left('Element',8),
   left('Act#',4),
   left('Stmt#',5),
   left('Env',4),
   left('System',6),
   left('Subsys',6),
   left('Type',8),
   left('S',1),
   left('TaskID',8),
   ''

   queue,
   copies('-',8),
   copies('-',8),
   copies('-',4),
   copies('-',5),
   copies('-',4),
   copies('-',6),
   copies('-',6),
   copies('-',8),
   '-',
   copies('-',8),
   ''

   rows    = 5
   headers = 1

 end /* ^headers  */

 if datatype(stcno,'Whole number') then
   stcno = 'STC' || right(stcno,5,'0')

 prefix = left(strip(act),8),
          left(element,8),
          right(actno,4),
          right(stmt,5),
          left(env,4),
          left(sys,6),
          left(sub,6),
          left(type,8),
          left(stg,1),
          left(stcno,8),
          ''
   if elmtype ^= element||type then do
     elmtype = element||type
     if ^badmin then do
       queue prefix
       rows = rows + 1
     end /* ^badmin */
   end /* elmtype ^= element||type */

   queue ' '  mcode||guff
   if mcode = 'C1G0294E' & procstep = 'BKUPLIST' then do
     queue ' ' 'Unable to back-up previous listing for' element '-'
     queue ' ' 'Please ignore above C1G0294E message'
     rows = rows + 2
   end /* mcode = 'C1G0294E' & procstep = 'BKUPLIST' */
   "EXECIO" rows+1 "DISKW C1MSGS3"
   if rc ^= 0 then call exception rc 'DISKW of C1MSGS3 failed'

return /* logit: */

/*-------------------------------------------------------------------*/
/* queue the output for later writing                                */
/*-------------------------------------------------------------------*/
list_CAP_STC:

 output = true /* flag we have been here                             */

 queue ' '
 queue cap.0 'concurrent action spawned tasks detected'
 queue ' '
 "EXECIO 3 DISKW C1MSGS3"
 if rc ^= 0 then call exception rc 'DISKW of C1MSGS3 failed'

 do q = 1 to cap.0 /* loop through the CAP output                    */
   queue cap.q
   "EXECIO 1 DISKW C1MSGS3"
   if rc ^= 0 then call exception rc 'DISKW of C1MSGS3 failed'

 end /* q = 1 to cap.0 */

 queue ' ' /* blank line                                             */
 "EXECIO 1 DISKW C1MSGS3"
 if rc ^= 0 then call exception rc 'DISKW of C1MSGS3 failed'

return /* list_CAP_STC: */

/*-------------------------------------------------------------------*/
/* sdsfcall                                                          */
/*-------------------------------------------------------------------*/
sdsfcall:

 parse arg cmdstr

 address SDSF cmdstr

 if rc = 0 then return

 say cmdstr ': failed RC='RC

 if isfmsg <> "" then say isfmsg

 do ix = 1 to isfmsg2.0
   say isfmsg2.ix
 end /* ix = 1 to isfmsg2.0 */

 if rc > 0 then exit 20

return /* sdsfcall: */

/*-------------------------------------------------------------------*/
/* Check for bad practice                                            */
/*-------------------------------------------------------------------*/
bad_practice:

 x = 6 /* Output line counter - The first 6 lines are headers        */

 nochange_types = 'COPYBOOK EARLMAC EASYMAC MAPSDF2P MACRO XSD'
 bind_types     = 'ASMA ASMB ASMC ASMK ASMP COBA COBB COBC COBD COBP' ,
                  'EASYTREV PLIB PLIC SEPB SEPC'

 say 'bad practice checking'
 /* Loop through all the actions to see if any are inefficient       */
 do i = 1 to z
   say 'checking' action.i
   parse var action.i element type prgrp action stg actno stmt progro ,
             elt_change pg_change autogen bindelt copyback new_elt

   select
     /* Updating non processed elements without changing them        */
     when wordpos(type,nochange_types) > 0   & ,
          wordpos(action,'ADD UPDATE') > 0   & ,
          ^pg_change                         & ,
          ^elt_change                        then
       call bad_msg1

     /* Generating non processed elements                            */
     when wordpos(type,nochange_types) > 0          & ,
          action                       = 'GENERATE' & ,
          jowner                      ^= 'ENDEVOR'  & ,
          ^copyback                                 & ,
          ^pg_change                                then
       call bad_msg2

     /* Generating bind elements                                     */
     when wordpos(action,'GENERATE ADD UPDATE') > 0 & ,
          type      = 'BIND' & ,
          ^pg_change         & ,
          ^autogen           & ,
          ^package           & ,
          ^new_elt           then
       if stg = 'F' & copyback       then nop /* Ignore re-release   */
       else
         /* Go back and see if the program was actioned too          */
         do y = i-1 to 0 by -1
           parse var action.y pelement ptype pprgrp paction pstg ,
                     pactno pstmt . . . . . . .
           if pelement              = element  & ,
              paction              ^= 'MOVE'   & ,
              paction              ^= 'DELETE' & ,
              pos(ptype,bind_types) > 0        then
             call bad_msg3
         end /* y = i to 1 by -1 */

     otherwise nop

   end /* select */
 end /* i = 1 to z */

 if x > 6 then do
   if send_email then
  /* call Send_email    Send the report to the user                  */
   call Write_bad   /* Log the bad practice actions                  */
 end /* x > 6 */

return /* bad_practice: */

/*-------------------------------------------------------------------*/
/* Bad_msg1 - dont add unchanged copybooks etc.                      */
/*-------------------------------------------------------------------*/
bad_msg1:

 newstack
 queue 'Action...:' actno
 queue 'Statement:' stmt
 queue 'Action...:' action
 queue 'Element..:' element
 queue 'Type.....:' type
 queue 'Stage....:' stg
 queue ' '
 queue '  Do not ADD' type 'elements if you are not changing them.'
 queue '  ADDing unchanged' type 'elements updates the footprints' ,
       'which can cause'
 queue '  cast errors which in turn may require generation and' ,
       're-testing.'
 queue '  However if the stage P element has been backed out or you'
 queue '  have changed the processor group then you can ignore this' ,
       'message.'
 queue ' '
 call end_msg /* Add the message to the stem variable                */

return /* bad_msg1 */

/*-------------------------------------------------------------------*/
/* Bad_msg2 - dont add generate copybooks etc.                       */
/*-------------------------------------------------------------------*/
bad_msg2:

 newstack
 queue 'Action...:' actno
 queue 'Statement:' stmt
 queue 'Action...:' action
 queue 'Element..:' element
 queue 'Type.....:' type
 queue 'Stage....:' stg
 queue ' '
 queue '  Do not generate' type 'elements unless you are changing' ,
       'the processor group.'
 queue '  Generating' type 'elements updates the footprints which' ,
       'can cause'
 queue '  cast errors which in turn may require generation and' ,
       're-testing.'
 queue ' '
 call end_msg /* Add the message to the output stem variable         */

return /* bad_msg2 */

/*-------------------------------------------------------------------*/
/* Bad_msg3 - dont add generate bind elements                        */
/*-------------------------------------------------------------------*/
bad_msg3:

 newstack
 send_to_admin = true
 queue 'Action...:' pactno
 queue 'Statement:' pstmt
 queue 'Action...:' paction
 queue 'Element..:' pelement
 queue 'Type.....:' ptype
 queue 'Stage....:' pstg
 queue ' '
 queue 'Action...:' actno
 queue 'Statement:' stmt
 queue 'Action...:' action
 queue 'Element..:' element
 queue 'Type.....:' type
 queue 'PrGrp....:' prgrp
 queue 'Stage....:' stg
 queue ' '
 queue '  You have implicitly' action'ed the BIND element.'
 queue '  BIND elements are automatically generated by the' ptype ,
       'element'
 queue '  so there is no need to implicitly' action ,
       'the BIND element too.'
 queue ' ' action'ing BIND elements causes the DB2 bind to be done' ,
       'twice,'
 queue '  once by the' ptype 'and once by the BIND' action'.'
 queue '  Please do not' action 'BIND elements when you' paction 'the',
       'program element.'
 queue ' '
 call end_msg /* Add the message to the output stem variable         */

return /* bad_msg3 */

/*-------------------------------------------------------------------*/
/* End_msg - Add the message to the stem variable                    */
/*-------------------------------------------------------------------*/
end_msg:

 say '     Bad practice'
 do x = x + 1 for queued()
   parse pull line
   o.x = '   ' line
 end /* x = x + 1 for queued() */
 delstack
 x = x - 1

 c = c + 1
 bad_action.c = action.i

return /* end_msg: */

/*-------------------------------------------------------------------*/
/* Send email back to user with the bad practice                     */
/*-------------------------------------------------------------------*/
Send_email:

 if jobname = '' then do
   jobname   = mvsvar('SYMDEF','JOBNAME')
   /* Work out job number                                            */
   ascb      = c2x(storage(224,4))
   assb      = c2x(storage(d2x(x2d(ascb)+336),4))
   jsab      = c2x(storage(d2x(x2d(assb)+168),4))
   jobnum    = storage(d2x(x2d(jsab)+20),8)
 end /* jobname = '' */
 a = outtrap('list.')
 "racunl0 user("jowner")"
 a = outtrap('off')

 if right(strip(list.1),9) ^= 'NOT FOUND' then do
   user = strip(substr(list.1,35),'T')
   user = word(user,2)',' word(user,1)
 end /* right(strip(list.1),9) ^= 'NOT FOUND' */

 o.1 = 'JOBNAME..:' jobname
 o.2 = 'JOBNUMBER:' jobnum
 o.3 = 'USER.....:' jowner
 o.4 = 'USER NAME:' user
 o.5 = ' '
 o.6 = ' '

 say 'C1MSGS3: Bad practice report'
 say

 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(80) blksize(0) dsorg(ps)"

 queue 'FROM: mapfre.endevor@rsmpartners.com'

 if jowner ^= '' then do
   say 'C1MSGS3: Sending email to  VERTIZOS@kyndryl.com'
   queue 'TO:  VERTIZOS@kyndryl.com'
 end /* jowner ^= '' */

 queue 'SUBJECT: EPLEX - Endevor efficiency advice -' jowner

 "execio" queued() "diskw SYSADDR (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed.'

 x   = x + 1
 o.x = ' '
 x   = x + 1
 o.x = 'This is an initiative to improve working efficiency and' ,
       'reduce mainframe CPU usage.'
 x   = x + 1
 o.x = 'If you feel that your actions are correct and that you should'
 x   = x + 1
 o.x = 'not receive this message then please contact us by replying' ,
       'to this email so that we can correct it.'
 x   = x + 1
 o.x = ' '
 x   = x + 1
 o.x = 'Please read the preventing common mistakes section of our' ,
       'Master Class.'
 x   = x + 1
 o.x = 'http://www.manufacturing.rbs.co.uk/GTendevor/Masterclass.htm'

 x   = x + 1
 o.x = ' '
 x   = x + 1
 o.x = 'Actions:'
 do i = 1 to z
   x   = x + 1
   o.x = action.i
 end /* i = 1 to z */

 o.0 = x

 "alloc f(SYSDATA) new space(5,15) tracks
  recfm(f,b) lrecl(800) blksize(0) dsorg(ps)"
 "execio * diskw SYSDATA (stem o. finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed.'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)' 'DEFAULT LOG(YES)'" exec
 send_rc = rc
 /* No check until OMVS segements have been sorted                   */
 /* if rc ^= 0 then call exception rc 'SENDMAIL failed.'             */

 "free fi(SYSADDR SYSDATA)"
 send_to_admin = false

return /* Send_email: */

/*-------------------------------------------------------------------*/
/* Write bad practice actions to the log file                        */
/*-------------------------------------------------------------------*/
Write_bad:

 if send_rc > 0 then q = '*'
                else q = ' '

 do i = 1 to c
   queue left(jobname,8) left(jobnum,8) left(jowner,7) q bad_action.i ,
         date('O')
 end /* i = 1 to c */
 /* No exception checks to avoid job errors if dataset is in use     */
 "alloc f(log) dsname('TTEV.TMP.BAD.LOG') mod"
 "execio * diskw LOG (finis"
 "free fi(log)"
 delstack

return /* Write_bad: */

/*-------------------------------------------------------------------*/
/* Send email warning of backout issues (temp code)                  */
/*-------------------------------------------------------------------*/
email_warning:

 say 'C1MSGS3: Processor group change found, emailing warning'
 say

 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(80) blksize(0) dsorg(ps)"

 queue 'FROM: mapfre.endevor@rsmpartners.com'
 queue 'TO: VERTIZOS@kyndryl.com'

 queue 'SUBJECT: EPLEX - Potential package CMR backout issue for' ,
       'C'substr(jobname,2)

 "execio" queued() "diskw SYSADDR (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed.'

 if jmr = true then do
   queue '**** This is a test email, please ignore ****'
   queue ' '
 end /* jmr = true */

 queue 'Package CMR C'substr(jobname,2) 'will have an issue' ,
       'if it is backed out.'
 queue ' '
 queue 'Endevor Support will resolve this issue and email you'
 queue 'when it is complete.'
 queue ' '
 queue 'If you are requested to back out this CMR then first'
 queue 'ensure that Endevor Support have sent confirmation'
 queue 'that the issue is resolved.'

 "alloc f(SYSDATA) new space(5,15) tracks
  recfm(f,b) lrecl(800) blksize(0) dsorg(ps)"
 "execio" queued() "diskw SYSDATA (finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed.'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)' 'DEFAULT LOG(YES)'" exec
 if rc ^= 0 then call exception rc 'SENDMAIL failed'

 "free fi(SYSADDR SYSDATA)"

return /* email_warning: */

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
   address tso "FREE F("jds_ddname.y" SYSADDR SYSDATA)"
   address tso 'delstack' /* Clear down the stack                    */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
