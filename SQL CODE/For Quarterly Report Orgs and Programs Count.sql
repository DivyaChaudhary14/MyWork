SELECT        
       HIFIS_Programs.[Name] AS "PROG NAME"
       ,HIFIS_Organizations.Name AS "ORG NAME"
              ,[ProgramDateStart] AS "PROG START DATE"
      ,[ProgramDateEnd] AS "PROG END DATE"
        ,HIFIS_Programs.CreatedDate AS "PROG CREATION DATE"
      ,HIFIS_Programs.[ActiveYN] AS "PROG ACTIVE Y/N"
      ,HIFIS_Programs.[Comments] AS "COMMENTS"
      ,HIFIS_ProgramTypes.NameE AS "PROG TYPE"
        ,HIFIS_Program_ServiceProviders.DateStart AS "Prog at Org Start"
        ,HIFIS_Program_ServiceProviders.DateEnd AS "Prog at Org End"
        ,HIFIS_Program_ServiceProviders.Comments AS "Prog at Comments"
        ,HIFIS_Organizations.ClusterID AS "Cluster ID#"
         FROM [HIFIS_prod].[dbo].[HIFIS_Programs]
  JOIN HIFIS_Program_ServiceProviders on HIFIS_Programs.ProgramID = HIFIS_Program_ServiceProviders.ProgramID
  JOIN HIFIS_ProgramTypes on HIFIS_Programs.ProgramTypeID = HIFIS_ProgramTypes.ID
  JOIN HIFIS_Organizations on HIFIS_Program_ServiceProviders.OrganizationID = HIFIS_Organizations.OrganizationID
  JOIN HIFIS_Cluster on HIFIS_Organizations.ClusterID = HIFIS_Cluster.ClusterID
  WHERE
  HIFIS_Organizations.ClusterID NOT IN (29, 38, 41, 28, 31, 26, 39, 30, 40, 27, 37)
  AND HIFIS_Organizations.OrganizationID <> 1
  AND NOT (HIFIS_Programs.ProgramID = 32 AND HIFIS_Organizations.OrganizationID in (13,14,15,17,19,20))--Removing MSP ORG'S for exit up
  AND NOT ( HIFIS_Programs.ProgramID =9 AND HIFIS_Organizations.OrganizationID=12)-- Removing MSP for sbsl
   AND NOT ( HIFIS_Programs.ProgramID =33 AND HIFIS_Organizations.OrganizationID in (61,62))-- Removing RAY AND TLW for Housing first
order by  HIFIS_Programs.[Name]
