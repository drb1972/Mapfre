MODEL = MODELA
DatasetType = '&PreferredBaseDatasetType'
Dd = PreferredDeltaDatasetType
Ld = PreferredListingDatasetType
If Dd = 'ELIB' & Node = DELTA  then $SkipRow = 'Y'
If Ld = 'ELIB' & Node = LISTLIB  then $SkipRow = 'Y'
If Ld = 'ELIB' & Node = LLISTLIB then $SkipRow = 'Y'
If Node = DELTA  then MODEL = MODELB
If Node = DELTA  then STGREF = Substr(Envname,1,3,'$')
If Node = DELTA    then DatasetType = '&PreferredDeltaDatasetType'
If Node = LISTLIB  then DatasetType = '&PreferredListingDatasetType'
If Node = LLISTLIB then DatasetType = '&PreferredListingDatasetType'
Prim      = '&Primary'
Secdry    = '&Secondary'
Dir       = '&Directory'
