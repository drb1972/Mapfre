/* REXX */
address tso

parse arg thisccid thisstag type sub

"execio * diskr REPIN (stem rep. finis"
if rc^=0 then exit 12

errors = 0
conflict = 0
inprog   = 0
missing = 0
allexist = 'YES'
checkexist = 'NO'
sys=substr(sub,1,2)
dsn = 'PREV.P'sub'.'type

/* The following check to see if deletes are being done, and if    */
/* they are, builds an array to check if the members being deleted */
/* actualy exist in the production library                         */

do c=1 to rep.0
  tag = substr(rep.c,16,1)
  action = substr(rep.c,1,6)
  if action = 'DELETE' & tag = 0 then do
    checkexist = 'YES'
    leave
  end
end /* Loop through and see if there are deletes */

if checkexist = 'YES' then do
  a = outtrap('pdsmems.','*')
  queue "display"
  queue "end"
  /* Changed to use PDSMAN to bring back lists of members */
  /* this traps less lines than listds so avoids storage abend */
  address tso
  "pdsman" "'"dsn"'"
  pdsrc = rc
  a = outtrap('off')
  if pdsrc > 0 then do
    say 'CMPARM3: Error reading' dsn 'directory'
    exit pdsrc
  end
  if pdsmems.0 > 0 then
    too = pdsmems.0 - 1
  do i = 2 to too
    do y = 1 to words(pdsmems.i)
      mem=word(pdsmems.i,y)
      found.mem = 'YES'
    end
  end
end /* End of read in member list */

do c=1 to rep.0

  tag = substr(rep.c,16,1)
  action = substr(rep.c,1,6)
  ccid = substr(rep.c,17,8)
  stage = substr(rep.c,26,1)
  stage = substr(rep.c,26,1)
  member = substr(rep.c,8,8)

  if tag = 0 then thismem = strip(substr(rep.c,8,8))

  if action = 'DELETE' & tag = 0 then do

    if found.thismem ^= 'YES' then do
      say 'CMPARM3: Error!! Unable to delete '||thismem||' as its not in '||,
          "PREV.P"sys"1."type""
      say 'CMPARM3:'
      missing = missing + 1
      errors = 8
      allexist = 'NO'
    end
  end

  if (tag = 1) & (member = thismem) then do
    say 'CMPARM3: CONFLICT !!' thismem 'ALSO FOUND IN ',
        ccid 'AT STAGE' stage 'WITH AN ACTION OF' action
    if stage = 'P' then do
      say 'CMPARM3: This is a change that is in progress.'
      say 'CMPARM3: The Rjob has run but the Cjob has not.'
      say 'CMPARM3: Warning!!' dsn'('thismem') contains the new code'
      say 'CMPARM3: for' ccid 'not the current live code'
      say 'CMPARM3:'
      inprog = inprog + 1
    end
    else
      conflict = conflict + 1
    say 'CMPARM3:'
    errors = 8
    if substr(ccid,1,2) <> 'C0' then do
      say 'CMPARM3: ERROR - THE CHANGE YOU ARE CONFLICTING WITH IS NOT'
      say 'CMPARM3:       - A VALID WIZARD ELEMENT. YOU HAVE PROBABLY '
      say 'CMPARM3:       - PREVIOUSLY ADDED A WIZARD MEMBER CALLED   '
      say 'CMPARM3:       - 'thismem' BY MISTAKE , WHICH YOU SHOULD   '
      say 'CMPARM3:       -  DELETE BEFORE YOU TRY AGAIN              '
      say 'CMPARM3:'
    end
  end

end

if conflict > 0 then do
  SAY 'CMPARM3: FOR CONFLICTING CHANGES IN STAGES E,F OR O'
  say 'CMPARM3: THESE ARE YOUR OPTIONS...................'
  say 'CMPARM3: 1) REMOVE THE CONFLICING MEMBERS FROM THIS CHANGE'
  say 'CMPARM3: 2) GET THE OWNERS OF THE OTHER CHANGE TO AMEND THEIR CHANGE'
  say 'CMPARM3: 3) WAIT FOR THE OTHER CHANGE TO BE PROMOTED TO STAGE P'
  say 'CMPARM3: 4) DELETE THE CONFLICTING WIZARD MEMBER IF YOU OWN IT'
  say 'CMPARM3: 5) IF YOU ARE CONFLICTING WITH C9999999 PLEASE CALL  '
  say 'CMPARM3:    ENDEVOR SUPPORT                                   '
  say 'CMPARM3:'
end

