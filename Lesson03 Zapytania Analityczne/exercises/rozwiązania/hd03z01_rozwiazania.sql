USE [AdventureworksDW2016CTP3]
GO
--	
--	Przygotowanie danych
------------------------------------------------------

	IF OBJECT_ID('tempdb..#Dane') IS NOT NULL DROP TABLE #Dane

	SELECT 
		a.AccountType			, 
		o.OrganizationName		,
		d.[DepartmentGroupName]	,
		SUM(f.Amount)		AS [Amount]
	INTO #Dane
	FROM 
				[dbo].[FactFinance]			AS	f
	INNER JOIN	[dbo].[DimAccount]			AS	a	ON [a].AccountKey			= [f].[AccountKey]
	INNER JOIN	[dbo].[DimOrganization]		AS	o	ON [o].OrganizationKey		= [f].[OrganizationKey]
	INNER JOIN	[dbo].[DimDepartmentGroup]	AS	d	ON [d].[DepartmentGroupKey] = [f].[DepartmentGroupKey]
	GROUP BY
		a.[AccountType]			, 
		o.[OrganizationName]	,
		d.[DepartmentGroupName]	

	SELECT TOP 10 *
	FROM [#Dane]

--	(1)
--	Pogupowa� #Dane po Account Type
--	Dla ka�dego Account Type wy�wietli�:
--	nazwa
--	liczb� wierszy w grupie
--	Sum� pozycji Amount
--	MAX, MIN i AVG na kolumnie Amount
------------------------------------------------------

	SELECT 
		d.AccountType	
	,	COUNT(*)			AS [cnt]
	,	MIN(d.Amount)		AS [min_Amount]
	,	MAX(d.Amount)		AS [max_Amount]
	,	AVG(d.Amount)		AS [avg_Amount]
	,	SUM(d.Amount)		AS [Amount]
	FROM [#Dane] AS d
	GROUP BY
		d.AccountType

--	(2)
--	To Samo co w (1)
--	dodatkowo wy�wietli� wiersz z TOTALem - grupowanie wszystkiego po ca�o�ci (np. za pomoc� ROLLUP)
--	posortowa� tak, �eby TOTAL by� na samej g�rze
--	dla TOTAL podmieni� kolumn� AccountType na "Total"
------------------------------------------------------

	SELECT 
		CASE
			WHEN GROUPING_ID(d.AccountType) = 1
			THEN 'TOTAL'
			ELSE d.AccountType	
			END
	,	COUNT(*)
	,	MIN(d.Amount)
	,	MAX(d.Amount)
	,	SUM(d.Amount)
	,	SUM(d.Amount)		AS [Amount]
	FROM [#Dane] AS d
	GROUP BY ROLLUP(d.AccountType)
	ORDER BY GROUPING_ID(d.AccountType) DESC

--	(3)
--	To Samo co w (1)
--	maj� pojawi� si� nast�puj�ce grupy: 
	--	[AccountType]			-	podzia� per konto
	--	[OrganizationName]		-	podzia� per organizacja
	--	[DepartmentGroupName]	-	podzia� per department
--	posortowa� tak, �eby nie miesza�y si� mi�dzy sob� grupowania -> najpierw AT, potem ON, potem DG
------------------------------------------------------

	SELECT 
		d.AccountType
	,	d.OrganizationName
	,	d.DepartmentGroupName	
	,	COUNT(*)
	,	MAX(d.Amount)
	,	SUM(d.Amount)
	,	SUM(d.Amount)			AS [Amount]
	FROM [#Dane] AS d
	GROUP BY GROUPING SETS(	(d.AccountType)			,
							(d.OrganizationName)	,
							(d.DepartmentGroupName)
						)
	ORDER BY GROUPING_ID(d.AccountType, OrganizationName,d.DepartmentGroupName)

--	(4)
--	To Samo co w (3), ale zrobi� jedn� kolumn� w kt�rej pojawi si� nazwa AT/ON/DG
--	oraz kolumn� [TypGrupowania] kt�ra przyjmie warto�ci AT, ON, DG w zale�no�ci od tego, po czym grupujemy
------------------------------------------------------

	SELECT
		CASE GROUPING_ID(d.AccountType, OrganizationName,d.DepartmentGroupName)
			WHEN 3 THEN	'AT'
			WHEN 5 THEN	'ON'
			WHEN 6 THEN	'DG'
			END [TypGrupowania] 
	,	CASE GROUPING_ID(d.AccountType, OrganizationName,d.DepartmentGroupName)
			WHEN 3 THEN	d.AccountType
			WHEN 5 THEN	d.OrganizationName
			WHEN 6 THEN	d.DepartmentGroupName
			END [Pozycja] 	
	,	COUNT(*)
	,	MAX(d.Amount)
	,	SUM(d.Amount)
	,	SUM(d.Amount)			AS [Amount]
	FROM [#Dane] AS d
	GROUP BY GROUPING SETS(	(d.AccountType)			,
							(d.OrganizationName)	,
							(d.DepartmentGroupName)
						)
	ORDER BY GROUPING_ID(d.AccountType, OrganizationName,d.DepartmentGroupName)