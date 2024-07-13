C1STGNUM = 2
C1STAGE  = Stg2nme
C1STGID  = Stg2ID
STGREF = Substr(Envname,1,3,'$') || '&C1STGNUM'
If Node = DELTA  then  STGREF = Substr(Envname,1,3,'$')
Prim      = '&Primary'
Secdry    = '&Secondary'
Dir       = '&Directory'
