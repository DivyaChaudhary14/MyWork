/****** Script for SelectTopNRows command from SSMS  ******/

--Counting Number of clients Housed in given period. Only people who have been moved in HIFIS counts.
SELECT COUNT(hch.clientid) as NumberOfPeopleHoused

FROM [HIFIS_prod].[dbo].[HIFIS_Clients_HousePlacements] hch
--Joining HousePlacements to get MoveInDates
JOIN [HIFIS_prod].[dbo].[HIFIS_HousePlacements] hp ON hch.ClientHousePlacementID = hp.HousePlacementID
--Joining Clients table to connect People's table for clusterID
JOIN [HIFIS_prod].[dbo].[HIFIS_Clients] hc ON hch.ClientID = hc.ClientID 
--Joining People's table for Clusterid
JOIN [HIFIS_prod].[dbo].[HIFIS_People] p ON p.PersonID =hc.PersonID
--Parameters for the combined tables.
WHERE hp.MovedInDate >= '2022-04-01' AND hp.MovedInDate <= '2023-03-31' AND ClusterID=1
