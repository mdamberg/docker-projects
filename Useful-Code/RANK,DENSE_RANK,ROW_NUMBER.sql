USE AdventureWorks2022

--------------------------------------------------------------------------------------RANK/DENSE_RANK/ROW_NUMBER-----------------------------------------------------------------------------------------------


Select
	[BusinessEntityID],
	[TerritoryID],
	[Bonus],
	RANK () over (order by bonus DESC) as RankBonus,
	DENSE_RANK () over (order by bonus DESC) as DenseRankBonus,
	ROW_NUMBER () over(order by bonus DESC) as RowNumBonus
from [Sales].[SalesPerson]


--Rank: will assign rows with the same value, the same rank and the skip the next number and continue on

--DenseRank: Will assign rows with the same value, the same rank and continue in numerical order

--RowNumber: will just give everything a row number regardless of value.