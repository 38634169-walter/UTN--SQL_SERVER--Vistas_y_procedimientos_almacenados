GO
USE Larabox;

--1

CREATE VIEW VW_PuntoUno AS
SELECT u.Nombreusuario, tc.Nombre AS [Tipo Cuenta], 
SUM(p.Importe) AS [Total abonado]
FROM Usuarios AS u
INNER JOIN Suscripciones AS s ON s.IDUsuario = u.ID
INNER JOIN TiposCuenta AS tc ON tc.ID = s.IDTipoCuenta
INNER JOIN Pagos AS p ON p.IDSuscripcion = s.ID
GROUP BY u.Nombreusuario, tc.Nombre

SELECT * FROM VW_PuntoUno ORDER BY Nombreusuario



--2
ALTER VIEW VW_PuntoUno AS
SELECT dp.Nombres,dp.Apellidos,u.Nombreusuario,tc.Nombre AS [Tipo Cuenta],
SUM(p.Importe) AS [Total abonado],
CASE
WHEN s.Fin IS NULL
THEN DATEDIFF(DAY,s.Inicio,GETDATE()) 
ELSE DATEDIFF(DAY,s.Inicio,s.Fin) 
END AS [Cantidad dias]
FROM Usuarios AS u
INNER JOIN DatosPersonales AS dp ON dp.ID = u.ID
INNER JOIN Suscripciones AS s ON s.IDUsuario = u.ID
INNER JOIN TiposCuenta AS tc ON tc.ID = s.IDTipoCuenta
INNER JOIN Pagos AS p ON p.IDSuscripcion = s.ID
GROUP BY dp.Nombres,dp.Apellidos,u.Nombreusuario, tc.Nombre,s.Inicio,s.Fin

SELECT * FROM VW_PuntoUno ORDER BY Nombreusuario


--3
SELECT * FROM Archivos 
WHERE Tamaño > (
	SELECT AVG(a.Tamaño) FROM Archivos AS a
	WHERE a.Extension = 'XLS'
)

--4
CREATE PROCEDURE SP_Punto4(
	@ID_Usuario BIGINT
)
AS
BEGIN
	BEGIN TRY
		SELECT dp.Nombres,dp.Apellidos,u.Nombreusuario,a.Nombre AS [Nombre Archivo],
		a.Extension
		FROM Usuarios AS u
		INNER JOIN DatosPersonales AS dp ON u.ID = dp.ID
		INNER JOIN Archivos AS a ON a.IDUsuario =U.ID
		WHERE U.ID = @ID_Usuario
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END

EXEC SP_Punto4 1



--5
ALTER PROCEDURE SP_Punto4(
	@ID_Usuario BIGINT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @costoMaximo MONEY
			SELECT @costoMaximo = MAX(tc.Costo) FROM Usuarios AS u
			INNER JOIN Suscripciones AS s ON s.IDUsuario=u.ID
			INNER JOIN TiposCuenta AS tc ON tc.ID = s.IDTipoCuenta
			WHERE u.ID = @ID_Usuario

			SELECT dp.Nombres,dp.Apellidos,u.Nombreusuario,a.Nombre AS [Nombre Archivo],
			a.Extension, a.Tamaño, tc.Costo / @costoMaximo * 100 AS[Porcenteje] 
			,tc.Nombre
			FROM Usuarios AS u
			INNER JOIN DatosPersonales AS dp ON u.ID = dp.ID
			INNER JOIN Archivos AS a ON a.IDUsuario =U.ID
			INNER JOIN Suscripciones AS s ON s.IDUsuario = u.ID
			INNER JOIN TiposCuenta AS tc ON tc.ID = s.IDTipoCuenta
			WHERE U.ID = @ID_Usuario
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 BEGIN
			ROLLBACK TRANSACTION
		END
		RAISERROR('ERROR AL ... ', 16,1)
	END CATCH
END

EXEC SP_Punto4 1

select * from TiposCuenta

SELECT MAX(tc.Costo) FROM Usuarios AS u
INNER JOIN Suscripciones AS s ON s.IDUsuario=u.ID
INNER JOIN TiposCuenta AS tc ON tc.ID = s.IDTipoCuenta
WHERE u.ID = 1

--6

ALTER PROCEDURE TiposCuenta_InsertaroModificar(
	@ID INT, 
	@nombre VARCHAR(50),
	@cuota INT,
	@costo MONEY
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			IF @ID = 0 BEGIN
				INSERT INTO TiposCuenta(Nombre,Cuota,Costo)
				VALUES (@nombre,@cuota,@costo)
			END
			ELSE BEGIN
				SELECT * FROM TiposCuenta WHERE Cuota = @cuota
				IF @@ROWCOUNT = 0 BEGIN
					UPDATE TiposCuenta SET Nombre=@nombre,Cuota=@cuota,Costo=@costo WHERE ID=@ID
				END
				ELSE BEGIN
					RAISERROR('Ese numero de cuota ya exite',16,1)
				END
			END
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('ERROR NO SE PUDO COMPLETAR LA ACCION',16,1)
	END CATCH
END
EXEC TiposCuenta_InsertaroModificar 1,'Free',1500,0.00

SELECT * FROM TiposCuenta

--7
ALTER PROCEDURE SP_SuscribirUsuario(
	@ID_Usuario BIGINT,
	@ID_TipoCuenta BIGINT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @ID_Suscripcion BIGINT			
			IF(SELECT COUNT(*) FROM Suscripciones WHERE IDUsuario=@ID_Usuario AND Fin IS NULL) > 0 BEGIN
				SELECT @ID_Suscripcion = ID FROM Suscripciones WHERE IDUsuario = @ID_Usuario AND Fin IS NULL
				UPDATE Suscripciones SET Fin=GETDATE() WHERE ID=@ID_Suscripcion
			END
			INSERT INTO Suscripciones(IDUsuario,IDTipoCuenta,Inicio)
			VALUES(@ID_Usuario,@ID_TipoCuenta,GETDATE())
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('ERROR AL ...',16,1)
	END CATCH
END

EXEC SP_SuscribirUsuario 6,4

--8

CREATE PROCEDURE SP_SubirArchivo(
	@ID_Uuario BIGINT,
	@nombre VARCHAR(100),
	@extension VARCHAR(8),
	@tamaño BIGINT
)
AS
BEGIN




SELECT * FROM Archivos WHERE IDUsuario=2

SELECT SUM(a.Tamaño) FROM Archivos AS a
INNER JOIN Usuarios AS u ON u.ID =a.IDUsuario
WHERE u.ID=2

SELECT tc.Cuota,tc.Nombre FROM Usuarios AS u
INNER JOIN Suscripciones AS s ON s.IDUsuario = u.ID
INNER JOIN TiposCuenta AS tc ON tc.ID = s.IDTipoCuenta
WHERE u.ID=2 AND s.Fin is null