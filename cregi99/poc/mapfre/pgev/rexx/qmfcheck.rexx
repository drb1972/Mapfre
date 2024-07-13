/*--------------------------REXX----------------------------*\
 *  Check QMF data migration elements                       *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n
arg eltname ccid

maxrc = 0

if eltname ^= ccid & ccid ^= 'NDVR#SUP' then do
  queue 'QMFCHECK:'
  queue 'QMFCHECK: Element name' eltname ' does not match the CCID',
         ccid
  queue 'QMFCHECK: RC=12'
  queue 'QMFCHECK:'
  "execio * diskw syntax (finis"
  maxrc = 12
end

"execio * diskr infile (stem line. finis"

/* Check that line 1 contains SELECT * FROM &OWNER.&TABLE */
line1 = word(line.1,1) word(line.1,2) word(line.1,3) word(line.1,4)
if line1 ^= 'SELECT * FROM &OWNER.&TABLE' then do
  queue 'QMFCHECK:'
  queue 'QMFCHECK: The first line of the element must be:'
  queue 'QMFCHECK: "SELECT * FROM &OWNER.&TABLE"'
  queue 'QMFCHECK:'
  "execio * diskw syntax (finis"
  maxrc = 12
end

/* Check that line 2 contains a WHERE clause */
if word(line.2,1) ^= 'WHERE' then do
  queue 'QMFCHECK:'
  queue 'QMFCHECK: The second line of the element must start with'
  queue 'QMFCHECK: a WHERE clause'
  queue 'QMFCHECK:'
  "execio * diskw syntax (finis"
  maxrc = 12
end

/* Check that no sequence numbers exist */
do i = 1 to line.0
  if substr(line.i,73,8) ^= '        ' then do
    queue 'QMFCHECK:'
    queue 'QMFCHECK: Remove the sequnce numbers/text in columns 73-80'
    queue 'QMFCHECK: QMF fails if sequence numbers are coded'
    queue 'QMFCHECK:'
    "execio * diskw syntax (finis"
    maxrc = 12
  end
end

exit maxrc
