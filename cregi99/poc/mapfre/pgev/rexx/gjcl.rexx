/* REXX */

PARSE ARG DSNAME MEMBER

/*                                                          */
/************************************************************/
/* THIS REXX GETS THE ISPF STATISTICS FOR THE INPUT DATASET */
/* AND THE PREPRPT DATASET AND ENSURE TWO TESTS             */
/* 1) THE MEMBER ID IS IDENTICAL BETWEEN THE TWO            */
/* 2) THE ID STATISTICS IS A NUMERIC VALUE                  */
/* THESE TWO CHECKS ARE TO ENSURE THE JCL/PROC HAS BEEN     */
/* PREPPED VIA THE PRE-PRODUCTION UTILITY                   */
/* THEN WE GET THE RC FROM THE FIRST LINE OF THE PDS AND    */
/* END WITH THE SAME RC AS JCLPREP ISSUED                   */
/************************************************************/
/*                                                          */

ADDRESS ISPEXEC

TRACE N

/* BUILD DATASET NAMES                                      */

DSN1=DSNAME
DSN2=DSNAME||'.PREPRPT'

/* INITIALISE PDS FILES AND GET ISPF STATISTICS             */

"LMINIT  DATAID(DDVAR1) DATASET('"DSN1"') ENQ(SHR)"
IF RC^=0 THEN CALL ENDISPF 13
'LMOPEN  DATAID('DDVAR1') OPTION(INPUT)'
IF RC^=0 THEN CALL ENDISPF 13

"LMINIT  DATAID(DDVAR2) DATASET('"DSN2"') ENQ(SHR)"
IF RC^=0 THEN CALL ENDISPF 13
'LMOPEN  DATAID('DDVAR2') OPTION(INPUT)'
IF RC^=0 THEN CALL ENDISPF 13

"LMMFIND DATAID("DDVAR1") MEMBER("MEMBER") STATS(YES)"
IF RC^=0 THEN CALL ENDISPF 13

/* STORE THE ID FOR THE FIRST PDS                           */

USER1=ZLUSER

"LMMFIND DATAID("DDVAR2") MEMBER("MEMBER") STATS(YES)"
IF RC^=0 THEN CALL ENDISPF 13

/* STORE THE ID FOR THE SECOND PDS                          */

USER2=ZLUSER

/* CHECK THE TYPE OF ID AS UTILITY SETS TO 7 BYTE NUMERIC   */

TESTTYPE=DATATYPE(USER1)

/* IF NOT RUN THROUGH PRE-PRODUCTION THEN EXIT              */

IF USER1^=USER2 | TESTTYPE^='NUM' THEN DO
   QUEUE "*******************************************************"
   QUEUE "*                                                     *"
   QUEUE "* TO ADD JCL OR A PROCEDURE TO ENDEVOR THE ELEMENT    *"
   QUEUE "* MUST HAVE FIRST BEEN PROCESSED THROUGH THE          *"
   QUEUE "* PRE-PRODUCTION JCLPREP UTILITY.                     *"
   QUEUE "*                                                     *"
   QUEUE "* THIS ELEMENT HAS NOT BEEN PRE-PRODUCTIONISED.       *"
   QUEUE "*                                                     *"
   QUEUE "* TO INVOKE THE PRE-PRODUCTION UTILITY THEN TYPE JCLP *"
   QUEUE "* FROM ANY ISPF PANEL.                                *"
   QUEUE "*                                                     *"
   QUEUE "*******************************************************"
   ADDRESS TSO "EXECIO "QUEUED()" DISKW README (FINIS)"
   IF RC^=0 THEN CALL ENDISPF 13
   CALL ENDISPF 20
   END

/* IF ALL OK THEN GET JCLPREP RC FROM FIRST LINE OF PREPRPT */

"LMGET DATAID("DDVAR2") MODE(INVAR) DATALEN(CRAP) DATALOC(CHKPREP)",
"MAXLEN(80)"

IF RC^=0 THEN CALL ENDISPF 13

/* STRIP OUT PREP RC AND EXIT WITH RC                       */

CHKPREP=STRIP(CHKPREP)
PARSE VALUE CHKPREP WITH . '=' PREPRC REST
EXIT PREPRC

ENDISPF:

PARSE ARG THE_RC
ZISPFRC = THE_RC
ADDRESS ISPEXEC 'VPUT (ZISPFRC) SHARED'
EXIT 0
