//&C1PREF.NDVR JOB 0,,CLASS=3,NOTIFY=&&SYSUID,REGION=8M,                00010005
//             SCHENV=SAS
//*                                                                     00020002
//DEL1     EXEC PGM=IEFBR14
//BSTRPTS  DD DSN=TTYY.&C1SYSUID..REPOUT,DISP=(NEW,CATLG,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=133
//*
)SEL &UNIT = Y
//*********************************************************************
//REPORTS  EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DSN=TTYY.&C1SYSUID..REPOUT,DISP=MOD
//BSTINP   DD *                                     SELECTION CRITERIA
     REPORT  03 .
     ENVIRONMENT UNIT .
     SYSTEM      &C1SYS .
     SUBSYSTEM   * .
     ELEMENT     * .
     TYPE        * .
     STAGE       * .
     DAYS        50 .
/*
//BSTPDS   DD DUMMY                                 FOOTPRINT DATA SET
//SMFDATA  DD DUMMY                                 SMF DATA SET
//UNLINPT  DD DUMMY                                 UNLOAD DATA SET
//BSTPCH   DD DSN=&&TEMP,DISP=(NEW,DELETE,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD UNIT=DASD,SPACE=(CYL,(150,15))
//SORTOUT  DD UNIT=DASD,SPACE=(CYL,(150,15))
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
)ENDSEL
//*********************************************************************
)SEL &SYST = Y
//REPORTS  EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DSN=TTYY.&C1SYSUID..REPOUT,DISP=MOD
//BSTINP   DD *                                     SELECTION CRITERIA
     REPORT  03 .
     ENVIRONMENT SYST .
     SYSTEM      &C1SYS .
     SUBSYSTEM   * .
     ELEMENT     * .
     TYPE        * .
     STAGE       * .
     DAYS        50 .
/*
//BSTPDS   DD DUMMY                                 FOOTPRINT DATA SET
//SMFDATA  DD DUMMY                                 SMF DATA SET
//UNLINPT  DD DUMMY                                 UNLOAD DATA SET
//BSTPCH   DD DSN=&&TEMP,DISP=(NEW,DELETE,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD UNIT=DASD,SPACE=(CYL,(150,15))
//SORTOUT  DD UNIT=DASD,SPACE=(CYL,(150,15))
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
)ENDSEL
//*********************************************************************
)SEL &ACPT = Y
//REPORTS  EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DSN=TTYY.&C1SYSUID..REPOUT,DISP=MOD
//BSTINP   DD *                                     SELECTION CRITERIA
     REPORT  03 .
     ENVIRONMENT ACPT .
     SYSTEM      &C1SYS .
     SUBSYSTEM   * .
     ELEMENT     * .
     TYPE        * .
     STAGE       * .
     DAYS        50 .
/*
//BSTPDS   DD DUMMY                                 FOOTPRINT DATA SET
//SMFDATA  DD DUMMY                                 SMF DATA SET
//UNLINPT  DD DUMMY                                 UNLOAD DATA SET
//BSTPCH   DD DSN=&&TEMP,DISP=(NEW,DELETE,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD UNIT=DASD,SPACE=(CYL,(150,15))
//SORTOUT  DD UNIT=DASD,SPACE=(CYL,(150,15))
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
)ENDSEL
//*********************************************************************
)SEL &PROD = Y
//REPORTS  EXEC PGM=NDVRC1,PARM='C1BR1000'
//BSTRPTS  DD DSN=TTYY.&C1SYSUID..REPOUT,DISP=MOD
//BSTINP   DD *                                     SELECTION CRITERIA
     REPORT  03 .
     ENVIRONMENT PROD .
     SYSTEM      &C1SYS .
     SUBSYSTEM   * .
     ELEMENT     * .
     TYPE        * .
     STAGE       * .
     DAYS        50 .
/*
//BSTPDS   DD DUMMY                                 FOOTPRINT DATA SET
//SMFDATA  DD DUMMY                                 SMF DATA SET
//UNLINPT  DD DUMMY                                 UNLOAD DATA SET
//BSTPCH   DD DSN=&&TEMP,DISP=(NEW,DELETE,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=838
//BSTLST   DD SYSOUT=*
//SORTIN   DD UNIT=DASD,SPACE=(CYL,(150,15))
//SORTOUT  DD UNIT=DASD,SPACE=(CYL,(150,15))
//C1MSGS1  DD SYSOUT=*
//APIPRINT DD SYSOUT=Z
//HLAPILOG DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*********************************************************************
)ENDSEL
//*
//FORMAT   EXEC PGM=IKJEFT1B,
//             PARM=('PARDEV1,&C1SYSUID')
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//REPOUT2  DD DSN=TTYY.&C1SYSUID..REPOUT2,DISP=(NEW,CATLG,DELETE),
//             SPACE=(CYL,(1,2)),
//             RECFM=FB,LRECL=133
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*                                                                     00020002
//SORT1    EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=TTYY.&C1SYSUID..REPOUT2,DISP=SHR
//SORTOUT  DD DSN=TTYY.&C1SYSUID..REPOUT2,DISP=SHR
//SYSIN    DD *
 SORT FIELDS=(1,18,CH,A)
/*
//FORMAT3  EXEC PGM=IKJEFT1B,
//             PARM=('PARDEV2,&C1SYSUID')
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
//REPOUT3  DD DSN=TTYY.&C1SYSUID..REPOUT3,DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(15,30),RLSE),
//             RECFM=FB,LRECL=133
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//PARALL   EXEC SAS,WORK='5000,2000',CONFIG='PREV.PEV1.DATA(SASEMAIL)'
//SYSIN    DD *
FILENAME MYMAIL EMAIL '&C1EMAIL'
         SUBJECT='&C1PREF.NDVR - PARALLEL DEVELOPMENT SPREADSHEET'
   ATTACH=("TTYY.&C1SYSUID..REPOUT3"EXTENSION='CSV')
         ;
DATA _NULL_;
  FILE MYMAIL;
 put 'Summary of elements in the &c1sys system.                   ';
 put '                                                              ';
 put 'Elements that occur in more than one development location are  ';
 put 'tagged as duplicate in the occurrence column.                  ';
 put 'Duplicate elements should be carefully managed to avoid code   ';
 put 'regression, and redundant versions should be deleted.        ';
 put '                                                               ';
 put 'You should also sort the spreadsheet by generate date to       ';
 put 'highlight elements in development that have not been generated ';
 put 'for over a year, and assess whether or not they are still valid.';
 put '                                                                ';
 put '                                                                ';
 put '                                                                ';
 put '                                                                ';
 put '                                                                ';
 put '                                                                ';
RUN;
/*
//DEL1     EXEC PGM=IEFBR14
//DD1      DD DSN=TTYY.&C1SYSUID..REPOUT,DISP=(MOD,DELETE,DELETE),
//             SPACE=(TRK,1)
//DD2      DD DSN=TTYY.&C1SYSUID..REPOUT2,DISP=(MOD,DELETE,DELETE),
//             SPACE=(TRK,1)
//DD3      DD DSN=TTYY.&C1SYSUID..REPOUT3,DISP=(MOD,DELETE,DELETE),
//             SPACE=(TRK,1)
//*
