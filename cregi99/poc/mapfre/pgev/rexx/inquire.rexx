/*--------REXX-------------------------------------------------------*\
 * Read a dataset list created by LMDLIST and create a job to        *
 * INQUIRE on all ELIBS in the list and analyse the output.          *
\*-------------------------------------------------------------------*/
trace n

arg hlq type mem
count  = 0 /* Counter for the number of elib datasets                */
estart = 1 /* Counter for the sysin statements                       */
estep  = 1 /* Counter for the number of steps to be built            */

call jcljob /* Build the top part of the auto job JCL                */
call jclinq /* Build the exec statement                              */

'execio * diskr dslist (stem r. finis' /* read ds list               */
if rc ^= 0 then call exception rc 'DISKR of DDname DSLIST failed'

/* loop through the results of the lmdlist command                   */
do i = 1 to r.0 /* create dd statement for each dsn                  */
  dsn   = subword(r.i,1,1)
  vol   = subword(r.i,2,1)
  dsorg = subword(r.i,3,1)

  /* establish if the dataset is an elib                             */
  if dsorg = 'VS' & right(dsn,5) = '.DATA' then do
    count  = count + 1
    ddname = "//E"||count
    ddname = left(ddname,11)
    queue ddname"DD DSN="dsn",DISP=SHR"

    if count = 749 then do

      do r = estart to 749 /* create inquire statement for each dsn  */
        queue '  INQUIRE  DDNAME=E'r '.'
      end /* do r = estart to 749                                    */

      estep = 2

      call jclinq /* Build another exec if there are lots of DDnames */

      estart = 750

    end /* if count = 749 then do                                    */

  end /* if dsorg = 'VS' & right(dsn,5) = '.DATA' then do            */

end /* do i = 1 to r.0                                               */

queue "//SYSIN    DD *"

do i = estart to count /* create inquire statement for each dsn      */
  queue "  INQUIRE  DDNAME=E"i "."
end /* do i = estart to count                                        */

queue "/* " /* build an end of sysin statement                       */

call jclend /* create elib report step                               */

/* the next two lines just finish the auto JCL                       */
queue "//*"
queue "// "

"execio * diskw jclout (finis" /* write JCL                          */
if rc ^= 0 then call exception rc 'DISKW of JCLOUT failed'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Build the top of the job                                          */
/*-------------------------------------------------------------------*/
jcljob:
 queue "//"mem" JOB ,CLASS=N,MSGCLASS=Y,USER=HKPGEND                  "
 queue "//*                                                           "
 queue "//SETVAR   SET HLQ="hlq",BASEEV=PGEV.BASE.                    "
 queue "//*                                                           "
 queue "//JCLLIB   JCLLIB ORDER=(PGOS.BASE.PROCLIB)                   "
 queue "//*                                                           "
 queue "//************************************************************"
 queue "//* THIS JOB IS CREATED DYNAMICALLY BY EVHEL%1M               "
 queue "//* USING THE INQUIRE REXX IN SYSTEM EV                       "
 queue "//************************************************************"
return

/*-------------------------------------------------------------------*/
/* Build the step header                                             */
/*-------------------------------------------------------------------*/
jclinq:
 queue "//JSTEP0"estep"0 EXEC PGM=BC1PNLIB                            "
 queue "//SYSPRINT DD DSN=&HLQ.INQUIRE"estep",DISP=(NEW,CATLG),       "
 queue "//             SPACE=(TRK,(75,75),RLSE),RECFM=FB,             "
 queue "//             LRECL=133                                      "
 queue "//BSTERR   DD SYSOUT=*                                        "
 queue "//SYSUDUMP DD SYSOUT=C                                        "
return

/*-------------------------------------------------------------------*/
/* Build check and SAS steps                                         */
/*-------------------------------------------------------------------*/
jclend:
 queue "//CHECK0"estep"0 IF RC NE 0 THEN                              "
 queue "//*                                                           "
 queue "//JSTEP0"estep"5 EXEC @SPWARN                                 "
 queue "//CHECK0"estep"0 ENDIF                                        "
 queue "//*                                                           "
 queue "//JSTEP030 EXEC SAS,                                          "
 queue "//             OPTIONS='MACRO,DQUOTE,YEARCUTOFF=1960',        "
 queue "//             TIME=10,SORT=20                                "
 queue "//DUMP     DD SYSOUT=Z                                        "
 queue "//SASLOG   DD SYSOUT=*                                        "
 queue "//SASLIST  DD SYSOUT=*,HOLD=YES                               "
 queue "//ELIBINQ  DD DSN=&HLQ.INQUIRE1,DISP=(OLD,DELETE)             "

 if count > 1000 then ,
 queue "//         DD DSN=&HLQ.INQUIRE2,DISP=(OLD,DELETE)             "

 queue "//ELIBLIST DD DSN=&HLQ.DSLIST."type",DISP=(OLD,DELETE)        "
 queue "//OUTFILE  DD DSN=&HLQ.ELIB."type"(+1),DISP=(NEW,CATLG),      "
 queue "//             SPACE=(TRK,(15,15),RLSE),RECFM=FB,             "
 queue "//             LRECL=132                                      "
 queue "//CSV      DD DSN=&HLQ.ELIB."type".CSV(+1),DISP=(NEW,CATLG),  "
 queue "//             SPACE=(TRK,(15,15),RLSE),RECFM=FB,             "
 queue "//             LRECL=132                                      "
 queue "//SYSIN    DD DSN=&BASEEV.SAS(ELIBRPT),DISP=SHR               "
 queue "//CHECK030 IF JSTEP030.SAS.RC GT 4 THEN                       "
 queue "//*                                                           "
 queue "//JSTEP035 EXEC @SPWARN                                       "
 queue "//CHECK030 ENDIF                                              "
 queue "//*                                                           "
 queue "//JSTEP040 EXEC EVHELIB2,TYPE="type",                         "
 queue "//             HLQ="hlq
return

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack                                             */
 do i = 1 to queued()
   pull
 end /* do i = 1 to queued()                                         */

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
