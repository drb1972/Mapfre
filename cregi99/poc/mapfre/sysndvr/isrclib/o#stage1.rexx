C1STGNUM = 1
C1STAGE  = Stg1nme
C1STGID  = Stg1ID
STGREF = Substr(Envname,1,3,'$') || '&C1STGNUM'
If Node = DELTA  then  STGREF = Substr(Envname,1,3,'$')
Prim      = '&Primary'
Secdry    = '&Secondary'
Dir       = '&Directory'
