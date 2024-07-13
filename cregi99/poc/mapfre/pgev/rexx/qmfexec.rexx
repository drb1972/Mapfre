/*--------------------------REXX----------------------------*\
 * This rexx executes QMF.                                  *
 * It has been written in order to switch to the Endevor    *
 * alternate id to extract the data and create the PREV     *
 * extract files.                                           *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n
arg parmdsn procdsn db2sub
say 'QMFEXEC: ' DATE() TIME()
say 'QMFEXEC:  Execute QMF'

/* Get the userid from storage                     */
ascb      = c2x(storage(224,4))
asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
asxbuser  = storage(d2x(x2d(asxb)+192),8)

/* Switch to alternate userid (ENDEVOR)             */
address tso
'alloc f(lgnt$$$i) dummy'
'alloc f(lgnt$$$o) dummy'
'execio * diskr LGNT$$$I (finis'
asxbuser  =     storage(d2x(x2d(asxb)+192),8)
say 'QMFEXEC:  User' asxbuser

/* call qmf */
address ispexec
parm="PARM(M=B,I=GENERAL.MIGDATA(&&&&PROC1='"parmdsn"(PARMS)',"||,
     "&&&&PROC2='"procdsn"(QMIGDATA)'),S="db2sub",P=QMFPLAN) NEWAPPL"
"SELECT PGM(DSQQMFE)" parm
qmfrc = rc
say "QMFEXEC:   QMF return code =" qmfrc
zispfrc = qmfrc
"vput zispfrc"

/* Switch back to the original user id              */
address tso
'execio * diskr LGNT$$$O (finis'
'free f(LGNT$$$I)'
'free f(LGNT$$$O)'
asxbuser = storage(d2x(x2d(asxb)+192),8)
say 'QMFEXEC:  User' asxbuser

exit qmfrc
