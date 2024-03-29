GO
/****** Object:  StoredProcedure [dbo].[sp_ProcessTFSItemDateHistory]    Script Date: 04/15/2015 14:43:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_ProcessTFSItemDateHistory]
	@Action nvarchar(50) = '',
	@Date nvarchar(50) = '',
	@StoreNo nvarchar(50) = '',
	@Area nvarchar(50) = '',
	@Brand nvarchar(50) = '',
	@ReceiptNo nvarchar(50) = '',
	@LotNo nvarchar(50) = '',
	@Status int = 1, 
	@SourceType int = 10,
	@SourceFrom nvarchar(50) = '',
	@SourceTo nvarchar(50) = '',
	@ItemNo nvarchar(50) = '',
	@Barcode nvarchar(50) = '',
	@Quater nvarchar(50) = '',
	@ExpireDate nvarchar(50)= '',
	@Quantity int = 0,
	@Description nvarchar(255) = '',
	@Value nvarchar(50) = '',
	@FromDate nvarchar(50) = '',
	@ToDate nvarchar(50)= '',
	@ErrMessage nvarchar(500) = '' out	
as
Begin

	Declare @row int = 0
	Declare @SQL nvarchar(Max) = ''
	DECLARE @ParmDefinition nvarchar(500)
	DECLARE @ValueList CURSOR
	
	/*
	 *	SourceType:
	 *		0: Input (Tồn Đầu Kỳ)
	 *		1: Sale (Bán)
	 *		2: TransferFrom (Nhập)
	 *		3: TransferTo (Xuất)
	 */
			 
	 /*
	  *	Add New Trans: 
	  *		+ Status = 0
	  *		+ Chua cap nhat ton kho
	  */
	  	  
	 -- Báo cáo TFS Date Từ cửa hàng
	 if(@Action = 'RptTFSDateByStore')
	begin
	SET @SQL = N'
	select TMP.ItemNo, I.ItemName,I.ItemCategoryName as CAT, I.ProductGroupName as [Group], I.UnitPrice as Price, TMP.StoreNo, TMP.Date, TMP.Quater,
	TMP.SourceType as [Type], TMP.SourceFrom, TMP.SourceTo, TMP.Start, TMP.Input, TMP.Output,TMP.Sale, TMP.[End] from
	-- Xuất
	(select ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILE.SourceType, '''' as SourceFrom, ID.SourceTo, '''' as Start, '''' as Sale, '''' as Input
	, ID.Quantity as Output, '''' as [End] from TFSItemLedgerEntry as ILE
	inner join TFSItemDateHistory as ID on ILE.ItemNo = ID.ItemNo and ILE.Quater = ID.Quater and ILE.SourceType = ID.SourceType and ILE.ReceiptNo = ID.ReceiptNo
	where ILE.SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103)
	union 
	-- Nhập
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILE.SourceType, ID.SourceFrom,'''' as SourceTo, '''' as Start, '''' as Sale, ID.Quantity as Input 
	, '''' as Output, '''' as [End]
	from TFSItemLedgerEntry as ILE
	inner join TFSItemDateHistory as ID on ILE.ItemNo = ID.ItemNo and ILE.Quater = ID.Quater and ILE.SourceType = ID.SourceType and ILE.ReceiptNo = ID.ReceiptNo
	where ILE.SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103)
	union 
	-- Bán
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILE.SourceType,'''' as SourceFrom,'''' as SourceTo, '''' as Start, sum(Isnull(ILE.Quantity,0)) as Sale, 
	'''' as Input, '''' as Output, '''' as [End]
	from TFSItemLedgerEntry as ILE
	where ILE.SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103)
	group by ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILE.Date, ILe.SourceType 
	union 
	-- Tồn đầu
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '''' as Date, ILE.SourceType,'''' as SourceFrom,'''' as SourceTo, Quantity as Start, '''' as Sale, 
	'''' as Input, '''' as Output, '''' as [End] 
	from TFSItemLedgerEntry as ILE
	where ILE.SourceType = 0 and Date < CONVERT(date,''' + @FromDate+ ''',103) 
	union
	 -- Tồn cuối
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '''' as Date, ''4'' as SourceType,'''' as SourceFrom,'''' as SourceTo, '''' as Start, '''' as Sale, 
	'''' as Input, '''' as Output, sum(ILE.Quantity) as [End] 
	from TFSItemLedgerEntry as ILE
	where Date <= CONVERT(date,''' + @ToDate+ ''',103)
	group by ILE.ItemNo, ILE.Quater,ILE.StoreNo
	) TMP
	inner join TFSItem as I on TMP.ItemNo = I.ItemNo
	where 1=1 '
	if(@StoreNo <> 'All' And @StoreNo <> '')	
		SET @SQL = @SQL + ' And TMP.StoreNo = ''' + @StoreNo + ''''	
	IF (@Area <> '')
		SET @SQL = @SQL + ' And TMP.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''')'		
	
	Set @SQL = @SQL + ' order by TMP.StoreNo, TMP.Quater, TMP.ItemNo, TMP.SourceType, TMP.Date asc'	
	--print @SQL	
	EXECUTE sp_executesql @SQL
	
	end
	 
	 -- Báo cáo TFS Date Từ HO
	 if(@Action = 'RptTFSDateByHO')
	 Begin
		SET @SQL = N'
		select TMP.ItemNo, I.ItemName,I.ItemCategoryName as CAT, I.ProductGroupName as [Group], I.UnitPrice as Price, TMP.StoreNo, TMP.Quater,
		Sum(isnull(TMP.Sale,0)) as Sale, sum(isnull(TMP.[End],0)) as [End] from
		
		-- Bán
		(select ILE.ItemNo, ILE.Quater,ILE.StoreNo, sum(Isnull(ILE.Quantity,0)) as Sale, '''' as [End]
		from TFSItemLedgerEntry as ILE
		where ILE.SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103)
		group by ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILe.SourceType
		union 
		
		 -- Tồn cuối
		select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '''' as Sale, sum(ILE.Quantity) as [End] 
		from TFSItemLedgerEntry as ILE
		where Date <= CONVERT(date,''' + @ToDate+ ''',103)
		group by ILE.ItemNo, ILE.Quater,ILE.StoreNo
		) TMP
		inner join TFSItem as I on TMP.ItemNo = I.ItemNo
		where 1=1 '
			
	if(@StoreNo <> 'All' And @StoreNo <> '')	
		SET @SQL = @SQL + ' And TMP.StoreNo = ''' + @StoreNo + ''''
	IF (@Area <> '')
		SET @SQL = @SQL + ' And TMP.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''')'		
	SET @SQL = @SQL + ' Group by TMP.ItemNo, I.ItemName,I.ItemCategoryName , I.ProductGroupName, I.UnitPrice, TMP.StoreNo, TMP.Quater
		order by TMP.StoreNo,TMP.ItemNo, TMP.Quater asc'	 
	 --print @SQL	
	EXECUTE sp_executesql @SQL
	 End
	  
	  --Báo cáo hệ thông data	 
	 if(@Action = 'RptTFSDateByWeek')
	 Begin
		SET @SQL = N'
		Select TMP.ItemNo, I.ItemName, I.ItemCategoryName, I.ProductGroupName, I.UnitPrice, TMP.Quantity, (I.UnitPrice * TMP.Quantity) As Total, TMP.Status, TMP.Quater, TMP.StoreNo From 
				('
				if(@StoreNo = 'All')
					SET @SQL = @SQL + N'Select ItemNo, ILE.Quater, N''Bán'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 1 as SourceType  from TFSItemLedgerEntry ILE Where SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, N''Nhập'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 2 as SourceType  from TFSItemLedgerEntry ILE Where SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, N''Xuất'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 3 as SourceType  from TFSItemLedgerEntry ILE Where SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					'
				if(@StoreNo <> 'All' And @StoreNo <> '')	
					SET @SQL = @SQL + N'Select ItemNo, ILE.Quater, N''Bán'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 1 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo = ''' +@StoreNo+ ''' And SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, N''Nhập'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 2 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo = ''' +@StoreNo+ ''' And SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, N''Xuất'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 3 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo = ''' +@StoreNo+ ''' And SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					'
				IF (@Area <> '')
					SET @SQL = @SQL + N'Select ItemNo, ILE.Quater, N''Bán'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 1 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''') And SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, N''Nhập'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 2 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''') And SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, N''Xuất'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 3 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''') And SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					'
				SET @SQL = @SQL + N') TMP
				inner join TFSItem as I on TMP.ItemNo = I.ItemNo
				Group by TMP.Status, TMP.SourceType, TMP.ItemNo, I.ItemName,I.ItemCategoryName , I.ProductGroupName, I.UnitPrice, TMP.Quantity, TMP.StoreNo, TMP.Quater
				order by TMP.StoreNo,TMP.ItemNo, TMP.Quater ASC, TMP.SourceType'						
		--print @SQL	
		EXECUTE sp_executesql @SQL	
	 End
		
	  
	 -- Lấy Tên ITEM 
	 If(@Action = 'GetItem')
	 Begin
		 	
			select * from TFSItemBatchNo as IB 
			inner join TFSItem as I on IB.ItemNo = I.ItemNo
			where (IB.ItemNo = @ItemNo or IB.Barcode = @Barcode)
	
	 End 
	 
	 -- Lấy Số Bill Mới
	 If(@Action = 'GetNewNumberReceiptNo')
	 Begin
		Declare @NumberingReceipt int
						
		set @row = (select COUNT(*) from TFSItemDateHistory where ReceiptNo like @Value +'%')
		
		if(@row = 0)
		begin
		set @NumberingReceipt = 0
		set @ReceiptNo = @Value + RIGHT('0000' + CONVERT(nvarchar(10),@NumberingReceipt + 1),4) 
		insert TFSItemDateHistory select '','',@ReceiptNo, 0,'','','','','','','','New',''
		
		select @Value + RIGHT('0000' + CONVERT(nvarchar(10),@NumberingReceipt + 1),4) as ReceiptNo
						
		end
						 
	 End
	 
	 -- Lấy Số Bill
	 If(@Action = 'GetNumberReceiptNo')
	 Begin
		set @ReceiptNo = (select Count(*) from TFSItemDateHistory where ReceiptNo like @Value + '%' and Description = 'New'  )
				
		if(@ReceiptNo > 0)
		begin
		Select ReceiptNo as ReceiptNo  from TFSItemDateHistory where ReceiptNo  like @Value + '%' and Description = 'New'
		end

	 End
	  
	 -- Thêm Transaction
	 If(@Action = 'AddTransaction')
	 Begin
	 
		 Set @row = (select COUNT(*) from TFSItemDateHistory where ReceiptNo = @ReceiptNo and ItemNo = @ItemNo and Quater = @Quater)
		if (@row > 0)
		Begin
			
			Set @ErrMessage = 'ItemNo: ' + @ItemNo + N' Đã tồn tại trong bill : ' + @ReceiptNo
			
			return
			
		End	
		
	 /* Bán, Xuất: Xuất phải kiểm tra lương tồn trước khi xuất */
		if (@SourceType = 1 or @SourceType = 3)
		Begin
			
			Set @row = (	Select isnull(sum(Quantity), 0) from TFSItemLedgerEntry
							Where StoreNo = @StoreNo and ItemNo = @ItemNo and Quater = @Quater
						)
			
			if (@row < @Quantity)
			Begin
				
				Set @ErrMessage = 'ItemNo: ' + @ItemNo + ' - Quý ' + @Quater + N' có lượng tồn : ' + CONVERT(nvarchar(10), @row) + N' < số lượng xuất ' + CONVERT(nvarchar(10), @Quantity)
				
				return
				
			End	
					
			Set @Quantity = @Quantity *(-1) 
			
		End
		
		/* Them 1 entry cho Transation */
		-- select * from TFSItemDateHistory	
			insert TFSItemDateHistory
			values(CONVERT(date,@Date, 103), @StoreNo, @ReceiptNo, 0, @SourceType, @SourceFrom, @SourceTo, @ItemNo,@Barcode, @Quater, @Quantity, @Description, GETDATE())
			
	 End
	 
	 -- Lấy Giao Dịch theo Bill
	 If(@Action = 'GetTransactionByReceiptNo')
	 Begin
	 
		Select ID.*, I.ItemName,I.Barcode, I.ItemCategoryCode, I.ItemCategoryName, I.Barcode, I.DivisionCode, I.ProductGroupCode,
		I.ProductGroupName, I.UnitCost, I.UnitPrice
		 from TFSItemDateHistory as ID
		inner join TFSItem as I on ID.ItemNo = I.ItemNo  
		where ID.ReceiptNo = @ReceiptNo and ID.[Status] = 0
		
	 End
	 
	 --delete giao dịch theo Bill
	 If(@Action='DeleteTransaction')
	 begin
	 
		delete TFSItemDateHistory where StoreNo =  @StoreNo and ReceiptNo = @ReceiptNo and ItemNo =  @ItemNo and Quater = @Quater and [Status] = 0 and [Description] <> 'New'
	 
	 end
	 
	 -- Lưu Transaction
	 If(@Action =  'SaveTransaction')
	 Begin
		set @row = (select COUNT(*) from TFSItemDateHistory where ReceiptNo = @ReceiptNo and [Status] = 0)
		if(@row = 0)
		begin
			Set @ErrMessage = N'Không tìm thấy số bill ' + @ReceiptNo + N' để lưu'
			return 
		end
						
		update TFSItemDateHistory set [Status] = 1 where ReceiptNo = @ReceiptNo
		-- Bỏ số bill cũ
		delete TFSItemDateHistory where ReceiptNo = @ReceiptNo and [Description] = 'New' 
		
		-- Trừ tồn kho Item Remain
		insert TFSItemLedgerEntry 
		select StoreNo, ItemNo,Barcode, Quater, SourceType, Quantity, ReceiptNo, [Date] from TFSItemDateHistory where ReceiptNo = @ReceiptNo and [Status] = 1
		
		-- Tạo số bill mới
		set @Value = right('0000' +CONVERT(nvarchar(10),convert(int,RIGHT(@ReceiptNo,4)) + 1),4)
		set @ReceiptNo = LEFT(@ReceiptNo,10) + @Value
		insert TFSItemDateHistory  
		select '','',@ReceiptNo, 0,'','','','','','','','New',''
		
		
		
	 End
	 
End	 
	 /*
	 exec sp_ProcessTFSItemDateHistory @Action=N'RptTFSDateByStore', @StoreNo = 'SSG02',@FromDate=N'01/04/2015',@ToDate=N'30/04/2015'
	 exec sp_ProcessTFSItemDateHistory @Action=N'RptTFSDateByHO',@FromDate=N'01/04/2015',@ToDate=N'30/04/2015'
	 
	 exec sp_ProcessTFSItemDateHistory @Action=N'GetTransactionByReceiptNo',@ReceiptNo=N'BSSG0204150008'
	 */
	 
	 
	 