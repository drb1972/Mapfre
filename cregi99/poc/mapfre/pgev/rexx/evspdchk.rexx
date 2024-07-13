/*-----------------------------REXX----------------------------------*\
 *  Check SPDEF source to ensure that correct WLM and ASUTIME value  *
 *  are used.                                                        *
 *  Check SQLP source to ensure that bind statements are not used.   *
 *  Check SQLP source to ensure no weird comment chars are used.     *
 *                                                                   *
 *  This REXX is called by the GDB2SP processor                      *
\*-------------------------------------------------------------------*/
trace n /* no sysdsn check because it runs under IRXJCL              */

parse source . . rexxname .

arg c1sy prgrp4 c1ty c1element

say rexxname':' Date() Time()
say rexxname':'
say rexxname': C1SY............:' c1sy
say rexxname': PRGRP4..........:' prgrp4
say rexxname': C1TY............:' c1ty
say rexxname': C1ELEMENT.......:' c1element
say rexxname':'

queue rexxname':' Date() Time()
queue rexxname':'
queue rexxname': C1SY............:' c1sy
queue rexxname': PRGRP4..........:' prgrp4
queue rexxname': C1TY............:' c1ty
queue rexxname': C1ELEMENT.......:' c1element
queue rexxname':'

exit_rc = 0

if left(c1element,2) ^= c1sy then do
  exit_rc = 12
  queue rexxname': The first 2 characters of the element name' ,
    'must equal the system name'
end /* left(c1element,2) ^= c1sy */

"EXECIO * DISKR SOURCE (STEM line. FINIS)"
if rc ^= 0 then call exception rc 'DISKR of SOURCE failed.'

if prgrp4 = 'C' & c1sy = 'KJ' then
  do n1 = 1 to line.0
    select
      when pos('WLM',line.n1) > 0 then do
        z = pos('#db2su',line.n1) + 6
        wlm = substr(line.n1,z,4)
        if wlm ^= 'AE08' then do
          exit_rc = 12
          queue rexxname':' wlm ,
              'IS AN INVALID WLM VALUE - Please contact DB2 DBA'
        end /*  wlm ^= 'AE08' */
      end /* pos('WLM',line.n1) > 0 */
      when wordpos('ASUTIME',line.n1) > 0 then do
        z = pos('ASUTIME LIMIT',line.n1) + 14
        asu = strip(substr(line.n1,z,6))
        if asu ^= '500000' then do
          exit_rc = 12
          queue rexxname':' asu ,
              'IS AN INVALID ASUTIME VALUE - Please contact DB2 DBA'
        end /* asu ^= '500000' */
      end /* pos('ASUTIME',line.n1) > 0 */
      otherwise nop
    end /* select */
  end /* n1 = 1 to line.0 */

/*  Check wlmno, first line & semicolon                              */
wlmno = ''

/* Check first line of SPDEF element */
if subword(line.1,1,2) = 'WLM ENVIRONMENT' then   /* cobd only       */
  wlmno = right(subword(line.1,3,1),2)

