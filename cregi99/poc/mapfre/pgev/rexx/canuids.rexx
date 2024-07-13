/*-----------------------------REXX----------------------------------*\
 *  This REXX logs users off who still have XPE controlled           *
 *  Endevor datasets allocated.                                      *
 *  It sends them a message and gives them 5 minutes to              *
 *  logoff cleanly first.                                            *
 *                                                                   *
 *  This is an OPS/MVS REXX and must be run with the OI utility      *
 *  it is designed to run after XPE is brought down.                 *
 *                                                                   *
 *  The OpsWait(1) statements are to avoid abending OPS/MVS          *
\*-------------------------------------------------------------------*/
trace n

message = 'You will be auto logged off in 2 mins to free Endevor' ,
          'files for backups, unless you free files or logoff.'
found   = 'N'

/* Endevor XPE controlled datasets                                   */
dsn.1 ='PGEV.UNITA.MCF'
dsn.2 ='PGEV.UNITB.MCF'
dsn.3 ='PGEV.SYSTC.MCF'
dsn.4 ='PGEV.SYSTD.MCF'
dsn.5 ='PGEV.ACPTE.MCF'
dsn.6 ='PGEV.ACPTF.MCF'
dsn.7 ='PGEV.PRODO.MCF'
dsn.8 ='PGEV.PRODP.MCF'
dsn.9 ='PGEV.ENDEVOR.PACKAGE'
dsn.10 ='PGEV.ENDEVOR.ELMCATL'
dsn.0 = 10

/* Send warning messages to all users first                          */
do i = 1 to dsn.0
   id. = ''
   z = opscledq() /* Clear down stack                                */
   Address 'OPER'
   'D GRS,RES=(SYSDSN,'DSN.I')'
   do j = 1 until queued() = 0
      pull x
      id.j = word(x,2)
   end /* j = 1 until queued() = 0 */
   do y = 5 to j
      if left(id.y,3) ^= 'XPE'     & ,
         left(id.y,2) ^= 'EV'      & ,
         left(id.y,2) ^= 'R0'      & ,
         id.y         ^= 'EAPISVR' then do
        Address "OPER" "se '"message"',USER=("id.y")"
        found = 'Y'
        if datatype(y/3,'W') = 1 then opswait(1) /*no more than 3 cmds*/
      end /* left(id.y,3) ^= 'XPE' & ... */
   end /* y = 5 to j */
   if datatype(i/3,'W') = 1 then opswait(1)
end /* i = 1 to dsn.0 */

/* If users have Endevor datasets then wait 5 minutes,               */
/* check again and then log them off                                 */
if found = 'Y' then do
  opswait(120)
  do i = 1 to dsn.0
     id. = ''
     z = opscledq()
     Address 'OPER'
     'D GRS,RES=(SYSDSN,'dsn.i')'
     do j = 1 until queued() = 0
        pull x
        lpar.j = word(x,1)
        id.j   = word(x,2)
        asid.j = word(x,3)
     end /* j = 1 until queued() = 0 */
     do y = 5 to j
        if left(id.y,3) ^= 'XPE' & ,
           left(id.y,2) ^= 'EV'  & ,
           left(id.y,2) ^= 'R0'  then do
          Address 'OPER' 'RO' lpar.y',C U='id.y',A='asid.y /* a user */
          Address 'OPER' 'RO' lpar.y',C'   id.y',A='asid.y /* a job  */
        end
        if datatype(y/3,'W') = 1 then opswait(1)
     end /* y = 5 to j */
     opswait(1)  /* wait for logoff before next grs                  */
  end /* left(id.y,3) ^= 'XPE' & ... */
end /* found = 'Y' */

exit
