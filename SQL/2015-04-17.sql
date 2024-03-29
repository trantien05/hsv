Insert Into ComboValue(Type, Code, Value, Year, Status, Priority, Brand)
Values('DateTFS', 'RptDateTotal', N'B/c Date Tổng', 0,0,4, 'TFS')

CREATE TYPE TFSItemLedgerEntryType AS Table(
	[StoreNo] [nvarchar](50) NOT NULL,
	[ItemNo] [nvarchar](50) NOT NULL,
	[Barcode] [nvarchar](50) NULL,
	[Quater] [int] NULL,
	[SourceType] [nchar](10) NULL,
	[Quantity] [int] NULL,
	[ReceiptNo] [nvarchar](50) NULL,
	[Date] [date] NULL,
	[Status] [int] NULL
)
Go
CREATE PROC sp_InsertTableTFSItemLedgerEntry @MyTable TFSItemLedgerEntryType Readonly
As
Begin
	Insert Into TFSItemLedgerEntry(StoreNo, ItemNo, Barcode, Quater, SourceType, Quantity, ReceiptNo, [Date], [Status])
	select StoreNo, ItemNo, Barcode, Quater, SourceType, Quantity, ReceiptNo, [Date], [Status] from @MyTable
End