/*--------------------------REXX----------------------------*\
 *  Passively get exclusive enq on a dataset                *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace n
arg dsn hours intmin

if intmin = '' then
  intmin = 5                          /* retry wait time in minutes */
interval = intmin * 60                /* retry wait time in seconds */

zispfrc = 0
mins   = hours * 60
sttime = time(m)
call get_jobinfo
say
say date() time()
say 'RESIZEE: Jobname =' jobn
say 'Passively wait for exclusive ENQ on DSN' dsn
say 'Retry interval =' intmin  'minutes'
say 'Will wait for' hours 'hour(s) before giving up'
say

do forever
  call check_enq dsn
  if enqmsg ^= '' & enqmsg ^= jobn then
    call inuse
  else do
    "alloc fi(lockdsn) da('"dsn"') old"
    if rc > 0 then do
      "free fi(lockdsn)"
      say date() time()
      say 'Attempted ENQ failed for' dsn
      say 'Retrying'
      sleepy = 'x = ALXRDOZE('interval')'
      interpret sleepy
    end /* RC > 0 */
    else do
      call check_enq dsn
      if enqmsg = jobn then do
        say date() time()
        say 'Exclusive ENQ successfull for' dsn
        leave
      end /* enqmsg = jobn */
      else do
        "free fi(lockdsn)"
        call inuse
        say 'Retrying'
        say
      end /* else */
    end /* else */
  end /* else */
  now = time(m)
  elapsed = now - sttime
  if elapsed > mins then do
    say 'Max elapsed time exceded. Try again some other time.'
    zispfrc = 12
    address ispexec "vput zispfrc"
    leave
  end
end /* do forever */
say

exit zispfrc

/*----------------------------------------------*/
/* Check dataset enqs                           */
/*----------------------------------------------*/
check_enq:
 arg enqdsn
 enqmsg   = ''
 enqjob.0 = ''
 s = queryenq("'"enqdsn"'")
 /* queryenq sometimes does not set variables and so the rexx fails */
 /* only for one user (BOWERC)? The next if allows for this         */
 if enqjob.0 <> '' then do
   if enqjob.0 > 0 then do
     do a = 1 to enqjob.0
       enqjob = strip(enqjob.a)
       if enqmsg ^= '' then
         enqmsg = enqmsg';' enqjob
       else
         enqmsg = enqjob
     end /* do a = 1 to enqjob.0 */
     enqmsg = strip(enqmsg)
   end /* enqjob.0 ^= 0 */
 end
return

/*----------------------------------------------*/
/* Dataset in use                               */
/*----------------------------------------------*/
inuse:
  say date() time()
  say 'Waiting for dataset' dsn'. In use by:'
  enqsay = enqmsg
  do forever
    if length(enqsay) < 80 then do
      say enqsay
      leave
    end
    x = substr(enqsay,1,80)
    end = pos(' ',enqsay,70)
    say substr(enqsay,1,end)
    enqsay = strip(substr(enqsay,end))
  end
  say
  sleepy = 'x = ALXRDOZE('interval')'
  interpret sleepy
return

/*----------------------------------------------*/
/* Get jobinfo                                  */
/*----------------------------------------------*/
get_jobinfo:
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

return
