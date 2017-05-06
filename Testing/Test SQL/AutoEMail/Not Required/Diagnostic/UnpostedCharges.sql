DECLARE @FuncNo VARCHAR(7) = 'INSERT FUNCTION REFERENCE'

DECLARE @FuncValue Money
DECLARE @RoomCharge Money
DECLARE @ExtraCharge Money
DECLARE @PackageCharge Money
DECLARE @MenuCharge Money
		
SET @FuncValue = 0
SET @RoomCharge = 0
SET @ExtraCharge = 0
SET @PackageCharge = 0
SET @MenuCharge = 0
		
-- FUNCTION CHARGE
SET @RoomCharge = @RoomCharge + 
	( SELECT ISNULL(sum(F_RM_CHG), 0)
		FROM FUNC_FIL
	WHERE F_REF = @FuncNo
		AND F_RM_CHG <> 0
		AND F_CUT <> 1
		AND F_OFFRM <> 1
		AND F_POSTED = 0
		AND ( F_OWNER IS NULL
			OR F_OWNER = ''
			OR F_OWNER = F_REF ) )

-- EXTRAS CHARGES
SET @ExtraCharge = @ExtraCharge +
 	( SELECT ISNULL(sum(AI_COVERS * AI_CHARGE), 0)
		FROM FUNC_FIL, AI_FILE, POST_DEF
	WHERE AI_FREF = @FuncNo
		AND AI_FREF = F_REF
		AND P_CODE = AI_CODE
		AND AI_CHARGE <> 0
		AND AI_POSTED = 0
		AND NOT ( P_COSTCENT = 'CCPAID' ) )

-- PACKAGE CHARGES
SET @PackageCharge = @PackageCharge +
 	( SELECT ISNULL(sum(PH_PRICE * PH_COVERS), 0)
		FROM FUNC_FIL, PKGHEAD
	WHERE PH_OWNER = @FuncNo
		AND F_REF    = PH_OWNER 
		AND PH_POSTED = 0 )

-- MENU CHARGES
SET @MenuCharge = @MenuCharge +
 	( SELECT ISNULL(sum(MNM_PRICE), 0)
		FROM FUNC_FIL, MASTMENU
	WHERE MNM_OWNER = @FuncNo
		AND MNM_OWNER = F_REF
		AND MNM_PRICE <> 0
		AND MNM_POSTED = 0 )

SET @FuncValue = @RoomCharge + @ExtraCharge + @PackageCharge + @MenuCharge

SELECT @RoomCharge AS RoomCharge, @ExtraCharge AS ExtraCharges, @PackageCharge AS PackageCharges, @MenuCharge AS MenuCharges, @FuncValue AS Total