/***rexx*********************************************************/
/** PROGRAM: RFTMAIL                                           **/
/** Author: Stuart Ashby                                       **/
/** DATE: Started 19/09/2006                                   **/
/**                                                            **/
/** Function: This rexx reads in a file created by an Infoman  **/
/** RFT and sends an e-mail if Endevor Support need to action  **/
/****************************************************************/

trace o
signal on error

rftrc = 0

/* read the card in */
"EXECIO * DISKR REPIN (STEM INP. FINIS)"
/* if the read fails then exit */
if rc > 0 then do
  say 'RFTMAIL: Return code 'rc' from DISKR command'
  exit rc
end /* if rc > 0 then do */

/* if the dataset is empty then exit */
if inp.0 = 0 then do
  say 'RFTMAIL: No records to process'
  exit 0
end /* if inp.0 = 0 then do */

do i = 1 to inp.0

  line   = strip(inp.i)
  cmr    = substr(line,1,8)   /* cmr number */
  status = substr(line,25,8)
  if status = 'BACKOUT' | ,
     status = 'ABORT'  then
    status_check = status
  else
    status_check = 'IMPL'

  /* loop through each 'plex/status' combination in the line */
  do ii = 36 to length(line) by 15
    plexpos = ii + 1
    if substr(line,plexpos,4) = 'PLEX' then do /* just check the wording */
      plex = substr(line,ii,5)
      local_status_pos = ii + 6
      local_status = substr(line,local_status_pos,8)
      if local_status ^= status_check then
        if local_status = 'IMPLFAIL' then
          queue 'RFTMAIL:' cmr 'is     marked as IMPLFAIL on the' plex
        else
          queue 'RFTMAIL:' cmr 'is not marked as' status_check 'on the' plex
    end  /* substr(line,plexpos,4) = 'PLEX' */
    else do
      queue 'RFTMAIL: Invalid value at line' i 'position' plexpos
      queue 'RFTMAIL: it should be "PLEX"'
      queue line
    end  /* else */
  end  /* do ii = 36 to length(line) by 15 */

end /* do i = 1 to inp.0 */

/* write to file for emailing */
if queued() > 0 then do
  say 'RFTMAIL:' queued() 'records will been sent to ¯ endevor'
  "EXECIO * DISKW EMAIL (FINIS"
  /* if the write fails then exit */
  if rc > 0 then do
    say 'RFTMAIL: Return code 'rc' from DISKW command'
    exit rc
  end /* if rc > 0 then do */
  rftrc = 4
end
else
  say 'RFTMAIL: All CMRs have been applied on all plexes'

/* terminate with return code to drive SAS step */
exit rftrc
