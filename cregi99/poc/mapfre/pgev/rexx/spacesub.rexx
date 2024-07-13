/*-----------------------------REXX----------------------------------*\
 *  This Rexx is used by JCL PROC EVL0101D to submit a separate      *
 *  batch job to run SPACEMAN (jobname EVL0102D).                    *
 *                                                                   *
 *  INPUT PARMs                                                      *
 *   PARMS   : The following variable                                *
 *             &CJOB - location of the "C" job JCL                   *
 *                                                                   *
 *  An example of the execution JCL can be found in the proc         *
 *  EVL0101D in PGOS.BASE.PROCLIB                                    *
 *                                                                   *
\*-------------------------------------------------------------------*/

parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

parse arg cjob

say rexxname':' Date() Time()
say rexxname':'
say rexxname': Cjob DSN='cjob
say rexxname':'

rexxlib  = 'PGEV.BASE.REXX'
rexxlibo = 'PGEV.BASE.REXX'
jobn     = 'EVL0102D'
user     = ',USER=PMFBCH'
class    = ',CLASS=A'
msgclass = ',MSGCLASS=Y'
jobname  = MVSVAR('SYMDEF','JOBNAME')

if left(jobname,2) = 'TT' then do
  rexxlibo = 'PREV.OEV1.REXX'
  jobn     = 'TTEV102D'
  class    = ',CLASS=I'
  msgclass = ',MSGCLASS=0'
  user     = ',NOTIFY=&SYSUID'
end /* left(jobname,2) = 'TT' */

jcl.1  = "//"jobn "JOB 1"class || msgclass",REGION=6M"user
jcl.2  = "//*                                                          "
jcl.3  = "//SPACEMAN EXEC PGM=IKJEFT1B,DYNAMNBR=99,PARM='%SPACEMAN'    "
jcl.4  = "//SYSEXEC  DD DISP=SHR,DSN="rexxlibo
jcl.5  = "//         DD DISP=SHR,DSN="rexxlib
jcl.6  = "//SYSTSPRT DD SYSOUT=*                                       "
jcl.7  = "//SYSTSIN  DD DUMMY                                          "
jcl.8  = "//JCL      DD DISP=SHR,DSN="cjob
jcl.9  = "//SYSADDR  DD DSN=&&SYSADDR,DISP=(NEW,PASS),                 "
jcl.10 = "//            SPACE=(TRK,(2,5),RLSE),LRECL=80,               "
jcl.11 = "//            RECFM=FB                                       "
jcl.12 = "//SPACELOG DD DSN=&&SPACELOG,DISP=(NEW,PASS),                "
jcl.13 = "//            SPACE=(TRK,(2,5),RLSE),LRECL=133,              "
jcl.14 = "//            RECFM=FB                                       "
jcl.15 = "//*                                                          "
jcl.16 = "//CHECKIT  IF SPACEMAN.RC GE 4 THEN                          "
jcl.17 = "//*                                                          "
jcl.18 = "//SENDMAIL EXEC PGM=IKJEFT1B,DYNAMNBR=256,                   "
jcl.19 = "//         PARM='%SENDMAIL DEFAULT LOG(YES)'                 "
jcl.20 = "//SYSEXEC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                  "
jcl.21 = "//SYSTSPRT DD SYSOUT=*                                       "
jcl.22 = "//SYSTSIN  DD DUMMY                                          "
jcl.23 = "//SYSDATA  DD DSN=&&SPACELOG,DISP=(OLD,DELETE)               "
jcl.24 = "//SYSADDR  DD DSN=&&SYSADDR,DISP=(OLD,DELETE)                "
jcl.25 = "//*                                                          "
jcl.26 = "//CHECKAB  IF SPACEMAN.RC GE 8 THEN                          "
jcl.27 = "//@SPWARN  EXEC @SPWARN                                      "
jcl.28 = "//CHECKAB  ENDIF                                             "
jcl.29 = "//CHECKIT  ENDIF                                             "
jcl.30 = "//*                                                          "
jcl.0  = 30

say rexxname': Created JCL start'
do i = 1 to jcl.0
  say jcl.i
end /* i = 1 to jcl.0 */
say rexxname': Created JCL end'

"EXECIO * DISKW SUBMIT (FINIS STEM JCL."
if rc ^= 0 then call exception rc 'DISKW to SUBMIT failed'

say rexxname':'
say rexxname':' jobn 'submitted'

exit

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso 'delstack'           /* Clear down the stack          */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
