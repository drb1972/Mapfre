/* rexx - Generate FILEAID COPY control cards from INCLUDE(OBJ)   */
/*        cards in a linkdeck      */

arg element_name proc_grp_5

/* Read ENDEVOR LINKCARD member  */

'execio * diskr source (stem line. finis'
cc = rc
  if cc > 0 then do
    say 'CPYCARD5: execio of SOURCE ddname gave a return code of 'cc
    exit cc
  end /* if cc > 0 then do */

say 'CPYCARD5: '
say 'CPYCARD5: Found 'line.0' cards to process'
say 'CPYCARD5: '

objects = 'no'
say 'CPYCARD5: variable objects is initially set to NO'

newload = 'yes'
say 'CPYCARD5: variable newload is initially set to YES'

say 'CPYCARD5: '

if (proc_grp_5 = 'U') then do
  newload = 'no'
  say 'CPYCARD5: variable newload is now set to NO'
end /* if (proc_grp_5 = 'U') then do */

do i = 1 to line.0          /* Process each line  */

  data = STRIP(line.i)      /* strip leading blanks  */
  say 'CPYCARD5: Processing line 'data

  if WORD(data,1) = 'INCLUDE' &,
    SUBSTR(WORD(data,2),1,6) = 'OBJECT' &,
    newload  = 'no' then do /* line.i is an INCLUDE OBJECT card */

    say 'CPYCARD5: '
    say 'CPYCARD5: Processing include members because '
    say 'CPYCARD5: WORD(data,1) = 'WORD(data,1)
    say 'CPYCARD5: SUBSTR(WORD(data,2),1,6) = 'SUBSTR(WORD(data,2),1,6)
    say 'CPYCARD5: newload is set to 'newload

      open = POS('(',data)     /* Find left bracket   */
      close = POS(')',data)    /* Find right Bracket  */

      member_name = SUBSTR(data,open+1,close-open-1)

      PUSH '$$DD01 COPY MEMBER='member_name

      'execio 1 diskw cpycards'  /*  Write a COPY statement  */
      cc = rc
        if cc > 0 then do
          say 'CPYCARD5: execio of CPYCARDS ddname gave a return code of 'cc
          exit cc
        end /* if cc > 0 then do */

      objects = 'yes'
      say 'CPYCARD5: variable objects is now set to YES'
  end /* newload  = 'no' then do */
  else do

     if WORD(data,1) ^= 'NAME' then do
       say 'CPYCARD5: '
       say 'CPYCARD5: WORD(data,1) = 'WORD(data,1)
       say 'CPYCARD5: is not equal to "NAME"'

       PUSH line.i

       say 'CPYCARD5: '
       say 'CPYCARD5: writing 'strip(line.i)' to DDname lnkcards'
       say 'CPYCARD5: '

        'execio 1 diskw lnkcards'  /* Write a Link statement asis */
        cc = rc
          if cc > 0 then do
            say 'CPYCARD5: execio of LNKCARDS DDname gave a return code of 'cc
            exit cc
          end /* if cc > 0 then do */

     end /* if WORD(data,1) ^= 'NAME' then do */
     else nop

  end /* else do */
end /* do i = 1 to line.0 */


'execio 0 diskr cpycards (finis'    /* Close file  */
cc = rc
  if cc > 0 then do
    say 'CPYCARD5: execio of CPYCARDS DDname gave a return code of 'cc
    exit cc
  end /* if cc > 0 then do */

'execio 0 diskr lnkcards (finis'    /* Close file  */
cc = rc
  if cc > 0 then do
    say 'CPYCARD5: execio of LNKCARDS DDname gave a return code of 'cc
    exit cc
  end /* if cc > 0 then do */

if objects = 'yes' then exit 0
                   else exit 4
