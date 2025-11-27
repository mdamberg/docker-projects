SELECT TOP (1000) [Release Period]
      ,[State]
      ,[Facility ID]
      ,[Completed Surveys]
      ,[Response Rate (%)]
  FROM [MavenHCAPS].[dbo].[Responses]




WITH RespRate AS
(
SELECT
	TOP 2 [Response Rate (%)],
	[State],
	[Facility ID]
FROM [dbo].[Responses]
WHERE [State] = 'AZ'
ORDER BY [Response Rate (%)] DESC
)

Select
	TOP 1 [Response Rate (%)]
FROM RespRate
ORDER BY [Response Rate (%)] ASC