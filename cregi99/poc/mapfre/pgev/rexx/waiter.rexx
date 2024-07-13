/*--------------------------REXX----------------------------*\
 *  Passively get exclusive enq on a dataset                *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace o
arg hours hlqs llqs

interval = 15                         /* retry wait time in seconds */
intmin   = interval / 60              /* retry wait time in minutes */

zispfrc = 0
mins   = hours * 60
sttime = time(m)
call get_jobinfo
say
say date() time()
say 'WAITER: Jobname =' jobn
say 'Retry interval =' intmin  'minutes'
say 'Will wait for' hours 'hour(s) before giving up'

do y = 1 to words(llqs)
  dsn = hlqs || '.' || word(llqs,y)
  say
  say 'Passively wait for exclusive ENQ on DSN' dsn
  do forever
    say '***' date() time() '***'
    call check_enq dsn
    if enqmsg ^= '' & enqmsg ^= jobn then
      call inuse
    else do
      x = outtrap('result.')
      "alloc fi(lockdsn) da('"dsn"') old"
      x = outtrap('OFF')
      if rc > 0 then do
        x = outtrap('result.')
        "free fi(lockdsn)"
        x = outtrap('OFF')
        say 'Attempted ENQ failed for' dsn
        say 'Retrying in' intmin 'minutes'
        sleepy = 'x = ALXRDOZE('interval')'
        interpret sleepy
      end /* RC > 0 */
      else do
        call check_enq dsn
        if enqmsg = jobn then do
          say 'Exclusive ENQ successful for' dsn
          leave
        end /* enqmsg = jobn */
        else do
          x = outtrap('result.')
          "free fi(lockdsn)"
          x = outtrap('OFF')
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
end
say

"execio * diskr subjcl (stem jcl. finis"
do i = 1 to jcl.0
  queue jcl.i
end
queue ""
address tso "submit *"  /* submit */
subrc = rc
say "WAITER: Submit RC =" subrc
subrc = abs(subrc)
if subrc > maxrc then
  maxrc = subrc

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
