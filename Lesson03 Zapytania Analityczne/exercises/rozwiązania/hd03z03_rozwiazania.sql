USE [AdventureworksDW2016CTP3]
GO
--	Przygotowanie danych:
--	wyci�gamy konta Aktyw�w, wg dat
------------------------------------------------------

	IF OBJECT_ID('tempdb..#Dane')			IS NOT NULL DROP TABLE #Dane
	IF OBJECT_ID('tempdb..#DaneAggr')		IS NOT NULL DROP TABLE #DaneAggr

	SELECT 
		f.[Date]			AS [Date],
		SUM(f.Amount)		AS [Amount]
	INTO #Dane
	FROM 
				[dbo].[FactFinance]				AS	f
	INNER JOIN	[dbo].[DimAccount]				AS	a	ON [a].AccountKey			= [f].[AccountKey]
	INNER JOIN	[dbo].[DimOrganization]			AS	o	ON [o].OrganizationKey		= [f].[OrganizationKey]
	INNER JOIN	[dbo].[DimDepartmentGroup]		AS	d	ON [d].[DepartmentGroupKey] = [f].[DepartmentGroupKey]
	WHERE 1=1
	AND a.[AccountType] = 'Assets'
	GROUP BY
		f.[Date]
	;

--	(1)
--	pokaza� stan na koniec kwarta�u (zostawi� tylko ostatnie daty w kwartale)
--	CTE + ROW_NUMBER() <- bardzo cz�ste po��czenie
------------------------------------------------------
	
	WITH cte_name AS
	(
		SELECT
			ROW_NUMBER() OVER (	PARTITION BY	YEAR([Date]),
												FLOOR((MONTH([Date])-1) / 3)
								ORDER BY [Date] DESC
								) AS [rn]
		,	YEAR([Date])	AS [yr]
		,	FLOOR((MONTH([Date])-1) / 3) + 1 AS [qt]
		,	[Date]
		,	[Amount]
		FROM #Dane
	)
	SELECT 
		[Date]
	,	'Y' + CAST([yr] AS VARCHAR(4)) + '/Q' +CAST([qt] AS VARCHAR(1)) AS [qt]
	,	[Amount]
	INTO #DaneAggr
	FROM cte_name
	WHERE [rn] = 1

	SELECT *
	FROM #DaneAggr

--	(2)
--	wykorzystuj�c dane z (1) przygotowa� raport pokazuj�cy zmian� wzgl�dn� oraz bezwzgl�dn� pomi�dzy nast�puj�cymi po sobie kwarta�ami
------------------------------------------------------

	SELECT	[qt]
        ,	[Amount]
		,	[Diff]		=	ROUND([Amount] - LAG([Amount]) OVER (ORDER BY [Date])											, 2)
		,	[DiffPrc]	=	ROUND(([Amount] - LAG([Amount]) OVER (ORDER BY [Date])) / LAG([Amount]) OVER (ORDER BY [Date])	, 2)
	FROM #DaneAggr
	ORDER BY [Date]