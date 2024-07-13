/*                                                                      00000010
//*--SKELETON CMSAOB   - BOTTOM OF AO STEP                           -- 00000020
//FAILURES DD SYSOUT=*,RECFM=FB                                         00000100
//*                                                                     00000200
//********************************************************************* 00000300
//** SPWARN - ABEND IF &STPNAME RETURN CODE IS NOT EQUAL TO ONE      ** 00000400
//********************************************************************* 00000500
//CHECKIT  IF &STPNAME..RC NE 1 THEN                                    00000600
//*                                                                     00000700
//SPWARN   EXEC @SPWARN,COND=EVEN                                       00000800
//CHECKIT  ENDIF                                                        00000900
//*                                                                     00000910
)SEL &PLXCLONE EQ Q1                                                    00000911
//********************************************************************* 00000920
//** E-MAIL THE SUPPORT MAILBOX ONLY IF THE JOB ABENDS               ** 00000930
//********************************************************************* 00000940
//CONDONLY EXEC PGM=IKJEFT1B,COND=ONLY,                                 00001000
//             PARM='%SENDMAIL DEFAULT LOG(YES)'                        00001100
//SYSEXEC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                             00001200
//SYSTSPRT DD SYSOUT=*                                                  00001300
//SYSTSIN  DD DUMMY                                                     00001400
//SYSADDR  DD *                                                         00001500
  FROM: mapfre.endevor@rsmpartners.com                                  00001600
  TO: mapfre.endevor@rsmpartners.com                                    00001700
  SUBJECT: EPLEX - &RMEM has failed!!!!                                 00001800
//SYSDATA  DD *                                                         00001900
Please investigate                                                      00002000
/*                                                                      00002100
)ENDSEL                                                                 00002200
