Select 
	TMP.Store,
	TMP.Category, 
	SUM(TMP.Quantity) As Quantity,
	SUM(TMP.COGS) As COGS,
	SUM(TMP.Value) As Value,
	SUM(TMP.NetSales) As NetSales,
	SUM(TMP.DiscountAmount) / SUM(TMP.Total) * 100 As DiccountPercent,
	TMP.Program
from (
	--Khuyễn mãi
	Select 
	SE.[Store No_] As Store, 
	SE.[Item Category Code] As Category, 
	SE.Quantity, 
	SE.[Cost Amount] As COGS, 
	SE.[Standard Price Including VAT] As Value, 
	SE.[Standard Net Price] As NetSales, 
	SE.Price, 
	SE.Quantity *(SE.[Standard Price Including VAT] - SE.Price) As DiscountAmount,
	SE.Quantity*SE.[Standard Price Including VAT] As Total,
	SE.[Promotion No_] As Program
	from [HO-LIVE$Transaction Header] TH
	Inner Join [HO-LIVE$Trans_ Sales Entry]  SE ON SE.[Transaction No_] = TH.[Transaction No_]
	Where  SE.[Promotion No_] <> '' And SE.Price > 0 And SE.[Standard Price Including VAT] > 0	
	And CONVERT(Date, TH.[Date], 103) >= CONVERT(DATE, '01/05/2015', 103) And CONVERT(Date, TH.[Date], 103) <= CONVERT(DATE, '01/06/2015', 103)
	And SE.[Store No_] = 'SSG10'
	--Giảm giá
	Union
	Select 
	SE.[Store No_] As Store, 
	SE.[Item Category Code] As Category, 
	SE.Quantity, 
	SE.[Cost Amount] As COGS, 
	SE.[Standard Price Including VAT] As Value, 
	SE.[Standard Net Price] As NetSales, 
	SE.Price, 
	TDE.[Discount Amount] As DiscountAmount,
	SE.Quantity*SE.[Standard Price Including VAT] As Total,
	TDE.[Offer No_] As Program
	from [HO-LIVE$Transaction Header] TH
	Inner Join [HO-LIVE$Trans_ Sales Entry]  SE ON SE.[Transaction No_] = TH.[Transaction No_]
	Inner Join [HO-LIVE$Trans_ Discount Entry] TDE ON TDE.[Transaction No_] = SE.[Transaction No_] And TDE.[Line No_] = SE.[Line No_] And TDE.[Offer Type] <> 0
	Where  SE.[Promotion No_] <> '' And SE.Price > 0 And SE.[Standard Price Including VAT] > 0	
	And CONVERT(Date, TH.[Date], 103) >= CONVERT(DATE, '01/05/2015', 103) And CONVERT(Date, TH.[Date], 103) <= CONVERT(DATE, '01/06/2015', 103)	
	And SE.[Store No_] = 'SSG10'
	--Tặng quà
	Union
	Select 
	SE.[Store No_] As Store, 
	SE.[Item Category Code] As Category, 
	SE.Quantity, 
	SE.[Cost Amount] As COGS, 
	SE.[Standard Price Including VAT] As Value, 
	SE.[Standard Net Price] As NetSales, 
	SE.Price, 
	TDBE.Quantity * SE.[Standard Price Including VAT] As DiscountAmount,
	SE.Quantity*SE.[Standard Price Including VAT] As Total,
	TDBE.[Offer No_] As Program
	from [HO-LIVE$Transaction Header] TH
	Inner Join [HO-LIVE$Trans_ Sales Entry]  SE ON SE.[Transaction No_] = TH.[Transaction No_]
	Inner Join [HO-LIVE$Trans_ Disc_ Benefit Entry] TDBE ON TDBE.[Transaction No_] = SE.[Transaction No_] 
	Where SE.[Total Rounded Amt_] = 0 And SE.Price > 0 And SE.[Standard Price Including VAT] > 0	
	And CONVERT(Date, TH.[Date], 103) >= CONVERT(DATE, '01/05/2015', 103) And CONVERT(Date, TH.[Date], 103) <= CONVERT(DATE, '01/06/2015', 103)
	And SE.[Store No_] = 'SSG10'
) AS TMP
Group By TMP.Store, TMP.Category, TMP.Program
Order By Store, Category, Program