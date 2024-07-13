//*        INPUT PDS TO SAS PROCESS                                     00010008
//&LOC     DD DISP=SHR,DSN=&DSN                                         00020009
//*                                                                     00030003
//*        OUTPUT MEMBER LIST FROM PROC SOURCE                          00040008
//D&LOC    DD DSN=&&TEMP,DISP=(,DELETE),                                00050009
//         RECFM=FB,LRECL=80,SPACE=(TRK,(1,5)),UNIT=3390                00060003
//*                                                                     00070003
//*        OUTPUT IEBCOPY SELECT STATEMENTS FROM SAS PROCESS            00080008
//C&LOC    DD DISP=(,CATLG),UNIT=3390,                                  00090018
//         DSORG=PS,RECFM=FB,LRECL=80,SPACE=(TRK,(1,5)),                00100018
//         DSN=&STRMPRFX.&STREAMID..F0&TRACKER..&SYS..&LOC..&TYPE..CNTL 00110018
//*                                                                     00120003
