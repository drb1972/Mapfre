/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This is a generic routine for copying contents from the TSO   | */
/* | data stack to a specified member within a specified library.  | */
/* |                                                               | */
/* | Name    : PGEV.BASE.REXX(EVLMWRIT)                            | */
/* | Author  : John Lewis - rip off from Carlton White             | */
/* |                        original = PGOS.BASE.EXEC(LMWRITE)     | */
/* | Date    : 4th October 2007                                    | */
/* |                                                               | */
/* | Input Parms  : LRECL      =  Record length of output          | */
/* |              : DATALIB    =  Name of output library           | */
/* |                DATAMEMBER =  Membername to be written out to  | */
/* |                              DATALIB.                         | */
/* |                                                               | */
/* |   Cond codes:  0 - successful execution                       | */
/* |               16 - TSO data stack empty or error writing to   | */
/* |                    DATALIB.                                   | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
 TRACE o
 arg parm

 if words(parm) ^= 3 then do
   SAY 'EVLMWRIT:'
   SAY 'EVLMWRIT: One or more Parameters are missing....'
   SAY 'EVLMWRIT: Required parameters are LRECL, DATAMEMBER and DATALIB'
   SAY 'EVLMWRIT:   LRECL       - Record length of records.'
   SAY 'EVLMWRIT:   DATAMEMBER  - Member name.'
   SAY 'EVLMWRIT:   DATALIB     - Library name.'
   ADDRESS TSO DELSTACK
   ADDRESS ISPEXEC
   ZISPFRC = 16
   "VPUT (ZISPFRC) SHARED"
   RETURN
   END


 parse var parm Lrecl DataMember DataLib

 IF QUEUED() = 0
    THEN
        DO
            SAY 'EVLMWRIT:'
            SAY 'EVLMWRIT: No records found in data stack...' ,
                       'terminating exec'
            SAY 'EVLMWRIT: Check QUEUE statements in executing exec'
            ADDRESS ISPEXEC
            ZISPFRC = 16
            "VPUT (ZISPFRC) SHARED"
            RETURN
        END

 ADDRESS ISPEXEC
 "LMINIT DATAID(PARMOUT) DATASET('"DataLib"') ENQ(SHRW)"
 "LMOPEN DATAID(&PARMOUT) OPTION(OUTPUT)"

 DO QUEUED()
    PARSE PULL DataCard
    "LMPUT DATAID(&PARMOUT) MODE(INVAR) DATALOC(DATACARD) DATALEN("Lrecl")"
 END

 "LMMREP DATAID(&PARMOUT) MEMBER("DataMember")"
 IF RC > 8
    THEN
        DO
            SAY 'EVLMWRIT:'
            SAY 'EVLMWRIT: Error while writing records to member' ,
                       DataMember '...terminating exec'
            ZISPFRC = 16
            "VPUT (ZISPFRC) SHARED"
        END

 "LMCLOSE DATAID(&PARMOUT)"
 "LMFREE  DATAID(&PARMOUT)"

 ADDRESS TSO
 DELSTACK

 RETURN
