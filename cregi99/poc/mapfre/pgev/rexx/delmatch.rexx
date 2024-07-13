/* rexx - to look at PDSM36 output                              */
/* if it reports a member match write a delete statement        */
say 'DELMATCH: ' DATE() TIME()
trace n
/******************************************************************/
/* Loop through the pdsm36 looking for target dd statements       */
/******************************************************************/
  delcount = 0
  do until readrc = 2          /* loop til you just cant loop no more */
    "execio 1 diskr pdsm36 "   /* read 1 line                         */
    readrc = rc                /* return code from execio             */
    pull pdsmrep               /* store pdsm36 line                   */
    if readrc > 2 then exit readrc        /* I/O error                */
    if word(pdsmrep,2) = 'MATCH' then do
        push ' DELETE MEMBER='word(pdsmrep,1)
        "execio 1 diskw deletes"
        say 'MATCH >' left(word(pdsmrep,1),8) '< WILL BE DELETED'
        delcount = delcount + 1
    end /* MATCH */
  end  /* End of pass through the pdsm36 */
  'execio 0 diskr deletes (finis'    /* Close file  */
  Say 'DELMATCH: 'right(delcount,10)  'MEMBERS TO BE DELETED'
  say lines 'lines of pdsm36 processed'

  if delcount > 0 then
    exit 0
  else
  exit 4
