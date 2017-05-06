-- ====================================================================================================================
-- Author:		Tony Tasker				
-- Create Date:	22/03/2017
-- Description:	Produces a report of CABS Components including Product, Module and Version information
--				based on SQL Object Extended Properties.
-- Product:		CABS
-- Module:		N/A
-- Parameters:	N/A
-- Returns:		N/A
-- Switches:	N/A
-- Test:		N/A
-- Called By:	N/A
-- Calls:		N/A
-- ====================================================================================================================
-- Version:		1.0
-- Date:		22/03/2017
-- ====================================================================================================================
-- Changes (1.0): TT: 22/03/2017: Original Version
-- ====================================================================================================================

SELECT EP2.value AS [Product]
	  ,EP3.value AS [Module]
	  ,CASE EP.class_desc
		WHEN 'INDEX' THEN
			I.name
		ELSE
			O.name			
		END AS [CABS Object]	 
	  ,EP.value AS [Version]
	  ,O.type AS [Type]	  
	  ,CASE EP.class_desc 
		WHEN 'INDEX' THEN
			EP.class_desc  + ' (on Table: ' + O.name +	')' COLLATE SQL_Latin1_General_CP1_CI_AS
		ELSE
			O.type_desc 
		END AS [Description] 
	  ,O.create_date AS [Create Date]
	  ,O.modify_date AS [Modify Date]  
FROM sys.extended_properties EP
INNER JOIN sys.extended_properties EP2 ON EP.major_id = EP2.major_id
INNER JOIN sys.extended_properties EP3 ON EP2.major_id = EP3.major_id
LEFT JOIN sys.all_objects O ON ep.major_id = O.object_id 
LEFT JOIN sys.indexes AS I ON ep.major_id = I.object_id AND EP.minor_id = I.index_id
WHERE ep.name = 'Version' AND EP2.name = 'Product' AND EP3.name = 'Module'
GROUP BY EP2.value
		,EP3.value
		,EP.class_desc
		,I.name
		,O.name			
		,EP.value
		,O.type
	  	,O.type_desc 		
	    ,O.create_date
	    ,O.modify_date
	  

	 