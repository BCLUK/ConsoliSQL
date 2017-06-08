SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:                            Peter Green
-- Create date: 01/06/2016
-- Description:   Return info from a booking to match the selection in Outlook TZ
-- =============================================
CREATE FUNCTION [dbo].[utf_get_OutlookFunctionDetails] 
(
                -- Add the parameters for the function here
                @FRef Varchar(10)
)
RETURNS 
@FoundRooms TABLE 
(
       -- Add the column definitions for the TABLE variable here
       RoomScore   Decimal(5,2),
       RoomCode Varchar(10),
       RoomName Varchar(100), 
       UseCode  VARCHAR(10),
       UseDescription Varchar(50),
       US_MIN int,
       US_Max int,
       Covers int,
       LOCN_START_TIME datetime,
       LOCN_END_TIME datetime,
       UTC_START_TIME datetime,
       UTC_END_TIME datetime,
       LOCAL_START_TIME datetime,
       LOCAL_END_TIME datetime,
       LocMatch Varchar(50),
       ActualLoc Varchar(10),
       Location Varchar(50),
       SizeFit Varchar(50),
       UseMatch Varchar(50),
       Occupancy Decimal(8,4)
)
AS
BEGIN
                -- Fill the table variable with the rows for your result set
                Insert Into @FoundRooms
                SELECT '1.00' as RoomScore,
              F_ROOM as RoomCode,
              RM_NAME as RoomNAme,
              F_USE as UseCode,
              rus.ST_DESC as UseDescription,
              US_MIN,
              US_MAX,
              F_PAX_GTD as CoversRequired,
              dbo.uf_getLocalDateTime(RM_LOC,F_STARTDATETIME) as LocalStartDateTime,  --LOCN_START_TIME Varchar(5),
              dbo.uf_getLocalDateTime(RM_LOC,F_ENDDATETIME) as LocalEndDateTime,  --LOCN_END_TIME Varchar(5),
              F_StartdateTime as UTCStartTime,  --UTC_START_TIME Varchar(5),
              F_EndDateTime as UTCEndTime,   --UTC_END_TIME Varchar(5),
              F_START, --LOCAL_START_TIME Varchar(5),
              F_END,   --LOCAL_END_TIME Varchar(5),
              '100 Location Match' as LocMatch, 
              RM_Loc as ActualLoc, 
              loc.ST_Desc as Location, 
              100, 
                dbo.uf_OutlookRoomFit(F_PAX_GTD,RM_ABBR,uS_RM_USE) as RoomFit,
               (Case US_MAX when 0 then 100.00 else (100.00 * F_PAX_GTD/US_MAX ) end) as occupancy
                     from FUNC_FIL inner join ROOMS 
                                                                                 on F_ROOM = RM_ABBR
                                                                                inner join RM_USE
                     on RM_ABBR = US_RM_CODE and US_RM_USE = F_USE
                     inner join sys_abbr rus on rus.ST_CODE = F_USE and rus.ST_TYPE='RUS'
                     inner join sys_abbr loc on loc.ST_CODE = RM_LOC and loc.ST_TYPE = 'LOC'
                           where F_REF = @FREF
                                                                                                   
                RETURN 
END