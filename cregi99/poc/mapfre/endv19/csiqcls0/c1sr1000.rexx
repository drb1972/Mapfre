PROC 0 DEBUG()

 GLOBAL PNLCSR PNLMSG ENDISCLW
/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.               */
/*                                                                   */
/* NAME: C1SR1000                                                    */
/*                                                                   */
/* PURPOSE: THIS CLIST IS USED TO DRIVE THE USER REPORTING DIALOG    */
/*                                                                   */
/*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*/
/* SET UP DEBUGGING AND RUN PARAMETERS                               */
/*-------------------------------------------------------------------*/
 IF &DEBUG = &STR(DEBUG) THEN +
    CONTROL MSG NOFLUSH LIST CONLIST SYMLIST NOPROMPT ASIS
 ELSE +
    CONTROL NOMSG NOFLUSH NOLIST NOCONLIST NOSYMLIST NOPROMPT ASIS

  SET &RC = 0
  SET &ENDISCLW = N                    /* INDICATE NO SCL WRITTEN    */
  SET &JCLFILE = FREE
  SET &CTLFILE = FREE
  SET &PNLMSG = &STR()
  SET &PNLCUR = ZCMD

  FREE ATTR(JCLATTR)
  ATTRIB JCLATTR LRECL(80) RECFM(F B) BLKSIZE(15440) DSORG(PS)

  ISPEXEC VGET (C1BJC1,C1BJC2,C1BJC3,C1BJC4,C1WU)

/*-------------------------------------------------------------------*/
/* DETERMINE THE APPROPRIATE HIGH LEVEL QUALIFIER FOR THE WORK DATA- */
/* SETS.  IF THE TSO PREFIX IS THE SAME AS THE TSO USER ID, THE THE  */
/* HLQ IS THE TSO PREFIX.  IF THE TSO PREFIX IS DIFFERENT THAN THE   */
/* TSO USER ID, THE HLQ IS THE CONCATENATION OF THE TSO PREFIX AND   */
/* THE TSO USER ID.  IF THERE IS NO PREFIX ASSOCIATED WITH THE USER, */
/* THE HLQ IS SET TO THE USERID.                                     */
/*-------------------------------------------------------------------*/
  ISPEXEC VGET (ZSCREEN,ZPREFIX,ZUSER)
  SET &DSNPFX = &STR(&ZUSER)
  IF (&ZPREFIX ^= &STR()) THEN +
    DO
      IF (&ZPREFIX ^= &ZUSER) THEN +
        SET &DSNPFX = &STR(&ZPREFIX..&ZUSER)
    END

/*-------------------------------------------------------------------*/
/* DISPLAY THE INITIAL PANEL TO GET ALL THE NECESSARY INFORMATION FOR*/
/* THE REPORT JOB.                                                   */
/*-------------------------------------------------------------------*/
DISP: +
  ERROR OFF
  ISPEXEC DISPLAY PANEL(C1SR1000) +
                  CURSOR(&PNLCUR) +
                  MSG(&PNLMSG)
  SET &RC = &LASTCC

  IF (&RC ^= 0) THEN +
     GOTO FINI

  SET &PNLMSG = &STR()
  SET &PNLCUR = ZCMD

  IF (&ZCMD = &STR()) THEN -
    DO
      SET &PNLCUR = ZCMD
      SET &PNLMSG = CISR008
      GOTO DISP
    END

  IF (((&ZCMD ^= E) AND (&ZCMD ^= S) AND (&ZCMD ^= X)) AND  +
      ((&ZCMD <1) OR (&ZCMD > 7))) THEN +
    DO
      SET &PNLCUR = ZCMD
      SET &PNLMSG = CISR009
      GOTO DISP
    END

/* SET UP A TEMPORARY FILE FOR BUILDING THE JCL */
  IF &JCLFILE = FREE THEN -
    DO
      SET &JCLDSN = &STR(&DSNPFX..NDVR&ZSCREEN..CNTL)
      ALLOC FILE(NDVRJCL&ZSCREEN) -
            DA('&JCLDSN') -
            TRACK SPACE(5 15) -
            MOD -
            UNIT(&C1WU) -
            USING(JCLATTR) -
            REUSE
      SET &JCLFILE = ALLOC
    END

  IF &CTLFILE = FREE THEN -
    DO
      SET &CTLDSN = &STR(&DSNPFX..SPFT&ZSCREEN..CNTL)
      ALLOC FILE(CTJCL&ZSCREEN) -
            DA('&CTLDSN') -
            TRACK SPACE(5 15) -
            MOD -
            UNIT(&C1WU) -
            USING(JCLATTR) -
            REUSE
      SET &CTLFILE = ALLOC
    END

  ISPEXEC VPUT (C1BJC1,C1BJC2,C1BJC3,C1BJC4)

