Description = TypeDescription
Length   = LRECL.Type
Pan = 'PANVALET LANGUAGE ' || '&Panvalet'
Lib = 'LIBRARIAN LANGUAGE ' || '&Librarian'
If IncludeOption = 'PV'  then PanLibClause = Pan
If IncludeOption = 'LB'  then PanLibClause = Lib
If IncludeOption = ''  then PanLibClause = ' '
RegPt = '80'
If DFmt = LOG  then RegPt = '0'
If Substr(DFmt,1,3) = IMA then RegPt = '0'
MODEL = 'MODEL'
If Type /= LastType then DefaultGroup = Procgrp
If Type = LastType  then MODEL = 'NOTHING'
LastType = Type
