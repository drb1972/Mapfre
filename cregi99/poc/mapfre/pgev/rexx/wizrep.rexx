/*REXX*/

address "ISPEXEC"

wizdsn = "PREV.P%%1.*.CMPARM"
"LMDINIT LISTID(LISTIDV) LEVEL("wizdsn")"
"LMDLIST LISTID("listidv") OPTION(LIST) DATASET(LDSN) STATS(NO)"

do i = 1 while rc = 0
  stem.i = ldsn
  "LMDLIST LISTID("listidv") OPTION(LIST) DATASET(LDSN) STATS(NO)"
end

"LMDLIST LISTID("listidv") OPTION(FREE)"

count = 0
do a = 1 to i - 1

  dataset = strip(stem.a)
  nodots = translate(stem.a,' ','.')

  /* Exclude in progress datasets */
  if word(nodots,5) = 'INPROG' then
    iterate
  else

    count = count + 1

  sub = substr(word(nodots,2),2,3)
  type = word(nodots,3)

  if count = 1 | count // 75 = 0 then do
    queue '//EVWIZHST JOB CLASS=N,MSGCLASS=Y,REGION=64M '
    queue '//*                                          '
  end

  queue '//PDSMAN'count 'EXEC PGM=PDSM08                         '
  queue '//PDSMSEL  DD *                                         '
  queue 'C0.ALL                                                  '
  queue '//PDSMPDS  DD DSN='dataset',DISP=SHR                    '
  queue '//PDSMRPT  DD DSN=PREV.NENDEVOR.WIZARD.PDSMAN,DISP=OLD  '
  queue '//*                                                     '
  queue '//WIZREP'count 'EXEC PGM=IKJEFT1B,PARM=WIZHIST2         '
  queue '//SYSEXEC  DD DSN=PGEV.BASE.REXX,DISP=SHR               '
  queue '//REPIN    DD DSN=PREV.NENDEVOR.WIZARD.PDSMAN,DISP=SHR  '
  queue '//REPOUT   DD DSN=PREV.REPORTS.WIZARD.'sub'.'type',     '
  queue '//             DISP=OLD                                 '
  queue '//SYSTSPRT DD SYSOUT=*                                  '
  queue '//SYSTSIN  DD DUMMY                                     '
  queue '//*                                                     '
  queue '//SORTER'count 'EXEC PGM=SORT                           '
  queue '//SORTIN   DD DSN=PREV.REPORTS.WIZARD.'sub'.'type',     '
  queue '//             DISP=SHR                                 '
  queue '//SORTOUT  DD DSN=PREV.REPORTS.WIZARD.'sub'.'type',     '
  queue '//             DISP=SHR                                 '
  queue '//SYSOUT   DD SYSOUT=*                                  '
  queue '//SYSIN    DD *                                         '
  queue ' SORT FIELDS=(1,39,CH,D)                                '
  queue '/*                                                      '

end

queue '//***************************************************** '
queue '//*                                                   * '
queue '//* RELEASE ALL THE FREE SPACE USED BY THE WIZARD     * '
queue '//* REPORTS DATASETS.                                 * '
queue '//*                                                   * '
queue '//***************************************************** '
queue '//SPCERLSE EXEC PGM=FDRCPK                              '
queue '//ABRMAP   DD SYSOUT=*,RECFM=FBA                        '
queue '//ABRSUM   DD SYSOUT=*             ** SUMMARY REPORT ** '
queue '//ABNLIGNR DD DUMMY                ** ABENDAID **       '
queue '//SYSPRINT DD SYSOUT=*                                  '
queue '//SYSUDUMP DD SYSOUT=C                                  '
queue '//SYSIN    DD DSN=PGEV.BASE.DATA(WIZREP),DISP=SHR       '
queue '//*                                                     '

/* write the jcl to the internal reader declared on ddname wizrepo */
address tso
"execio "queued()" diskw wizrepo (finis)"

if rc > 0 then do
  say 'WIZREP:'
  say 'WIZREP: Error writing to DD name WIZREPO. RC =' rc
  call exception 12
end /* if rc > 0 then do */

exit

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code