/*-------------------------------------------------------------------*/
/* DISPATCH THE APPROPRIATE PROCESSING ROUTINE BASED ON THE OPTION   */
/* THAT THE USER SELECTED.                                           */
/*-------------------------------------------------------------------*/
  IF (&ZCMD = 1) THEN +
     C1SR1100 DEBUG(&DEBUG)
  IF (&ZCMD = 2) THEN +
     C1SR1200 DEBUG(&DEBUG)
  IF (&ZCMD = 3) THEN +
     C1SR1300 DEBUG(&DEBUG)
  IF (&ZCMD = 4) THEN +
     C1SR1400 DEBUG(&DEBUG)
  IF (&ZCMD = 5) THEN +
     C1SR1500 DEBUG(&DEBUG)
  IF (&ZCMD = 6) THEN +
     C1SR1600 DEBUG(&DEBUG)
  IF (&ZCMD = 7) THEN +
     C1SR1700 DEBUG(&DEBUG)
  IF (&ZCMD = E) THEN +
     GOTO ISPFEDIT
  IF (&ZCMD = S) THEN +
     GOTO SUBJOB
  IF (&ZCMD = X) THEN +
     GOTO FINI

  SET &ZCMD = &STR()
  GOTO DISP

/*********************************************************************/
/* EDIT THE JCL AND CONTROL STATEMENTS                               */
/*********************************************************************/
ISPFEDIT: +
   ISPEXEC EDIT DATASET('&JCLDSN')
   SET &ZCMD =
   SET &RC = 0
   GOTO DISP

/*-------------------------------------------------------------------*/
/* SUBMIT THE REQUEST                                                */
/*-------------------------------------------------------------------*/
SUBJOB: +
  ISPEXEC VPUT (C1BJC1,C1BJC2,C1BJC3,C1BJC4) PROFILE

  IF (&ENDISCLW = &STR(N)) THEN +
    DO
      SET &PNLMSG = CISR014
      SET &PNLCUR = ZCMD
      GOTO DISP
    END

  ISPEXEC FTOPEN TEMP
  ISPEXEC FTINCL C1SR8000
  ISPEXEC FTCLOSE
  ISPEXEC VGET (ZTEMPF)

  ALLOC FILE(ZTJCL) DA('&ZTEMPF') SHR
  OPENFILE ZTJCL INPUT
  SET &EOF = OFF

  ALLOC FILE(CTJCL&ZSCREEN) DA('&CTLDSN') MOD
  OPENFILE CTJCL&ZSCREEN OUTPUT

/*-------------------------------------------------------------------*/
/* SET UP ERROR ROUTINE FOR THE REPORTING INTERFACE                  */
/*-------------------------------------------------------------------*/
  ERROR -
    DO
      SET &RC = &LASTCC
      IF (&RC = 400) THEN -
        SET &EOF = ON
      ELSE IF (&RC > 12) THEN +
        DO
          WRITE AN I/O ERROR OCCURRED IN C1SR1000.  RC=&RC..
          GOTO FINI
        END
      RETURN
    END

READJCL1: -
  GETFILE ZTJCL
  IF (&EOF = ON) THEN -
    GOTO EOFJCL1
  SET &CTJCL&ZSCREEN = &ZTJCL
  PUTFILE CTJCL&ZSCREEN
  GOTO READJCL1

EOFJCL1: -
  CLOSFILE ZTJCL
  FREE FILE(ZTJCL)

  OPENFILE NDVRJCL&ZSCREEN INPUT
  SET &EOF = OFF

READJCL2: -
  GETFILE NDVRJCL&ZSCREEN
  IF (&EOF = ON) THEN -
    GOTO EOFJCL2
  IF (&ZSCREEN = 1) THEN -
    SET &CTJCL&ZSCREEN = &NDVRJCL1
  ELSE IF (&ZSCREEN = 2) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL2
  ELSE IF (&ZSCREEN = 3) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL3
  ELSE IF (&ZSCREEN = 4) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL4
  ELSE IF (&ZSCREEN = 5) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL5
  ELSE IF (&ZSCREEN = 6) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL6
  ELSE IF (&ZSCREEN = 7) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL7
  ELSE IF (&ZSCREEN = 8) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL8
  ELSE IF (&ZSCREEN = 9) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCL9
  ELSE IF (&ZSCREEN = A) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLA
  ELSE IF (&ZSCREEN = B) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLB
  ELSE IF (&ZSCREEN = C) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLC
  ELSE IF (&ZSCREEN = D) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLD
  ELSE IF (&ZSCREEN = E) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLE
  ELSE IF (&ZSCREEN = F) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLF
  ELSE IF (&ZSCREEN = G) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLG
  ELSE IF (&ZSCREEN = H) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLH
  ELSE IF (&ZSCREEN = I) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLI
  ELSE IF (&ZSCREEN = J) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLJ
  ELSE IF (&ZSCREEN = K) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLK
  ELSE IF (&ZSCREEN = L) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLL
  ELSE IF (&ZSCREEN = M) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLM
  ELSE IF (&ZSCREEN = N) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLN
  ELSE IF (&ZSCREEN = O) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLO
  ELSE IF (&ZSCREEN = P) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLP
  ELSE IF (&ZSCREEN = Q) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLQ
  ELSE IF (&ZSCREEN = R) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLR
  ELSE IF (&ZSCREEN = S) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLS
  ELSE IF (&ZSCREEN = T) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLT
  ELSE IF (&ZSCREEN = U) THEN -
         SET &CTJCL&ZSCREEN = &NDVRJCLU
  ELSE -
     SET &CTJCL&ZSCREEN = &NDVRJCLV
  PUTFILE CTJCL&ZSCREEN
  GOTO READJCL2

