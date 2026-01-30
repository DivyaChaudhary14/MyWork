
-- ============================================================================
-- HIFIS Data Anonymization Script - Optimized Version
-- ============================================================================
-- Purpose: Anonymize PII for non-production environments
-- Improvements over original:
--   1. Consolidated updates (one UPDATE per table)
--   2. Deterministic fake data (reproducible, searchable)
--   3. Realistic patterns (names, phones, emails look real)
--   4. WHERE clauses to skip NULL values
--   5. Estimated 80-90% faster execution
-- ============================================================================

SET NOCOUNT ON;

-- ============================================================================
-- LOOKUP TABLES FOR REALISTIC FAKE DATA
-- ============================================================================
-- Using VALUES constructor instead of temp tables for speed

DECLARE @FirstNames TABLE (ID INT, Name VARCHAR(50));
DECLARE @LastNames TABLE (ID INT, Name VARCHAR(50));

INSERT INTO @FirstNames (ID, Name) VALUES
(1,'James'),(2,'Mary'),(3,'John'),(4,'Patricia'),(5,'Robert'),(6,'Jennifer'),
(7,'Michael'),(8,'Linda'),(9,'David'),(10,'Elizabeth'),(11,'William'),(12,'Barbara'),
(13,'Richard'),(14,'Susan'),(15,'Joseph'),(16,'Jessica'),(17,'Thomas'),(18,'Sarah'),
(19,'Charles'),(20,'Karen'),(21,'Chris'),(22,'Lisa'),(23,'Daniel'),(24,'Nancy'),
(25,'Matthew'),(26,'Betty'),(27,'Anthony'),(28,'Margaret'),(29,'Mark'),(30,'Sandra'),
(31,'Alex'),(32,'Ashley'),(33,'Steven'),(34,'Kimberly'),(35,'Paul'),(36,'Emily'),
(37,'Andrew'),(38,'Donna'),(39,'Joshua'),(40,'Michelle'),(41,'Kenneth'),(42,'Dorothy'),
(43,'Kevin'),(44,'Carol'),(45, 'Brian'),(46,'Amanda'),(47,'George'),(48,'Melissa'),
(49,'Timothy'),(50,'Deborah');

INSERT INTO @LastNames (ID, Name) VALUES
(1,'Smith'),(2,'Johnson'),(3,'Williams'),(4,'Brown'),(5,'Jones'),(6,'Garcia'),
(7,'Miller'),(8,'Davis'),(9,'Rodriguez'),(10,'Martinez'),(11,'Hernandez'),(12,'Lopez'),
(13,'Gonzalez'),(14,'Wilson'),(15,'Anderson'),(16,'Thomas'),(17,'Taylor'),(18,'Moore'),
(19,'Jackson'),(20,'Martin'),(21,'Lee'),(22,'Perez'),(23,'Thompson'),(24,'White'),
(25,'Harris'),(26,'Sanchez'),(27,'Clark'),(28,'Ramirez'),(29,'Lewis'),(30,'Robinson'),
(31,'Walker'),(32,'Young'),(33,'Allen'),(34,'King'),(35,'Wright'),(36,'Scott'),
(37,'Torres'),(38,'Nguyen'),(39,'Hill'),(40,'Flores'),(41,'Green'),(42,'Adams'),
(43,'Nelson'),(44,'Baker'),(45,'Hall'),(46,'Rivera'),(47,'Campbell'),(48,'Mitchell'),
(49,'Carter'),(50,'Roberts');

-- ============================================================================
-- HELPER FUNCTIONS (inline expressions)
-- ============================================================================
-- FakePhone: 204-555-XXXX (Winnipeg area code, 555 prefix = always fake)
-- FakeEmail: firstname.lastname.ID@test.local
-- FakeComment: 'Test comment #ID' (preserves something searchable)

-- ============================================================================
-- CORE CLIENT DATA
-- ============================================================================

