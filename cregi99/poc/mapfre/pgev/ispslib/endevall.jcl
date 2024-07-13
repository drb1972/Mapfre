//&C1PREF.NDVR JOB 0,'ENDEVOR CSV UTILITY',CLASS=3,REGION=8M,
//             NOTIFY=&&SYSUID&SCHENV
//*
//* EXECUTE CSV UTILITY TO LIST ELEMENTS
//NDVRLIST EXEC PGM=NDVRC1,PARM='CONCALL,DDN:CONLIB,BC1PCSV0'
//BSTIPT01 DD *
)SEL &UNIT = Y
  LIST ELEMENT *
    FROM ENVIRONMENT 'UNIT' SYSTEM &C1SYS SUBSYSTEM &C1SUB
      TYPE * STAGE A
    OPTIONS NOSEARCH NOCSV
   .
  LIST ELEMENT *
    FROM ENVIRONMENT 'UNIT' SYSTEM &C1SYS SUBSYSTEM &C1SUB
      TYPE * STAGE B
    OPTIONS NOSEARCH NOCSV
   .
)ENDSEL
)SEL &SYST = Y
  LIST ELEMENT *
    FROM ENVIRONMENT 'SYST' SYSTEM &C1SYS SUBSYSTEM &C1SUB
      TYPE * STAGE C
    OPTIONS NOSEARCH NOCSV
   .
  LIST ELEMENT *
    FROM ENVIRONMENT 'SYST' SYSTEM &C1SYS SUBSYSTEM &C1SUB
      TYPE * STAGE D
    OPTIONS NOSEARCH NOCSV
   .
)ENDSEL
)SEL &ACPT = Y
  LIST ELEMENT *
    FROM ENVIRONMENT 'ACPT' SYSTEM &C1SYS SUBSYSTEM &C1SUB
      TYPE * STAGE E
    OPTIONS NOSEARCH NOCSV
   .
  LIST ELEMENT *
    FROM ENVIRONMENT 'ACPT' SYSTEM &C1SYS SUBSYSTEM &C1SUB
      TYPE * STAGE F
    OPTIONS NOSEARCH NOCSV
   .
)ENDSEL
)SEL &PROD = Y
  LIST ELEMENT *
    FROM ENVIRONMENT 'PROD' SYSTEM &C1SYS SUBSYSTEM *
      TYPE * STAGE O
    OPTIONS NOSEARCH NOCSV
   .
  LIST ELEMENT *
    FROM ENVIRONMENT 'PROD' SYSTEM &C1SYS SUBSYSTEM *
      TYPE * STAGE P
    OPTIONS NOSEARCH NOCSV
   .
)ENDSEL
/*
//APIEXTR  DD DSN=&&CSVOUT,DISP=(MOD,PASS),
//             SPACE=(CYL,(15,15),RLSE),
//             RECFM=FB,LRECL=1600
//CSVMSGS1 DD SYSOUT=*
//C1MSGSA  DD SYSOUT=*
//BSTERR   DD SYSOUT=Z
//APIPRINT DD SYSOUT=Z
//*
//CHECKIT  IF NDVRLIST.RC GT 4 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//*RETRIEVE MEMBER HIGHEST IN CONCATENATION ORDER
//PRESORT1 EXEC PGM=FILEAID
//DD01     DD DISP=SHR,DSN=&EVPREF1..SYMNAME                            */
//         DD DISP=SHR,DSN=&EVPREF2..SYMNAME                            */
//DD01O    DD DSN=&&ECHALELM,DISP=(NEW,PASS),
//             SPACE=(TRK,(15,75,44),RLSE),LRECL=80,
//             RECFM=FB
//SYSPRINT DD SYSOUT=*
//SYSLIST  DD SYSOUT=*
//SYSIN    DD *
$$DD01 COPY MEMBER=ECHALELM
/*
//*
//CHECKIT  IF PRESORT1.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//* SORT INTO ELEMENT AND TYPE ORDER
//SORT1    EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=&&CSVOUT,DISP=(OLD,DELETE)
//SORTOUT  DD DSN=&&CSVSORT,DISP=(NEW,PASS),
//             SPACE=(CYL,(15,15),RLSE)
//SYMNAMES DD DSN=&&ECHALELM(ECHALELM),DISP=(OLD,PASS)
//SYMNOUT  DD SYSOUT=Z,RECFM=FBA,LRECL=121
//SYSIN    DD *
 SORT FIELDS=(ALELM-RS-ELMNAME,A,ALELM-RS-TYPE,A)
  INCLUDE COND=(ALELM-RS-RECTYP,EQ,C'M')
/*
//*
//CHECKIT  IF SORT1.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//*  THE NEXT STEP RUNS AN RFT REPORT AGAINST INFOMAN TO LIST
//*  ALL PACKAGE TYPE RECORDS
//*
//INFOMAN  EXEC PGM=IKJEFT1B,
//             DYNAMNBR=99,
//             REGION=6M
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//BLGTRACE DD SYSOUT=*
//SYSPROC  DD DSN=PGIB.BASE.CLIST,DISP=SHR
//ISPSLIB  DD DSN=PGIB.BASE.SKELS,DISP=SHR
//ISPMLIB  DD DSN=SYS1.SISPMENU,DISP=SHR
//ISPPROF  DD SPACE=(CYL,(1,1,20),),RECFM=FB,
//             LRECL=80
//ISPTLIB  DD DSN=*.ISPPROF,DISP=(OLD,PASS),
//             VOL=REF=*.ISPPROF
//         DD DSN=SYSTSO.BASE.TABLES,DISP=SHR
//         DD DSN=PGIB.BASE.TABLES,DISP=SHR
//         DD DSN=SYS1.SISPTENU,DISP=SHR
//ISPPLIB  DD DSN=PGIB.BASE.PANELS,DISP=SHR
//         DD DSN=SYS1.SISPPENU,DISP=SHR
//PRTFILE  DD RECFM=FB,LRECL=80,BLKSIZE=320,SYSOUT=*
//ISPLOG   DD RECFM=VA,LRECL=125,BLKSIZE=129,SYSOUT=*
//ISPLIST  DD RECFM=FBA,LRECL=121,BLKSIZE=3146,SYSOUT=*
//RFTP0    DD DSN=&EVPREF1..RFT,DISP=SHR
//         DD DSN=&EVPREF2..RFT,DISP=SHR
//OUTPUT   DD DSN=&&RFTOUT,DISP=(,PASS),
//             SPACE=(CYL,(1,5),RLSE),
//             RECFM=FB,LRECL=300
//SYSTSIN  DD *
  ISPSTART PGM(TSUTINM) PARM(SESS(P0) CLASS(&ENTRY)                    +
  IRC(;PROF,7,4,5,,                                                    +
  1,1,MANAGEMENT,                                                      +
  7,DDNAME,,                                                           +
  5,3,1,OUTPUT,                                                        +
  2,00000060,                                                          +
  3,YES,,                                                              +
  4,9,                                                                 +
  ;REP,6,PACKAGE,;QUIT))
/*
//*
//CHECKIT  IF INFOMAN.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//*  THE NEXT STEP COMBINES THE OUTPUT FROM INFOMAN WITH THE OUTPUT
//*  FROM ENDEVOR MATCHING THE LAST GENERATE CCID WITH THE INFOMAN
//*  CCID.
//COMBINE  EXEC PGM=IKJEFT1B,PARM='%COMBINE'
//SYSEXEC  DD DSN=&EVPREF1..REXX,DISP=SHR
//         DD DSN=&EVPREF2..REXX,DISP=SHR
//ELEMENT  DD DSN=&&CSVSORT,DISP=(OLD,DELETE)
//INFOMAN  DD DSN=&&RFTOUT,DISP=(OLD,DELETE)
//INFOOUT  DD DSN=&&INFOOUT,DISP=(,PASS),
//             SPACE=(CYL,(1,5),RLSE),
//             RECFM=FB,LRECL=1901
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//*
//CHECKIT  IF COMBINE.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//* THE NEXT STEP EXTRACTS REQUIRED RECORDS AND
//* ADDS CSV FORMATTING TO THE FINAL FILE
//*
//SORT2    EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SYMNAMES DD DSN=&&ECHALELM(ECHALELM),DISP=(OLD,PASS)
//         DD DDNAME=SYMNDUPS
//         DD DDNAME=SYMNRFT
//SYMNDUPS DD *
* FOLLOWING STATEMENT SHOULD MATCH LRECL OF THE APIEXTR FILE
POSITION,1600
SKIP,1
DUPS-DUPLICATE-INDICATOR,*,1,CH
/*
//SYMNRFT  DD *
RFT-CMR-RECORD-NUMBER,*,08,CH
RFT-DATE-ENTERED,*,08,CH
RFT-DATE-MODIFIED,*,08,CH
RFT-BUSINESS-RECORD,*,08,CH
RFT-SERVICE-AFFECTED,*,15,CH
RFT-CATEGORY,*,01,CH
RFT-IMPL-TIME,*,05,CH
RFT-PLANNED-CHANGE-DURATION,*,08,CH
RFT-CHANGE-DESCRIPTION,*,45,CH
RFT-CHANGE-STATUS,*,08,CH
RFT-LOCAL-STATUS,*,08,CH
RFT-MIS-CODE,*,08,CH
RFT-CHANGE-ORIGINATOR,*,15,CH
RFT-ORIGINATORS-PHONE,*,13,CH
RFT-ASSIGNEE-AREA,*,03,CH
RFT-ENVIRONMENT,*,06,CH
RFT-APPL-OR-INFR-IND,*,01,CH
RFT-COORD-QA-CHECK-STATUS,*,02,CH
RFT-ID-OF-ACTIVITY-RECORD,*,01,CH
RFT-REASON-FOR-CHANGE,*,01,CH
RFT-REASON-CODE,*,02,CH
RFT-MAX-BACKOUT,*,05,CH
RFT-OUTAGE-REQUIRED,*,01,CH
RFT-TOTAL-OUTAGE,*,08,CH
RFT-INTENDED-IMPL-DATE,*,08,CH
RFT-SPONSORS-NAME,*,15,CH
RFT-CHANGE-ANALYST-INITIALS,*,02,CH
RFT-AUTHORISED-BY,*,15,CH
RFT-ALLOW-CHANGE-REVIEW,*,01,CH
RFT-FORWARD-PLANNING,*,01,CH
/*
//SYMNOUT  DD SYSOUT=Z,RECFM=FBA,LRECL=121
//SORTIN   DD DSN=&&INFOOUT,DISP=(OLD,DELETE)
//SORTOUT  DD DSN=&&OUTCSV,DISP=(,PASS),
//             SPACE=(CYL,(1,5),RLSE),
//             RECFM=FB,LRECL=900
//SYSIN    DD *
 SORT FIELDS=COPY
      OUTREC FIELDS=(ALELM-RS-ENV,C',',
                     ALELM-RS-SYSTEM,C',',
                     ALELM-RS-SUBSYS,C',',
                     ALELM-RS-STG-ID,C',',
                     ALELM-RS-ELMNAME,C',',
                     ALELM-RS-TYPE,C',',
                     DUPS-DUPLICATE-INDICATOR,C',',
                     ALELM-RS-PROCGRP,C',',
                     ALELM-RS-UPD-YYYY,C'-',                            S-UPD-DD
                     ALELM-RS-UPD-MM,C'-',ALELM-RS-UPD-DD,C',',
                     ALELM-RS-SIGNOUT,C',',
                     ALELM-RS-LACT-NAME,C',',
                     ALELM-RS-LACT-YYYY,C'-',                           -RS-LACT
                     ALELM-RS-LACT-MM,C'-',ALELM-RS-LACT-DD,C',',       -RS-LACT
                     ALELM-RS-LACT-HH,C':',ALELM-RS-LACT-MI,C',',
                     ALELM-RS-LACT-USER,C',',
                     ALELM-RS-LACT-COMMENT,C',',
                     ALELM-RS-GEN-YYYY,C'-',                            S-UPD-DD
                     ALELM-RS-GEN-MM,C'-',ALELM-RS-GEN-DD,C',',
                     ALELM-RS-GEN-HH,C':',ALELM-RS-GEN-MI,C',',
                     ALELM-RS-GEN-USER,C',',
                     ALELM-RS-GEN-COMMENT,C',',
                     ALELM-RS-SPKG-ID,C',',
                     ALELM-RS-SPKG-YYYY,C'-',                           -RS-LACT
                     ALELM-RS-SPKG-MM,C'-',ALELM-RS-SPKG-DD,C',',       -RS-LACT
                     ALELM-RS-SPKG-HH,C':',ALELM-RS-SPKG-MI,C',',
                     ALELM-RS-LACT-CCID,C',',
                     RFT-DATE-ENTERED,C',',
                     RFT-DATE-MODIFIED,C',',
                     RFT-BUSINESS-RECORD,C',',
                     RFT-SERVICE-AFFECTED,C',',
                     RFT-CATEGORY,C',',
                     RFT-IMPL-TIME,C',',
                     RFT-PLANNED-CHANGE-DURATION,C',',
                     RFT-CHANGE-DESCRIPTION,C',',
                     RFT-CHANGE-STATUS,C',',
                     RFT-MIS-CODE,C',',
                     RFT-CHANGE-ORIGINATOR,C',',
                     RFT-ORIGINATORS-PHONE,C',',
                     RFT-ASSIGNEE-AREA,C',',
                     RFT-ENVIRONMENT,C',',
                     RFT-REASON-CODE,C',',
                     RFT-MAX-BACKOUT,C',',
                     RFT-OUTAGE-REQUIRED,C',',
                     RFT-INTENDED-IMPL-DATE,C',',
                     RFT-SPONSORS-NAME,C',',
                     RFT-CHANGE-ANALYST-INITIALS,C',',
                     RFT-AUTHORISED-BY,C',',
                     RFT-ALLOW-CHANGE-REVIEW,C',',
                     RFT-FORWARD-PLANNING,C',')
//*
//CHECKIT  IF SORT2.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//SQUASH   EXEC PGM=IKJEFT1B,PARM='%CSVSQASH'
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SYSEXEC  DD DSN=&EVPREF1..REXX,DISP=SHR
//         DD DSN=&EVPREF2..REXX,DISP=SHR
//INPUT    DD DSN=&&OUTCSV,DISP=(OLD,DELETE)
//OUTPUT   DD DSN=&&SQUASHED,
//             DISP=(NEW,PASS),
//             SPACE=(CYL,(5,5),RLSE),
//             RECFM=VB,LRECL=27994
//SYSTSIN  DD DUMMY
//*
//CHECKIT  IF SQUASH.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//*
//*RETRIEVE MEMBER HIGHEST IN CONCATENATION ORDER
//PREMERGE EXEC PGM=FILEAID
//DD01     DD DISP=SHR,DSN=&EVPREF1..DATAVB                             */
//         DD DISP=SHR,DSN=&EVPREF2..DATAVB                             */
//DD01O    DD DSN=&&CSVHDR,DISP=(NEW,PASS),
//             SPACE=(TRK,(15,75,44),RLSE),LRECL=27994,
//             RECFM=VB
//SYSPRINT DD SYSOUT=*
//SYSLIST  DD SYSOUT=*
//SYSIN    DD *
$$DD01 COPY MEMBER=CSVHDR
/*
//*
//CHECKIT  IF PREMERGE.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//* THE NEXT STEP ADDS A HEADER TO TO THE FINAL FILE
//*
//MERGE    EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=&&CSVHDR(CSVHDR),DISP=(OLD,PASS)
//         DD DSN=&&SQUASHED,DISP=(OLD,DELETE)
//SYSUT2   DD DSN=&C1PREF..&C1SYSUID..INFOOUT.CSV.FINAL,
//             DISP=(NEW,PASS),
//             SPACE=(CYL,(5,5),RLSE),
//             RECFM=VB,LRECL=27994
//SYSIN    DD DUMMY
//*
//CHECKIT  IF MERGE.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF
//*
//* SEND EMAIL WITH CSV FILE ATTACHMENT TO USER
//*
//EMAIL    EXEC PGM=IKJEFT1A,DYNAMNBR=256,
//             PARM='%SENDMAIL DEFAULT LOG(YES) MIME(YES)'
//SYSPROC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD DUMMY
//SYSADDR  DD *
  FROM: MAPFRE.ENDEVOR@RSMPARTNERS.COM
  TO:   &C1EMAIL
  SUBJECT: EPLEX - &C1PREF.NDVR - ENDEVOR SPREADSHEET REPORT
/*
//SYSDATA  DD DISP=OLD,DSN=&C1PREF..&C1SYSUID..INFOOUT.CSV.FINAL
//*
//CHECKIT  IF EMAIL.RC GT 0 THEN
//SPWARN   EXEC @SPWARN,COND=EVEN
//         ENDIF