if inprog > 0 then do
  say 'CMPARM3: For changes in progress in stage P......'
  say 'CMPARM3: 1) The code in' dsn 'is not the current live code'
  say 'CMPARM3: 2) If this change goes live after the in progress CMR then'
  say 'CMPARM3:    there will be no issues.'
  say 'CMPARM3: 3) If this change is to go live before the in progress CMR then'
  say 'CMPARM3:    a) The in progress CMR will overwrite this change when it',
      'goes live'
  say 'CMPARM3:    b) Backout is compromised and may not be possible through'
  say 'CMPARM3:       normal Endevor processing'
  say 'CMPARM3: To override this warning and continue then re add this'
  say 'CMPARM3: element with the first 7 characters of the comment =  "**FORCE"'
  say 'CMPARM3:'
end

if errors = 8 & thisstag = 'O' & allexist = 'YES' & inprog = 0 then
  errors = 4

if errors = 0 then do
  say 'CMPARM3:                                                      '
  say 'CMPARM3: NO OTHER CHANGES CONFLICT WITH '||thisccid
  say 'CMPARM3: THE WIZARD OF 'sys' WILL ALLOW THIS CHANGE TO PROCEED'
  say 'CMPARM3:                            O                         '
  say 'CMPARM3:       ___                 / \                        '
  say 'CMPARM3:     _|___|_              /___\                       '
  say 'CMPARM3:     \/O_O\/              |O_O|     ,%%%%%%%,         '
  say 'CMPARM3:     //\o/\\     |||       \u/    ,%%/\%%%/\%%,       '
  say 'CMPARM3:    ..#####.   /|||||\   __|=|__ ,%%%\&"""&/%%%,      '
  say 'CMPARM3:   .//|###|\\  ||o_o||  (./.-.\.)%%%%/ O O \%%%%      '
  say 'CMPARM3:   (< |###| \\ |\.=./| .//| · |\\%%%%|  _  |%%%%      '
  say 'CMPARM3:   .\\|###|,//|::   ::|// | · |`\\%%%(__Y__)%%%.      '
  say 'CMPARM3:   .//| _ |// `\ ::: /`\\/  ·  \//.%%%%\-/%%%%.       '
  say 'CMPARM3:      // \\    .\ : /   \|__.__|/ / .%%%%%%%. \       '
  say 'CMPARM3:     //   \\   /  :  \   |  |  |  | |       | |       '
  say 'CMPARM3:    ((     )) /   :   \  <. I .>  | | |   | | |       '
  say 'CMPARM3:     \\    ||/,.,.:.,.,\  | | |  /  | |   | |  \      '
  say 'CMPARM3:     _\\   ||   || ||    _| | |_ | _| |   | |_ |      '
  say 'CMPARM3:    (/|\) (||) (_) (_)  <___|___> (,,,).,.(,,,) .     '
end

if allexist = no then do
  say 'CMPARM3:  '
  say 'CMPARM3: ERROR YOU ARE TRYING TO DELETE 'missing' MEMBER(S) THAT'
  say 'CMPARM3: CANNOT BE FOUND IN ENDEVOR LIBRARY     '||"PREV.P"sys"1."type""
  say 'CMPARM3: CONTACT ENDEVOR SUPPORT IF THEY ARE IN '||"PG"sys".BASE."type""
  say 'CMPARM3:  '
end

if errors = 8 then do
  say 'CMPARM3:  '
  if conflict > 0 then
    say 'CMPARM3: ERROR -' conflict 'STAGE E,F OR O CONFLICTS FOUND'
  if inprog   > 0 then
    say 'CMPARM3: ERROR -' inprog 'CMR IN PROGESS CONFLICTS FOUND'
  say 'CMPARM3:  '
  say 'CMPARM3: YOU CANNOT ADD THIS CHANGE CURRENTLY, AS THERE'
  say 'CMPARM3: ARE OTHER CHANGES REFERENCING THE SAME MEMBERS.'
  say 'CMPARM3: PLEASE AMEND' thisccid 'OR WAIT FOR THE OTHER CHANGES'
  say 'CMPARM3: LISTED TO BE PROMOTED'
end

if errors = 4 then do
  say 'CMPARM3:  '
  say 'CMPARM3: ------------ EMERGENCY CHANGE SUMMARY -------------'
  say 'CMPARM3: ***************************************************'
  say 'CMPARM3: WARNING!!  '||conflict||' CONFLICTS FOUND '
  say 'CMPARM3:  '
  say 'CMPARM3: YOU ARE ABOUT TO UPDATE '||conflict||' MEMBERS THAT'
  say 'CMPARM3: ARE CURRENTLY BEING MODIFIED IN OTHER CHANGE RECORDS.'
  say 'CMPARM3: IF THESE CHANGES ARE NOT UPDATED, YOUR CHANGES WILL'
  say 'CMPARM3: BE REGRESSED!!                                     '
  say 'CMPARM3:  '
  say 'CMPARM3: YOU MUST ENSURE THAT OWNERS OF THE OTHER CHANGES ARE'
  say 'CMPARM3: AWARE OF THIS SO THEY CAN AMEND THEIR SOURCE CODE TO INCLUDE'
  say 'CMPARM3: YOUR CHANGES                                           '
end

exit errors
