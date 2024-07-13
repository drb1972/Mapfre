  $dt1 = datatype(Primary)
  $dt2 = datatype(Secondary)
  $dt3 = datatype(Directory)
  IF $dt1 = 'NUM' THEN PrimaryFct   = ProductionSizeFactor * Primary
  IF $dt2 = 'NUM' THEN SecondaryFct = ProductionSizeFactor * Secondary
  IF $dt3 = 'NUM' THEN DirectoryFct = ProductionSizeFactor * Directory
