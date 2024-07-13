/* REXX */

ADDRESS MVS

do until readrc = 2
   "execio 1 diskr repin "    /* read 1 line                         */
   readrc = rc                /* return code from execio             */
   parse pull pdsmrep          /* store repin line                    */
   if readrc > 2 then exit readrc        /* I/O error                */
   IF SUBSTR(pdsmrep,2,6) = 'Member' THEN DO
    CCID = SUBSTR(pdsmrep,10,8)
    DATI = SUBSTR(pdsmrep,34,10)
    DAT = SUBSTR(DATI,7,4)||'/'||SUBSTR(DATI,1,2)||'/'||SUBSTR(DATI,4,2)
    TME = SUBSTR(pdsmrep,46,5)
   END
   IF SUBSTR(pdsmrep,2,12) = '** PDSM08 **' THEN DO
      SYS = SUBSTR(pdsmrep,62,2)
      DSN = SUBSTR(pdsmrep,56,20)
      DSN = TRANSLATE(DSN,' ','.')
      SHORTTYP = WORD(DSN,3)
      TYPE = OVERLAY(SHORTTYP,'        ')
   END
   IF SUBSTR(pdsmrep,2,4) = 'COPY' THEN DO
      MEM = SUBSTR(pdsmrep,9,8)
      ACTION = SUBSTR(pdsmrep,2,6)
      QUEUE '   'MEM' 'TYPE' 'SYS' 'DAT' 'ACTION' 'CCID
      "execio 1 diskw repout"
      if rc > 0 then do
          say 'ERROR WRITING REPOUT' rc
          exit rc
      end
   END
   IF SUBSTR(pdsmrep,2,6) = 'DELETE' THEN DO
      MEM = SUBSTR(pdsmrep,9,8)
      ACTION = SUBSTR(pdsmrep,2,6)
      QUEUE '   'MEM' 'TYPE' 'SYS' 'DAT' 'ACTION' 'CCID
      "execio 1 diskw repout"
      if rc > 0 then do
          say 'ERROR WRITING REPOUT' rc
          exit rc
      end
   END

END
"EXECIO 0 DISKR repout (FINIS"
EXIT
