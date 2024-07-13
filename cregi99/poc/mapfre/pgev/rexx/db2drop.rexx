/*--------------------------REXX----------------------------*\
 *  Drop DB2 Stored Procedure in production                 *
 *                                                          *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *              August 2004                                 *
\*----------------------------------------------------------*/
trace n
arg ssid

say 'DB2DROP:  *** PARMS ***'
say 'DB2DROP:'
say 'DB2DROP:  DBSUB....'ssid
say 'DB2DROP:'
say 'DB2DROP: Ignore -204 failures as the procedure may not exist'
say 'DB2DROP:'

Address TSO "SUBCOM DSNREXX" /* host cmd env available? */
If rc Then /* no, let's make one */
s_rc = Rxsubcom('ADD','DSNREXX','DSNREXX') /* add host cmd env */

/* read all the DROP statements */
"execio * diskr DROPS (stem drops. finis"
if cc > 0 then do
  say 'DB2DROP: error on diskr DDNAME DROPS'
  exit cc
end

/* Connect to the DB2 subsystem */
Address DSNREXX
"CONNECT" ssid
say 'DB2DROP: Connect to' ssid 'RC='rc
if rc <> 0 then call sqlca
say 'DB2DROP:'

/* execute the DB2 statements */
do i = 1 to drops.0
  sqlstmnt = strip(drops.i)
  "EXECSQL" sqlstmnt
  say 'DB2DROP:' sqlstmnt 'RC='sqlcode
  If sqlcode <> 0 & sqlcode <> -204 Then Call sqlca
end

Address DSNREXX "DISCONNECT"   /* Disconnect from the DB2 subsystem */
If sqlcode <> 0 Then Call sqlca

exit

/***************** S U B R O U T I N E S ******************************/

/*--------------------------------------------------------------*/
/*  Display sqlca on error                                      */
/*--------------------------------------------------------------*/
sqlca:
 Say  " SQLSTATE =" sqlstate
 Say  " SQLERRP  =" sqlerrp
 Say  " SQLERRMC =" sqlerrmc
 Say  " SQLCODE  =" sqlcode
Exit 12
