DataRow = ' '
Sys = System
SSys = Subsystem
T = Type
P = Procgrp
U1 = LoadLibrary
U2 = ObjectLibrary
SDS = SourceDataSet
IF NewFrm /= 'Y' THEN Lvls = 0
NewElm = 'Y'
IF ElmFlag /= 'Y' THEN NewElm = 'N'
ElmName = 'TELM&r'
IF ElmFlag /= 'Y' THEN ElmName = '.'
IF SourceDataSet = ' ' THEN SDS = '.'
IF Type = ' ' THEN T = '.'
IF Procgrp = ' ' THEN P = '.'
IF LoadLibrary = ' ' THEN U1 = '.'
IF ObjectLibrary = ' ' THEN U2 = '.'
DSN = FromDataSet
IF NewFrm /= 'Y' THEN DSN = SDS
DataRow = '&DSN &NewElm &ElmName &Output &Sys &SSys &T &P &U1 &U2'
