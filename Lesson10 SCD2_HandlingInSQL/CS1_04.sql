
--	sprawdzamy, co ju� jest w tabeli:

	SELECT *
	FROM	[dbo].[DWH_DimEmployeeSCD2]
	ORDER BY PESEL, IsActive

--	odpalamy �adowanie:

	EXEC [dbo].[usp_Reload_DWH_DimEmployeeSCD2]

--	sprawdzamy, czy si� za�adowa�o:

	SELECT *
	FROM	[dbo].[DWH_DimEmployeeSCD2]
	ORDER BY PESEL, IsActive

------------------------------------------------------------------------------------------------

--	wprowadzamy zmiany:

--	1)	Kowalski to tak na prawd� Kowalewski, poprawiamy w HR
--	2)	Mazur dosta�a podwy�k�
--	3)	Dudek awansowa�a

	UPDATE [dbo].[HR_Employees]
	SET EmpLastName = 'Kowalewski'
	WHERE PESEL = '87011001223'

	UPDATE [dbo].[FIN_Payroll]
	SET Salary = 12500
	WHERE PESEL = '67031001223'

	UPDATE [dbo].[ORG_Structure]
	SET JobPosition = 'Specjalista ds. Controllingu'
	WHERE PESEL = '97041001223'

--	odpalamy �adowanie:

	EXEC [dbo].[usp_Reload_DWH_DimEmployeeSCD2]

--	sprawdzamy, czy si� zmieni�o:

	SELECT *
	FROM	[dbo].[DWH_DimEmployeeSCD2]
	ORDER BY PESEL, IsActive

	
--	wprowadzamy zmiany:

--	1)	Dudek Odchodzi
--	2)	Zesp� zmienia nazw� na 'Zesp� ds. Controllingu'
	
	DELETE 
	FROM [dbo].[HR_Employees]
	WHERE PESEL = '97041001223'

	DELETE 
	FROM [dbo].[FIN_Payroll]
	WHERE PESEL = '97041001223'

	DELETE 
	FROM [dbo].[ORG_Structure]
	WHERE PESEL = '97041001223'

	UPDATE [ORG_Structure]
	SET TeamName = 'Zesp� ds. Controllingu'
	WHERE TeamName = 'Zesp� ds. Controllingu i sprawozdawczo�ci Finansowej'

--	odpalamy �adowanie:

	EXEC [dbo].[usp_Reload_DWH_DimEmployeeSCD2]

--	sprawdzamy, czy si� zmieni�o:

	SELECT *
	FROM	[dbo].[DWH_DimEmployeeSCD2]
	ORDER BY PESEL, IsActive
