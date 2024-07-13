//*--SKELETON CMSPACKS                                               -- 00000100
//*--REINSTATE LISTINGS AND SIGNOUT ELEMENTS AFTER BACKOUT           -- 00000200
//*                                                                     00000300
//********************************************************************* 00000400
//** IDCAMS - CHECK IF LISTING DSN EXISTS                            ** 00000500
//********************************************************************* 00000600
//LISTCAT  EXEC PGM=IDCAMS                                              00000700
//SYSPRINT DD SYSOUT=*                                                  00000800
//SYSIN    DD *                                                         00000900
 LISTCAT ENTRIES(&SHIPHLQC..LISTINGS)                                   00001000
/*                                                                      00001100
//********************************************************************* 00001200
//** REINSTAT - REINSTATE LISTINGS (IF THERE IS ONE)                 ** 00001300
//********************************************************************* 00001400
//IFLISTOK IF LISTCAT.RC = 0 THEN                                       00001500
//*                                                                   * 00001600
//REINSTAT EXEC PGM=NDVRC1,PARM='BC1PNCPY'                              00001700
//LISTINP  DD DSN=&SHIPHLQC..LISTINGS,DISP=SHR                          00001800
//LISTOUT  DD DSN=PREV.P&C1SY..LISTINGS,DISP=SHR                        00001900
//SYSPRINT DD SYSOUT=*                                                  00002000
//SYSIN    DD *                                                         00002100
  COPY INPUT DDNAME=LISTINP                                             00002200
      OUTPUT DDNAME=LISTOUT UPDATE .                                    00002300
/*                                                                      00002400
//IFLISTOK ENDIF                                                        00002500
//*                                                                     00002600
//********************************************************************* 00002700
//** SPWARN - ABEND IF REINSTAT RETURN CODE IS GREATER THAN ZERO     ** 00002800
//********************************************************************* 00002900
//CHECKIT  IF REINSTAT.RC GT 0 THEN                                     00003000
//*                                                                     00003100
//SPWARN   EXEC @SPWARN,COND=EVEN                                       00003200
//CHECKIT  ENDIF                                                        00003300
//*                                                                     00003400
//********************************************************************* 00003500
//** PACKREP - ENDEVOR PACKAGE DETAIL REPORT                         ** 00003600
//********************************************************************* 00003700
//PACKREP  EXEC PGM=NDVRC1,PARM='C1BR1000'                              00003800
//BSTRPTS  DD DSN=&&PKGREP,DISP=(NEW,PASS,DELETE),                      00003900
//             SPACE=(CYL,(2,2)),                                       00004000
//             RECFM=FBA,LRECL=133                                      00004100
//BSTINP   DD *                                                         00004200
     REPORT  72 .                                                       00004300
     ENVIRONMENT * .                                                    00004400
     PACKAGE  &CMR.P .                                                  00004500
     STATUS  IN-ED IN-AP DE APPROVED EXE AB CO BA .                     00004600
/*                                                                      00004700
//BSTPDS   DD DUMMY                                                     00004800
//SMFDATA  DD DUMMY                                                     00004900
//UNLINPT  DD DUMMY                                                     00005000
//BSTPCH   DD DISP=(NEW,DELETE,DELETE),                                 00005100
//             SPACE=(TRK,(15,30),RLSE),                                00005200
//             RECFM=FB,LRECL=838                                       00005300
//BSTLST   DD SYSOUT=*                                                  00005400
//SORTIN   DD SPACE=(CYL,(5,5))                                         00005500
//SORTOUT  DD SPACE=(CYL,(5,5))                                         00005600
//C1MSGS1  DD SYSOUT=*                                                  00005700
//APIPRINT DD SYSOUT=*                                                  00005800
//HLAPILOG DD SYSOUT=*                                                  00005900
//SYSOUT   DD SYSOUT=*                                                  00006000
//SYSPRINT DD SYSOUT=*                                                  00006100
//*                                                                     00006200
//********************************************************************* 00006300
//** SPWARN - ABEND IF PACKREP RETURN CODE IS GREATER THAN FOUR      ** 00006400
//********************************************************************* 00006500
//CHECKIT  IF PACKREP.RC GT 4 THEN                                      00006600
//*                                                                     00006700
//SPWARN   EXEC @SPWARN,COND=EVEN                                       00006800
//CHECKIT  ENDIF                                                        00006900
//*                                                                     00007000
//********************************************************************* 00007100
//** SIGNSCL - BUILD ENDEVOR SIGNIN SCL                              ** 00007200
//********************************************************************* 00007300
//SIGNSCL  EXEC PGM=IRXJCL,PARM='EVSPECI &CMR.P &OPTION'                00007400
//SYSTSPRT DD SYSOUT=*                                                  00007500
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                               00007600
//SYSTSIN  DD DUMMY                                                     00007700
//PKGREP   DD DSN=&&PKGREP,DISP=(OLD,DELETE)                            00007800
//SCL      DD DSN=&&SCL,DISP=(NEW,PASS,DELETE),                         00007900
//             SPACE=(TRK,(15,30),RLSE),                                00008000
//             RECFM=FB,LRECL=80                                        00008100
//*                                                                     00008200
//********************************************************************* 00008300
//** SPWARN - ABEND IF SIGNSCL RETURN CODE IS GREATER THAN FOUR      ** 00008400
//********************************************************************* 00008500
//CHECKIT  IF SIGNSCL.RC GT 4 THEN                                      00008600
//*                                                                     00008700
//SPWARN   EXEC @SPWARN,COND=EVEN                                       00008800
//CHECKIT  ENDIF                                                        00008900
//*                                                                     00009000
//********************************************************************* 00009100
//** SIGNOUT - EXECUTE COMMANDS BUILT BY EVSPECI REXX                ** 00009200
//********************************************************************* 00009300
//SIGNOUT  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'                00009400
//C1SORTIO DD SPACE=(CYL,(50,50)),RECFM=VB,                             00009500
//             LRECL=32760                                              00009600
//APIPRINT DD SYSOUT=*                                                  00009700
//HLAPILOG DD SYSOUT=*                                                  00009800
//C1MSGS1  DD SYSOUT=*                                                  00009900
//C1MSGS2  DD SYSOUT=*                                                  00010000
//C1PRINT  DD SYSOUT=*,RECFM=FBA,                                       00010100
//             LRECL=133                                                00010200
//SYSPRINT DD SYSOUT=*                                                  00010300
//SYSUDUMP DD SYSOUT=C                                                  00010400
//SYSOUT   DD SYSOUT=*                                                  00010500
//SYMDUMP  DD DUMMY                                                     00010600
//BSTIPT01 DD DSN=&&SCL,DISP=(OLD,DELETE)                               00010700
//*                                                                     00010800
//********************************************************************* 00010900
//** SPWARN - ABEND IF SIGNOUT RETURN CODE GREATER THAN EIGHT        ** 00011000
//********************************************************************* 00011100
//CHECKIT  IF SIGNOUT.RC GT 8 THEN                                      00011200
//*                                                                     00011300
//SPWARN   EXEC @SPWARN,COND=EVEN                                       00011400
//CHECKIT  ENDIF                                                        00011500
//*                                                                     00011600
