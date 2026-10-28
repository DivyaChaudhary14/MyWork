SELECT        
    -- Program name
    HIFIS_Programs.[Name] AS "PROG NAME", 
    
    -- Organization name
    HIFIS_Organizations.Name AS "ORG NAME",
    
    -- Program start and end dates
    [ProgramDateStart] AS "PROG START DATE",
    [ProgramDateEnd] AS "PROG END DATE",
    
    -- Program creation date
    HIFIS_Programs.CreatedDate AS "PROG CREATION DATE",
    
    -- Indicates whether the program is active (Yes/No)
    HIFIS_Programs.[ActiveYN] AS "PROG ACTIVE Y/N",
    
    -- Program-specific comments
    HIFIS_Programs.[Comments] AS "COMMENTS",
    
    -- Program type (e.g., Emergency Shelter, Housing Support)
    HIFIS_ProgramTypes.NameE AS "PROG TYPE",
    
    -- Start and end dates of the program at a specific organization
    HIFIS_Program_ServiceProviders.DateStart AS "Prog at Org Start",
    HIFIS_Program_ServiceProviders.DateEnd AS "Prog at Org End",
    
    -- Additional comments about the program at the organization
    HIFIS_Program_ServiceProviders.Comments AS "Prog at Comments",
    
    -- Cluster ID to which the organization belongs
    HIFIS_Organizations.ClusterID AS "Cluster ID#"
FROM 
    -- Main table containing program data
    [HIFIS_prod].[dbo].[HIFIS_Programs]
    
    -- Join to map programs to service providers (organizations running the programs)
    JOIN HIFIS_Program_ServiceProviders 
        ON HIFIS_Programs.ProgramID = HIFIS_Program_ServiceProviders.ProgramID
    
    -- Join to include program types
    JOIN HIFIS_ProgramTypes 
        ON HIFIS_Programs.ProgramTypeID = HIFIS_ProgramTypes.ID
    
    -- Join to include organization details
    JOIN HIFIS_Organizations 
        ON HIFIS_Program_ServiceProviders.OrganizationID = HIFIS_Organizations.OrganizationID
    
    -- Join to include cluster details (hierarchical grouping of organizations)
    JOIN HIFIS_Cluster 
        ON HIFIS_Organizations.ClusterID = HIFIS_Cluster.ClusterID
WHERE
    -- Exclude specific clusters based on their IDs
    HIFIS_Organizations.ClusterID NOT IN (#, #, #)
    
    -- Exclude a specific organization
    AND HIFIS_Organizations.OrganizationID <> #
    
    -- Exclude programs and organizations
    AND NOT (HIFIS_Programs.ProgramID = # 
             AND HIFIS_Organizations.OrganizationID IN (#, #, #))
    
    -- Exclude programs
    AND NOT (HIFIS_Programs.ProgramID = # 
             AND HIFIS_Organizations.OrganizationID = #)
    
    -- Exclude a program for specific organizations
    AND NOT (HIFIS_Programs.ProgramID = # 
             AND HIFIS_Organizations.OrganizationID IN (#, #))
             
ORDER BY  
    -- Sort results by program name
    HIFIS_Programs.[Name];
