GO
/****** Object:  StoredProcedure [dbo].[sp_ProcessTFSItemDateHistory]    Script Date: 04/27/2015 14:41:53 ******/
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
	 -- Báo cáo TFS Date Web-ERP Từ cửa hàng
	 if(@Action = 'RptTFSDateWebERPByStore')
	 BEGIN 
	 SET @SQL = N''
	 END
	 
	   
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
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo,  ILE.Date, ILE.SourceType,'''' as SourceFrom,'''' as SourceTo, Quantity as Start, '''' as Sale, 
	'''' as Input, '''' as Output, '''' as [End] 
	from TFSItemLedgerEntry as ILE
	where ILE.SourceType = 0 and Date <= CONVERT(date,''' + @FromDate+ ''',103) And [Status] = 1 
	union
	 -- Tồn cuối
	select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '''' as Date, ''4'' as SourceType,'''' as SourceFrom,'''' as SourceTo, '''' as Start, '''' as Sale, 
	'''' as Input, '''' as Output, sum(ILE.Quantity) as [End] 
	from TFSItemLedgerEntry as ILE
	where Date <= CONVERT(date,''' + @ToDate+ ''',103) And [Status] = 1 
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
	
	--Báo cáo tổng 
	if(@Action = 'RptTFSDateTotal')
	 Begin
		SET @SQL = N'
		Select I.ItemName,I.ItemCategoryName as CAT, I.ProductGroupName as [Group], I.UnitPrice as Price, AL.ItemNo, AL.StoreNo,
		Q1SMN, Q2SMN, Q3SMN, Q4SMN, Q1SMB, Q2SMB, Q3SMB, Q4SMB, Q1HTSMN, Q2HTSMN, Q3HTSMN, Q4HTSMN, Q1HTSMB, Q2HTSMB, Q3HTSMB, Q4HTSMB
		from 
		(
			select TMP.ItemNo, TMP.StoreNo,		
			SUM(CASE WHEN TMP.Quater = 1 Then SMN Else 0 End) As Q1SMN,
			SUM(CASE WHEN TMP.Quater = 2 Then SMN Else 0 End) As Q2SMN,
			SUM(CASE WHEN TMP.Quater = 3 Then SMN Else 0 End) As Q3SMN,
			SUM(CASE WHEN TMP.Quater = 4 Then SMN Else 0 End) As Q4SMN,
			
			SUM(CASE WHEN TMP.Quater = 1 Then SMB Else 0 End) As Q1SMB,
			SUM(CASE WHEN TMP.Quater = 2 Then SMB Else 0 End) As Q2SMB,
			SUM(CASE WHEN TMP.Quater = 3 Then SMB Else 0 End) As Q3SMB,
			SUM(CASE WHEN TMP.Quater = 4 Then SMB Else 0 End) As Q4SMB,
			
			SUM(CASE WHEN TMP.Quater = 1 Then HTSMN Else 0 End) As Q1HTSMN,
			SUM(CASE WHEN TMP.Quater = 2 Then HTSMN Else 0 End) As Q2HTSMN,
			SUM(CASE WHEN TMP.Quater = 3 Then HTSMN Else 0 End) As Q3HTSMN,
			SUM(CASE WHEN TMP.Quater = 4 Then HTSMN Else 0 End) As Q4HTSMN,
			
			SUM(CASE WHEN TMP.Quater = 1 Then HTSMB Else 0 End) As Q1HTSMB,
			SUM(CASE WHEN TMP.Quater = 2 Then HTSMB Else 0 End) As Q2HTSMB,
			SUM(CASE WHEN TMP.Quater = 3 Then HTSMB Else 0 End) As Q3HTSMB,
			SUM(CASE WHEN TMP.Quater = 4 Then HTSMB Else 0 End) As Q4HTSMB	
			from
			-- Kho MN
			(
			select ILE.ItemNo, ILE.Quater,ILE.StoreNo, sum(ILE.Quantity) as SMN, 0 As SMB, 0 As HTSMN, 0 As HTSMB
			from TFSItemLedgerEntry as ILE
			where [Date] between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) And StoreNo = ''WHS''
			group by ILE.ItemNo, ILE.Quater,ILE.StoreNo
			union 
			--Kho MB
			select ILE.ItemNo, ILE.Quater,ILE.StoreNo, 0 As SMN, sum(ILE.Quantity) as SMB, 0 As HTSMN, 0 As HTSMB
			from TFSItemLedgerEntry as ILE
			where [Date] between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) And StoreNo = ''WHS-N''
			group by ILE.ItemNo, ILE.Quater,ILE.StoreNo
			--HTS MN
			Union
			select ILE.ItemNo, ILE.Quater,ILE.StoreNo, 0 As SMN, 0 As SMB, sum(ILE.Quantity) as HTSMN, 0 As HTSMB
			from TFSItemLedgerEntry as ILE
			where [Date] between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) And StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''MN'' And Brand = ''TFS'')
			group by ILE.ItemNo, ILE.Quater,ILE.StoreNo
			--HTS MB
			Union
			select ILE.ItemNo, ILE.Quater,ILE.StoreNo, 0 As SMN, 0 As SMB, 0 As HTSMN, sum(ILE.Quantity) as HTSMB
			from TFSItemLedgerEntry as ILE
			where [Date] between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) And StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''MB'' And Brand = ''TFS'')
			group by ILE.ItemNo, ILE.Quater,ILE.StoreNo
			) TMP
			--Right Join 	AllStoreItemQuater A On A.StoreNo = TMP.StoreNo And TMP.ItemNo = A.ItemNo And A.Quater = TMP.Quater	
			Group By TMP.StoreNo, TMP.ItemNo
		) AL
	inner join TFSItem as I on AL.ItemNo = I.ItemNo	
	order by AL.StoreNo,AL.ItemNo asc'	 
	--print @SQL	
	EXECUTE sp_executesql @SQL
	 End
	 
	 -- Báo cáo TFS Date Từ HO
	 if(@Action = 'RptTFSDateByHO')
	 Begin
		SET @SQL = N'
		Select StoreNo, AL.ItemNo, ItemName, ItemCategoryName as CAT, ProductGroupName as [Group], UnitPrice as Price,
		Q1Sale, Q1End, Q2Sale, Q2End, Q3Sale, Q3End, Q4Sale, Q4End
		From 
		(
			select TMP.StoreNo, TMP.ItemNo,Sum(isnull(TMP.Sale,0)) as Sale, sum(isnull(TMP.[End],0)) as [End],
			SUM(CASE WHEN TMP.Quater = 1 Then Sale Else 0 End) As Q1Sale,
			SUM(CASE WHEN TMP.Quater = 1 Then [End] Else 0 End) As Q1End,
			SUM(CASE WHEN TMP.Quater = 2 Then Sale Else 0 End) As Q2Sale,
			SUM(CASE WHEN TMP.Quater = 2 Then [End] Else 0 End) As Q2End,
			SUM(CASE WHEN TMP.Quater = 3 Then Sale Else 0 End) As Q3Sale,
			SUM(CASE WHEN TMP.Quater = 3 Then [End] Else 0 End) As Q3End,
			SUM(CASE WHEN TMP.Quater = 4 Then Sale Else 0 End) As Q4Sale,
			SUM(CASE WHEN TMP.Quater = 5 Then [End] Else 0 End) As Q4End
			from
						
				(select ILE.ItemNo, ILE.Quater,ILE.StoreNo, sum(Isnull(ILE.Quantity,0)) as Sale, '''' as [End]
				from TFSItemLedgerEntry as ILE
				where ILE.SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103)
				group by ILE.ItemNo, ILE.Quater,ILE.StoreNo, ILe.SourceType
				union 
				
				select ILE.ItemNo, ILE.Quater,ILE.StoreNo, '''' as Sale, sum(ILE.Quantity) as [End] 
				from TFSItemLedgerEntry as ILE		
				where Date <= CONVERT(date,''' + @ToDate+ ''',103) And [Status] = 1 
				group by ILE.ItemNo,ILE.StoreNo, ILE.Quater
				) TMP
				--Right Join 	AllStoreItemQuater A On A.StoreNo = TMP.StoreNo And TMP.ItemNo = A.ItemNo And A.Quater = TMP.Quater				
				Group by TMP.ItemNo, TMP.StoreNo			
		) AL
		INNER join TFSItem as I on AL.ItemNo = I.ItemNo
		where 1=1 '
		if(@StoreNo <> 'All' And @StoreNo <> '')	
					SET @SQL = @SQL + N' And AL.StoreNo = ''' + @StoreNo + ''''
				IF (@Area <> '')
					SET @SQL = @SQL + N' And AL.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''')'		
		SET @SQL = @SQL + N'order by AL.StoreNo ASC,AL.ItemNo ASC'			 
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
					SET @SQL = @SQL + 'Select ItemNo, ILE.Quater, N''Ban'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 1 as SourceType  from TFSItemLedgerEntry ILE Where SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					
					Select ItemNo, ILE.Quater, ''Nhap'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 2 as SourceType  from TFSItemLedgerEntry ILE Where SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, ''Xuat'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 3 as SourceType  from TFSItemLedgerEntry ILE Where SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					'
				if(@StoreNo <> 'All' And @StoreNo <> '')	
					SET @SQL = @SQL + 'Select ItemNo, ILE.Quater, N''Ban'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 1 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo = ''' +@StoreNo+ ''' And SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union					
					Select ItemNo, ILE.Quater, ''Nhap'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 2 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo = ''' +@StoreNo+ ''' And SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, ''Xuat'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 3 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo = ''' +@StoreNo+ ''' And SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					'
				IF (@Area <> '')
					SET @SQL = @SQL + 'Select ItemNo, ILE.Quater, N''Ban'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 1 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''') And SourceType = 1 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, ''Nhap'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 2 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''') And SourceType = 2 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					union
					Select ItemNo, ILE.Quater, ''Xuat'' As [Status], SUM(Quantity) As Quantity, ILE.StoreNo, 3 as SourceType  from TFSItemLedgerEntry ILE Where ILE.StoreNo in (Select StoreNo FROM StoreLink SL Where StoreArea = ''' +@Area+ ''' And Brand = '''+ @Brand +''') And SourceType = 3 and ILE.Date between CONVERT(date,''' + @FromDate+ ''',103) and CONVERT(date,''' + @ToDate+ ''',103) Group By ItemNo, ILE.Quater, ILE.StoreNo
					'
				SET @SQL = @SQL + ') TMP
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
		insert TFSItemDateHistory select '','',@ReceiptNo, 0,'','','','','','','','New',GETDATE()
		
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
							Where StoreNo = @StoreNo and ItemNo = @ItemNo and Quater = @Quater And [Status] = 1
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
		select StoreNo, ItemNo,Barcode, Quater, SourceType, Quantity, ReceiptNo, [Date], [Status], GETDATE() AS CreateDate  from TFSItemDateHistory where ReceiptNo = @ReceiptNo and [Status] = 1
		
		-- Tạo số bill mới
		set @Value = right('0000' +CONVERT(nvarchar(10),convert(int,RIGHT(@ReceiptNo,4)) + 1),4)
		set @ReceiptNo = LEFT(@ReceiptNo,10) + @Value
		Insert Into TFSItemDateHistory([Date], StoreNo, ReceiptNo, [Status], SourceType, SourceFrom, SourceTo, ItemNo, Barcode, Quater, Quantity, Description, CreateDate)
		Values(CONVERT(date,'01/01/1900', 103), @StoreNo, @ReceiptNo, 0,0,'','','','',0,0,'New',GETDATE())		
	 End 
	 
	 
	 --Lấy thông tin tồn đầu kỳ mới nhất
	 if(@Action = 'GetOpeningStock')
	 Begin
		Select Top 1 ID.*, I.ItemName,I.Barcode, I.ItemCategoryCode, I.ItemCategoryName, I.Barcode, I.DivisionCode, I.ProductGroupCode,
		I.ProductGroupName, I.UnitCost, I.UnitPrice
		 from TFSItemLedgerEntry as ID
		inner join TFSItem as I on ID.ItemNo = I.ItemNo  
		where ID.[Status] = 1 And SourceType = 0 Order by ID DESC
	 End
	 
	 if(@Action = 'GetOpeningStockQueue')
	 Begin	 
		IF Exists(Select ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103))
		Begin
			Select @ReceiptNo = ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103)
			Select ID.Id, ID.StoreNo, ID.ItemNo, ID.Quater, ID.Quantity, ID.Date , I.ItemName,I.Barcode, I.ItemCategoryCode, I.ItemCategoryName, I.Barcode, I.DivisionCode, I.ProductGroupCode,
			I.ProductGroupName, I.UnitCost, I.UnitPrice
			from TFSItemLedgerEntry as ID
			inner join TFSItem as I on ID.ItemNo = I.ItemNo 
			Where ReceiptNo = @ReceiptNo ANd ID.[Status] = 0 And StoreNo <> ''	
			Order by ID.Quater, StoreNo, ID.ItemNo	
		End
	 End
	 
	 if(@Action = 'GetOpeningStockQueueDouble')
	 Begin	 
		IF Exists(Select ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103))
		Begin
			Select @ReceiptNo = ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103)			
			Select TMP.*, I.ItemName,I.Barcode, I.ItemCategoryCode, I.ItemCategoryName, I.Barcode, I.DivisionCode, I.ProductGroupCode,
			I.ProductGroupName, I.UnitCost, I.UnitPrice
			FROM 
			(
			Select StoreNo, ItemNo, Quater, COUNT(*) As Number from TFSItemLedgerEntry ID Where ReceiptNo = @ReceiptNo ANd ID.[Status] = 0 And StoreNo <> ''
			Group By StoreNo, ItemNo, Quater Having COUNT(*) > 1
			) TMP
			inner join TFSItem as I on TMP.ItemNo = I.ItemNo
			Order by TMP.Quater, StoreNo, TMP.ItemNo
		End
	 End
	 	
	 -- Exec sp_ProcessTFSItemDateHistory @Action = 'GetOpeningStockQueueDouble'
	 -- Select ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103)
	 
	 --Thêm tồn đầu kỳ, hiện tại không có sử dụng hàm này bị lỗi chậm khi import nhiều
	 if(@Action = 'AddOpeningStock')
	 Begin
		IF Exists(select ItemNo from TFSItemLedgerEntry where ReceiptNo = @ReceiptNo and ItemNo = @ItemNo and Quater = @Quater And SourceType = 0)
		Begin
			Set @ErrMessage = 'ItemNo: ' + @ItemNo + N' Đã tồn tại trong bill : ' + @ReceiptNo			
			return
		End
		insert TFSItemLedgerEntry(StoreNo, ItemNo, Barcode, Quater, SourceType, Quantity, ReceiptNo, [Date], [Status])
		Values(@StoreNo, @ItemNo, @Barcode, @Quater, 0, @Quantity, @ReceiptNo, CONVERT(date,GETDATE(), 103), 0)			
	 End
	 --Lưu tồn đầu kỳ
	 If(@Action = 'SaveOpeningStock')
	 Begin
		IF Not Exists(select ReceiptNo from TFSItemLedgerEntry where ReceiptNo = @ReceiptNo and [Status] = 0 And StoreNo <> '')
		Begin
			Set @ErrMessage = N'Không tìm thấy số bill ' + @ReceiptNo + N' để lưu'
			return 
		End
		--Update lại tất cả các item cũ có liên quan đến bill mới
		Update TFSItemLedgerEntry Set [Status] = 0 Where SourceType = 0 And Id in (Select MIN(Id) as ID From TFSItemLedgerEntry Where SourceType = 0 And Status = 1 Or ReceiptNo = @ReceiptNo Group By StoreNo, ItemNo, Quater Having COUNT(*) >1)	
		--Update xác nhận là sử dụng item này
		Update TFSItemLedgerEntry Set [Status] = 1 Where ReceiptNo = @ReceiptNo And SourceType = 0
		
		--Tạo số bill mới tồn đầu kỳ
		set @Value = right('0000' +CONVERT(nvarchar(10),convert(int,RIGHT(@ReceiptNo,4)) + 1),4)
		set @ReceiptNo = LEFT(@ReceiptNo,8) + @Value
		Exec sp_ProcessTFSItemDateHistory @Action = 'AddNumberReceiptNoByOpeningStock', @ReceiptNo = @ReceiptNo
	 End	 
	 
	 --Lấy ReceiptNo Tồn đầu kỳ mới nhất
	 If(@Action = 'GetNumberReceiptNoByOpeningStock')
	 Begin
		IF Exists(Select ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103))
			Select ReceiptNo From TFSItemLedgerEntry Where CONVERT(date,[Date], 103) = CONVERT(date,'01/01/1900', 103)
		ELSE
		Begin
			Exec sp_ProcessTFSItemDateHistory @Action = 'AddNumberReceiptNoByOpeningStock', @ReceiptNo = 'TTFS04150000'
			Select 'TTFS04150000' as ReceiptNo
		End
	 End
	 
	 -- Thêm ReceiptNo tồn đầu kỳ
	 If(@Action = 'AddNumberReceiptNoByOpeningStock')
	 Begin
		If(@ReceiptNo<>'')
		Begin
			Delete from TFSItemLedgerEntry Where SourceType = 0 And StoreNo = ''
			Insert Into TFSItemLedgerEntry(StoreNo, ItemNo,SourceType, ReceiptNo, [Date], [Status]) Values('','',0,@ReceiptNo,CONVERT(date,'01/01/1900', 103),0)			
		End
	 End
	 
	 --Hàm xóa sử dụng khi số bill mới có trạng thái chưa lưu, mà người dùng lại import thêm mới cần phải xóa số bill hiện có rồi mới thêm mới
	 If(@Action = 'DeleteOpeningStock')
	 Begin
		Delete from TFSItemLedgerEntry Where [Status] = 0 And ReceiptNo = @ReceiptNo And StoreNo <> '';
	 End
End	 
	
	 
	 
	 