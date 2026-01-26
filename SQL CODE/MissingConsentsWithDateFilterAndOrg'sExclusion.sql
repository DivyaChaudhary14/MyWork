DECLARE @FilterOrgID INT = NULL; -- Replace NULL with a specific OrgID to filter, or leave it as NULL to not filter by OrgID
DECLARE @FilterStartDate DATE = '2023-09-01'; -- Add this filter for startDate

WITH RankedConsents AS (
  SELECT
    [HIFIS_Consent].[ClientID],
    [HIFIS_Consent].[StartDate],
    [ExpiryDate],
    [DocumentID],
    [ConsentTypeID],
    HIFIS_Organizations.Name AS OrgName, 
    HIFIS_Consent_ServiceProviders.OrgID,
    ROW_NUMBER() OVER (
      PARTITION BY [HIFIS_Consent].[ClientID]
      ORDER BY [HIFIS_Consent].[StartDate] DESC, [DocumentID] DESC
    ) AS rn
  FROM [HIFIS_prod].[dbo].[HIFIS_Consent]
  JOIN HIFIS_Consent_ServiceProviders
    ON HIFIS_Consent.ConsentID = HIFIS_Consent_ServiceProviders.ConsentID
  JOIN HIFIS_Organizations
    ON HIFIS_Organizations.OrganizationID = HIFIS_Consent_ServiceProviders.OrgID
  JOIN [HIFIS_Clients]
    ON [HIFIS_Clients].[ClientID] = [HIFIS_Consent].[ClientID]
  WHERE [HIFIS_Clients].ClientStateTypeId = 1
    AND ConsentTypeID IN (1, 4, 5)
    AND (@FilterOrgID IS NULL OR HIFIS_Consent_ServiceProviders.OrgID = @FilterOrgID)
    -- Add this filter for startDate
    AND [HIFIS_Consent].[StartDate] > @FilterStartDate
)
 
SELECT
  [ClientID],
  [StartDate],
  [ExpiryDate],
  [DocumentID],
  [ConsentTypeID],
  OrgName AS [Name] 
FROM RankedConsents
WHERE rn = 1 AND DocumentID IS NULL AND OrgName != 'MSP IPDA' AND  OrgName !='MSP Detox Men''s Program'
AND OrgName !='MSP Detox Women''s Program' AND OrgName !='TSA CJServices CSFO';
