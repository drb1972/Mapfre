/* REXX                                                       */
/* This rexx is used when a user moves a wizard member from   */
/* stage e to stage f. It checks to see if another version    */
/* of the wizard member is already at f and if so compares    */
/* it to the existing one at e. If there are members that     */
/* are no longer being promoted , then the rexx builds        */
/* delete statements to remove the orphaned members from the  */
/* output library at stage f, which are then executed in the  */
/* subsequent step.                                           */

ADDRESS TSO
PARSE ARG SYS TYPE ELEMENT

RCODE = 0

DSN1 = 'PREV.E'SYS'1.'TYPE'.CMPARM'
DSN2 = 'PREV.F'SYS'1.'TYPE'.CMPARM'

SAY 'DSN1 = ' DSN1
SAY 'DSN2 = ' DSN2

PDSMEM = "'" || DSN2 || "(" || ELEMENT || ")'"
CHECK = SYSDSN(PDSMEM)
IF CHECK <> OK THEN DO
EXIT 0
END

  "ALLOC F(STAGEF) DSNAME('"DSN2"("ELEMENT")') SHR"
  IF RC > 0 THEN EXIT 0

  'EXECIO * DISKR STAGEF (STEM CMPARMF. FINIS'
  IF RC > 0 THEN EXIT 0
  "FREE F(STAGEF)"


  "ALLOC F(STAGEE) DSNAME('"DSN1"("ELEMENT")') SHR"
  'EXECIO * DISKR STAGEE (STEM CMPARME. FINIS'
  "FREE F(STAGEE)"


  SAY 'CMPARM7: READING STAGE E CMPARM MEMBER'
  DO A = 1 TO CMPARME.0
       IF SUBSTR(CMPARME.A,1,4) = COPY THEN DO
       ELEE = STRIP(SUBSTR(CMPARME.A,8,8))
       FOUND.ELEE = 'YES'
       say 'CMPARM7:'
       say 'CMPARM7: Found copy statement 'ELEE
       END
  END

  RC = 1   /* ASSUME THERES NO CHANGES BETWEEN STAGE E AND F */
  SAY 'RC = 'RC


  SAY 'READING STAGE F CMPARM MEMBER'
  DO B = 1 TO CMPARMF.0
       IF SUBSTR(CMPARMF.B,1,4) = COPY THEN DO
         ELEF = STRIP(SUBSTR(CMPARMF.B,8,8))
         say 'CMPARM7:'
         say 'CMPARM7: Found copy statement 'ELEF
         IF FOUND.ELEF <> 'YES' THEN DO
           SAY 'FOUND.ELEF= ' FOUND.ELEF
           RCODE = 2 /* I FOUND SOME DIFFERENCES SO WILL HAVE TO DELETE
                    SOME MEMBERS FROM THE OUTPUT LIBRARY AT STAGE F */
           QUEUE " DELETE    MEMBER="ELEF""
           SAY 'CMPARM7: WILL DELETE MEMBER 'ELEF
         END
       END
  END

       PUSH " EDITDIR OUTDD=DELMEM"
       "EXECIO "QUEUED()" DISKW DELMEM (FINIS)"
       SAY 'CMPARM7:'
       SAY 'CMPARM7: ABOUT TO END WITH RC = 'RCODE

EXIT RCODE
