/* rexx - To copy contents of one dataset to another         */
/*        If the dataset is empty it is not copied.          */
/*                                                           */
/*                                       John PD Scott       */
/*                                       25.10.96            */
/*  Return Code 0 is OK                                      */
/*                                                           */
/*              20 is an error opening the CONTROL file.     */
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
/*              COPY FROM ddin TO ddout .                    */
/*                                                           */
/*  All other commands are treated as comments               */
/*                                                           */
/*  e.g. JCL                                                 */
/* --------------------------------------------------------- */
/*      //STEP01   EXEC PGM=IRXJCL,                          */
/*      // PARM='DSCOPY'                                     */
/*      //SYSEXEC  DD DISP=SHR,DSN=pds.with.this.rexx.in     */
/*      //SYSTSPRT DD SYSOUT=*                               */
/*      //DD01     DD DSN=&&TEMPIN,(OLD,PASS)                */
/*      //DD02     DD DSN=MY.INPUT.DS2,DISP=SHR              */
/*      //DD07     DD DSN=MY.OUTPUT,DISP=SHR                 */
/*      //DD08     DD SYSOUT=*                               */
/*      //CONTROL  DD *                                      */
/*           THIS IS A COMMENT                               */
/*           COPY FROM DD01 TO DD07 .                        */
/*           COPY FROM DD02 TO DD08 .                        */
/*                                                           */
/* --------------------------------------------------------- */

trace n

/*  Read the //CONTROL file                                  */
/*                                                           */
"execio * diskr CONTROL (stem card. finis"
if rc > 0 then exit(20)

/*  Write the header                                         */
/*                                                           */
say 'DSCOPY: --- D A T A S E T   C O P Y ---' date() time()
say 'DSCOPY:'

/*  Loop through  the control statements                     */
/*                                                           */
do i = 1 to card.0

  /*  Validate the control statements                        */
  /*                                                         */
  parse var card.i command from in to out dot rest
  say 'DSCOPY:' command from in to out dot
  say 'DSCOPY:'

  if command = 'COPY' then do

    if from ^= 'FROM' then do
      say 'DSCOPY: The second parm must be FROM'
      exit(13)
    end

    if to ^= 'TO' then do
      say 'DSCOPY: The third parm must be TO'
      exit(14)
    end

    if dot ^= '.' then do
      say 'DSCOPY: There must be a space before the full stop'
      exit(15)
    end

    /* Read an input dataset. Read it in chunks to avoid region */
    /* errors in big listings.                                  */
    line_count = 0
    do until readrc = 2

      "execio 500 diskr" in "(stem data."
      readrc = rc
      if rc > 2 then                  /* I/O error      */
        call exception 20 'Execio diskr from' in 'failed RC =' rc

      if rc = 2 then do               /* EOF            */
        "execio 0 diskr" in "(finis"  /* close the file */
        if rc > 2 then                  /* I/O error      */
          call exception 20 'Execio diskr from' in 'failed RC =' rc
      end

      line_count = line_count + data.0
      if data.0 > 0 then do
        "execio * diskw" out "(stem data."
        if rc > 0 then
          call exception 40 'Execio diskw to' out 'failed RC =' rc
        drop data.
      end /* data.0 > 0 */

    end /* do until readrc = 2 */

    "execio 0 diskw" out "(finis"       /* close the file */
    if rc > 0 then
      call exception 40 'Execio diskw to' out 'failed RC =' rc

    say 'DSCOPY:' line_count 'Records read from' in
    say 'DSCOPY:'
    say 'DSCOPY:' line_count 'Records written to' out
    say 'DSCOPY:'
    say 'DSCOPY:'

  end /* command = 'COPY' */

end /* do i = 1 to card.0 */

say 'DSCOPY: --- End of cards ---'

exit

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 parse arg return_code comment

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
