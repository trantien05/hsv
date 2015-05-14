--- Code Table

SELECT * INTO #CodeTable 
From
(
Select CH.CodeOfferNo, NumOfCharacter, CL.Type, FromNumOfCharacter, ToNumOfCharacter, No, CLD.Description from CodeHeader CH
Inner Join CodeLine CL On CH.CodeOfferNo = CL.CodeOfferNo
Inner Join CodeLineDetail CLD On CLD.CodeOfferNo = CL.CodeOfferNo And CL.Type = CLD.Type And CLD.Active = 1
Where CH.CodeTypeNo = 'Offer' and CH.Active = 1
) as TMP

Select * FROM #CodeTable
DECLARE @varbinaryField varbinary(max);
Select * from CodeLine 
Select * from CodeHeader
Where 1 =1 
And SUBSTRING(TYPE,1,1) = 'B' Or SUBSTRING(TYPE,1,1) = 'C'
And SUBSTRING(TYPE,2,1) = 'R' Or SUBSTRING(TYPE,2,1) = 'C'


Select SUBSTRING(Description,1,1) from CodeLine

DECLARE @var VARBINARY(MAX)
SET @var = 0x21232F297A57A5A743894A0E4A801FC3
SELECT CAST(@var AS VARCHAR(MAX))

SELECT CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), 'Help'))

