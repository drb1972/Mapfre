/*REXX */
trace o
/* Set up the otions for the SCL when it is written */
 queue "SET OPTIONS CCI 'NDVR#SUPPORT'"
 queue "            COM 'DELETE OLD CODE'"
 queue "            OVE ."

/* read in the file that contains a list of subsystems */
    "EXECIO * DISKR TABLE (STEM PITS. FINIS)"

/* read in the file that contains the Endevor report */
    "EXECIO * DISKR REPORT (STEM LINE. FINIS)"

do s=1 to pits.0
  pit.s = substr(pits.s,1,3)

do A=1 to line.0
parse value line.a with ele.a env.a sys.a sub.a typ.a sid.a seq.a ver.a,
pro.a bse.a bid.a cur.a cid.a gen.a rst.a

select
 /* when a sandpit subsystem is found, build scl to delete the element
    if the generate date is more than five days ago */
  when sub.a = pit.s then do
say gen.a sub.a pit.s
/* having established that this is a sandpit subsystem, the last gen
   date has to be checked against today, and if more than four days
   have elapsed then build delete statements */

/* get the first two chars that equal the day of the month */
 castdaybig = substr(gen.a,1,2)
/* trim off leading zeroes */
 castday = strip(castdaybig,l,'0')
/* get the middle three chars that equal the name of the month */
 castmon = substr(gen.a,3,3)
/* get the last two chars that equal the year */
 castyea = substr(gen.a,6,2)

/* change the style of the month to suit the date('b') routine */
 if castmon = 'JAN' then month = 'Jan'
 if castmon = 'FEB' then month = 'Feb'
 if castmon = 'MAR' then month = 'Mar'
 if castmon = 'APR' then month = 'Apr'
 if castmon = 'MAY' then month = 'May'
 if castmon = 'JUN' then month = 'Jun'
 if castmon = 'JUL' then month = 'Jul'
 if castmon = 'AUG' then month = 'Aug'
 if castmon = 'SEP' then month = 'Sep'
 if castmon = 'OCT' then month = 'Oct'
 if castmon = 'NOV' then month = 'Nov'
 if castmon = 'DEC' then month = 'Dec'

/* get current date in relative format */
 start = date('B')

/* get date of generate in relative format */
 castwhen = date('B',''castday||' '||month||' 20'||castyea'')

/* work out difference between relative dates */
 diff = start - castwhen
 SAY DIFF

/* if gen date is more than four days ago then build delete stmts */
        if diff > 4 then do

                           queue "DELETE ELEMENT '"ele.a"'"
                           queue "FROM ENV "env.a
                           queue "     SYS "sys.a
                           queue "     SUB "sub.a
                           queue "     TYP "typ.a
                           queue "     STA "sid.a
                           queue "        ."
                         end /* end do for if */
                          end /* end do for when */
  otherwise nop
end /* end select */
end /* end do for line.0 */

end /* end do for pits.0 */

"execio * diskw scl (finis"      /* write to scl ddname for next step */

  exit
