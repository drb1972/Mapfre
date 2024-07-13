DataRow = ' '
msg = "Source Data Set Not Specified in Inventory Table!"
IF LENGTH(WORD(Data,1)) > 44 THEN DataRow = Overlay('**',DataRow,1,2)
DataRow = Overlay(WORD(Data,1),DataRow,4,57,' ')
IF WORD(Data,1) = '.' THEN DataRow = Overlay(msg,DataRow,4,57,' ')
IF WORD(Data,1) = '.' THEN DataRow = Overlay('**',DataRow,1,2)
DataRow = Overlay(WORD(Data,2),DataRow,63,1)
DataRow = Overlay(WORD(Data,3),DataRow,68,8,' ')
IF WORD(Data,3) = '.' THEN DataRow = Overlay(' ',DataRow,68,8,' ')
DataRow = Overlay(WORD(Data,4),DataRow,77,7,' ')
DataRow = Overlay(WORD(Data,5),DataRow,85,8,' ')
DataRow = Overlay(WORD(Data,6),DataRow,94,8,' ')
DataRow = Overlay(WORD(Data,7),DataRow,104,8,' ')
IF WORD(Data,7) = '.' THEN DataRow = Overlay(' ',DataRow,104,8,' ')
DataRow = Overlay(WORD(Data,8),DataRow,113,8,' ')
IF WORD(Data,8) = '.' THEN DataRow = Overlay(' ',DataRow,113,8,' ')
DataRow = Overlay(WORD(Data,9),DataRow,176,44,' ')
IF WORD(Data,9) = '.' THEN DataRow = Overlay(' ',DataRow,176,44,' ')
str = WORD(Data,10)
IF str = '.' THEN str = ' '
DataRow = DataRow || ' ' || str
