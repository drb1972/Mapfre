/* rexx to list TTc1system.change.*                          */
/* build wizard copy statements based on dsnlist             */
trace i
say 'estoy en el rexx wiz0201d'
  parse arg change c1system

  address ispexec
 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller
  vget (zuser)
  l1 = ''
  L2 = ''
  L3 = ''
  L4 = ''
  L5 = ''
  L6 = ''
  L7 = ''
  L8 = ''
  nonwiz = ''
  written = 0

  address tso
  "ALLOC DD(WIZTYPE) DA('PGEV.BASE.DATA(WIZTYPES)') SHR"
  /* Read input file into stem variable         */
  "execio * diskr WIZTYPE (stem wiz. finis"
  "FREE F(WIZTYPE)"

  do a = 1 to wiz.0
    if substr(wiz.a,16,5) = 'which' then do
      type = strip(substr(wiz.a,4,8))
      wizard.type = 'YES'
    end /* if substr(wiz.a,16,5) = 'which' then do */
  end /* do a = 1 to wiz.0 */

  address ispexec
  "vget (zuser zprefix)"

  if zprefix ^= 'TTOS' then do /* For the DBAs */
    wizlib = "TT"right(zprefix,2)"."ZUSER"."change".WIZCNTL"
    mask   = 'TT'right(zprefix,2)'.'change
  end /* zprefix ^= 'TTOS' then */
  else do /* For Batch Services */
    wizlib = "TT"c1system"."ZUSER"."change".WIZCNTL"
    mask   = 'TT'c1system'.'change
  end /* else */

  address tso
  m = msg('OFF')
  "DELETE '"wizlib"'"
  m = msg('ON')
  "ALLOC DA('"wizlib"') NEW",
  "TRACKS SPACE(10,10) DIR(50) LRECL(80) RECFM(F B)"
  zedsmsg = wizlib
  zedlmsg = wizlib 'ALLOCATED'
  address ispexec
  'SETMSG MSG(ISRZ001)'
  address tso
  "FREE DA('"wizlib"')"
  if rc <> 0 then do
       address ispexec
       zedsmsg = ALLOCATION
       zedlmsg = wizlib 'error'
       'SETMSG MSG(ISRZ001)'
  end /* rc <> 0 */
  call listds
 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller

  if nonwiz ^= '' then do
    address ispexec
    zedsmsg = ''
    zedlmsg = "The following datasets were not processed as they are",
              "not wizard types:" nonwiz ,
              "Contact Endevor Support if you want these to be set up."
    'SETMSG MSG(ISRZ001)'
    exit
  end /* nonwiz ^= '' */

  if dsns = 0 then do
     address ispexec
     zedsmsg = 'No Datasets'
     zedlmsg = "No match on" mask
     'SETMSG MSG(ISRZ001)'
     exit
  end /* dsns = 0 */
  call pangreen shiny.disco.balls

  address ispexec
  zedsmsg = written 'types'
  zedlmsg = written 'type members in' wizlib
  'SETMSG MSG(ISRZ001)'
  exit

/*----------- S U B R O U T I N E S ------------*/

/*----------------------------------------------*/
/* LISTDS                                       */
/*----------------------------------------------*/
listds:
 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller

  dsns = 0

  a = OUTTRAP('listds.')

  ADDRESS TSO LISTDS "'"mask"'" LEVEL
  listdscc = rc

  a = OUTTRAP('OFF')

  if listdscc <> 0 then do

     address ispexec
     zedsmsg = listds.2
     zedlmsg = dsn listds.1
     'SETMSG MSG(ISRZ001)'
     return

  end /* listdscc <> 0 */

  dsns = 0
  do i = 1 to listds.0
    dsn = strip(listds.i)

    mems = 0  /* added by emlyn */

     dsnquals = translate(dsn,' ','.')

     if word(dsnquals,4) = '' & change = word(dsnquals,2) then do

       dsns = dsns + 1
       lib.dsns = dsn
       z = LISTDSI("'"dsn"' directory")
       if sysreason > 0 then do
          address ispexec
          zedsmsg = SYSMSGLVL1
          zedlmsg = dsn SYSMSGLVL2
         'SETMSG MSG(ISRZ001)'
         exit
       end /* if sysreason > 0 then do */

       if sysmembers > 0 then do
         call pangreen dsn
         dsnquals = translate(dsn,' ','.')
         address tso
         x = outtrap('listdsmem.')
         "listds '"dsn"' members"
         cc = rc
         x = outtrap('off')

         if cc <> 0 then do
           address ispexec
           zedsmsg = 'ERROR PRESS PF1'
           zedlmsg = dsn
           'SETMSG MSG(ISRZ001)'
           exit
         end /* if cc <> 0 then do */

         type = word(dsnquals,3) /* normal position for wizard llq */

         if wizard.type = 'YES' then do /* is this a wizard llq? */

           if type = 'JOBLIB' then ddn = 'JOBLIBX'
           else ddn = type

           address tso
           "alloc fi("ddn") DA('"wizlib"("type")') shr"

           if rc <> 0 then do
             address ispexec
             zedsmsg = 'allocation error'
             zedlmsg = 'member' type 'failed'
             'SETMSG MSG(ISRZ001)'
               exit
           end /* if rc <> 0 then do */

           mems = 0

           do a = 7 to listdsmem.0 /* get a member list of the library */
             call pangreen dsn listdsmem.a
             ADDRESS ISPEXEC
             pdsmem = strip(substr(listdsmem.a,3,8))

             if pdsmem <> '$$$SPACE' then do
               mems = mems + 1
               copy.mems = 'COPY   'pdsmem
             end /* not $$$SPACE */

           end /* do a = 7 to listdsmem.0 */

         end /* if wizard.= type = YES' then do */
         else
           if left(type,7) ^= 'DOCJOBS' then
             nonwiz = nonwiz mask"."type

       end /* if sysmembers > 0 then do */

       if mems > 0 then do
          address tso
          "EXECIO" mems "DISKW" ddn "(STEM copy. FINIS"
          "FREE FI("ddn")"
          written = written + 1
       end /* if mems > 0 then do */

     end /* dsnqual 4  =  */
  end /* i = 1 to listds.0 */
return

/*----------------------------------------------*/
/* PANGREEN                                     */
/*----------------------------------------------*/
pangreen:
 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller
      parse arg msg line
      L1 = L2
      L2 = L3
      L3 = L4
      L4 = L5
      L5 = L6
      L6 = L7
      L7 = L8
      L8 = line
      'ISPEXEC CONTROL NONDISPL'
      'ISPEXEC DISPLAY PANEL(WIZ2001N)'
      address tso
return
