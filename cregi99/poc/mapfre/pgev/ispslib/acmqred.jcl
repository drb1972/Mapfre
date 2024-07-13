//&JOBNAME JOB 0,CLASS=3,MSGCLASS=0,NOTIFY=&SYSUID
//*
//* THIS JOB RUNS ACMQ AND BUILDS DELETE SCL FOR REDUNDANT
//* COMPONENTS LIKE COPYBOOKS OR MACROS
//*
//*-------------------------------------------------------------------
//*  LIST THE ELEMENTS
//*-------------------------------------------------------------------
//NDVR010  EXEC PGM=NDVRC1,PARM='CONCALL,DDN:CONLIB,BC1PCSV0'
//CSVMSGS1 DD SYSOUT=Z
//C1MSGSA  DD SYSOUT=*
//BSTERR   DD SYSOUT=Z
//APIPRINT DD SYSOUT=Z
//APIEXTR  DD DSN=&&ELEMENTS,DISP=(NEW,PASS),
//            SPACE=(TRK,(900,100),RLSE),
//            RECFM=FB,LRECL=1600
//CSVIPT01 DD *
 LIST ELEMENT *
   FROM ENVIRONMENT &ARENVR SYSTEM &ARSYS SUBSYSTEM &ARSUBSYS
     TYPE &ARTYPE STAGE &ARSTG
   OPTIONS NOCSV .
/*
//*
//CHECK010 IF NDVR010.RC = 0 THEN
//*
//*-------------------------------------------------------------------
//*  BUILD ACMQ COMMANDS
//*-------------------------------------------------------------------
//NDVR020  EXEC PGM=SORT
//SYSOUT   DD SYSOUT=Z
//SORTIN   DD DISP=(OLD,DELETE),DSN=&&ELEMENTS
//SORTOUT  DD DSN=&&ACMQSCL,DISP=(NEW,PASS),
//            SPACE=(TRK,(150,45),RLSE),
//            RECFM=FB,LRECL=80
//SYSIN    DD *
 OPTION COPY
  OUTFIL OUTREC=(1:C' LIST USING COMPONENTS FOR ELEMENT',36:39,8,
                46:C'SYSTEM &ARSYS TYPE &ARTYPE .          ',/,
                1:C' LIST USING COMPONENTS FOR MEMBER ',36:39,8,
                46:C' .                                 ')
/*
//*
//CHECK020 IF NDVR020.RC NE 0 THEN
//@SPWARN  EXEC @SPWARN,COND=EVEN
//CHECK020 ENDIF
//*
//*-------------------------------------------------------------------
//*  RUN ACMQ
//*-------------------------------------------------------------------
//NDVR030  EXEC PGM=NDVRC1,PARM='BC1PACMQ'
//ACMMSGS1 DD DSN=&&ACMQMSGS,DISP=(NEW,PASS),
//            SPACE=(TRK,(15,90),RLSE),
//            RECFM=FBA,LRECL=133
//ACMMSGS2 DD SYSOUT=*
//ACMOUT   DD SYSOUT=*
//APIPRINT DD DUMMY
//ACMSCLIN DD DISP=(OLD,DELETE),DSN=&&ACMQSCL
//*
//CHECK030 IF NDVR030.RC GT 4 THEN
//@SPWARN  EXEC @SPWARN,COND=EVEN
//CHECK030 ENDIF
//*
//*-------------------------------------------------------------------
//*  SELECT THE OUTPUT
//*-------------------------------------------------------------------
//NDVR040  EXEC PGM=SORT
//SYSOUT   DD SYSOUT=Z
//SORTIN   DD DISP=(OLD,DELETE),DSN=&&ACMQMSGS
//SORTOUT  DD DSN=&&ACMQRES,DISP=(NEW,PASS),
//            SPACE=(TRK,(150,45),RLSE),
//            RECFM=FB,LRECL=80
//SYSIN    DD *
 OPTION COPY
  INCLUDE COND=(22,8,CH,EQ,C'ACMQ204I',OR,
                22,8,CH,EQ,C'ACMQ207I',OR,
                22,8,CH,EQ,C'ACMQ212W')
/*
//*
//CHECK040 IF NDVR040.RC NE 0 THEN
//@SPWARN  EXEC @SPWARN,COND=EVEN
//CHECK040 ENDIF
//*
//*-------------------------------------------------------------------
//*  REPORT AND BUILD SCL
//*-------------------------------------------------------------------
//NDVR050  EXEC PGM=IKJEFT1B,
//         PARM='%ACMQRED &ARENVR &ARSTG &ARSUBSYS &ARTYPE'
)SEL &ARSYS  = EK
//SYSEXEC  DD DSN=PREV.OEV1.REXX,DISP=SHR
//         DD DSN=PREV.PEV1.REXX,DISP=SHR
//         DD DSN=PGEV.BASE.REXX,DISP=SHR
)ENDSEL
)SEL &ARSYS ^= EK
//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR
)ENDSEL
//SYSTSPRT DD SYSOUT=*
//ACMQ     DD DSN=&&ACMQRES,DISP=(OLD,DELETE)
//SYSTSIN  DD DUMMY
//SCL      DD SYSOUT=*
//*
//CHECK050 IF NDVR050.RC NE 0 THEN
//@SPWARN  EXEC @SPWARN,COND=EVEN
//CHECK050 ENDIF
//*
//IF0010   ENDIF