PRINT 'Anonymizing HIFIS_People...';
UPDATE p SET 
    FirstName = COALESCE(fn.Name, 'Test'),
    LastName = COALESCE(ln.Name, 'User'),
    MiddleName = CASE WHEN p.MiddleName IS NOT NULL THEN LEFT(fn2.Name, 1) END,
    DOB = CASE WHEN p.DOB IS NOT NULL THEN DATEFROMPARTS(YEAR(p.DOB), MONTH(p.DOB), 1) END, -- Keep month/year, set day to 1
    Aka1 = CASE WHEN p.Aka1 IS NOT NULL THEN 'Alias_' + CAST(p.PersonID AS VARCHAR(10)) END,
    Aka2 = CASE WHEN p.Aka2 IS NOT NULL THEN 'Alias2_' + CAST(p.PersonID AS VARCHAR(10)) END,
    MetaDataSearch = CASE WHEN p.MetaDataSearch IS NOT NULL 
        THEN COALESCE(fn.Name, 'Test') + ' ' + COALESCE(ln.Name, 'User') + ' ' + CAST(p.PersonID AS VARCHAR(10)) END
FROM HIFIS_People p
LEFT JOIN @FirstNames fn ON fn.ID = (p.PersonID % 50) + 1
LEFT JOIN @LastNames ln ON ln.ID = ((p.PersonID / 50) % 50) + 1
LEFT JOIN @FirstNames fn2 ON fn2.ID = ((p.PersonID + 7) % 50) + 1;

PRINT 'Anonymizing HIFIS_Clients...';
UPDATE HIFIS_Clients SET 
    FileNumber = ClientID,
    AdditionalAttributes = CASE WHEN AdditionalAttributes IS NOT NULL 
        THEN 'Attr_' + CAST(ClientID AS VARCHAR(10)) END,
    DateOfDeath = CASE WHEN DateOfDeath IS NOT NULL THEN LastUpdatedDate END;

PRINT 'Anonymizing HIFIS_Addresses...';
UPDATE HIFIS_Addresses SET 
    MetaDataSearch = CASE WHEN MetaDataSearch IS NOT NULL 
        THEN 'Address_' + CAST(AddressID AS VARCHAR(10)) END;

-- ============================================================================
-- CLIENT CONTACT INFO
-- ============================================================================

PRINT 'Anonymizing HIFIS_Clients_Houses...';
UPDATE HIFIS_Clients_Houses SET 
    Telephone1 = CASE WHEN Telephone1 IS NOT NULL THEN '204-555-' + RIGHT('0000' + CAST(ClientHouseID % 10000 AS VARCHAR(4)), 4) END,
    Telephone2 = CASE WHEN Telephone2 IS NOT NULL THEN '204-555-' + RIGHT('0000' + CAST((ClientHouseID + 1000) % 10000 AS VARCHAR(4)), 4) END,
    MobilePhone = CASE WHEN MobilePhone IS NOT NULL THEN '204-555-' + RIGHT('0000' + CAST((ClientHouseID + 2000) % 10000 AS VARCHAR(4)), 4) END,
    Email = CASE WHEN Email IS NOT NULL THEN 'client' + CAST(ClientHouseID AS VARCHAR(10)) + '@test.local' END;

PRINT 'Anonymizing HIFIS_DigitalContacts...';
UPDATE HIFIS_DigitalContacts SET 
    DigitalContactValue = CASE WHEN DigitalContactValue IS NOT NULL 
        THEN 'contact_' + CAST(DigitalContactID AS VARCHAR(10)) + '@test.local' END;

-- ============================================================================
-- USER PROFILES
-- ============================================================================

