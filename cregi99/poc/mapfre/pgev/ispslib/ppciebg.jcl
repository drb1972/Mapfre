//IEBGENER EXEC PGM=IEBGENER                                            00010000
//SYSPRINT DD SYSOUT=*                                                  00020000
//SYSIN    DD DUMMY                                                     00030000
//*                                                                     00040000
//SYSUT1   DD DISP=SHR,                                                 00050006
//         DSN=&STRMPRFX.&STREAMID..F0&TRACKER..CNTL(&L.0&TRACKER)      00060012
//SYSUT2   DD SYSOUT=(G,INTRDR)                                         00070003
//*                                                                     00080002
