/*-----------------------------REXX----------------------------------*\
 *  Submit a job to execute SCL                                      *
 *  This was written for USS processors that have to submit          *
 *  a job in order to customise EAR files so that CMEW sessions      *
 *  are not locked and a higher priority can be added to the job.    *
\*-------------------------------------------------------------------*/
trace n
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg jobname region schenv uid c1prtype c1en c1ty c1su c1stage c1prgrp

say rexxname':' Date() Time()
say rexxname':'
say rexxname': Jobname.........:' jobname
say rexxname': Region..........:' region
say rexxname': Schenv..........:' schenv
say rexxname': Uid.............:' uid
say rexxname': C1prtype........:' c1prtype
say rexxname': C1en............:' c1en
say rexxname': C1ty............:' c1ty
say rexxname': C1su............:' c1su
say rexxname': C1stage.........:' c1stage
say rexxname': C1prgrp.........:' c1prgrp
say rexxname':'

processor = left(c1prtype,1) || c1ty
thisjob   = mvsvar('SYMDEF','JOBNAME')

/* Set unique jobname for RMP                                        */
if left(c1su,2) = 'QI' & c1prtype = 'GENERATE' then
  jobname = overlay('1',jobname,8)

/* Set the job SCHENV                                                */
select
  when schenv  = 'N/A'                   then schenv = 'QGEN'
  when c1ty    = 'EAR' & c1prgrp = 'EAR' then schenv = 'QGEN'
  otherwise nop
end /* select */

/* Read the SCL                                                      */
"execio * diskr sclin (stem scl. finis"
if rc ^= 0 then call exception rc 'DISKR of SCLIN failed.'

queue "//"jobname " JOB 0,CLASS=3,NOTIFY="uid",REGION="region","
queue "//             SCHENV="schenv",MSGCLASS=0,TIME=1440"
queue "//*+------------------------------------------------------+    "
queue "//*|  THIS JOB WAS SUBMITTED BY THE" processor "PROCESSOR      "
queue "//*|  BY USER" uid
queue "//*+------------------------------------------------------+    "
queue "//NDVRUSS   EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'      "
queue "//APIPRINT  DD SYSOUT=Z                                        "
queue "//HLAPILOG  DD SYSOUT=*                                        "
queue "//C1MSGS1   DD SYSOUT=*                                        "
queue "//C1MSGS2   DD DISP=(NEW,PASS),DSN=&&C1MSGS2,                  "
queue "//             SPACE=(TRK,(2,5)),                              "
queue "//             RECFM=FBA,LRECL=133                             "
queue "//SYSUDUMP  DD SYSOUT=C                                        "
queue "//SYMDUMP   DD SYSOUT=C                                        "
queue "//SYSOUT    DD SYSOUT=*                                        "
queue "//SYSPRINT  DD SYSOUT=*                                        "
queue "//EN$PPRT   DD DUMMY                                           "
queue "//BSTIPT01  DD *                                               "

/* Queue the SCL                                                     */
do i = 1 to scl.0
  queue scl.i
end /* i = 1 to scl.0 */

queue "/*                                                             "

queue "//*                                                          "
queue "//* GET JOB DETAILS FOR EMAIL HEADER                         "
queue "//*                                                          "
queue "//JOBDTLS  EXEC PGM=IKJEFT1B,PARM='%JOBDTLS" uid"'           "
if left(c1su,2) = 'EK' then do
  queue "//SYSEXEC  DD DSN=PREV.OEV1.REXX,DISP=SHR                  "
  queue "//         DD DSN=PGEV.BASE.REXX,DISP=SHR                  "
end /* left(c1su,2) = 'EK' */
else
  queue "//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                  "