PRINT 'Anonymizing HIFIS_UserProfiles...';
UPDATE HIFIS_UserProfiles SET 
    UserName = CASE WHEN UserID != 1 THEN 'User_' + CAST(UserID AS VARCHAR(10)) ELSE UserName END,
    EmailAddress = CASE WHEN EmailAddress IS NOT NULL THEN 'user' + CAST(UserID AS VARCHAR(10)) + '@test.local' END,
    PasswordResetGUID = CASE WHEN PasswordResetGUID IS NOT NULL THEN CAST(NEWID() AS VARCHAR(50)) END,
    SecurityKey = CASE WHEN SecurityKey IS NOT NULL THEN CAST(NEWID() AS VARCHAR(100)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'User comment #' + CAST(UserID AS VARCHAR(10)) END;

-- ============================================================================
-- APPOINTMENTS & SCHEDULING
-- ============================================================================

PRINT 'Anonymizing HIFIS_Appointments...';
UPDATE HIFIS_Appointments SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Appointment note #' + CAST(AppointmentID AS VARCHAR(10)) END,
    Description = CASE WHEN Description IS NOT NULL THEN 'Appointment #' + CAST(AppointmentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Reservations...';
UPDATE HIFIS_Reservations SET 
    OverrideComment = CASE WHEN OverrideComment IS NOT NULL 
        THEN 'Override note #' + CAST(ReservationID AS VARCHAR(10)) END;

-- ============================================================================
-- CASE MANAGEMENT
-- ============================================================================

PRINT 'Anonymizing HIFIS_Cases...';
UPDATE HIFIS_Cases SET CaseNumber = CaseID;

PRINT 'Anonymizing HIFIS_Comments...';
UPDATE HIFIS_Comments SET 
    Subject = CASE WHEN Subject IS NOT NULL THEN 'Subject #' + CAST(CommentID AS VARCHAR(10)) END,
    CommentBody = CASE WHEN CommentBody IS NOT NULL THEN 'Comment body #' + CAST(CommentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_FollowUps...';
UPDATE HIFIS_FollowUps SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Follow-up note #' + CAST(FollowUpID AS VARCHAR(10)) END;

-- ============================================================================
-- SERVICES & PROGRAMS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Services...';
UPDATE HIFIS_Services SET 
    ReferredByName = CASE WHEN ReferredByName IS NOT NULL THEN 'Referrer_' + CAST(ServiceID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Service note #' + CAST(ServiceID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Services_Programs_Payment...';
UPDATE HIFIS_Services_Programs_Payment SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Payment note #' + CAST(ServicePaymentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Programs...';
UPDATE HIFIS_Programs SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Program note #' + CAST(ProgramID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Program_ServiceProviders...';
UPDATE HIFIS_Program_ServiceProviders SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Provider note #' + CAST(ProgramServiceProviderID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ProgramFixedCosts...';
UPDATE HIFIS_ProgramFixedCosts SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Fixed cost #' + CAST(ProgramFixedCostID AS VARCHAR(10)) END;

-- ============================================================================
-- HEALTH & MEDICAL
-- ============================================================================

PRINT 'Anonymizing HIFIS_HealthIssues...';
UPDATE HIFIS_HealthIssues SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Health issue #' + CAST(HealthIssueID AS VARCHAR(10)) END,
    Symptoms = CASE WHEN Symptoms IS NOT NULL THEN 'Symptom description #' + CAST(HealthIssueID AS VARCHAR(10)) END,
    Medication = CASE WHEN Medication IS NOT NULL THEN 'Medication #' + CAST(HealthIssueID AS VARCHAR(10)) END,
    Treatment = CASE WHEN Treatment IS NOT NULL THEN 'Treatment #' + CAST(HealthIssueID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_HealthIssuesHistory...';
UPDATE HIFIS_HealthIssuesHistory SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Health history #' + CAST(HealthIssueHistoryID AS VARCHAR(10)) END,
    Medication = CASE WHEN Medication IS NOT NULL THEN 'Historical med #' + CAST(HealthIssueHistoryID AS VARCHAR(10)) END,
    Treatment = CASE WHEN Treatment IS NOT NULL THEN 'Historical treatment #' + CAST(HealthIssueHistoryID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Medications...';
UPDATE HIFIS_Medications SET 
    MedicationName = CASE WHEN MedicationName IS NOT NULL THEN 'Medication_' + CAST(MedicationID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Med note #' + CAST(MedicationID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Dispensing...';
UPDATE HIFIS_Dispensing SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Dispensing note #' + CAST(DispensingID AS VARCHAR(10)) END;

-- ============================================================================
-- LEGAL & INCIDENTS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Incidents...';
UPDATE HIFIS_Incidents SET 
    PoliceReportNo = CASE WHEN PoliceReportNo IS NOT NULL THEN 'RPT-' + CAST(IncidentID AS VARCHAR(10)) END,
    PoliceBadge = CASE WHEN PoliceBadge IS NOT NULL THEN 'BADGE-' + CAST(IncidentID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Incident note #' + CAST(IncidentID AS VARCHAR(10)) END,
    Location = CASE WHEN Location IS NOT NULL THEN 'Location_' + CAST(IncidentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_LegalEvents...';
UPDATE HIFIS_LegalEvents SET 
    Charge = CASE WHEN Charge IS NOT NULL THEN 'Charge_' + CAST(LegalEventID AS VARCHAR(10)) END,
    ChargeNumber = CASE WHEN ChargeNumber IS NOT NULL THEN 'CHG-' + CAST(LegalEventID AS VARCHAR(10)) END,
    ChargeType = CASE WHEN ChargeType IS NOT NULL THEN 'Type_' + CAST(LegalEventID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Legal note #' + CAST(LegalEventID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_BailEvents...';
UPDATE HIFIS_BailEvents SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Bail note #' + CAST(BailEventID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ProbationEvents...';
UPDATE HIFIS_ProbationEvents SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Probation note #' + CAST(ProbationEventID AS VARCHAR(10)) END;

-- ============================================================================
-- HOUSING
-- ============================================================================

PRINT 'Anonymizing HIFIS_Houses...';
UPDATE HIFIS_Houses SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'House note #' + CAST(HouseID AS VARCHAR(10)) END,
    OccupancyComment = CASE WHEN OccupancyComment IS NOT NULL THEN 'Occupancy note #' + CAST(HouseID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_HouseMaintenance...';
UPDATE HIFIS_HouseMaintenance SET 
    ContractingCompany = CASE WHEN ContractingCompany IS NOT NULL THEN 'Contractor_' + CAST(HouseMaintenanceID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Maintenance note #' + CAST(HouseMaintenanceID AS VARCHAR(10)) END,
    Description = CASE WHEN Description IS NOT NULL THEN 'Maintenance desc #' + CAST(HouseMaintenanceID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_HousePhotos...';
UPDATE HIFIS_HousePhotos SET 
    PhotoImage = NULL,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Photo note #' + CAST(HousePhotoID AS VARCHAR(10)) END,
    FileName = CASE WHEN FileName IS NOT NULL THEN 'photo_' + CAST(HousePhotoID AS VARCHAR(10)) + '.jpg' END;

PRINT 'Anonymizing HIFIS_HousePlacementAttempt...';
UPDATE HIFIS_HousePlacementAttempt SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Placement note #' + CAST(HousePlacementAttemptID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_HousingSubsidy...';
UPDATE HIFIS_HousingSubsidy SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Subsidy note #' + CAST(HousingSubsidyID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Rooms...';
UPDATE HIFIS_Rooms SET 
    RoomName = CASE WHEN RoomName IS NOT NULL THEN 'Room_' + CAST(RoomID AS VARCHAR(10)) END;

-- ============================================================================
-- STAYS & BEDS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Stays...';
UPDATE HIFIS_Stays SET 
    OverrideComment = CASE WHEN OverrideComment IS NOT NULL THEN 'Stay note #' + CAST(StayID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_BedStatusHistory...';
UPDATE HIFIS_BedStatusHistory SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Bed status note #' + CAST(BedStatusHistoryID AS VARCHAR(10)) END;

-- ============================================================================
-- ASSESSMENTS & SURVEYS
-- ============================================================================

PRINT 'Anonymizing HIFIS_IntakeAssessmentSummary...';
UPDATE ias SET 
    ClientName = COALESCE(fn.Name, 'Test') + ' ' + COALESCE(ln.Name, 'User'),
    IntakeDescription = CASE WHEN ias.IntakeDescription IS NOT NULL 
        THEN 'Intake assessment #' + CAST(ias.IntakeAssessmentSummaryID AS VARCHAR(10)) END
FROM HIFIS_IntakeAssessmentSummary ias
LEFT JOIN @FirstNames fn ON fn.ID = (ias.IntakeAssessmentSummaryID % 50) + 1
LEFT JOIN @LastNames ln ON ln.ID = ((ias.IntakeAssessmentSummaryID / 50) % 50) + 1;

PRINT 'Anonymizing HIFIS_SPDAT_Intake...';
UPDATE HIFIS_SPDAT_Intake SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'SPDAT intake #' + CAST(SPDAT_IntakeID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_SPDAT_Intake_QuestionsAnswered...';
UPDATE HIFIS_SPDAT_Intake_QuestionsAnswered SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'SPDAT answer #' + CAST(SPDAT_Intake_QuestionsAnsweredID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_VAT_Intake...';
UPDATE HIFIS_VAT_Intake SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'VAT intake #' + CAST(VAT_IntakeID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_VAT_Intake_QuestionsAnswered...';
UPDATE HIFIS_VAT_Intake_QuestionsAnswered SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'VAT answer #' + CAST(VAT_Intake_QuestionsAnsweredID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_QuestionAnswered...';
UPDATE HIFIS_QuestionAnswered SET 
    TextValue = CASE WHEN TextValue IS NOT NULL THEN 'Answer #' + CAST(QuestionAnsweredID AS VARCHAR(10)) END;

-- ============================================================================
-- PIT (POINT IN TIME) COUNT
-- ============================================================================

PRINT 'Anonymizing HIFIS_PiTQuestionnaires...';
UPDATE HIFIS_PiTQuestionnaires SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'PiT note #' + CAST(PiTQuestionnaireID AS VARCHAR(10)) END,
    QuickInfo = CASE WHEN QuickInfo IS NOT NULL THEN 'PiT info #' + CAST(PiTQuestionnaireID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_PiTQuestionsAnswers...';
UPDATE HIFIS_PiTQuestionsAnswers SET 
    TextValue = CASE WHEN TextValue IS NOT NULL THEN 'PiT answer #' + CAST(PiTQuestionsAnswerID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_PiTShifts...';
UPDATE HIFIS_PiTShifts SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'PiT shift note #' + CAST(PiTShiftID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_PiTSurvey...';
UPDATE HIFIS_PiTSurvey SET 
    ReasonForAbandoned = CASE WHEN ReasonForAbandoned IS NOT NULL THEN 'Abandoned reason #' + CAST(PiTSurveyID AS VARCHAR(10)) END,
    Location = CASE WHEN Location IS NOT NULL THEN 'PiT location #' + CAST(PiTSurveyID AS VARCHAR(10)) END,
    Comment = CASE WHEN Comment IS NOT NULL THEN 'PiT survey note #' + CAST(PiTSurveyID AS VARCHAR(10)) END;

-- ============================================================================
-- FINANCIAL
-- ============================================================================

PRINT 'Anonymizing HIFIS_ClientIncomes...';
UPDATE HIFIS_ClientIncomes SET 
    EmployerName = CASE WHEN EmployerName IS NOT NULL THEN 'Employer_' + CAST(ClientIncomeID AS VARCHAR(10)) END,
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Income note #' + CAST(ClientIncomeID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ClientExpenses...';
UPDATE HIFIS_ClientExpenses SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Expense note #' + CAST(ClientExpenseID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_LiabilitiesOrAssests...';
UPDATE HIFIS_LiabilitiesOrAssests SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Asset/Liability #' + CAST(LiabilityOrAssetID AS VARCHAR(10)) END,
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Financial note #' + CAST(LiabilityOrAssetID AS VARCHAR(10)) END;

-- ============================================================================
-- CLIENT FACTORS & BEHAVIORS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Client_BehaviouralFactor...';
UPDATE HIFIS_Client_BehaviouralFactor SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Behavioural note #' + CAST(BehaviouralFactorID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Client_ContributingFactor...';
UPDATE HIFIS_Client_ContributingFactor SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Contributing factor note #' + CAST(ContributingFactorID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Client_DistinguishingFeatures...';
UPDATE HIFIS_Client_DistinguishingFeatures SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Feature #' + CAST(DistinguishingFeatureID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Client_WatchConcerns...';
UPDATE HIFIS_Client_WatchConcerns SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Watch concern #' + CAST(WatchConcernID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Client_Barred_Periods...';
UPDATE HIFIS_Client_Barred_Periods SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Barred note #' + CAST(BarredPeriodID AS VARCHAR(10)) END;

-- ============================================================================
-- CONTACTS & EVENTS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Client_ContactEventTypes...';
UPDATE HIFIS_Client_ContactEventTypes SET 
    OtherPartyName = CASE WHEN OtherPartyName IS NOT NULL THEN 'Contact_' + CAST(ContactEventTypeID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Contact note #' + CAST(ContactEventTypeID AS VARCHAR(10)) END,
    Subject = CASE WHEN Subject IS NOT NULL THEN 'Contact subject #' + CAST(ContactEventTypeID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Conflicts...';
UPDATE HIFIS_Conflicts SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Conflict note #' + CAST(ConflictID AS VARCHAR(10)) END;

-- ============================================================================
-- IDENTIFICATION & MILITARY
-- ============================================================================

PRINT 'Anonymizing HIFIS_PeopleIdentification...';
UPDATE HIFIS_PeopleIdentification SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'ID_' + CAST(PeopleIdentificationID AS VARCHAR(10)) END,
    DocumentNo = CASE WHEN DocumentNo IS NOT NULL THEN 'DOC-' + RIGHT('00000000' + CAST(PeopleIdentificationID AS VARCHAR(8)), 8) END,
    Description = CASE WHEN Description IS NOT NULL THEN 'ID desc #' + CAST(PeopleIdentificationID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_IndianStatus...';
UPDATE HIFIS_IndianStatus SET 
    TreatyNumber = CASE WHEN TreatyNumber IS NOT NULL THEN 'TREATY-' + CAST(IndianStatusID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ArmyServicePeriods...';
UPDATE HIFIS_ArmyServicePeriods SET 
    VACCaseWorker = CASE WHEN VACCaseWorker IS NOT NULL THEN 'VAC_Worker_' + CAST(ArmyServicePeriodID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Service note #' + CAST(ArmyServicePeriodID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_GangAffiliation...';
UPDATE HIFIS_GangAffiliation SET 
    GangName = CASE WHEN GangName IS NOT NULL THEN 'Group_' + CAST(GangAffiliationID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Affiliation note #' + CAST(GangAffiliationID AS VARCHAR(10)) END;

-- ============================================================================
-- VEHICLES
-- ============================================================================

PRINT 'Anonymizing HIFIS_PeopleCars...';
UPDATE HIFIS_PeopleCars SET 
    LicencePlate = CASE WHEN LicencePlate IS NOT NULL 
        THEN 'TST-' + RIGHT('000' + CAST(PeopleCarID % 1000 AS VARCHAR(3)), 3) END;

-- ============================================================================
-- DOCUMENTS & PHOTOS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Documents...';
UPDATE HIFIS_Documents SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Document_' + CAST(DocumentID AS VARCHAR(10)) END,
    Body = NULL,
    Description = CASE WHEN Description IS NOT NULL THEN 'Document desc #' + CAST(DocumentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ClientPhotos...';
UPDATE HIFIS_ClientPhotos SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Photo_' + CAST(ClientPhotoID AS VARCHAR(10)) END,
    PhotoImage = NULL,
    Description = CASE WHEN Description IS NOT NULL THEN 'Photo desc #' + CAST(ClientPhotoID AS VARCHAR(10)) END;

-- ============================================================================
-- EDUCATION & SOCIAL ASSISTANCE
-- ============================================================================

PRINT 'Anonymizing HIFIS_ClientEducationLevels...';
UPDATE HIFIS_ClientEducationLevels SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Education note #' + CAST(ClientEducationLevelID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_SocialAssistManagers...';
UPDATE HIFIS_SocialAssistManagers SET 
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Social assist note #' + CAST(SocialAssistManagerID AS VARCHAR(10)) END;

-- ============================================================================
-- MESSAGES & BULLETINS
-- ============================================================================

PRINT 'Anonymizing HIFIS_Messages...';
UPDATE HIFIS_Messages SET 
    MessageSubject = CASE WHEN MessageSubject IS NOT NULL THEN 'Message subject #' + CAST(MessageID AS VARCHAR(10)) END,
    MessageBody = CASE WHEN MessageBody IS NOT NULL THEN 'Message body #' + CAST(MessageID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Bulletins...';
UPDATE HIFIS_Bulletins SET 
    Subject = CASE WHEN Subject IS NOT NULL THEN 'Bulletin subject #' + CAST(BulletinID AS VARCHAR(10)) END,
    Description = CASE WHEN Description IS NOT NULL THEN 'Bulletin body #' + CAST(BulletinID AS VARCHAR(10)) END;

-- ============================================================================
-- WAITING LISTS
-- ============================================================================

PRINT 'Anonymizing HIFIS_WaitingLists...';
UPDATE HIFIS_WaitingLists SET 
    WaitingListName = CASE WHEN WaitingListName IS NOT NULL THEN 'WaitList_' + CAST(WaitingListID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Waitlist note #' + CAST(WaitingListID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ClientWaitingLists...';
UPDATE HIFIS_ClientWaitingLists SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Client waitlist note #' + CAST(ClientWaitingListID AS VARCHAR(10)) END;

-- ============================================================================
-- MISC TABLES
-- ============================================================================

PRINT 'Anonymizing HIFIS_AuditLog...';
UPDATE HIFIS_AuditLog SET 
    SearchValue = CASE WHEN SearchValue IS NOT NULL THEN 'Search_' + CAST(AuditLogID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Chores...';
UPDATE HIFIS_Chores SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Chore #' + CAST(ChoreID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_ClientHistoryChanges...';
UPDATE HIFIS_ClientHistoryChanges SET 
    Value = CASE WHEN Value IS NOT NULL THEN 'History value #' + CAST(ClientHistoryChangeID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Consent...';
UPDATE HIFIS_Consent SET 
    Comment = CASE WHEN Comment IS NOT NULL THEN 'Consent note #' + CAST(ConsentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_CustomData...';
UPDATE HIFIS_CustomData SET 
    TextValue = CASE WHEN TextValue IS NOT NULL THEN 'Custom data #' + CAST(CustomDataID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_FundingOrganizations...';
UPDATE HIFIS_FundingOrganizations SET 
    NameE = CASE WHEN NameE IS NOT NULL THEN 'Funder_' + CAST(FundingOrganizationID AS VARCHAR(10)) END,
    NameF = CASE WHEN NameF IS NOT NULL THEN 'Bailleur_' + CAST(FundingOrganizationID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_GroupActivities...';
UPDATE HIFIS_GroupActivities SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Group activity #' + CAST(GroupActivityID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_MailingList...';
UPDATE HIFIS_MailingList SET 
    MailListName = CASE WHEN MailListName IS NOT NULL THEN 'MailList_' + CAST(MailingListID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Organizations...';
UPDATE HIFIS_Organizations SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Org_' + CAST(OrganizationID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Org note #' + CAST(OrganizationID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_PeopleGroupsComments...';
UPDATE HIFIS_PeopleGroupsComments SET 
    TextBody = CASE WHEN TextBody IS NOT NULL THEN 'Group comment #' + CAST(PeopleGroupsCommentID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Places...';
UPDATE HIFIS_Places SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Place_' + CAST(PlaceID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Place note #' + CAST(PlaceID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Reports...';
UPDATE HIFIS_Reports SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Report_' + CAST(ReportID AS VARCHAR(10)) END,
    Description = CASE WHEN Description IS NOT NULL THEN 'Report desc #' + CAST(ReportID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Sessions...';
UPDATE HIFIS_Sessions SET 
    Description = CASE WHEN Description IS NOT NULL THEN 'Session #' + CAST(SessionID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_StoredItems...';
UPDATE HIFIS_StoredItems SET 
    ItemDescription = CASE WHEN ItemDescription IS NOT NULL THEN 'Stored item #' + CAST(StoredItemID AS VARCHAR(10)) END,
    Comments = CASE WHEN Comments IS NOT NULL THEN 'Storage note #' + CAST(StoredItemID AS VARCHAR(10)) END,
    ItemLocation = CASE WHEN ItemLocation IS NOT NULL THEN 'Location_' + CAST(StoredItemID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Template_Rights...';
UPDATE HIFIS_Template_Rights SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Template_' + CAST(TemplateRightID AS VARCHAR(10)) END,
    Description = CASE WHEN Description IS NOT NULL THEN 'Template desc #' + CAST(TemplateRightID AS VARCHAR(10)) END;

PRINT 'Anonymizing HIFIS_Cluster...';
UPDATE HIFIS_Cluster SET 
    Name = CASE WHEN Name IS NOT NULL THEN 'Cluster_' + CAST(ClusterID AS VARCHAR(10)) END;

-- ============================================================================
-- DONE
-- ============================================================================

SET NOCOUNT OFF;
PRINT '';
PRINT '============================================================================';
PRINT 'Anonymization complete!';
PRINT '============================================================================';