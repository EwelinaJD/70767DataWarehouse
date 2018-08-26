USE [TestDB]
GO

--	Tabela wymiaru pracownika w HURTOWNI
--------------------------------------------------

	--	w systemach docelowych istniej� ju� klucze g��wne tabel
	--	ale zgodnie z dobrymi praktykami nie b�dziemy ich u�ywa� jako PK w hurtownii
	--	dodajemy klucze surogatowe (techniczne) kt�re nie nios� informacji biznesowej
	--	klucz g��wny z tabeli �r�d�owej jest kopiowany, ale ju� jako atrybut (EmpId)
	--	mo�emy doda� constraint UNIQUE, ale nie musimy

	CREATE TABLE dest.DimEmployee
	(
		DimEmployeeKey	INT				NOT NULL	IDENTITY(1,1) PRIMARY KEY
	,	EmpId			VARCHAR(3)		NOT NULL	UNIQUE
	,	EmpFirstName	VARCHAR(100)	NOT NULL
	,	EmpLastName		VARCHAR(100)	NOT NULL
	)
	GO


--	Tabela fakt�w w HURTOWNI
--------------------------------------------------
	
	--	podobnie jak wy�ej, dodajemy nowy klucz (FactPaymentKey)
	--	dodatkowo b�dziemy chcieli utw�rzy� FK pomi�dzy tabel� Fakt�w i Wymiarem pracownika
	--	kolumn� do ��czenia b�dzie (DimEmployeeKey)
	--	kolumna EmpId przestaje nam by� potrzebna (dublowanie danych)
	--	maj�d DimEmployeeKey b�dziemy mogli j� doci�gn�� zawsze z wymiau - wi�c pomijamy

	CREATE TABLE dest.FactPayment
	(
		FactPaymentKey	INT				NOT NULL	IDENTITY(1,1) PRIMARY KEY 
	,	PaymentId		INT				NOT NULL	UNIQUE
	,	DimEmployeeKey	INT				
	,	DateId			DATE			
	,	Amount			FLOAT
	)
	GO
