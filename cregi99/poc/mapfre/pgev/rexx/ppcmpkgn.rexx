/*--------------------------REXX----------------------------*\
 *  Notify user of job submission                           *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace n

arg trkid pkgid sysuid

cvt       = c2x(storage(10,4))
ascb      = c2x(storage(224,4))
psatold   = c2x(storage(21c,4))
ascb_jbni = c2x(storage(d2x(x2d(ascb)+172),4))
ascb_jbns = c2x(storage(d2x(x2d(ascb)+176),4))
assb      = c2x(storage(d2x(x2d(ascb)+336),4))
asxb      = c2x(Storage(D2x(X2d(ascb)+108),4))
acee      = c2x(Storage(D2x(X2d(asxb)+200),4))
jsab      = c2x(storage(d2x(x2d(assb)+168),4))

/* work out jobnumber */
jbid = storage(d2x(x2d(jsab)+20),8)

/* get userid */
aceeusri  =     Storage(D2x(X2d(acee)+21),8)

/* work out jobname */
if ascb_jbns = 0 then,
   jobn = storage(ascb_jbni,8)
else,
   jobn = storage(ascb_jbns,8)

if jobn = init then,
   jobn = storage(d2x(x2d(jsab)+28),8)

/* display results */
say
say 'User' strip(aceeusri,t) 'submitted' strip(jobn,t)
say 'JES assigned' jbid 'to job.'
say

/* send message to user */
address tso
"SEND 'JOB "strip(jobn,t)"("jbid") SUBMITTED',USER("sysuid")"

exit
