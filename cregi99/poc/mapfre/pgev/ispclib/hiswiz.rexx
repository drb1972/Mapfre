/*-----------------------------REXX----------------------------------*\
 * Called by WIZHIST to build and display wizard history             *
\*-------------------------------------------------------------------*/
trace n

do while zcmd <> 'Q'
  address ispexec 'DISPLAY PANEL(wizhist2)'
  if rc > 0 then exit

  select
    when zcmd = 'S' then do
      results   = 'NO'
      member    = strip(mem)
      dsn       = 'PREV.REPORTS.WIZARD.'sys'1.'type
      supcdsn   = 'PREV.WIZARD'sys'.'type'.SUPERC'

      x = listdsi("'"dsn"'")
      if x > 4 & sysreason ^= 25 then do /* Error and not migrated   */
        zedsmsg = type 'is not a wizard type'
        zedlmsg = dsn 'Not found'
        address ispexec 'SETMSG MSG(ISRZ001) msgloc(type)'
        iterate
      end /* x > 4 & sysreason ^= 25 */

      address tso "alloc da('"dsn"') f(DATAIN) shr"
      if rc > 4 then do
        ZEDSMSG = sysmsglvl1
        ZEDLMSG = sysmsglvl2
        address ispexec 'SETMSG MSG(ISRZ001)'
        iterate
      end /* rc > 4 */

      address ispexec
      "TBCREATE CHANGES NOWRITE KEYS(TBKEY)
                NAMES(NAME TYPE SY ACT DATE CCID)"

      address tso
      do until readrc = 2           /* loop through change file      */
        "execio 1 diskr DATAIN"     /* read 1 line                   */
        readrc = rc                 /* return code from execio       */
        if readrc = 2 then leave
        pull scanin                 /* store scanin line             */
        if pos(member,scanin) > 0 then do
          parse var scanin name type sy date act ccno 51 .
          ccid    = strip(ccno)
          tbkey   = ccid || name
          results = 'YES'
          address ispexec "TBADD CHANGES"
        end /* pos(member,scanin) > 0 */

        if pos(member,scanin) = 0 & results = 'YES' then leave

      end /* do until readrc = 2 */

      /* Close and free the wizard history file                      */
      "execio 0 diskr DATAIN (finis"
      "free f(DATAIN)"

      if readrc > 2 then exit readrc /* I/O error                    */

      if results = 'NO' then do
        zedsmsg = 'SORRY, NOTHING FOUND'
        zedlmsg = 'No match found in the history'
        address ispexec 'SETMSG MSG(ISRZ001)'
      end /* results = 'NO' */

      else do

        address ispexec
        "TBTOP CHANGES"
        "TBSORT CHANGES FIELDS(date,C,d,name,C,A)"
        ccdispr = 0
        do while ccdispr < 8
          "TBDISPL CHANGES PANEL(WIZHIST)"
          ccdispr = rc
          if word(zcmd,1) = 'SORT' then do
            parse var zcmd cmd parm dir .
            if dir = '' then dir = 'A'
            select
              when parm = 'CCID' then
                "TBSORT CHANGES FIELDS(CCID,C,"dir",NAME C,A)"
              when parm = 'DATE' then
                "TBSORT CHANGES FIELDS(DATE,C,"dir")"
              when parm = 'NAME' then
                "TBSORT CHANGES FIELDS(NAME,C,"dir")"
              otherwise nop
            end /* select */
          end /* word(zcmd,1) = 'SORT' */
          else
            if ztdsels = 1 then do
              if act = 'DELETE' then do
                zedsmsg = 'No SUPERC for deletes'
                zedlmsg = 'There is no SUPERC output for a DELETE'
                address ispexec 'SETMSG MSG(ISRZ001) msgloc(type)'
              end /* act = 'DELETE' */
              else
                "BROWSE DATASET('"supcdsn"("ccid")')"
            end /* ztdsels = 1 */
        end /* do while ccdispr < 8 */
        "TBEND CHANGES"
      end /* else (results = 'YES') */
    end /* zcmd = 'S' */

    when zcmd = 'Z' then
      address ispexec "BROWSE DATASET('PREV.PEV1.DATA(WIZTYPES)')"
    when zcmd = 'H' then
      address ispexec "BROWSE DATASET('PREV.PEV1.DATA(WIZHELP)')"
    otherwise nop

  end /* select */

end /* do while zcmd <> 'Q' */

exit
