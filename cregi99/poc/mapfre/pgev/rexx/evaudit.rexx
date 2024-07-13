/*-----------------------------REXX----------------------------------*\
 *  EVAUDIT reads Endevor job JCL and creates EVGFT* jobs which      *
 *  run via the internal reader                                      *
 *  EVAUDIT runs as part of standard Rnnnnnnn job processing         *
 *                                                                   *
 *  Assumptions:                                                     *
 *   We can predict the target library from the DDNAME:              *
 *   e.g. //OAR                                                      *
 *        //DEL                                                      *
 *        //OCR                                                      *
 *  The previous DD name is the associated staging DSN               *
\*-------------------------------------------------------------------*/
trace n
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

parse arg dest

say rexxname':' DATE() TIME()
say rexxname': Destination' dest

j2   = substr(dest,5,1) /* Plex identifier = e.g P or Q or N         */
user = sysvar(sysuid)
if user = 'PMFBCH' then hlq = 'PGEV.SHIP'
                   else hlq = 'TTEV.SHIP'

call main 'JCL'

call main 'JCLB'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Loop through the JCL looking for target dd statements             */
/*                                                                   */
/* Save the 'from' and 'to' line numbers of //tgt DD statements      */
/*-------------------------------------------------------------------*/
main:
 parse arg ddname

 jobname  = 'FIRST'
 jobs     = 0
 staged   = 0
 tgtcount = 0                 /* targets found                       */
 current  = 0                 /* position in job                     */
 jcllines = 0                 /* Total jcllines read                 */

 do until readrc = 2          /* start looping                       */
   "execio 1 diskr" ddname    /* read 1 line                         */
   if rc > 2 then call exception rc 'DISKR of' ddname 'failed'
   readrc   = rc              /* return code from execio             */
   jcllines = jcllines + 1    /* Total jcllines read                 */
   current  = current + 1     /* position in this job                */
   pull card.current          /* store jcl line                      */

   /* Look for sysin JCL using the DLM=## card                       */
   if word(card.current,1)             = '//SYSUT1'  & ,
      word(card.current,2)             = 'DD'        & ,
      substr(word(card.current,3),1,9) = 'DATA,DLM=' then
     validjcl = 'no'

   /* If there is in stream data then find out what the char is      */
   if substr(word(card.current,3),1,9) = 'DATA,DLM=' then
     delim = right(word(card.current,3),2)

   /* Look for the end of DLM= cards                                 */
   if word(card.current,1)     = delim & ,
      substr(card.current,3,2) = '  '  then
     validjcl = 'yes'

   /* Look for jobname                                               */
   if word(card.current,2) = 'JOB' then
     if '//' = substr(card.current,1,2) then
       if substr(card.current,3,1) = '*'  | ,
          substr(card.current,1,3) = ' '  | ,
          validjcl                 = 'no' then
         iterate
       else do
         prevjob = jobname
         jobname = substr(card.current,3,8)
         jt      = substr(jobname,1,1)
         say rexxname': Found JCL JOB' jobname
         jobs    = jobs + 1
         current = 1
         if prevjob <> 'FIRST' then
           call xref
       end /* else */

   /* Look for tgt DD statements                                     */
   target = substr(card.current,1,5)             /* if ddname        */
   if target = '//OAR' | ,                       /* //OAR            */
      target = '//DEL' | ,                       /* //DEL            */
      target = '//OCR' then do                   /* //OCR            */
     ddlabel      = substr(card.current,1,10)    /*                  */
     tgtcount     = tgtcount + 1                 /* Count it.        */
     tgtstart.tgtcount = current                 /* Save line no.    */
     dsn.tgtcount = ''                           /* Reset dsn        */
     sdd.tgtcount = ddlabel                      /* Save tgtnn       */

     /* Put all the lines of this JCL statement into DDLINES         */
     ddlines = card.current                    /* load first line    */
     dd      = current + 1                     /* start @ next line  */

     do while substr(card.dd,1,3) = '// '      /* Add on the next    */
       ddlines = ddlines || card.dd            /* line of JCL        */
       dd = dd + 1
     end /* while substr(card.dd,1,3) = '// ' */

     tgtend.tgtcount = dd               /* Next valid line after tgt */

     /* Find the low level qualifier on the DSN= clause              */
     parse value ddlines with word1 'DSN=' dsn.tgtcount rest
     parse value dsn.tgtcount with dsn.tgtcount ',' rest
     temp = dsn.tgtcount

     if target <> '//DEL' then do

       previous = current - 1       /* Point at line before current  */
       ddlines  = ''                /* Reset the area to save lines  */

       do x = previous to 1 by -1               /* Loop backwards    */
         parse var card.x word1 word2 word3     /* until             */
         if word2 = 'EXEC' then                 /* start of step     */
           leave
         ddlines = ddlines || card.x            /* concatenate lines */
       end /* x = previous to 1 by -1 */

       parse value ddlines with word1 'DSN=' staging rest

       parse value staging with staging ',' rest

       if staging ^= '' then do
         say rexxname': Staging DSN    :' staging
         tgtdsn        = dsn.tgtcount
         staged        = staged + 1
         tgtdsn.staged = tgtdsn

         /* Overlay the staging dataset with Qplex values            */
         dsnquals  = translate(staging,' ','.')
         dsnlevels = words(dsnquals)
         if dsnlevels = 6 then
           stgdsn.staged = overlay('H',staging,35)    /* ^WIZ        */
         else
           stgdsn.staged = overlay('PREV',staging,1)  /* WIZ         */

         say rexxname': HOST    DSN    :' stgdsn.staged
         fpdsn.staged = stgdsn.staged'.FP'
         say rexxname': Footprint dsn  :' fpdsn.staged
       end /* staging ^= '' */
     end /* target <> '//DEL' */

     say rexxname': Destination DSN:' dsn.tgtcount

   end /* target = '//OAR' | ... */

 end  /* until readrc = 2 */

 prevjob = jobname

 call xref

