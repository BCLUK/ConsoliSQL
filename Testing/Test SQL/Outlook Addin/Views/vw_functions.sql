SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_functions]
AS
SELECT      F_REF, F_ROOM, RM_NAME, F_DAY, F_START, F_END, F_PAX_ACT, F_MBR_NAME, F_INPROG, F_FINISHED, 
			vw_RoomUses.ST_DESC AS RoomUse, F_INTERN, F_STATUS, vw_RoomStatuses.ST_DESC AS Status_Desc, 
			F_COMMENT, F_COMMENT2, F_CUT, F_OFFRM, RM_LOC, vw_Locations.ST_DESC AS Location_Desc, 
			F_MBR_NO, F_OWNER, F_Startdatetime, F_Enddatetime, 
			  DATEADD(minute,-(Cast(Substring(F_SetUp,4,2) as int)),(DATEADD(hh,-(Cast(Substring(F_SetUp,1,2) as int)),F_Startdatetime))) as StartOccupy,
			  DATEADD(minute,(Cast(Substring(F_BDOWN,4,2) as int)),(DATEADD(hh,-(Cast(Substring(F_BDOWN,1,2) as int)),F_Enddatetime))) as EndOccupy

FROM            FUNC_FIL INNER JOIN
                         SYS_ABBR as vw_RoomStatuses ON FUNC_FIL.F_STATUS = vw_RoomStatuses.ST_CODE INNER JOIN
                         SYS_ABBR as vw_RoomUses ON FUNC_FIL.F_USE = vw_RoomUses.ST_CODE INNER JOIN
                         ROOMS ON FUNC_FIL.F_ROOM = ROOMS.RM_ABBR INNER JOIN
                         SYS_ABBR as vw_Locations ON ROOMS.RM_LOC = vw_Locations.ST_CODE