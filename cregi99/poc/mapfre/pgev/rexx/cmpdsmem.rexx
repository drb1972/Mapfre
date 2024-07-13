/*-----------------------------REXX----------------------------------*\
 *  CMPDSMEM                                                         *
 *  This does a simple member level count of the two datasets to see *
 *  if they contain the same number of members and therefore stand a *
 *  chance of being the same, producing diagnostics if there is a    *
 *  mismatch.                                                        *
 *                                                                   *
 *  Used in the job created by the RESIZE Rexx                       *
\*-------------------------------------------------------------------*/
trace n

parse source . . rexxname .
say rexxname':'
say rexxname':' Date() Time()
say rexxname':'

/* set up constants and initialise variables                         */
true        = 1
false       = 0
error_found = false

/* read input parameters (names of the two files to be compared)     */
"execio * diskr in (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of IN failed'

dsn1 = word(line.1,1)
dsn2 = word(line.2,1)

say
say rexxname': DSN1............:' dsn1
say rexxname': DSN2............:' dsn2

/* check the files exist                                             */
if sysdsn("'"dsn1"'") ^= 'OK' then do /* dataset doesn't exist       */
  queue 'DSN1' dsn1 sysdsn("'"dsn1"'")
  "execio" 1 "diskw readme"
  if rc ^= 0 then call exception rc 'DISKW to README failed'
  error_found = true
end /* sysdsn("'"dsn1"'") ^= OK */

if sysdsn("'"dsn2"'") ^= 'OK' then do /* dataset doesn't exist       */
  queue 'DSN2' dsn2 sysdsn("'"dsn2"'")
  "execio" 1 "diskw readme"
  if rc ^= 0 then call exception rc 'DISKW to README failed'
  error_found = true
end /* sysdsn("'"dsn2"'") ^= OK */

if ^error_found then do
  /* retrieve the names of the members and store them in stem vars   */
  /* DSN1                                                            */
  dsn1_members.  = false /* default to 'member not found'            */
  i              = 0
  /* Get a list of members in the dataset                            */
  t = outtrap('tsoout.')
  "listds '"dsn1"' members"
  if rc ^= 0 then call exception rc 'Error on listds of' dsn1

  /* list of members starts at line 7                                */
  do t = 7 to tsoout.0
    member = strip(tsoout.t)
    if member = '$$$SPACE' then iterate /* pdsman spacemap           */
    else do
      i                       = i + 1
      dsn1_members.i          = member
      member_c2x              = c2x(member) /* support backout mbrs  */
      dsn1_members.member_c2x = true /* indicate member exists       */
    end /* else */
  end /* t = 7 to tsoout.0 */
  dsn1_members.0 = i

  /* retrieve the names of the members and store them in stem vars   */
  /* DSN2                                                            */
  dsn2_members.  = false /* default to 'member not found'            */
  i              = 0
  /* Get a list of members in the dataset                            */
  t = outtrap('tsoout.')
  "listds '"dsn2"' members"
  if rc ^= 0 then call exception rc 'Error on listds of' dsn2

  /* list of members starts at line 7                                */
  do t = 7 to tsoout.0
    member = strip(tsoout.t)
    if member = '$$$SPACE' then iterate /* pdsman spacemap           */
    else do
      i                       = i + 1
      dsn2_members.i          = member
      member_c2x              = c2x(member) /* support backout mbrs  */
      dsn2_members.member_c2x = true /* indicate member exists       */
    end /* else */
  end /* t = 7 to tsoout.0 */
  dsn2_members.0 = i

  say
  say rexxname':' dsn1_members.0 'Members (excluding $$$SPACE) in' dsn1
  say rexxname':' dsn2_members.0 'Members (excluding $$$SPACE) in' dsn2

  if dsn1_members.0 ^= dsn2_members.0 then do /* report mismatches   */
    error_found = true
    queue dsn1_members.0 'Members (excluding $$$SPACE) in' dsn1
    queue dsn2_members.0 'Members (excluding $$$SPACE) in' dsn2
    queue 'Mismatch in number of members between the two files'
    "execio" 3 "diskw readme"
    if rc ^= 0 then call exception rc 'DISKW to README failed'

    /* report which members are in one file but not the other        */
    /* (both ways round, so code seems to be duplicated)             */
    all_members_found = true
    queue ' '
    queue 'Members in' dsn1 'that are not in' dsn2':-'
    "execio" 2 "diskw readme"
    if rc ^= 0 then call exception rc 'DISKW to README failed'

    do i = 1 to dsn1_members.0
      /* perform look up to check for existance in other file        */
      dsn1_member_c2x = c2x(dsn1_members.i)
      member_check = dsn2_members.dsn1_member_c2x
      if ^member_check then do /* member doesn't exist in other file */
        queue '  'dsn1_members.i
        "execio" 1 "diskw readme"
        if rc ^= 0 then call exception rc 'DISKW to README failed'
        all_members_found = false
      end /* ^member_check */
    end /* i = 1 to dsn1_members.0 */

    if all_members_found then do
      queue '  none'
      "execio" 1 "diskw readme"
      if rc ^= 0 then call exception rc 'DISKW to README failed'
    end /* all members found */

    all_members_found = true
    queue ' '
    queue 'Members in' dsn2 'that are not in' dsn1':-'
    "execio" 2 "diskw readme"
    if rc ^= 0 then call exception rc 'DISKW to README failed'
    do i = 1 to dsn2_members.0
      /* perform look up to check for existance in other file        */
      dsn2_member_c2x = c2x(dsn2_members.i)
      member_check = dsn1_members.dsn2_member_c2x
      if ^member_check then do /* member doesn't exist in other file */
        queue '  'dsn2_members.i
        "execio" 1 "diskw readme"
        if rc ^= 0 then call exception rc 'DISKW to README failed'
        all_members_found = false
      end /* ^member_check */
    end /* i = 1 to dsn2_members.0 */
    if all_members_found then do
      queue '  none'
      "execio" 1 "diskw readme"
      if rc ^= 0 then call exception rc 'DISKW to README failed'
    end /* all members found */

  end /* dsn1_members.0 ^= dsn2_members.0 */
  else say rexxname': Member counts match'

end /* ^error_found */

"execio" 0 "diskw readme (FINIS"

if error_found then exit 8

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
