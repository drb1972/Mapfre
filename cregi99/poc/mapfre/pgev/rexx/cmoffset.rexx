/*-----------------------------REXX----------------------------------*\
 *   This rexx is called by EVUTLITY for CMR utilities.              *
 *                                                                   *
 *   Receives the CMR date and time and then calculates any time     *
 *   or date deviation, if required.                                 *
\*-------------------------------------------------------------------*/

parse source . . rexxname . . . . addr .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

parse arg chgdate chgtime direction amount

sysid   = mvsvar(sysname)  /* LPAR name                              */
environ = sysvar('SYSENV') /* processing mode FORE/MVS/ISPF          */

if environ ^= 'FORE' then do
  say rexxname':'
  say rexxname':' DATE() TIME() 'Processing on' sysid
  say rexxname':'
  say rexxname':  *** Input parms ***'
  say rexxname':'
  say rexxname':  CHGDATE........'chgdate
  say rexxname':  CHGTIME........'chgtime
  say rexxname':  DIRECTION......'direction
  say rexxname':  AMOUNT.........'amount
  say rexxname':'
  say rexxname':  *** End of input parms ***'
end /* environ ^= 'FORE' */

/* assign vars for further processing, typically :-                  */
/*        direction = '+'                                            */
/*        amount    = '3600' (seconds moved)                         */
direction  = strip(direction)
amount     = strip(amount)
demand_jul = chgdate
today_base = date('B',demand_jul,'J')

hh = left(chgtime,2)
mm = substr(chgtime,3,2)
ss = '00'

/* work out the start and adjusted end time of the CMR               */
str_secs   = ss + 60 * (mm + 60 * hh)
interpret "end_secs    =  str_secs" direction amount

hh_str = right(((str_secs / 60) / 60 % 1),2,'0')
mm_str = right(((str_secs - (hh_str * 60 * 60)) / 60 % 1),2,'0')
ss_str = right(((str_secs - (hh_str * 60 * 60)) - (mm_str * 60)),2,'0')

hh_end = right(((end_secs / 60) / 60 % 1),2,'0')
mm_end = right(((end_secs - (hh_end * 60 * 60)) / 60 % 1),2,'0')
ss_end = right(((end_secs - (hh_end * 60 * 60)) - (mm_end * 60)),2,'0')

/* if the adjusted CMR goes over 2400 then adjust the date           */
if hh_end||mm_end >= '2400' then do

  if environ ^= 'FORE' then do
    say rexxname':'
    say rexxname': The DATE / TIME subroutine has been triggered'
    say rexxname': because the adjusted TIME has resulted in a'
    say rexxname': DATE change being required.'
    say rexxname':'
    say rexxname': This is achieved by moving the current Julian'
    say rexxname': date on by 1 calendar day.'
    say rexxname':'
  end /* environ ^= 'FORE' */
  if hh_end||mm_end = '2400' & environ ^= 'FORE' then do
    say rexxname':'
    say rexxname': Time = 2400 is not VALID for CA7 processing.'
    say rexxname':'
    say rexxname': Amending the time to 0000 and adding 1 calendar d  ay.'
    say rexxname':'
  end /* hh_end||mm_end = '2400' & environ ^= 'FORE' */

  next_base  = today_base + 1
  next_stand = date('S',next_base,'B')
  out_jul    = substr(next_stand,3,2)||right(date('D',next_stand,'S'),3,'0')
  hh_end     = right((((end_secs - 86400) / 60) / 60 % 1),2,'0')

end /* hh_end||mm_end >= '2400' */

else do
  out_jul  = demand_jul
end /* else do */

demand_jul = demand_jul
in_time    = hh_str||mm_str

out_jul    = out_jul
out_time   = hh_end||mm_end

chgdate    = out_jul  /* modified julian day number                  */
chgtime    = out_time /* modified time                               */
fdate      = out_jul
ftime      = out_time

/* return the values to the calling exec                             */
if environ ^= 'FORE' then do
  say rexxname':'
  say rexxname':  *** Output parms ***'
  say rexxname':'
  say rexxname':  CHGDATE........'chgdate
  say rexxname':  CHGTIME........'chgtime
  say rexxname':  FDATE..........'fdate
  say rexxname':  FTIME..........'ftime
  say rexxname':'
  say rexxname':  *** End of output parms ***'
end /* environ ^= 'FORE' */

return chgdate chgtime fdate ftime

