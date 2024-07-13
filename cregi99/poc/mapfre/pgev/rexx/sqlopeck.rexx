/*-----------------------------REXX---------------------------------**\
 *  Check output from the OPE execute for SQL                        *
 *  Check for:                                                       *
 *  - RI errors                                                      *
 *  - DB2 not operational                                            *
 *                                                                   *
 *  This rexx is executed from GSQL.                                 *
\*-------------------------------------------------------------------*/
trace n

errors     = 0       /* Flag for errors found                        */

parse arg c1element stack_size
say
say 'SQLOPECK:' Date() Time()
say 'SQLOPECK:  *** Input parameters ***'
say 'SQLOPECK:'
say 'SQLOPECK:  c1element..' c1element
say 'SQLOPECK:  stack_size.' stack_size

say ' '
say 'SQLOPECK: Reading the OPE SYSTSPRT'

/* If OPEPRINT is empty then set exit_rc to 1 so that OPETSPRT       */
/* is made visible by the processor.                                 */
"execio 1 diskr OPEPRINT (stem trash. finis)"
if rc > 2 then call exception rc 'DISKR of OPEPRINT failed.'
if rc = 2 then exit_rc = 1
          else exit_rc = 0

"execio * diskr OPETSPRT (stem line. finis)"
if rc ^= 0 then call exception rc 'DISKR of OPETSPRT failed.'

/* Look for NOT OPERATIONAL messages                                 */
do i = 1 to line.0
  notoper_pos = wordpos('NOT OPERATIONAL,',line.i)
  if notoper_pos > 0 then do
    lpar  = mvsvar(sysname)
    dbsub = word(line.i,notoper_pos-1)
    call write 'SQLOPECK: This job ran on lpar' lpar 'but DB2' ,
               'subsystem' dbsub
    call write 'SQLOPECK: was not running on' lpar'.'
    call write ' '
    call write 'SQLOPECK: Please code SCHENV='dbsub 'on your job card'
    call write 'SQLOPECK: remove any SYSAFF cards that you have,'
    call write 'SQLOPECK: then GENERATE or UPDATE element' c1element'.'
    exit exit_rc
  end /* wordpos('NOT OPERATIONAL',line.i) */
end /* i = 1 to line.0 */

drop line.

say ' '
say 'SQLOPECK: Reading the OPE SYSPRINT'

do forever
  call read_line

  select
    when pos('SQLCODE = -530',line) > 0 | ,
         pos('SQLCODE = -531',line) > 0 | ,
         pos('SQLCODE = -532',line) > 0 | ,
         pos('SQLCODE = -533',line) > 0 | ,
         pos('SQLCODE = -534',line) > 0 | ,
         pos('SQLCODE = -537',line) > 0 | ,
         pos('SQLCODE = -538',line) > 0 then do
      call write 'SQLOPECK: You have encountered a Referential Integrity',
                 'error in the OPE.'
      call write 'SQLOPECK: Endevor can not evaluate these errors.'
      call write 'SQLOPECK: You must check the production tables.'
      call write 'SQLOPECK: Refer to DDNAME OPEPRINT for the full' ,
                 'output listing.'
      call write 'SQLOPECK: Output line:' left(line,100)
      call write ' '
      call write '    Contact '                                         ,
                 'VERTIZOS@kyndryl.com'
      call write ' '
    end /* pos('SQLCODE = -530',line) > 0 | ....... */

    when pos('SQLCODE = -803',line) > 0 then do
      call write 'SQLOPECK: You have encountered a -803' ,
                 'error in the OPE.'
      call write 'SQLOPECK: This means that a row that you inserting' ,
                 'already exists in the table.'
      call write 'SQLOPECK: Try adding or generating the backout SQL' ,
                 'to delete the rows then'
      call write 'SQLOPECK: try again.'
      call write 'SQLOPECK: Refer to DDNAME OPEPRINT for the full' ,
                 'output listing.'
      call write 'SQLOPECK: Output line:' left(line,100)
      call write ' '
      call write '  If you can not resolve this error yourself then' ,
      call write ' contact'
                 'VERTIZOS@kyndryl.com '
      call write ' '
    end /* pos('SQLCODE = -803',line) > 0 */
    otherwise nop
  end /* select */

  if eof = 'Y' then
    leave
end /* do forever */

/* Just a normal SQL error                                           */
if errors = 0 then do
  call write 'SQLOPECK: Your SQL has failed to execute in the OPE',
             'environment.'
  call write 'SQLOPECK: Refer to DDNAME OPEPRINT or OPETSPRT for the' ,
             'full output listing.'
  call write 'SQLOPECK: Please correct the errors and UPDATE' ,
             'the element.'
  call write ' '
  call write '  If you can not resolve this error yourself then' ,
  call write '      contact'
             'VERTIZOS@kyndryl.com '
  call write ' '
end /* errors = 0 */

"execio 0 diskw README (finis"         /* Close README               */
if rc ^= 0 then call exception rc 'DISKW to README failed'

say ' '
say 'SQLOPECK:' Date() Time()

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Read_line & strip comments                                        */
/*-------------------------------------------------------------------*/
read_line:

 if queued() = 0 then do
   /* N.B. Stack size is used to make the code more efficient        */
   "execio" stack_size "diskr OPEPRINT"
   readrc = rc
   if readrc   = 2 & ,        /* EOF */
      queued() = 0 then do
     "execio 0 diskr OPEPRINT (finis"   /* close the file            */
     eof = 'Y'
     return
   end /* readrc   = 2 & queued() = 0 */
   if readrc > 2 then call exception readrc 'DISKR of OPEPRINT failed'
 end /* queued() = 0 */

 pull line

 if line = '' then /* If the line is blank                           */
   call read_line

return /* read_line */

/*-------------------------------------------------------------------*/
/* Write 1 line to the ouput                                         */
/*-------------------------------------------------------------------*/
write:
 parse arg outline

 if errors = 0 then do
   x = listdsi(SQL file)
   outline.1 = ''
   outline.2 = 'SQLOPECK: SQL element' c1element
   outline.3 = ''
   "execio" 3 "diskw README (stem outline."
   if rc > 1 then call exception rc 'DISKW to README failed'
   drop outline.
   errors = 1
 end /* errors = 0 */

 outline.1 = outline
 "execio 1 diskw README (stem outline."
 if rc > 1 then call exception rc 'DISKW to README failed'

return /* write */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* clear down the stem variables */
 drop outline.
 drop line.
 drop stmt.

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

 if return_code = 20 then do /* EXECIO DISKR error */
   outline.1 = 'SQLOPECK: You have encountered a read error',
               'for element' c1element
   outline.2 = 'SQLOPECK: This may be due "Storage not available"' ,
               'if the output is large.'
   outline.3 = 'SQLOPECK: Try increasing the region size on you job',
               'card by temporarily'
   outline.4 = 'SQLOPECK: coding ",REGION=128M"'
   "execio 4 diskw README (finis stem outline."
   if rc ^= 0 then say 'SQLOPECK: DISKW to README failed RC =' rc
 end /* return_code = 20 */

exit return_code
