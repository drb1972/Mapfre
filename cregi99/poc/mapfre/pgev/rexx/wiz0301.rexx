/* rexx                                                      */

  parse arg change c1system type
  address ispexec
  "vget (zuser zprefix)"
  wizlib = "TT"c1system"."ZUSER"."change".WIZCNTL"
  if zprefix ^= 'TTOS' then /* For the DBAs */
    wizlib   = "TT"right(zprefix,2)"."ZUSER"."change".WIZCNTL"
  else /* For Batch Services */
    wizlib   = "TT"c1system"."ZUSER"."change".WIZCNTL"
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

/* Start - check types selected is a wizard type                    */

  cmpdsn = "PREV.E"c1system"1."type".CMPARM"
  check = sysdsn("'"cmpdsn"'")
  if check <> 'OK' then do
    address ispexec
    zedsmsg = type 'not a wizard type'
    zedlmsg = type 'is not a wizard type, use standard endevor'
    'SETMSG MSG(ISRZ001)'
    exit
  end /* check <> 'OK' */

/* End   - check types selected is a wizard type                    */

  wizcntl = wizlib || "(" || type || ")"
  check = sysdsn("'"wizcntl"'")
  if check = 'OK' then do
    address ispexec
    zedsmsg = 'Member already exits'
    zedlmsg = 'Member' type 'already exists'
    'SETMSG MSG(ISRZ001)'
    exit
  end
  queue 'DELETE <MEMNAM>'
  address tso
  "alloc f(wizcntl) dsname('"wizcntl"') shr"
  "execio 1 diskw wizcntl (finis"
  "free f(wizcntl)"
  address ispexec
  "edit dataset('"wizcntl"')"
