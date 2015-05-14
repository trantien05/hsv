USE TFSTest

DROP Table TFSItem
SELECT * INTO TFSItem FROM TFS.dbo.TFSItem

DROP Table TFSItemDateHistory
SELECT * INTO TFSItemDateHistory FROM TFS.dbo.TFSItemDateHistory

DROP Table TFSItemLedgerEntry
SELECT * INTO TFSItemLedgerEntry FROM TFS.dbo.TFSItemLedgerEntry

DROP Table StoreLink
SELECT * INTO StoreLink FROM TFS.dbo.StoreLink

DROP Table [USER]
SELECT * INTO [USER] FROM TFS.dbo.[USER]

DROP Table MenuRight
SELECT * INTO MenuRight FROM TFS.dbo.MenuRight