/* rexx to write CA7 batch terminal statements to add cjob and bjob */
 trace n
 arg cmr locn
 if locn = 'P02' then do
   say 'location ' locn ' so add jobs to CA7R02'
   queue 'JOB'
   queue 'ADD,B'||cmr||',SYSTEM=ENDEVOR,EXEC=Y,JCLID=5'
   queue 'ADD,C'||cmr||',SYSTEM=ENDEVOR,EXEC=Y,JCLID=5'
   "EXECIO "QUEUED()" DISKW CA7CARDS (FINIS)"
   if rc <> 0 then exit(5)
   exit 0
 end /* P02 */
 else do
   say 'NOT RUNNING FOR CA7P02 so SET RC=4'
   exit 4
 end