if wlmno = '' then do                             /* not cobd        */
  if subword(line.1,1,2) ^= 'CREATE PROCEDURE' then do /* StProc     */
    queue rexxname': Error'
    queue rexxname': First line of element is not' ,
          '"CREATE PROCEDURE" or "WLM ENVIRONMENT"'
    queue rexxname': Please review the element'
    queue rexxname':'
    exit_rc = 12
  end /* subword(line.1,1,2) ^= 'CREATE PROCEDURE' */

  if c1ty ^= 'SQLP' then do

    /* Check production WLM environment has been specified           */
    do i = 2 to line.0
      if subword(line.i,1,2) = 'WLM ENVIRONMENT' then do
        wlmno = right(subword(line.i,3,1),2)
        leave
      end /* subword(line.i,1,2) = 'WLM ENVIRONMENT' */
    end /* i = 2 to line.0 */

    /* check that the last character is a semicolon                  */
    lastline = line.0
    lastline = substr(line.lastline,1,72)
    lastword = words(lastline)
    if right(word(lastline,lastword),1) ^= ';' then do
      queue rexxname': Error'
      queue rexxname': Last character of the source is not a semicolon'
      queue rexxname':'
      exit_rc = 12
    end /* right(word(lastline,lastword),1) ^= ';' */

  end /* c1ty ^= 'SQLP' */

  else do /*  Check for invalid SQLP statements */

    x = line.1
    upper x
    x = left(word(x,3),8)
    if x = '#DB2QUAL' then do
      exit_rc = 12
      queue rexxname': Do not code #DB2QUAL. on the CREATE PROCEDURE' ,
            'line'
      queue 'Line' 1 '-' line.1
    end /* x = '#DB2QUAL' */

    if left(word(line.1,3),2) ^= c1sy then do
      exit_rc = 12
      queue rexxname': The first 2 characters of the SQLP name' ,
        'must equal the system name'
      queue 'Line' 1 '-' line.1
    end /* left(word(line.1,3),2) ^= c1sy */

    found_language = 0
    do i = 1 to line.0
      if left(word(line.i,1),2) = '--' then /* if comment line       */
        iterate
      if left(line.i,2) = '##' then do /* sysin dlm characters       */
        exit_rc = 13
        queue rexxname': The characters ## are not valid in positions' ,
          '1 & 2 of the source'
        queue 'Line' i '-' line.i
      end /* left(line.i,2) =  */

      upper line.i /* convert the source to upper case               */

      if wordpos('APPLICATION ENCODING SCHEME',line.i) > 0 | ,
         wordpos('CURRENT DATA',line.i)                > 0 | ,
         wordpos('DEFER PREPARE',line.i)               > 0 | ,
         wordpos('DEGREE',line.i)                      > 0 | ,
         wordpos('DYNAMICRULES',line.i)                > 0 | ,
         wordpos('EXPLAIN',line.i)                     > 0 | ,
         wordpos('IMMEDIATE WRITE',line.i)             > 0 | ,
         wordpos('ISOLATION LEVEL',line.i)             > 0 | ,
         wordpos('KEEP DYNAMIC',line.i)                > 0 | ,
         wordpos('NODEFER PREPARE',line.i)             > 0 | ,
         wordpos('OPTHINT',line.i)                     > 0 | ,
         wordpos('PACKAGE OWNER',line.i)               > 0 | ,
         wordpos('QUALIFIER',line.i)                   > 0 | ,
         wordpos('RELEASE AT',line.i)                  > 0 | ,
         wordpos('REOPT',line.i)                       > 0 | ,
         wordpos('VALIDATE',line.i)                    > 0 | ,
         wordpos('VERSION',line.i)                     > 0 then do
        exit_rc = 12
        queue rexxname': The following statement is not allowed...'
        queue 'Line' i '-' line.i
      end /* wordpos('xxxxx',line.i) > 0 */
      if wordpos('LANGUAGE SQL',line.i) > 0 then
        found_language = 1
      if wordpos('DEBUG MODE',line.i) > 0 & ,
         words(left(line.i,72)) > 3 then do
        exit_rc = 12
        queue rexxname': DEBUG MODE must be the only option on the line'
        queue 'Line' i '-' line.i
      end /* wordpos('DEBUG MODE',line.i) > 0 & .. */
    end /* i = 2 to line.0 */

    if ^found_language then do
      exit_rc = 12
      queue rexxname': You must code "LANGUAGE SQL" in the SQLP element'
    end /* ^found_language */

    lastline = line.0
    lastline = substr(line.lastline,1,72)

    /* check that the last line is not blank                         */
    if length(strip(lastline)) = 0 then do
      queue rexxname': Error'
      queue rexxname': The last line must not be blank'
      queue rexxname':'
      exit_rc = 12
    end /* right(word(lastline,lastword),1) ^= ';' */

    else do

      /* check that the last character is a hash                     */
      lastword = words(lastline)
      if right(word(lastline,lastword),1) ^= '#' then do
        queue rexxname': Error'
        queue rexxname': Last character of the source is not a hash(#)'
        queue rexxname':'
        exit_rc = 12
      end /* right(word(lastline,lastword),1) ^= ';' */

    end /* else */

  end /* else */

end /* wlmno = '' */

if c1ty  ^= 'SQLP' then do

  if wlmno ^= '' then do
    if datatype(wlmno) ^= 'NUM' then do
      queue rexxname': Error'
      queue rexxname': Production WLM environment' wlmno 'invalid'
      queue rexxname': Must be 2 numeric characters'
      queue rexxname': Amend SPDEF element'
      queue rexxname':'
      exit_rc = 13
    end /* datatype(wlmno) ^= 'NUM' */
  end /* wlmno ^= '' */
  else do
    queue rexxname': Error'
    queue rexxname': Production WLM environment not specified'
    queue rexxname':'
    exit_rc = 13
  end /* else */

end /* c1ty  ^= 'SQLP' */

if exit_rc > 0 then do
  "EXECIO * DISKW README (FINIS"
  if rc ^= 0 then call exception rc 'DISKW to README failed.'
end /* exit_rc > 0 */

exit exit_rc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso 'delstack' /* Clear down the stack                      */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
