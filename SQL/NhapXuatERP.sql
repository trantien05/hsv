
	select TMP.ItemNo, I.ItemName,I.ItemCategoryName as CAT, I.ProductGroupName as [Group], I.UnitPrice as Price, TMP.StoreNo, TMP.Date, TMP.Quater,
	TMP.SourceType as [Type], TMP.SourceFrom, TMP.SourceTo, TMP.Start, TMP.Input, TMP.Output,TMP.Sale, TMP.[End] from
	-- Xuất
	(
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILE.SourceType, '' as SourceFrom, ID.SourceTo, 0 as Start, 0 as Sale, 0 as Input, ID.Quantity as Output, 0 as [End], 0 As ERPInput, 0 As ERPOutput, 0 As ERPEnd 
	from TFSItemLedgerEntry as ILE
	inner join TFSItemDateHistory as ID on ILE.ItemNo = ID.ItemNo and ILE.Quater = ID.Quater and ILE.SourceType = ID.SourceType and ILE.ReceiptNo = ID.ReceiptNo
	where ILE.SourceType = 3 and ILE.Date between CONVERT(date,'01/04/2015',103) and CONVERT(date,'30/04/2015',103)
	union 
	-- Nhập
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILE.SourceType, ID.SourceFrom,'' as SourceTo, 0 as Start, 0 as Sale, ID.Quantity as Input , 0 as Output, 0 as [End], 0 As ERPInput, 0 As ERPOutput, 0 As ERPEnd 
	from TFSItemLedgerEntry as ILE
	inner join TFSItemDateHistory as ID on ILE.ItemNo = ID.ItemNo and ILE.Quater = ID.Quater and ILE.SourceType = ID.SourceType and ILE.ReceiptNo = ID.ReceiptNo
	where ILE.SourceType = 2 and ILE.Date between CONVERT(date,'01/04/2015',103) and CONVERT(date,'30/04/2015',103)
	union 
	-- Bán
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILE.SourceType,'' as SourceFrom,'' as SourceTo, 0 as Start, sum(Isnull(ILE.Quantity,0)) as Sale, 0 as Input, 0 as Output, 0 as [End], 0 As ERPInput, 0 As ERPOutput, 0 As ERPEnd 
	from TFSItemLedgerEntry as ILE
	where ILE.SourceType = 1 and ILE.Date between CONVERT(date,'01/04/2015',103) and CONVERT(date,'30/04/2015',103)
	group by ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILe.SourceType 
	union 
	-- Tồn đầu
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '' as Date, ILE.SourceType,'' as SourceFrom,'' as SourceTo, Quantity as Start, 0 as Sale, 0 as Input, 0 as Output, 0 as [End], 0 As ERPInput, 0 As ERPOutput, 0 As ERPEnd 
	from TFSItemLedgerEntry as ILE
	where ILE.SourceType = 0 and Date < CONVERT(date,'01/04/2015',103) 
	union
	 -- Tồn cuối
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '' as Date, '4' as SourceType,'' as SourceFrom,'' as SourceTo, 0 as Start, 0 as Sale, 0 as Input, 0 as Output, sum(ILE.Quantity) as [End], 0 As ERPInput, 0 As ERPOutput, 0 As ERPEnd 
	from TFSItemLedgerEntry as ILE
	where Date <= CONVERT(date,'30/04/2015',103)
	group by ILE.ItemNo, ILE.Quater,ILE.StoreNo	
	
	
	
	) TMP
	inner join TFSItem as I on TMP.ItemNo = I.ItemNo
	where 1=1  order by TMP.StoreNo, TMP.Quater, TMP.ItemNo, TMP.SourceType, TMP.Date asc
