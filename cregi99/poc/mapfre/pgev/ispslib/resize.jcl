&EWJCL1
&EWJCL2
&EWJCL3
&EWJCL4
//*
//* +----------------------------------------------------------+
//* +  RESIZE DATASETS                                         +
//* +----------------------------------------------------------+
)SEL &ENQTYPE = P
//* +----------------------------------------------------------+
//* +  GET DATASET FOR EXCLUSIVE USE                           +
//* +----------------------------------------------------------+
//LOCKDSN  EXEC PGM=IKJEFT01                                            00010039
//SYSTSPRT DD SYSOUT=*                                                  00010050
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR                               00010060
//ISPLLIB  DD DISP=SHR,DSN=PGEV.BASE.LOAD
//ISPSLIB  DD DISP=SHR,DSN=SYS1.SISPSENU
//ISPMLIB  DD DISP=SHR,DSN=SYS1.SISPMENU
//ISPPLIB  DD DISP=SHR,DSN=SYS1.SISPPENU
//ISPTLIB  DD DISP=SHR,DSN=SYS1.SISPTENU
//ISPCTL1  DD SPACE=(CYL,(1,1)),
//            LRECL=80,BLKSIZE=800,RECFM=FB
//ISPPROF  DD SPACE=(CYL,(1,1,20)),LRECL=80,RECFM=FB
//ISPLIST  DD SYSOUT=*,
//            LRECL=121,BLKSIZE=1210,RECFM=FBA
//ISPLOG   DD SYSOUT=Z,RECFM=VA,LRECL=125,BLKSIZE=129
//SYSTSIN  DD *                                                         00010070
ISPSTART CMD(RESIZEE &IDSN &MAXWAIT &INTERVAL)                          00010039
)ENDSEL
//*
//* +----------------------------------------------------------+
//* + RENAME &IDSN
//* +     TO &RENAMDSN
//* +----------------------------------------------------------+
//RENAME1   EXEC PGM=IDCAMS
//SYSPRINT  DD SYSOUT=*
)SEL &ENQTYPE ^= P
//LOCK      DD DISP=OLD,DSN=&IDSN
)ENDSEL
//SYSIN     DD *
    ALTER &IDSN +
      NEWNAME(&RENAMDSN)
/*
//* +----------------------------------------------------------+
//* + COPY &RENAMDSN
//* +   TO &NEWDSN
//* +----------------------------------------------------------+
//IF00100   IF RC = 0 THEN
)IF &COPYPGM = IEBCOPY THEN )DO
//COPY     EXEC PGM=IEBCOPY
//FCOPYON  DD DUMMY
//SYSPRINT DD SYSOUT=*
//PDSIN    DD DSN=&RENAMDSN,
//            DISP=OLD
//PDSOUT   DD DSN=&NEWDSN,
//            DISP=(NEW,CATLG),
//            LIKE=&LIKEDSN,
//            DCB=&LIKEDSN,
)IF &LDIR = NO_LIM THEN
//            SPACE=(&LUNITS,(&LPRI,&LSEC)),
)ELSE
//            SPACE=(&LUNITS,(&LPRI,&LSEC,&LDIR)),
//            DSNTYPE=&LDSTYP
//SYSIN    DD *
  COPY OUTDD=PDSOUT,INDD=((PDSIN,R))
  EXCLUDE MEMBER=$$$SPACE
/*
//SYSUT3   DD SPACE=(CYL,(30,30),RLSE),UNIT=SYSDA WORK FILE 1
//SYSUT4   DD SPACE=(CYL,(30,30),RLSE),UNIT=SYSDA WORK FILE 2
)ENDDO
)ELSE )DO
//COPY     EXEC PGM=NDVRC1,PARM=(BC1PNCPY)
//PDSIN    DD DISP=SHR,DSN=&RENAMDSN
//PDSOUT   DD DSN=&NEWDSN,
//            DISP=(NEW,CATLG),
//            LIKE=&LIKEDSN,
//            DCB=&LIKEDSN,
)IF &LDIR = NO_LIM THEN
//            SPACE=(&LUNITS,(&LPRI,&LSEC)),
)ELSE
//            SPACE=(&LUNITS,(&LPRI,&LSEC,&LDIR)),
//            DSNTYPE=&LDSTYP
//SYSPRINT DD  SYSOUT=*
//BSTERR   DD  SYSOUT=*
//APIPRINT DD  SYSOUT=Z
//SYSUDUMP DD  SYSOUT=Z
//SYSIN    DD  *
  COPY INPUT  DDNAME=PDSIN
       OUTPUT DDNAME=PDSOUT UPDATE IF PRESENT .
/*
)ENDDO
//IF00100   ENDIF
//* +----------------------------------------------------------+
//* + REDEFINE ALIASES
//* +----------------------------------------------------------+
//IF00150   IF RC = 0 THEN
//ALIAS    EXEC PGM=IKJEFT01,
//     PARM=('RESIZEA &RENAMDSN',
//           ' &NEWDSN')
//SYSTSPRT DD SYSOUT=*
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSIN  DD DUMMY
//PRINT1   DD SYSOUT=*               /* IDCAMS */
//SYSPRINT DD SYSOUT=*               /* IDCAMS */
//IF00150   ENDIF
//* +----------------------------------------------------------+
//* + RENAME   &NEWDSN
//* +  BACK TO &IDSN
//* +----------------------------------------------------------+
//IF00200   IF RC = 0 THEN
//RENAME2 EXEC PGM=IDCAMS
//SYSPRINT  DD SYSOUT=*
//SYSIN     DD *
    ALTER &NEWDSN +
          NEWNAME(&IDSN)
/*
//IF00200   ENDIF
//* +----------------------------------------------------------+
//* + DO A MEMBER COUNT ON &IDSN
//* + AND &RENAMDSN
//* +----------------------------------------------------------+
//CMPDSMEM EXEC PGM=IKJEFT1B
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//README   DD SYSOUT=*,BLKSIZE=0
//IN       DD *
&RENAMDSN
&IDSN
/*
//SYSTSIN  DD *
 %CMPDSMEM
/*
)SEL &DELOLD = Y
//* +----------------------------------------------------------+
//* + DELETE OLD DATASET
//* +        &RENAMDSN
//* +----------------------------------------------------------+
//IF00300   IF RC = 0 THEN
//DELETE    EXEC PGM=IDCAMS
//SYSPRINT  DD SYSOUT=*
//SYSIN     DD *
    DELETE &RENAMDSN
    SET MAXCC = 0
/*
//IF00300   ENDIF
)ENDSEL
//* +----------------------------------------------------------+
//* + SEND MESSAGE ON FAILURE                                  +
//* +----------------------------------------------------------+
//IF08000   IF RC GT 0 THEN
//MESSAGE  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=Z
//SYSPRINT DD SYSOUT=Z
//SYSTSIN  DD *
SE 'RESIZE FAILED FOR   &IDSN'                                         -
U(&SYSUID) LOGON
SE 'RESIZE FAILED FOR   &IDSN'                                         -
U(&SYSUID) LOGON
SE 'RESIZE FAILED FOR   &IDSN'                                         -
U(&SYSUID) LOGON
SE 'RESIZE FAILED FOR   &IDSN'                                         -
U(&SYSUID) LOGON
SE 'RESIZE FAILED FOR   &IDSN'                                         -
U(&SYSUID) LOGON
//IF08000   ENDIF