queue "//SYSTSPRT DD SYSOUT=Z                                       "
queue "//C1MSGSIN DD DISP=(OLD,PASS),DSN=&&C1MSGS2                  "
queue "//C1MSGS2  DD SYSOUT=*                                       "
queue "//SYSADDR  DD DISP=(NEW,PASS),DSN=&&SYSADDR,                 "
queue "//             SPACE=(TRK,(1,5)),                            "
queue "//             RECFM=FB,LRECL=80                             "
queue "//SYSTSIN  DD DUMMY                                          "
queue "//*                                                          "
queue "//* SEND JOB COMPLETION EMAIL                                "
queue "//*                                                          "
queue "//SENDMAIL EXEC PGM=IKJEFT1B,DYNAMNBR=256,                   "
queue "//  PARM='%SENDMAIL DEFAULT LOG(YES) DEBUG'"
queue "//SYSEXEC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                  "
queue "//SYSTSPRT DD SYSOUT=Z                                       "
queue "//SYSTSIN  DD DUMMY                                          "
queue "//SYSDATA  DD DISP=(OLD,DELETE),DSN=&&C1MSGS2                "
queue "//SYSADDR  DD DISP=(OLD,DELETE),DSN=&&SYSADDR                "

/* Switch to the alternate id                                        */
'alloc f(lgnt$$$i) dummy'
'alloc f(lgnt$$$o) dummy'
'execio * diskr LGNT$$$I (finis'

/* Write the JCL to a dataset and submit the job                     */

jcl_dsn = 'TTEV.TMP.'processor'.D'right(date('S'),6)'.T' || ,
          left(space(translate(time('N'),,':'),0),6)'.JCL'
"alloc f(JCL) dsname('"jcl_dsn"') new catalog"
"execio * diskw JCL (finis"
 if rc ^= 0 then call exception rc 'DISKW to JCL failed.'
"free fi(JCL)"

null  = outtrap('output.')
"submit ('"jcl_dsn"')"
subrc = rc
null  = outtrap('off')

"delete '"jcl_dsn"'"

/* Switch the userid back                                            */
'execio * diskr LGNT$$$O (finis'
'free f(LGNT$$$I)'
'free f(LGNT$$$O)'

if subrc ^= 0 then call exception rc 'SUBMIT of job failed.'

job_details = output.1

if thisjob = 'EAPISVR' then
  call send_email
else
  address tso "send '"job_details"' USER( "uid" )"

/* Write informational message                                       */
queue 'Your' word(scl.2,1) 'has been passed to the ENDEVOR userid for' ,
      'actioning.'
queue 'This means that job' word(job_details,2) 'has been'
queue 'submitted under the security of the ENDEVOR userid.'
queue ' '
queue 'There is a notifier on the job to let you know when the job'
queue 'finishes and the maximum processor return code issued.'
queue ' '
queue 'Please use SDSF (on Qplex) to review the batch job output.'
queue 'Issue the SDSF command PRE' jobname';OWNER ENDEVOR;ST'
queue 'to get the display then a ? next to the entry with the correct'
queue 'job number. If there are README DDnames then please read them.'
queue ' '

"execio * diskw INFO (finis"
if rc ^= 0 then call exception rc 'DISKW to INFO failed.'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Send email back to user to tell them that the job has been subbed */
/*-------------------------------------------------------------------*/
Send_email:

 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(80) blksize(0) dsorg(ps)"

 queue 'FROM: endevor@rbos.co.uk'
 queue 'TO:' uid'@rbos.co.uk'
 queue 'SUBJECT:' job_details

 "execio" queued() "diskw SYSADDR (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed.'

 "alloc f(SYSDATA) new space(2,2) tracks
 recfm(f,b) lrecl(80) blksize(0) dsorg(ps)"

 queue 'Job' word(job_details,2) ,
       'submitted to the Qplex to perform the following action(s)'
 queue ' '
 do i = 1 to scl.0 /* Queue the SCL                                  */
   queue scl.i
 end /* i = 1 to scl.0 */

 "execio" queued() "diskw SYSDATA (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed.'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)'
       'REMLVEURGW06.SERVER.RBSGRP.NET LOG(YES) DEBUG'" exec

 "free fi(SYSADDR SYSDATA)"

return /* Send_email */

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
