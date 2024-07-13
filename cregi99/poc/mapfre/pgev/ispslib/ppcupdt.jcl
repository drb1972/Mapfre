//&L.0&TRACKER  JOB ,'&UPDTTYPE &STREAMID',                             00010000
//         MSGCLASS=0,NOTIFY=&&SYSUID,CLASS=G                           00020000
//*                                                                     00030000
//* &UPDTTYPE                                                           00040000
//* COMPONENTS FOR STREAM &STREAMID                                     00050000
//*                                                                     00060000
)DOT PPCTTTB                                                            00070000
//&MEMBER  EXEC PGM=IEBCOPY                                             00080000
//SYSPRINT DD SYSOUT=*                                                  00090000
//*                                                                     00100000
//SOURCE   DD DISP=SHR,DSN=&UPDTDSN                                     00110000
//TARGET   DD DISP=SHR,DSN=&TRGTDSN                                     00120000
//*                                                                     00130000
//SYSIN    DD *                                                         00140000
)SEL &PRODOVER = UP | &PRODOVER = OV                                    00150000
  COPY     OUTDD=TARGET                                                 00160000
           INDD=((SOURCE,R))                                            00170000
  SELECT   MEMBER=&MEMBER                                               00180000
)ENDSEL                                                                 00190000
)SEL &PRODOVER = OX                                                     00200000
  EDITDIR  OUTDD=SOURCE                                                 00210000
  DELETE   MEMBER=&MEMBER                                               00220000
  EDITDIR  OUTDD=TARGET                                                 00230000
  DELETE   MEMBER=&MEMBER                                               00240000
)ENDSEL                                                                 00250000
/*                                                                      00260000
)ENDDOT                                                                 00270000
//                                                                      00280000
