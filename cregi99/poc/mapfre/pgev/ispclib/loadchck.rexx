/*--------------------------REXX-----------------------------*\
 *  This REXX is used by processors GLOAD & MLOAD to ensure  *
 *  that a load module in the PREV library belongs to the    *
 *  element being processed.                                 *
 *  It will also check any aliases being copied.             *
 *-----------------------------------------------------------*
 *  Author:     Stuart Ashby                                 *
 *              Endevor Support                              *
\*-----------------------------------------------------------*/
trace n
arg c1element c1type c1action lib c1prgrp

alias = 'NONE'

say 'LOADCHCK:  *** Input parameters ***'
say 'LOADCHCK:'
say 'LOADCHCK:  c1element..' c1element
say 'LOADCHCK:  c1type.....' c1type
say 'LOADCHCK:  c1action...' c1action
say 'LOADCHCK:  lib........' lib
say 'LOADCHCK:  c1prgrp....' c1prgrp
say 'LOADCHCK:'

/* Read in the output from report 80 on the load library */
"execio * diskr BSTRPTS (stem line. finis)"
if rc > 0 then do
  say 'LOADCHCK: EXECIO of BSTRPTS ddname gave a return code of' rc
  call exception 12
end /* if rc > 0 */

/* Write out the report output for debugging */
"execio" line.0 "diskw FOOTRPT (stem line. finis)"
if rc ^= 0 then do
  say 'LOADCHCK: Execio diskw to FOOTRPT failed RC =' rc
  call exception 12
end /* if rc ^= 0 then do */

do a = 1 to line.0
  /* Get the dataset name */
  if word(line.a,1) = 'LIBRARY:' then do
    dsn = word(line.a,2)
    leave
  end
end

say 'LOADCHCK: Checking members in dataset' dsn
say 'LOADCHCK:'

/* Do the check for the element */
say 'LOADCHCK: Checking member' c1element
call check_mem c1element

/* Do the check for the aliases */
if c1prgrp = 'LOADMODA' | ,
   c1prgrp = 'COMMONA'  then do
  say 'LOADCHCK:'
  say 'LOADCHCK: Checking for aliases....'

  /* Get the list of ALIASes form the dummy alias copy report */
  "execio * diskr ALIASREP (stem alias. finis"
  if rc > 0 then do
    say 'LOADCHCK: EXECIO of ALIASIN ddname gave a return code of' rc
    call exception 12
  end /* if rc > 0 */
  /* Write out the report output for debugging */
  "execio" alias.0 "diskw TESTCOPY (stem alias. finis)"
  if rc ^= 0 then do
    say 'LOADCHCK: Execio diskw to TESTCOPY failed RC =' rc
    call exception 12
  end /* if rc ^= 0 then do */

  do i = 1 to alias.0
    if pos('*ALIAS*',alias.i) > 0 then do
      alias = strip(substr(alias.i,10,8))
      say 'LOADCHCK: Checking alias' alias
      call check_mem alias
    end
  end /* i = 1 to alias.0 */

  if alias = 'NONE' then do
    queue 'LOADCHCK: No aliases found.'
    queue 'LOADCHCK: But you have used processor group' c1prgrp
    queue 'LOADCHCK: which means that aliases should exist for' ,
          'element' c1element'.'
    queue 'LOADCHCK: If you do not intend to add aliases with' c1element
    queue 'LOADCHCK: then use processor group' ,
          strip(c1prgrp,t,'A') 'instead of' c1prgrp'.'
    "execio" queued() "diskw README (finis"
    say 'LOADCHCK: No aliases found (see DD README)'
    exit 12
  end

end /* if c1prgrp = 'LOADMODA' */

exit

/*---------------------- S U B R O U T I N E S -----------------------*/

/*---------------------------------------------------------------*/
/* Check_mem     - Check the members for the added load module   */
/*---------------------------------------------------------------*/
check_mem:
arg load_mem

do a = 1 to line.0

  Call format_record

  if (mod.a = '*LOADMOD' & ,
      mem.a = load_mem) & ,
     (ele.a ^= c1element | ,
      typ.a ^= c1type) then
    if c1action = 'MOVE' then
      call move
    else
      call readme

end /* a = 1 to line.0 */

say 'LOADCHCK:' load_mem 'OK'

return

/*---------------------------------------------------------------*/
/* Format_record - Get the footprint information                 */
/*---------------------------------------------------------------*/
Format_record:
 /* this subroutine populates array variables */
 parse var line.a 2  mem.a ,
                  13 mod.a ,
                  23 env.a ,
                  33 sys.a ,
                  43 sub.a ,
                  53 ele.a ,
                  65 typ.a ,
                  73 .
 /* remove trailing blanks */
 typ.a= strip(typ.a)
 ele.a= strip(ele.a)
 sys.a= strip(sys.a)

return /* end of format_record: subroutine */

/*---------------------------------------------------------------*/
/* Readme - Write out a readme for adds/generates etc.           */
/*---------------------------------------------------------------*/
Readme:
 /* this subroutine writes out errors when the load modules exists */
 queue
 queue "  The load module '"load_mem"' already exists" ,
       "in the dataset"
 queue " " dsn "and was created by element"
 queue " " c1element "type" typ.a "system" sys.a "subsystem" sub.a
 queue
 queue " YOU CANNOT OVERWRITE THAT MEMBER WITH ELEMENT" c1element ,
       "type" c1type
 queue
 queue "  Any questions call +44 (0)123 963 8560"
 queue
 "execio" queued() "diskw README (finis"
 say 'LOADCHCK:' load_mem 'NOT OK (see DD README)'
 exit 20

return /* end of README: subroutine */

/*---------------------------------------------------------------*/
/* Move - Write out a readme for moves                           */
/*---------------------------------------------------------------*/
Move:
 /* This subroutine writes out errors when the load modules exists */
 if lib = 'I' then
   mode = 'from'
 else
   mode = 'to'
 queue
 queue "  The copy of load module '"load_mem"'" mode "the dataset"
 queue " " dsn "could not be completed because"
 queue " " dsn"("load_mem") is not the output from the element"
 queue " " c1element "type" c1type
 queue "  but was created by element"
 queue " " ele.a "type" typ.a "from system" sys.a "subsystem" sub.a
 queue
 queue "           THE COPY HAS BEEN HALTED"
 queue
 queue "  Any questions call +44 (0)123 963 8560"
 queue
 "execio" queued() "diskw README (finis"
 say 'LOADCHCK:' load_mem 'NOT OK (see DD README)'
 exit 20

return /* end of DELETE: subroutine */

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 arg return_code

 zispfrc = return_code
 address ispexec "VPUT (ZISPFRC) SHARED"

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code