return /* main: */

/*-------------------------------------------------------------------*/
/* Xref - Write XREF file and build EVFOOT job                       */
/*-------------------------------------------------------------------*/
xref:

 "ALLOC DA('"hlq"."prevjob"."dest".XREF') MOD fi(xref)"
 queue ' job =' prevjob
 do s = 1 to staged
   queue ' stage.'tgtdsn.s '=' stgdsn.s
   queue ' fpdsn.'tgtdsn.s '=' fpdsn.s
 end /* s = 1 to staged */
 queue ''

 "execio * diskw XREF (finis"
 if rc ^= 0 then call exception rc 'DISKW to XREF failed'

 "FREE FI(XREF)"

 /* XREF used for change database                                    */
 say rexxname':'
 say rexxname': Allocated:' hlq'.'prevjob'.'dest'.XREF'
 if staged > 0 then do
   evfoot_job = 'EVGFT'j2||jt'I'
   queue "//"evfoot_job "JOB 0,CLASS=N,MSGCLASS=Y"
   queue "//*"
   queue "//* FOOTPRINTS FOR JOB" prevjob
   do s = 1 to staged
     s2 = left(s,2)
     queue "//*"
     queue "//*** PROCESSING" stgdsn.s "***"
     queue "//EFOOT"s2 " EXEC PGM=NDVRC1,PARM=BC1PFOOT,DYNAMNBR=1500"
     queue "//STEPLIB  DD DSN=SYSNDVR.NOINFO.AUTHLIB,DISP=SHR"
     queue "//BSTLST   DD SYSOUT=*"
     queue "//APIPRINT DD SYSOUT=*"
     queue "//SYSUDUMP DD SYSOUT=C"
     queue "//DELFP    DD DSN="fpdsn.S","
     queue "//             SPACE=(TRK,(0,0)),  /* DELETE .FP DATASET */"
     queue "//             DISP=(MOD,DELETE)   /* IN CASE OF RE-RUN  */"
     queue "//BSTPCH   DD DSN=&&PCH"s",DISP=(NEW,PASS),"
     queue "//             SPACE=(TRK,(15,75),RLSE),"
     queue "//             LRECL=838,RECFM=FB"
     queue "//BSTPDS   DD DISP=SHR,DSN="stgdsn.s
     queue "//BSTIPT   DD *"
     queue "   ANALYZE ."
     queue "   EXCLUDE MEMBER $$$SPACE ."
     queue "   INCLUDE CSECT *LOADMOD ."
     queue "/*"
     queue "//CHKE"s2 "  IF EFOOT"s".RC GT 8 THEN"
     queue "//WARNE"s2 " EXEC @SPWARN"
     queue "//CHKE"s2 "  ENDIF"
     queue "//*"
     queue "//FOOT"s2 "  EXEC PGM=IKJEFT1B,"
     queue "//             PARM='EVFOOT" stgdsn.s"'"
     queue "//SYSPROC  DD DSN=PGEV.BASE.REXX,DISP=SHR"
     queue "//BSTPCH   DD DSN=&&PCH"s",DISP=(OLD,DELETE)"
     queue "//FOOTREP  DD DSN="fpdsn.s","
     queue "//             DISP=(NEW,CATLG),"
     queue "//             SPACE=(250,(5,5),RLSE),AVGREC=K,"
     queue "//             LRECL=250,RECFM=FB"
     queue "//SYSTSPRT DD SYSOUT=*"
     queue "//SYSTSIN  DD DUMMY"
     queue "//*"
     queue "//CHKF"s2 "  IF FOOT"s".RC NE 0 THEN"
     queue "//WARNF"s2 " EXEC @SPWARN"
     queue "//CHKF"s2 "  ENDIF"
   end /* s = 1 to staged */
   queue "//*"
   queue "//*                               END OF JOB"
   queue "//"
   queue ""

   "execio * diskw SUBMIT (finis"
   if rc ^= 0 then call exception rc 'DISKW to SUBMIT failed'
              else say rexxname': JOB' evfoot_job 'submitted'
 end /* stage > 1 */

 staged = 0
 say rexxname':' jcllines 'lines of jcl processed from' ddname

return /* xref: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso "FREE F(XREF)"       /* Free files that may be open   */
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
