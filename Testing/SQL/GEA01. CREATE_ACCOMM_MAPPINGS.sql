-- =============================================
-- Author: Mark Birch
-- Script Name: GEA00. CREATE_ACCOMM_MAPPINGS.sql
-- Create date: 27-APR-2016
-- Description:	To insert settings for Global Extras mappings
-- =============================================
-- Usage : Run through SQL Query Analyser
-- Error Handling : None Expected
-- =============================================
-- Version: 2
-- Date: 22/06/2016
-- =============================================
-- Changes: 22/06/2016: MCB: Now includes Client Number 
-- =============================================
SET NOCOUNT ON;

DELETE FROM xCABS_CONFIG_TABLE
WHERE [SECTION] IN('GlobalExtras_AccomCodes')
GO

IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = 'GlobalExtras_AccomCodes' AND [KEY] = 'ACDIS') = 0 
BEGIN 
INSERT INTO xCABS_CONFIG_TABLE
([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
VALUES
('S', '', 'GlobalExtras_AccomCodes', 'ACDIS', 'RW', '0', 'cc', GETUTCDATE())
END
GO
IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = 'GlobalExtras_AccomCodes' AND [KEY] = 'ACSB') = 0 
BEGIN 
INSERT INTO xCABS_CONFIG_TABLE
([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
VALUES
('S', '', 'GlobalExtras_AccomCodes', 'ACSB', 'ASS; DOUDS; DOUTS; ASEPB; RW; DOU; DTB', '0', 'cc', GETUTCDATE())
END
GO
IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = 'GlobalExtras_AccomCodes' AND [KEY] = 'ACSUP') = 0 
BEGIN 
INSERT INTO xCABS_CONFIG_TABLE
([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
VALUES
('S', '', 'GlobalExtras_AccomCodes', 'ACSUP', 'DOU; DTB37', '0', 'cc', GETUTCDATE())
END
GO
IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = 'GlobalExtras_AccomCodes' AND [KEY] = 'ACTR') = 0 
BEGIN 
INSERT INTO xCABS_CONFIG_TABLE
([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
VALUES
('S', '', 'GlobalExtras_AccomCodes', 'ACTR', 'DOUTS; DTB', '0', 'cc', GETUTCDATE())
END
GO
IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = 'GlobalExtras_AccomCodes' AND [KEY] = 'ClientNo') = 0 
BEGIN 
INSERT INTO xCABS_CONFIG_TABLE
([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
VALUES
('S', '', 'GlobalExtras_AccomCodes', 'ClientNo', 'C007906', '0', 'cc', GETUTCDATE())
END
GO
IF (SELECT COUNT(*) FROM xCABS_CONFIG_TABLE WHERE [DELETED] = 0 AND [SECTION] = 'GlobalExtras_AccomCodes' AND [KEY] = 'Include') = 0 
BEGIN 
INSERT INTO xCABS_CONFIG_TABLE
([TYPE], [SOURCE], [SECTION], [KEY], [VALUE], [DELETED], [CHANGE_BY], [CHANGE_UTC])
VALUES
('S', '', 'GlobalExtras_AccomCodes', 'Include', 'ACDIS, ACSB, ACSUP, ACTR', '0', 'cc', GETUTCDATE())
END
GO


