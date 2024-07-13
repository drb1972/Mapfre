/* rexx - To replace the symbolics coded in a BINDCNTL       */
/*        with overrides obtained from the PROCINC BINDPARM  */
/*                                                           */
/*                                       John Scott          */
/*                                       05.08.98            */
/*  Return Code 0 is OK                                      */
/*                                                           */
/*              20 is an error opening the CONTROL file.     */
/*              21 is an error opening the BINDIN file.      */
/*                                                           */
/*              30 is an input file error                    */
/*              40 is an output file error                   */
/*                                                           */
/*              13 missing FROM statement in CONTROL file.   */
/*              14 missing TO   statement in CONTROL file.   */
/*              15 missing "." at end of statement.          */
/*                                                           */
/*  CONTROL CARD syntax:                                     */
/*                                                           */
/*  The COPY command:                                        */
/*                                                           */
/*              CHANGE FROM symbolin TO symbolout            */
/*                                                           */
/*  All other commands are treated as comments               */
/*                                                           */
/*  BINDIN syntax is BINDCNTL with symbolics  e.g.           */
/*                                                           */
/*   BIND PLAN      (NEDBIND)                             -  */
/*        OWNER     (ED01#OWNR)                           -  */
/*        ACTION    (REPLACE) RETAIN                      -  */
/*        VALIDATE  (BIND)                                -  */
/*        ISOLATION (CS)                                  -  */
/*        ACQUIRE   (USE)                                 -  */
/*        RELEASE   (COMMIT)                              -  */
/*        EXPLAIN   (#EXPL)                               -  */
/*        MEMBER    (NEDBIND)                                */
/*                                                           */
/*  e.g. JCL                                                 */
/* --------------------------------------------------------- */
/*      //STEP01   EXEC PGM=IRXJCL,                          */
/*      // PARM='BNDSYMBS &C1ELEMENT'                        */
/*      //SYSEXEC  DD DISP=SHR,DSN=pds.with.this.rexx.in     */
/*      //SYSTSPRT DD SYSOUT=*                               */
/*      //BINDIN   DD DSN=&&ELMOUT(elmnt name) ,(OLD,DELETE) */
/*      //BINDOUT  DD DSN=&DSNBIND(element name),DISP=SHR,   */
/*      //            FOOTPRINT=CREATE,MONITOR=&MONITOR      */
/*      //CONTROL  DD *                                      */
/*           THIS IS A COMMENT                               */
/*           CHANGE FROM #STG  TO &ZSTGID .                  */
/*           CHANGE FROM #SUFF TO &ZSUFF  .                  */
/*                                                           */
/* --------------------------------------------------------- */
/*                                                           */
  trace  n
/*                                                           */
/*  Read the //CONTROL file                                  */
/*                                                           */
  parse arg element
  address mvs
  "execio * diskr control  (stem card. finis"
  if rc > 0 then exit(20) ;

/*                                                           */
/*  Write the header                                         */
/*                                                           */
  say "-- B N D S Y M B S ---"   date() time()
  say ""

/*                                                           */
/*  Read the BINDIN dataset                                  */
/*                                                           */
  "execio * diskr" bindin "(stem data. finis"
  if rc > 0 then exit(30) ;
/*                                                           */
/*  For each line of the BINDIN dataset, loop through the    */
/*  control statements.                                      */
/*                                                           */
  do i = 1 to card.0
/*                                                           */
/*  Validate each control statement and if the BINDIN        */
/*  dataset line contains the control card 'in' string       */
/*  replace it with the control card 'out' string            */
/*                                                           */
    parse var card.i command from in to out dot rest
    say card.i
    if command = CHANGE then do
      if from     ^= FROM then exit(13)
      if to       ^= TO   then exit(14)
      do j = 1 to data.0
        data.j  = SUBSTR(data.j,1,72)
        ix     = POS(in, data.j)
        do while ix ^= 0
          begline = SUBSTR(data.j,1,ix-1)
          endline = SUBSTR(data.j,ix+LENGTH(in))
  /*                                                           */
  /*  The following Select has had to be inserted to cater     */
  /*  for the way resolutions get handled at Prod stage        */
  /*  eg. 'out' will get set to null for #SUFF and #SUF1       */
  /*       and to " " for #STG                                 */
  /*                                                           */
          select
            when out = "."   then data.j = begline||endline
            when out = '""'  then data.j = begline||endline
            when out = '"'   then data.j = begline||" "||endline
            otherwise             data.j = begline||out||endline
          end
         data.j  = SUBSTR(data.j,1,72)
         ix     = POS(in, data.j)
        end
      end
    end
  end
      say data.0 'Records read from' bindin
  /*                                                           */
  /*  If more than 0 records write all the lines               */
  /*  (including changes) to BINDOUT                           */
  /*                                                           */
      if data.0 > 0 then do
        "execio * diskw" bindout "(stem data. finis"
        cond = rc
        if cond > 0 then do
          say '!!!!!!!!!!!!!!!!!!!'
          say 'error writing file:' bindout
          say 'execio rc:' cond
          say '!!!!!!!!!!!!!!!!!!:'
        exit(40) ;
        end
        say data.0 'Records written to' bindout
        data. = ""
      end
      say ""
  say '--- End of cards ---'
/*                                                           */
  exit(0)
