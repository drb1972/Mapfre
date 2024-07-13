//*
//WIZMOVE  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'
//C1TPDD01 DD SPACE=(CYL,(1,1)),RECFM=VB,LRECL=260
//C1TPDD02 DD SPACE=(CYL,(1,1)),RECFM=VB,LRECL=260
//C1TPLSIN DD SPACE=(CYL,(1,1)),RECFM=FB,LRECL=80
//C1TPLSOU DD SPACE=(CYL,(1,1))
//C1PLMSGS DD SYSOUT=*
//*-------------------------------------------------------------------*
//*  OUTPUT DATA SETS                                                 *
//*-------------------------------------------------------------------*
//C1MSGS1  DD SYSOUT=*
//C1MSGS2  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSABEND DD SYSOUT=C
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*-------------------------------------------------------------------*
//*  ENDEVOR CONTROL STATEMENTS                                       *
//*-------------------------------------------------------------------*
//BSTIPT01 DD *
