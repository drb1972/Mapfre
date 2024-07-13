/* rexx                                                      */

  parse arg change c1system
  address ispexec
  "vget (zuser zprefix)"

  if zprefix ^= 'TTOS' then /* For the DBAs */
    wizlib  = "TT"right(zprefix,2)"."ZUSER"."change".WIZCNTL"
  else /* For Batch Services */
    wizlib = "TT"c1system"."ZUSER"."change".WIZCNTL"

  address tso
  check = sysdsn("'"wizlib"'")

  select
    when check = 'DATASET NOT FOUND' then do
      address tso
      "ALLOC DA('"wizlib"') NEW",
      "TRACKS SPACE(10,10) DIR(50) LRECL(80) RECFM(F B)"
       zedsmsg = wizlib
       zedlmsg = wizlib 'ALLOCATED'
       address ispexec
       'SETMSG MSG(ISRZ001)'
       address tso
       "FREE DA('"wizlib"')"
    end
    when check = 'OK' then do
      nop
    end
    otherwise do
       address ispexec
       zedsmsg = check
       zedlmsg = wizlib check
       'SETMSG MSG(ISRZ001)'
    end /* otherwise */
  end /* select */
  address ispexec
  "edit dataset('"wizlib"')"
