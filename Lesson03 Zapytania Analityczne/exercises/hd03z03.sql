USE [AdventureworksDW2016CTP3]
GO
--	Przygotowanie danych:
--	wyci�gamy konta Aktyw�w, wg dat
------------------------------------------------------

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

--	(2)
--	wykorzystuj�c dane z (1) przygotowa� raport pokazuj�cy zmian� wzgl�dn� oraz bezwzgl�dn� pomi�dzy nast�puj�cymi po sobie kwarta�ami
------------------------------------------------------
