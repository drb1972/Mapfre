//T0&TRACKER  JOB ,'PACKAGE UPDATE TO &STREAMID',                       00010011
//         MSGCLASS=0,NOTIFY=&&SYSUID,CLASS=G                           00020000
//*                                                                     00030000
//* COPY PACKAGE DATASETS TO STREAM                                     00040008
//*                                                                     00050008
)DOT PACKAGE                                                            00060007
//&TYPE    EXEC PGM=IEBCOPY                                             00070003
//SYSPRINT DD SYSOUT=*                                                  00080003
//*                                                                     00090003
//PACKAGE  DD DISP=SHR,DSN=&PKGEDSN                                     00100009
//STREAMED DD DISP=SHR,DSN=&TRGTDSN                                     00110003
//*                                                                     00120003
//SYSIN    DD *                                                         00130003
  COPY     OUTDD=STREAMED                                               00140003
           INDD=((PACKAGE,R))                                           00150003
/*                                                                      00160003
)ENDDOT                                                                 00170003
