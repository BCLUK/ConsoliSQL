-- =====================================================================================================
-- Author:		Tony Tasker
-- Create date: 18/01/2017
-- Description:	This script can be used to configure CABS AutoEMail for SHU
--
-- =====================================================================================================
-- Version:		2
-- Date:		25/01/2017
-- =====================================================================================================
-- Changes:	TT: 18/01/2017: Original Version
--  (1)
-- Changes:	TT: 25/01/2017: Changed date from '2016-06-15 09:30:00' to '2016-06-01 09:30:00' as it
--  (2)						generated an out of bounds error when run at SHU
-- =====================================================================================================
SET NOCOUNT ON 
GO
 
/* 
	INSERT Record into AEF_LINK for the weekly report email for Uninvoiced Event
*/

IF NOT EXISTS (SELECT AEFL_FREF FROM AEF_LINK WHERE AEFL_FREF = 'FFFFFFF')
	INSERT INTO AEF_LINK
		(AEFL_FREF, AEFL_SessNo, AEFL_EmailType, AEFL_CanSend, AEFL_FDay, AEFL_SENT, AEFL_SendTime, AEFL_Source, AEFL_Department, AEFL_EmailSPROC)
		VALUES ('FFFFFFF', '', 'AEFUIE', 1, '2016-06-01 00:00:01.000', 1, '2016-06-01 09:30:00', 'UPDATE:STATUS', 'CCHIRE', 'CABS_AEF_SEND_UIE')


/* 
	INSERT Record into AEF_LINK for the weekly report email for Uninvoiced Event
*/
IF NOT EXISTS (SELECT AEFL_FREF FROM AEF_LINK WHERE AEFL_FREF = 'FFFFFFE')
	INSERT INTO AEF_LINK
		(AEFL_FREF, AEFL_SessNo, AEFL_EmailType, AEFL_CanSend, AEFL_FDay, AEFL_SENT, AEFL_SendTime, AEFL_Source, AEFL_Department, AEFL_EmailSPROC)
		VALUES ('FFFFFFE', '', 'AEFUPE', 1, '2016-06-01 00:00:01.000', 1, '2016-06-01 09:30:00', 'UPDATE:STATUS', 'CCHIRE', 'CABS_AEF_SEND_UPE')

/* 
	INSERT Record into AEF_LINK for the weekly summary reminder email
*/
IF NOT EXISTS (SELECT AEFL_FREF FROM AEF_LINK WHERE AEFL_FREF = 'FFFFFFD')
	INSERT INTO AEF_LINK
		(AEFL_FREF, AEFL_SessNo, AEFL_EmailType, AEFL_CanSend, AEFL_FDay, AEFL_SENT, AEFL_SendTime, AEFL_Source, AEFL_Department, AEFL_EmailSPROC)
		VALUES ('FFFFFFD', '', 'AEFSWR', 0, '2016-06-01 00:00:01.000', 1, '2016-06-01 09:30:00', 'UPDATE:STATUS', 'CCHIRE', 'CABS_AEF_SEND_SWR')


/* Delete autoemail queue except for the the system records */
DELETE AEF_LINK WHERE AEFL_FREF NOT IN ('FFFFFFD', 'FFFFFFE','FFFFFFF')

/* Shows only 3 records in autoemail queue */
SELECT * FROM vw_AEFLINK

/* Ensure table AutoEmailFunction is empty */
DELETE AutoEmailFunction

/* Shows no records in AutoEmailFunction */
SELECT * FROM AutoEmailFunction


