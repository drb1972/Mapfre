/* Rexx - Submit job and Save job/number in message and history

   This routine is an updates/replacement for the Endevor v18.0 version
   of the CISUB clist.  It now saves and resrores the TSO PROFILE
   INTERCOM setting and uses ISPF messages to show jobname/number
   */
   stempf = arg(1)                      /* JCL DSN must be first parm */
   PkgSub = arg(2)                      /* PkGSub=Y if package submit */
   Package= arg(3)                      /* Package Name (Or null)     */
   ADDRESS ISPEXEC "VGET (SUBHIST ENABWAI EEVCCID EEVCOMM)" ,
                   "ASIS"               /* Prior History/CurrLoc      */
   if SUBHIST = '' then
      SUBHIST  = "***"                         /* initialise history  */

   CALL MSG "ON"
   x = Outtrap("out.",10,"NOCONCAT")    /* Trap output                */
   address tso "PROFILE"                /* Get current profile values */
   intercom = 'INTERCOM'                /* Default setting if not fnd */
   If out.0 \= 0 Then Do
      Parse Upper Var out.1 . . .  p4 p5 p6 . /* Save profile settings*/
      Address  TSO "PROFILE NOINTERCOM" /* Please do not disturb      */
   End
   ADDRESS TSO "SUBMIT '"stempf"'" ;
   x = Outtrap("OFF")                   /* Stop traping output        */
   Address  TSO "PROFILE" p4 p5 p6      /* Restore profile settings   */
   DO k = 1 TO out.0
   /*                                                                 */
   /* Added support for up to 7-digit job names (only seen 6)         */
   /*                                                                 */
      sa= out.k
      PARSE VAR out.k WITH . "JOB " jobnam "(J" JOBNUM ")" .
      if left(jobnum,2) == 'OB' then    /* If we have .(JOBnnnnn)     */
        jobnum = right(substr(jobnum,3),7,'0')
      else
        if left(jobnum,1) == 'O' then   /* or we have .(JOnnnnnn)     */
          jobnum = right(substr(jobnum,2),7,'0')
      if jobnum == '' then jobnum = '*' /* default to last fnd        */
   END
   ZEDSMSG = jobnam || '(' || jobnum || ') SUB''D'
   if PkgSub = "Y" then /* format the history message for package or ele */
      SUBHIST = left(Date(N),06,'00'x)copies('00'x,1)left(Time(N),09,'00'x),
        ||LEFT(LEFT(ZEDSMSG,POS(')',ZEDSMSG)),18,'00'x),
        ||LEFT('PACKAGE',09,'00'x),
        ||LEFT('ACTIONS',09,'00'x),
        ||LEFT(PACKAGE,24,'00'x)||'00'x, /* with trailing null for Wrap */
        || SUBHIST
   else
      SUBHIST = left(Date(N),06,'00'x)copies('00'x,1)left(Time(N),09,'00'x),
        ||LEFT(LEFT(ZEDSMSG,POS(')',ZEDSMSG)),18,'00'x),
        ||LEFT(STRIP(ENABWAI)||'00'x,
        ||STRIP(EEVCCID)||'00'x,
        ||STRIP(EEVCOMM),
        ,42,'00'x)||'00'x, /* always include white space for the word wrap */
        || SUBHIST
   ZEDLMSG = LEFT('SUBMITTED JOBS HISTORY (THIS SESSION)',77,'00'X)||SUBHIST
   ADDRESS ISPEXEC "VPUT (SUBHIST) SHARED"  /* Update history value  */
   ADDRESS ISPEXEC "SETMSG MSG(ENDE218W)"
   If POS('/',EEVETDMS) > 0 then      /* Did we have a status?     */
      EEVETDMS = left(EEVETDMS,POS('/',EEVETDMS)) || "Sub'd"

  Exit 0