EOFJCL2: -
  ERROR OFF
  CLOSFILE CTJCL&ZSCREEN OUTPUT
  FREE FILE(CTJCL&ZSCREEN)

  CLOSFILE NDVRJCL&ZSCREEN INPUT

  CONTROL MSG
  SUBMIT '&CTLDSN'
  CONTROL NOMSG

  FREE FILE(CTJCL&ZSCREEN)
  FREE FILE(FTJCL)

  IF (&JCLFILE = ALLOC) THEN -
    DO
      FREE FILE(NDVRJCL&ZSCREEN)
      DELETE '&JCLDSN' SCRATCH NONVSAM
      SET &JCLFILE = FREE
    END

  IF (&CTLFILE = ALLOC) THEN -
    DO
      FREE FILE(CTJCL&ZSCREEN)
      DELETE '&CTLDSN' SCRATCH NONVSAM
      SET &CTLFILE = FREE
    END

  SET &ENDISCLW = &STR(N)

/*-------------------------------------------------------------------*/
/* INCREMENT THE LAST CHARACTER IN THE JOB NAME.  THE ROUTINE ASSUMES*/
/* THAT THE JOBNAME IS IN THE FIRST JOB CARD STATEMENT.  THE ROUTINE */
/* ALSO ASSUMES THAT THE LAST CHARACTER OF THE JOB NAME PRECEEDS THE */
/* FIRST BLANK IN THE JOB CARD, IN OTHER WORDS, THE JOB CARD LOOKS   */
/* SOMETHING LIKE '//JOBNAMEX JOB (ACCOUNT),NAME,... '               */
/*-------------------------------------------------------------------*/
  ISPEXEC VGET (C1BJC1) PROFILE
  SET C1LN = &LENGTH(&STR(&C1BJC1))
  SET C1SPACE = &SYSINDEX(&STR( ),&STR(&C1BJC1)

  /*-----------------------------------------------------------------*/
  /* &C1SPACE CONTAINS THE INDEX OF THE FIRST SPACE.  IF THE VALUE IS*/
  /* IN THE RANGE 4-11 THEN THE JCL STATEMENT IS ASSUMED TO CONTAIN  */
  /* A VALID JOBCARD.  THE FIRST THREE CHARACTERS OF THE JCL STATE-  */
  /* MENT ARE ASSUMED TO BE // AND THE FIRST CHARACTER OF THE JOB    */
  /* NAME.                                                           */
  /*-----------------------------------------------------------------*/
  IF ((&C1SPACE > 3) AND +
      (&C1SPACE < 12)) THEN +
    DO
      SET C1LASTCH = &SUBSTR(&C1SPACE - 1,&STR(&C1BJC1))
      SET C1UID    = &SUBSTR(3:&C1SPACE - 2,&STR(&C1BJC1))
      IF  (&C1UID = &ZUSER) THEN +
        DO
        SET C1CURCH = &SYSINDEX(&C1LASTCH,  +
                  &STR(ABCDEFGHIJKLMNOPQRSTUVWXYZA01234567890))
        IF (&C1CURCH > 0) THEN +
          DO
            SET C1NEXTCH = &SUBSTR(&C1CURCH + 1,  +
                       &STR(ABCDEFGHIJKLMNOPQRSTUVWXYZA01234567890))
            SET C1JCV1 = &STR(&SUBSTR(1:&C1SPACE - 2,&C1BJC1))
            SET C1JCV2 = &STR(&SUBSTR(&C1SPACE + 1:&C1LN + 1, &C1BJC1))
            SET C1BJC1 = &STR(&C1JCV1&C1NEXTCH&C1JCV2)
            ISPEXEC VPUT (C1BJC1) PROFILE
          END
        END
    END

   SET &ZCMD = &STR()
   SET &PNLMSG = CISR001  /* JOB SUBMITTED  */
   SET &PNLCUR = ZCMD
   SET &RC = 0
   ISPEXEC CONTROL DISPLAY REFRESH
   GOTO DISP

/*------------------------------------------------------------------*/
/* THE DIALOG IS COMPLETE.  DELETE THE TEMPORARY FILES AND EXIT.    */
/*------------------------------------------------------------------*/
FINI: +
  IF (&JCLFILE = ALLOC) THEN -
    DO
      FREE FILE(NDVRJCL&ZSCREEN)
      DELETE '&JCLDSN' SCRATCH NONVSAM
      SET &JCLFILE = FREE
    END

  IF (&CTLFILE = ALLOC) THEN -
    DO
      FREE FILE(CTJCL&ZSCREEN)
      DELETE '&CTLDSN' SCRATCH NONVSAM
      SET &CTLFILE = FREE
    END

  FREE ATTR(JCLATTR)

  EXIT
