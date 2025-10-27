
/* ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
																										--	CREATING AND USING VIEWS 
/* ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE [MavenHCAPS]

GO

SELECT TOP (1000) [Release Period]
      ,[Measure ID]
      ,[Bottom-box Percentage]
      ,[Middle-box Percentage]
      ,[Top-box Percentage]
  FROM [MavenHCAPS].[dbo].[National_Results]


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Creating data result set for TOP BOX results for View

CREATE VIEW TopBoxPerformance AS

Select
	n.[Measure ID],
	n.[Top-box Percentage],
	DENSE_RANK() OVER (ORDER BY n.[Top-box Percentage] desc) 
			as TopBoxRank,
	q.[Question],
	q.[Top-box Answer]
FROM [dbo].[National_Results] n LEFT JOIN [dbo].[Questions] q 
		ON n.[Measure ID] = q.[Measure ID]	

--Use this Select Statement to view the newly formed View

Select * from TopBoxPerformance

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Creating data result set for Middle BOX results for View

CREATE VIEW MiddleBoxPerformance AS

  Select
	n.[Measure ID],
	n.[Middle-box Percentage],
	DENSE_RANK() OVER (ORDER BY n.[Middle-box Percentage] desc) 
			as TopBoxRank,
	q.Question,
	q.[Middle-box Answer]
FROM [dbo].[National_Results] n LEFT JOIN [dbo].[Questions] q 
		ON n.[Measure ID] = q.[Measure ID]

--Use this Select Statement to view the newly formed View

	Select * from MiddleBoxPerformance 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Creating data result set for Bottom BOX results for View

CREATE VIEW BottomBoxPerformance AS

  Select
	n.[Measure ID],
	n.[Bottom-box Percentage],
	DENSE_RANK() OVER (ORDER BY n.[Bottom-box Percentage] desc) 
			as BottomBoxRank,
	q.[Question],
	q.[Bottom-box Answer]
FROM [dbo].[National_Results] n LEFT JOIN [dbo].[Questions] q ON
	n.[Measure ID] = q.[Measure ID]

--Use this Select Statement to view the newly formed View

	Select * from BottomBoxPerformance 
