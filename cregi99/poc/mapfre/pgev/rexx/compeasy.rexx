/*REXX*/
/*******************************************************************/
/* This rexx executes the Easytrieve DB2 compiler                  */
/* It has been written in order to switch to the Endevor alternate */
/* id for ASXBUSER so that "SQL INCLUDE <tablename>" statements    */
/* will work. This functionality is only exploited in the LN       */
/* system as yet.                                                  */
/* Switching the id to ENDEVOR will use ENDEVOR as the table       */
/* qualifier. The DBAs have set up aliases of ENDEVOR.<tablename>  */
/* to point to the actual tables.                                  */
/*******************************************************************/
trace n
say 'COMPEASY: ' DATE() TIME()
say 'COMPEASY:  Easytrieve DB2 compile interface'

/* Get the userid from storage                     */
ascb      = c2x(storage(224,4))
asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
asxbuser  = storage(d2x(x2d(asxb)+192),8)

/* Switch to alternate userid (ENDEVOR)             */
'alloc f(lgnt$$$i) dummy'
'alloc f(lgnt$$$o) dummy'
'execio * diskr LGNT$$$I (finis'
asxbuser  =     storage(d2x(x2d(asxb)+192),8)
say 'COMPEASY:  User' asxbuser

/* call the EASYTRIEVE compiler */
address tso "call *(EZTPA00)"
comprc = rc
say "COMPEASY:  Compile return code =" comprc

/* Switch back to the original user id              */
'execio * diskr LGNT$$$O (finis'
'free f(LGNT$$$I)'
'free f(LGNT$$$O)'
asxbuser = storage(d2x(x2d(asxb)+192),8)
say 'COMPEASY:  User' asxbuser

exit comprc
