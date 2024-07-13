/* REXX */

DO WHILE option <> 'Q'
  DISPLAY:
  ADDRESS ISPEXEC
  'DISPLAY PANEL(wizhist2)'
  ADDRESS TSO
  if rc > 0 then exit
  err = ''
  IF OPTION = 'S' THEN DO
    MISSING = 'NO'
    MEMBER = STRIP(MEM)
    TYPESMALL = STRIP(TYPE)
    OUTPUT = 0
    RESULTS = 'NO'
    DSN = 'PREV.REPORTS.WIZARD.'SYS'1.'TYPE''

    X = LISTDSI("'"DSN"'")
    IF SYSREASON  > 0 THEN MISSING = 'YES'
    "ALLOC DA('"DSN"') F(DATAIN) shr"
    if rc > 4 then do
      err = 'Please try again soon - EVHWZHSD running'
      missing = yes
    end

    IF MISSING = 'NO' THEN DO
      FOUND = 'NO'
      ADDRESS ISPEXEC
      "CONTROL ERRORS RETURN" /*  STOP ISPF ERRORS ENDING THE EXEC */

      "TBCREATE CHANGES NOWRITE KEYS(TBKEY)",
              "NAMES(NAME TYPE SYS ACT DATE CCID)"
      TB_ROWS = 0

  /*  err = 'Please wait - searching for changes'     */
      do until readrc = 2           /* loop through change file   */
        ADDRESS TSO
        "execio 1 diskr datain  "   /* read 1 line                */
        readrc = rc                 /* return code from execio    */
        if readrc = 2             then leave
        pull scanin                 /* store scanin  line         */
        IF POS(MEMBER,scanin) > 0 THEN DO
          PARSE VAR scanin NAME TYPE SYS DATE ACT CCNO 51 .
          CCID   = strip(CCNO)
          TBKEY  = CCID || NAME
          RESULTS = 'YES'
          found = yes
          ADDRESS ISPEXEC
          TB_ROWS = TB_ROWS + 1
          "TBADD CHANGES"
        END   /* end look for member */

        IF POS(MEMBER,scanin) = 0 & found = yes then leave

      end /* read through change file    */

      ADDRESS TSO
      "execio 0 diskr datain (finis "
      "FREE F("DATAIN")"
      if readrc > 2 then exit readrc        /* I/O error      */
      IF RESULTS = 'NO' THEN ERR = 'SORRY, NOTHING FOUND'
      IF MISSING = 'YES' THEN ERR = 'ERROR - INVALID WIZARD TYPE!'
      IF RESULTS = 'YES' THEN DO
        IF OUTPUT = 1 THEN ERR = OUTPUT||' CHANGE FOUND'
        IF OUTPUT > 1 THEN ERR = OUTPUT||' CHANGES FOUND'

        ADDRESS ISPEXEC
        "TBTOP CHANGES"
        "TBSORT CHANGES FIELDS(date,C,d,name,C,A)"
        SEL     = 0
        CCDISPR = 0
        IF TB_ROWS = 0  THEN SEL = 9
        DO WHILE (CCDISPR < 8 & SEL = 0)
          "TBDISPL CHANGES PANEL(wizhist)"
          ccdispr  = rc
          IF ZCMD = ' '  THEN DO
             IF ZTDSELS = 1 THEN DO
                call HISTORY CCID
             ZTDSELS = 0
             END
          end
          ELSE DO
        /*   Something entered on COMMAND LINE            */
             PARSE VAR ZCMD CMD PARM dir .
             if dir = ''   then dir = 'A'
             IF CMD = 'SORT'      THEN DO
                IF PARM = 'CCID'     THEN DO
                   "TBSORT CHANGES FIELDS(CCID,C,"dir",NAME C,A)"
                end
                ELSE IF PARM = 'DATE'   THEN DO
                   "TBSORT CHANGES FIELDS(DATE,C,"dir")"
                end
                ELSE IF PARM = 'NAME'   THEN DO
                   "TBSORT CHANGES FIELDS(NAME,C,"dir")"
                end
             end
          end
        end
      END
      ADDRESS ISPEXEC "TBEND CHANGES"
    end
  end /* end of 's' chosen */
  IF OPTION = 'Z' THEN CALL WIZTYPES
  IF OPTION = 'H' THEN CALL WIZHELP
end

EXIT 0


HISTORY: ARG CCID
WHERE = 'PREV.WIZARD'OS'.'TYPE'.SUPERC('CCID')'

TEST=MSG(off)
 "FREE F(histin)";
"ALLOC DA('"WHERE"') F(histin) SHR"
 "FREE F(histin)";

 address ispexec
 "BROWSE DATASET('"where"'"
 err = ' '
RETURN

WIZTYPES:
 address ispexec
WIZTYP = 'PREV.PEV1.DATA(WIZTYPES)'

 "BROWSE DATASET('"WIZTYP"'"
err  = ''

return

WIZHELP:
 address ispexec
WIZHLP = 'PREV.PEV1.DATA(WIZHELP)'

 "BROWSE DATASET('"WIZHLP"'"

err  = ''
return
