//*--SKELETON  CMSEMAIL - SEND EMAIL IF RJOB FAILS                    --
//*********************************************************************
//** E-MAIL THE SUPPORT MAILBOX ONLY IF THE JOB ABENDS               **
//*********************************************************************
//CONDONLY EXEC PGM=IKJEFT1B,COND=ONLY,
//             PARM='%SENDMAIL DEFAULT LOG(YES)'
//SYSEXEC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//SYSADDR  DD *
  FROM: mapfre.endevor@rsmpartners.com
  TO: mapfre.endevor@rsmpartners.com
  SUBJECT: EPLEX - EPLEX &RMEM has failed!!!!
//SYSDATA  DD *
Please investigate
/*
