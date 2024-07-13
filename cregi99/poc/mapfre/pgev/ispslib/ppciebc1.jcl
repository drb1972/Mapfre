//&LOC&COUNT  EXEC PGM=IRXJCL,PARM='PPCRECNT'                           00010025
//SYSEXEC  DD DISP=SHR,DSN=TTEM.PCM.EXEC                                00020004
//SYSTSOUT DD SYSOUT=*                                                  00030004
//SYSTSPRT DD SYSOUT=*                                                  00040004
//SYSTSIN  DD DUMMY                                                     00050004
//IN       DD DISP=SHR,                                                 00060018
//         DSN=&STRMPRFX.&STREAMID..F0&TRACKER..&SYS..&LOC..&TYPE..CNTL 00070020
//*                                                                     00080004
//         IF (&LOC&COUNT..RC = 0) THEN                                 00090022
//*                                                                     00100004
//IEBCOPY  EXEC PGM=IEBCOPY                                             00110016
//SYSPRINT DD SYSOUT=*                                                  00120000
//*                                                                     00130000
//SOURCE   DD DISP=SHR,DSN=&DSN                                         00140000
//*                                                                     00150000
//STREAMED DD DISP=SHR,DSN=&TRGTDSN                                     00160000
//*                                                                     00170000
//SYSIN    DD *                                                         00180000
  COPY     OUTDD=STREAMED                                               00190000
           INDD=((SOURCE,R))                                            00200009
/*                                                                      00210000
//         DD DISP=SHR,                                                 00220018
//         DSN=&STRMPRFX.&STREAMID..F0&TRACKER..&SYS..&LOC..&TYPE..CNTL 00230020
//*                                                                     00240005
//         ENDIF                                                        00250005
//*                                                                     00260005
