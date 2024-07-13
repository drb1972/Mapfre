DataRow = ' '
FromDataSet = WORD(Data,1)
IF LENGTH(FromDataSet) > 44 THEN DataRow = Overlay('**',DataRow,1,3,' ')
FromDataSet = TRANSLATE(FromDataSet,'','*')
FromDataSet = SPACE(FromDataSet,0)
DataRow = Overlay(FromDataSet,DataRow,4,68,' ')
