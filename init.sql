
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF DB_ID(N'ComercialLaEstrella') IS NULL
    CREATE DATABASE ComercialLaEstrella;
GO

USE ComercialLaEstrella;
GO

/* =====================================================================
   1. TABLAS Y LLAVES
   ===================================================================== */

-- ---------------------------------------------------------------------
-- 1.1 Catálogos de ubicación
-- ---------------------------------------------------------------------

-- PAIS: nombre único
CREATE TABLE PAIS (
    ID_PA       INT IDENTITY(1,1) NOT NULL,
    NOMBRE_PA   NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_PAIS     PRIMARY KEY (ID_PA),
    CONSTRAINT UQ_PAIS_NOM UNIQUE (NOMBRE_PA)
);

-- DEPARTAMENTO: pertenece a un único país; nombre único dentro del país
CREATE TABLE DEPARTAMENTO (
    ID_DEP      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_DEP  NVARCHAR(60)      NOT NULL,
    ID_PA       INT               NOT NULL,
    CONSTRAINT PK_DEPARTAMENTO  PRIMARY KEY (ID_DEP),
    CONSTRAINT FK_DEP_PAIS      FOREIGN KEY (ID_PA) REFERENCES PAIS (ID_PA),
    CONSTRAINT UQ_DEP_PAIS_NOM  UNIQUE (ID_PA, NOMBRE_DEP)
);

-- MUNICIPIO: pertenece a un único departamento; nombre único dentro del depto.
CREATE TABLE MUNICIPIO (
    ID_MUN      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_MUN  NVARCHAR(60)      NOT NULL,
    ID_DEP      INT               NOT NULL,
    CONSTRAINT PK_MUNICIPIO     PRIMARY KEY (ID_MUN),
    CONSTRAINT FK_MUN_DEP       FOREIGN KEY (ID_DEP) REFERENCES DEPARTAMENTO (ID_DEP),
    CONSTRAINT UQ_MUN_DEP_NOM   UNIQUE (ID_DEP, NOMBRE_MUN)
);

-- ---------------------------------------------------------------------
-- 1.2 Catálogos simples (nombre único)
-- ---------------------------------------------------------------------
CREATE TABLE TIPO_TIENDA (
    ID_TIP_TIE      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_TIP_TIE  NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_TIPO_TIENDA     PRIMARY KEY (ID_TIP_TIE),
    CONSTRAINT UQ_TIPO_TIENDA_NOM UNIQUE (NOMBRE_TIP_TIE)
);

CREATE TABLE TIPO_IDENTIFICACION (
    ID_TIP_IDE      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_TIP_IDE  NVARCHAR(30)      NOT NULL,
    CONSTRAINT PK_TIPO_IDENTIFICACION     PRIMARY KEY (ID_TIP_IDE),
    CONSTRAINT UQ_TIPO_IDENTIFICACION_NOM UNIQUE (NOMBRE_TIP_IDE)
);

CREATE TABLE CARGO (
    ID_CAR      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_CAR  NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_CARGO     PRIMARY KEY (ID_CAR),
    CONSTRAINT UQ_CARGO_NOM UNIQUE (NOMBRE_CAR)
);

CREATE TABLE CATEGORIA (
    ID_CAT      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_CAT  NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_CATEGORIA     PRIMARY KEY (ID_CAT),
    CONSTRAINT UQ_CATEGORIA_NOM UNIQUE (NOMBRE_CAT)
);

CREATE TABLE MARCA (
    ID_MAR      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_MAR  NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_MARCA     PRIMARY KEY (ID_MAR),
    CONSTRAINT UQ_MARCA_NOM UNIQUE (NOMBRE_MAR)
);

-- ESTADO_VENTA: REGISTRADA, PENDIENTE, PAGADA y ANULADA
CREATE TABLE ESTADO_VENTA (
    ID_ES_VEN       INT IDENTITY(1,1) NOT NULL,
    NOMBRE_ES_VEN   NVARCHAR(20)      NOT NULL,
    CONSTRAINT PK_ESTADO_VENTA     PRIMARY KEY (ID_ES_VEN),
    CONSTRAINT UQ_ESTADO_VENTA_NOM UNIQUE (NOMBRE_ES_VEN)
);

CREATE TABLE METODO_PAGO (
    ID_MET_PAG      INT IDENTITY(1,1) NOT NULL,
    NOMBRE_MET_PAG  NVARCHAR(30)      NOT NULL,
    CONSTRAINT PK_METODO_PAGO     PRIMARY KEY (ID_MET_PAG),
    CONSTRAINT UQ_METODO_PAGO_NOM UNIQUE (NOMBRE_MET_PAG)
);

-- ---------------------------------------------------------------------
-- 1.3 Núcleo del modelo
-- ---------------------------------------------------------------------

-- PERSONA: supertipo con los datos comunes de empleados y clientes.
CREATE TABLE PERSONA (
    ID_PER          INT IDENTITY(1,1) NOT NULL,
    NOMBRE_PER      NVARCHAR(50)      NOT NULL,
    APELLIDO_PER    NVARCHAR(50)      NOT NULL,
    TELEFONO        VARCHAR(20)       NOT NULL,
    CORREO_PER      NVARCHAR(100)     NULL,
    DIRECCION_PER   NVARCHAR(150)     NOT NULL,
    ID_MUN          INT               NOT NULL,
    CONSTRAINT PK_PERSONA  PRIMARY KEY (ID_PER),
    CONSTRAINT FK_PER_MUN  FOREIGN KEY (ID_MUN) REFERENCES MUNICIPIO (ID_MUN)
);
-- CORREO_PER único pero admite varios NULL: en SQL Server un UNIQUE solo
-- permite un NULL, por eso se usa un índice único filtrado.
CREATE UNIQUE INDEX UQ_PER_CORREO ON PERSONA (CORREO_PER) WHERE CORREO_PER IS NOT NULL;

-- TIENDA: ubicada en un único municipio y de un único tipo
CREATE TABLE TIENDA (
    ID_TI           INT IDENTITY(1,1) NOT NULL,
    NOMBRE_TI       NVARCHAR(100)     NOT NULL,
    DIRECCION_TI    NVARCHAR(150)     NOT NULL,
    TELEFONO_TI     VARCHAR(20)       NOT NULL,
    ID_MUN          INT               NOT NULL,
    ID_TIP_TIE      INT               NOT NULL,
    CONSTRAINT PK_TIENDA   PRIMARY KEY (ID_TI),
    CONSTRAINT FK_TI_MUN   FOREIGN KEY (ID_MUN)     REFERENCES MUNICIPIO (ID_MUN),
    CONSTRAINT FK_TI_TIPO  FOREIGN KEY (ID_TIP_TIE) REFERENCES TIPO_TIENDA (ID_TIP_TIE)
);

-- EMPLEADO: una tienda, un cargo y una única PERSONA (1:1 por UNIQUE)
CREATE TABLE EMPLEADO (
    ID_EMP              INT IDENTITY(1,1) NOT NULL,
    FECHA_CONTRATACION  DATE              NOT NULL,
    ID_TI               INT               NOT NULL,
    ID_CAR              INT               NOT NULL,
    ID_PER              INT               NOT NULL,
    CONSTRAINT PK_EMPLEADO    PRIMARY KEY (ID_EMP),
    CONSTRAINT FK_EMP_TIENDA  FOREIGN KEY (ID_TI)  REFERENCES TIENDA (ID_TI),
    CONSTRAINT FK_EMP_CARGO   FOREIGN KEY (ID_CAR) REFERENCES CARGO (ID_CAR),
    CONSTRAINT FK_EMP_PERSONA FOREIGN KEY (ID_PER) REFERENCES PERSONA (ID_PER),
    CONSTRAINT UQ_EMP_PERSONA UNIQUE (ID_PER)
);

-- CLIENTE: un tipo de identificación y una única PERSONA;
-- (tipo de identificación, número) es único
CREATE TABLE CLIENTE (
    ID_CLI                  INT IDENTITY(1,1) NOT NULL,
    ID_TIP_IDE              INT               NOT NULL,
    NUMERO_IDENTIFICACION   VARCHAR(20)       NOT NULL,
    ID_PER                  INT               NOT NULL,
    CONSTRAINT PK_CLIENTE      PRIMARY KEY (ID_CLI),
    CONSTRAINT FK_CLI_TIPO_IDE FOREIGN KEY (ID_TIP_IDE) REFERENCES TIPO_IDENTIFICACION (ID_TIP_IDE),
    CONSTRAINT FK_CLI_PERSONA  FOREIGN KEY (ID_PER)     REFERENCES PERSONA (ID_PER),
    CONSTRAINT UQ_CLI_PERSONA  UNIQUE (ID_PER),
    CONSTRAINT UQ_CLI_IDENT    UNIQUE (ID_TIP_IDE, NUMERO_IDENTIFICACION)
);

-- PRODUCTO: una única categoría y una única marca
CREATE TABLE PRODUCTO (
    ID_PRO          INT IDENTITY(1,1) NOT NULL,
    NOMBRE_PRO      NVARCHAR(100)     NOT NULL,
    DESCRIPCION_PRO NVARCHAR(255)     NOT NULL,
    ID_CAT          INT               NOT NULL,
    ID_MAR          INT               NOT NULL,
    CONSTRAINT PK_PRODUCTO PRIMARY KEY (ID_PRO),
    CONSTRAINT FK_PRO_CAT  FOREIGN KEY (ID_CAT) REFERENCES CATEGORIA (ID_CAT),
    CONSTRAINT FK_PRO_MAR  FOREIGN KEY (ID_MAR) REFERENCES MARCA (ID_MAR)
);

-- ---------------------------------------------------------------------
-- 1.4 Tablas asociativas y transaccionales
-- ---------------------------------------------------------------------

-- CATALOGO_PRODUCTO: precio vigente y existencia por (tienda, producto)
CREATE TABLE CATALOGO_PRODUCTO (
    PRECIO_VIGENTE_CAT_PRO      DECIMAL(12,2) NOT NULL,
    EXISTENCIA_ACTUAL_CAT_PRO   INT           NOT NULL,
    ID_TI                       INT           NOT NULL,
    ID_PRO                      INT           NOT NULL,
    CONSTRAINT PK_CATALOGO_PRODUCTO PRIMARY KEY (ID_TI, ID_PRO),
    CONSTRAINT FK_CATPRO_TIENDA     FOREIGN KEY (ID_TI)  REFERENCES TIENDA (ID_TI),
    CONSTRAINT FK_CATPRO_PRODUCTO   FOREIGN KEY (ID_PRO) REFERENCES PRODUCTO (ID_PRO),
    CONSTRAINT CK_CATPRO_PRECIO     CHECK (PRECIO_VIGENTE_CAT_PRO > 0),
    CONSTRAINT CK_CATPRO_EXIST      CHECK (EXISTENCIA_ACTUAL_CAT_PRO >= 0)
);

-- VENTA: en una tienda, atendida por un empleado, hecha por un cliente, con un estado
CREATE TABLE VENTA (
    ID_VEN      INT IDENTITY(1,1) NOT NULL,
    FECHA_VEN   DATETIME2(0)      NOT NULL CONSTRAINT DF_VEN_FECHA  DEFAULT SYSDATETIME(),
    ID_TI       INT               NOT NULL,
    ID_EMP      INT               NOT NULL,
    ID_CLI      INT               NOT NULL,
    ID_ES_VEN   INT               NOT NULL CONSTRAINT DF_VEN_ESTADO DEFAULT 1,  -- 1 = REGISTRADA
    CONSTRAINT PK_VENTA        PRIMARY KEY (ID_VEN),
    CONSTRAINT FK_VEN_TIENDA   FOREIGN KEY (ID_TI)     REFERENCES TIENDA (ID_TI),
    CONSTRAINT FK_VEN_EMPLEADO FOREIGN KEY (ID_EMP)    REFERENCES EMPLEADO (ID_EMP),
    CONSTRAINT FK_VEN_CLIENTE  FOREIGN KEY (ID_CLI)    REFERENCES CLIENTE (ID_CLI),
    CONSTRAINT FK_VEN_ESTADO   FOREIGN KEY (ID_ES_VEN) REFERENCES ESTADO_VENTA (ID_ES_VEN)
);

-- DESGLOSE_VENTA: PK (ID_VEN, ID_PRO) impide repetir un producto en la venta.
-- subtotal = cantidad * precio unitario (CHECK)
CREATE TABLE DESGLOSE_VENTA (
    CANTIDAD_DES_VEN        INT           NOT NULL,
    PRECIO_UNITARIO_DES_VEN DECIMAL(12,2) NOT NULL,
    SUBTOTAL_DES_VEN        DECIMAL(12,2) NOT NULL,
    ID_VEN                  INT           NOT NULL,
    ID_PRO                  INT           NOT NULL,
    CONSTRAINT PK_DESGLOSE_VENTA PRIMARY KEY (ID_VEN, ID_PRO),
    CONSTRAINT FK_DES_VENTA      FOREIGN KEY (ID_VEN) REFERENCES VENTA (ID_VEN),
    CONSTRAINT FK_DES_PRODUCTO   FOREIGN KEY (ID_PRO) REFERENCES PRODUCTO (ID_PRO),
    CONSTRAINT CK_DES_CANTIDAD   CHECK (CANTIDAD_DES_VEN > 0),
    CONSTRAINT CK_DES_PRECIO     CHECK (PRECIO_UNITARIO_DES_VEN > 0),
    CONSTRAINT CK_DES_SUBTOTAL   CHECK (SUBTOTAL_DES_VEN = CANTIDAD_DES_VEN * PRECIO_UNITARIO_DES_VEN)
);

-- PAGO: una única venta y un único método de pago; monto > 0
CREATE TABLE PAGO (
    ID_PAG      INT IDENTITY(1,1) NOT NULL,
    MONTO_PAG   DECIMAL(12,2)     NOT NULL,
    ID_MET_PAG  INT               NOT NULL,
    ID_VEN      INT               NOT NULL,
    CONSTRAINT PK_PAGO       PRIMARY KEY (ID_PAG),
    CONSTRAINT FK_PAG_METODO FOREIGN KEY (ID_MET_PAG) REFERENCES METODO_PAGO (ID_MET_PAG),
    CONSTRAINT FK_PAG_VENTA  FOREIGN KEY (ID_VEN)     REFERENCES VENTA (ID_VEN),
    CONSTRAINT CK_PAG_MONTO  CHECK (MONTO_PAG > 0)
);

-- Índices de apoyo para los JOIN de triggers y vistas
CREATE INDEX IX_PAGO_VENTA   ON PAGO (ID_VEN);
CREATE INDEX IX_VENTA_TIENDA ON VENTA (ID_TI);
GO

/* ---------------------------------------------------------------------
   TRIGGER 1: Insert_Detalle — protege el inventario
   Se dispara al insertar en DESGLOSE_VENTA.
     1) La venta debe estar registrada.
     2) El producto debe existir en el catálogo de la tienda de la venta
        y la cantidad no puede superar la existencia → si no, RAISERROR
        'Stock insuficiente' + ROLLBACK.
     3) Si todo es válido, descuenta la cantidad de CATALOGO_PRODUCTO.
   --------------------------------------------------------------------- */
CREATE TRIGGER Insert_Detalle
ON DESGLOSE_VENTA
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Solo se agregan productos a ventas registradas
    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN VENTA v        ON v.ID_VEN    = i.ID_VEN
               INNER JOIN ESTADO_VENTA e ON e.ID_ES_VEN = v.ID_ES_VEN
               WHERE e.NOMBRE_ES_VEN <> 'REGISTRADA')
    BEGIN
        RAISERROR('Solo se pueden agregar productos a ventas en estado REGISTRADA', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2) Validar stock en la tienda de cada venta.
    --    Se agrupa por (tienda, producto) por si el INSERT trae varias filas.
    --    LEFT JOIN: si el producto no está en el catálogo de esa tienda,
    --    c.ID_PRO queda NULL y también se rechaza.
    IF EXISTS (SELECT 1
               FROM (SELECT v.ID_TI, i.ID_PRO, SUM(i.CANTIDAD_DES_VEN) AS CANTIDAD
                     FROM inserted i
                     INNER JOIN VENTA v ON v.ID_VEN = i.ID_VEN
                     GROUP BY v.ID_TI, i.ID_PRO) s
               LEFT JOIN CATALOGO_PRODUCTO c ON c.ID_TI  = s.ID_TI
                                            AND c.ID_PRO = s.ID_PRO
               WHERE c.ID_PRO IS NULL
                  OR s.CANTIDAD > c.EXISTENCIA_ACTUAL_CAT_PRO)
    BEGIN
        RAISERROR('Stock insuficiente', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 3) Descontar el inventario de la tienda
    UPDATE c
    SET c.EXISTENCIA_ACTUAL_CAT_PRO = c.EXISTENCIA_ACTUAL_CAT_PRO - s.CANTIDAD
    FROM CATALOGO_PRODUCTO c
    INNER JOIN (SELECT v.ID_TI, i.ID_PRO, SUM(i.CANTIDAD_DES_VEN) AS CANTIDAD
                FROM inserted i
                INNER JOIN VENTA v ON v.ID_VEN = i.ID_VEN
                GROUP BY v.ID_TI, i.ID_PRO) s
            ON s.ID_TI = c.ID_TI AND s.ID_PRO = c.ID_PRO;
END;
GO

/* ---------------------------------------------------------------------
   TRIGGER 2: Insert_Pago — Estado automático de la venta
   Se dispara al insertar en PAGO.
     1) No se aceptan pagos a ventas ANULADA ni a ventas ya PAGADA.
     2) Suma TODOS los pagos de la venta y los compara con el total
        (suma de SUBTOTAL_DES_VEN). Si pagado >= total procede a  estado PAGADA.
   --------------------------------------------------------------------- */
CREATE TRIGGER Insert_Pago
ON PAGO
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Los ids se buscan por nombre para no depender de números fijos
    DECLARE @PAGADA  INT = (SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = 'PAGADA');
    DECLARE @ANULADA INT = (SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = 'ANULADA');

    -- 1) Validaciones
    IF EXISTS (SELECT 1 FROM inserted i
               INNER JOIN VENTA v ON v.ID_VEN = i.ID_VEN
               WHERE v.ID_ES_VEN = @ANULADA)
    BEGIN
        RAISERROR('No se pueden registrar pagos a una venta ANULADA', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM inserted i
               INNER JOIN VENTA v ON v.ID_VEN = i.ID_VEN
               WHERE v.ID_ES_VEN = @PAGADA)
    BEGIN
        RAISERROR('La venta ya se encuentra PAGADA', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2) Si la suma de pagos alcanza o supera el total procede a PAGADA.
    --    Pagos y desglose se suman en subconsultas separadas para que
    --    un JOIN no multiplique las filas y altere las sumas.
    UPDATE v
    SET v.ID_ES_VEN = @PAGADA
    FROM VENTA v
    INNER JOIN (SELECT ID_VEN, SUM(MONTO_PAG) AS TOTAL_PAGADO
                FROM PAGO
                WHERE ID_VEN IN (SELECT ID_VEN FROM inserted)
                GROUP BY ID_VEN) p ON p.ID_VEN = v.ID_VEN
    INNER JOIN (SELECT ID_VEN, SUM(SUBTOTAL_DES_VEN) AS TOTAL_VENTA
                FROM DESGLOSE_VENTA
                WHERE ID_VEN IN (SELECT ID_VEN FROM inserted)
                GROUP BY ID_VEN) d ON d.ID_VEN = v.ID_VEN
    WHERE p.TOTAL_PAGADO >= d.TOTAL_VENTA;
END;
GO

/* ---------------------------------------------------------------------
   TRIGGERS COMPLEMENTARIOS (mantenemos la consistencia del inventario y el estado de la venta)
   --------------------------------------------------------------------- */

-- Al ELIMINAR un desglose: devuelve el inventario a la tienda.
CREATE TRIGGER Delete_Detalle
ON DESGLOSE_VENTA
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted d
               INNER JOIN VENTA v        ON v.ID_VEN    = d.ID_VEN
               INNER JOIN ESTADO_VENTA e ON e.ID_ES_VEN = v.ID_ES_VEN
               WHERE e.NOMBRE_ES_VEN <> 'REGISTRADA')
    BEGIN
        RAISERROR('Solo se puede eliminar el detalle de ventas en estado REGISTRADA', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE c
    SET c.EXISTENCIA_ACTUAL_CAT_PRO = c.EXISTENCIA_ACTUAL_CAT_PRO + s.CANTIDAD
    FROM CATALOGO_PRODUCTO c
    INNER JOIN (SELECT v.ID_TI, d.ID_PRO, SUM(d.CANTIDAD_DES_VEN) AS CANTIDAD
                FROM deleted d
                INNER JOIN VENTA v ON v.ID_VEN = d.ID_VEN
                GROUP BY v.ID_TI, d.ID_PRO) s
            ON s.ID_TI = c.ID_TI AND s.ID_PRO = c.ID_PRO;
END;
GO

-- Al MODIFICAR un desglose: devuelve lo anterior (DELETED), descuenta
-- lo nuevo (INSERTED) y valida que el inventario no quede negativo.
CREATE TRIGGER Update_Detalle
ON DESGLOSE_VENTA
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM VENTA v
               INNER JOIN ESTADO_VENTA e ON e.ID_ES_VEN = v.ID_ES_VEN
               WHERE v.ID_VEN IN (SELECT ID_VEN FROM inserted UNION SELECT ID_VEN FROM deleted)
                 AND e.NOMBRE_ES_VEN <> 'REGISTRADA')
    BEGIN
        RAISERROR('Solo se puede modificar el detalle de ventas en estado REGISTRADA', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Movimiento neto por (tienda, producto): + lo devuelto, - lo nuevo
    DECLARE @neto TABLE (ID_TI INT, ID_PRO INT, DELTA INT, PRIMARY KEY (ID_TI, ID_PRO));

    INSERT INTO @neto (ID_TI, ID_PRO, DELTA)
    SELECT x.ID_TI, x.ID_PRO, SUM(x.DELTA)
    FROM (SELECT v.ID_TI, d.ID_PRO,  d.CANTIDAD_DES_VEN AS DELTA
          FROM deleted d  INNER JOIN VENTA v ON v.ID_VEN = d.ID_VEN
          UNION ALL
          SELECT v.ID_TI, i.ID_PRO, -i.CANTIDAD_DES_VEN AS DELTA
          FROM inserted i INNER JOIN VENTA v ON v.ID_VEN = i.ID_VEN) x
    GROUP BY x.ID_TI, x.ID_PRO;

    IF EXISTS (SELECT 1 FROM @neto n
               LEFT JOIN CATALOGO_PRODUCTO c ON c.ID_TI = n.ID_TI AND c.ID_PRO = n.ID_PRO
               WHERE n.DELTA < 0
                 AND (c.ID_PRO IS NULL OR c.EXISTENCIA_ACTUAL_CAT_PRO + n.DELTA < 0))
    BEGIN
        RAISERROR('Stock insuficiente', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE c
    SET c.EXISTENCIA_ACTUAL_CAT_PRO = c.EXISTENCIA_ACTUAL_CAT_PRO + n.DELTA
    FROM CATALOGO_PRODUCTO c
    INNER JOIN @neto n ON n.ID_TI = c.ID_TI AND n.ID_PRO = c.ID_PRO;
END;
GO

-- Al MODIFICAR o ELIMINAR pagos: recalcula PAGADA / REGISTRADA.
CREATE TRIGGER Recalcular_Estado_Pago
ON PAGO
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @REGISTRADA INT = (SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = 'REGISTRADA');
    DECLARE @PAGADA     INT = (SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = 'PAGADA');
    DECLARE @ANULADA    INT = (SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = 'ANULADA');

    UPDATE v
    SET v.ID_ES_VEN = CASE
                          WHEN ISNULL(d.TOTAL_VENTA, 0) > 0
                           AND ISNULL(p.TOTAL_PAGADO, 0) >= d.TOTAL_VENTA THEN @PAGADA
                          ELSE @REGISTRADA
                      END
    FROM VENTA v
    LEFT JOIN (SELECT ID_VEN, SUM(MONTO_PAG) AS TOTAL_PAGADO
               FROM PAGO GROUP BY ID_VEN) p ON p.ID_VEN = v.ID_VEN
    LEFT JOIN (SELECT ID_VEN, SUM(SUBTOTAL_DES_VEN) AS TOTAL_VENTA
               FROM DESGLOSE_VENTA GROUP BY ID_VEN) d ON d.ID_VEN = v.ID_VEN
    WHERE v.ID_ES_VEN <> @ANULADA
      AND v.ID_VEN IN (SELECT ID_VEN FROM inserted UNION SELECT ID_VEN FROM deleted);
END;
GO

-- Al ANULAR una venta: devuelve el inventario a la tienda.
-- Una venta ANULADA no puede volver a otro estado.
CREATE TRIGGER Anular_Venta
ON VENTA
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(ID_ES_VEN) RETURN;

    DECLARE @ANULADA INT = (SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = 'ANULADA');

    IF EXISTS (SELECT 1 FROM inserted i
               INNER JOIN deleted d ON d.ID_VEN = i.ID_VEN
               WHERE d.ID_ES_VEN = @ANULADA AND i.ID_ES_VEN <> @ANULADA)
    BEGIN
        RAISERROR('Una venta ANULADA no puede reactivarse', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE c
    SET c.EXISTENCIA_ACTUAL_CAT_PRO = c.EXISTENCIA_ACTUAL_CAT_PRO + s.CANTIDAD
    FROM CATALOGO_PRODUCTO c
    INNER JOIN (SELECT i.ID_TI, dv.ID_PRO, SUM(dv.CANTIDAD_DES_VEN) AS CANTIDAD
                FROM inserted i
                INNER JOIN deleted d         ON d.ID_VEN  = i.ID_VEN
                INNER JOIN DESGLOSE_VENTA dv ON dv.ID_VEN = i.ID_VEN
                WHERE i.ID_ES_VEN = @ANULADA AND d.ID_ES_VEN <> @ANULADA
                GROUP BY i.ID_TI, dv.ID_PRO) s
            ON s.ID_TI = c.ID_TI AND s.ID_PRO = c.ID_PRO;
END;
GO

/* =====================================================================
   3. VISTAS
    pendientes
   ===================================================================== */


/* =====================================================================
   4. USUARIO DEL API (mínimo privilegio: lee y escribe datos,
      no puede modificar la estructura)
   ===================================================================== */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$(API_USER)')
    CREATE LOGIN [$(API_USER)] WITH PASSWORD = N'$(API_PASSWORD)', DEFAULT_DATABASE = ComercialLaEstrella;
GO
USE ComercialLaEstrella;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(API_USER)')
    CREATE USER [$(API_USER)] FOR LOGIN [$(API_USER)];
ALTER ROLE db_datareader ADD MEMBER [$(API_USER)];
ALTER ROLE db_datawriter ADD MEMBER [$(API_USER)];
GO

/* =====================================================================
   5. DATOS DE PRUEBA
   ===================================================================== */
SET NOCOUNT ON;

-- Ubicación
INSERT INTO PAIS (NOMBRE_PA) VALUES (N'Guatemala'), (N'El Salvador');

INSERT INTO DEPARTAMENTO (NOMBRE_DEP, ID_PA) VALUES
    (N'Guatemala', 1), (N'Sacatepéquez', 1), (N'Quetzaltenango', 1), (N'San Salvador', 2);

INSERT INTO MUNICIPIO (NOMBRE_MUN, ID_DEP) VALUES
    (N'Guatemala', 1),          -- 1
    (N'Mixco', 1),              -- 2
    (N'Antigua Guatemala', 2),  -- 3
    (N'Quetzaltenango', 3),     -- 4
    (N'San Salvador', 4);       -- 5

-- Catálogos simples
INSERT INTO TIPO_TIENDA (NOMBRE_TIP_TIE) VALUES (N'Sucursal'), (N'Express'), (N'Bodega');
INSERT INTO TIPO_IDENTIFICACION (NOMBRE_TIP_IDE) VALUES (N'DPI'), (N'NIT'), (N'Pasaporte');
INSERT INTO CARGO (NOMBRE_CAR) VALUES (N'Gerente'), (N'Vendedor'), (N'Cajero'), (N'Bodeguero');
INSERT INTO CATEGORIA (NOMBRE_CAT) VALUES
    (N'Línea blanca'), (N'Electrodomésticos'), (N'Electrónica'), (N'Muebles');
INSERT INTO MARCA (NOMBRE_MAR) VALUES
    (N'Mabe'), (N'Oster'), (N'Samsung'), (N'LG'), (N'Sony'), (N'Estrella Home');

-- El orden importa: los triggers y el DEFAULT de VENTA usan estos ids
INSERT INTO ESTADO_VENTA (NOMBRE_ES_VEN) VALUES
    (N'REGISTRADA'),   -- 1
    (N'PENDIENTE'),    -- 2
    (N'PAGADA'),       -- 3
    (N'ANULADA');      -- 4

INSERT INTO METODO_PAGO (NOMBRE_MET_PAG) VALUES
    (N'Efectivo'), (N'Tarjeta de crédito'), (N'Tarjeta de débito'), (N'Transferencia');

-- Tiendas
INSERT INTO TIENDA (NOMBRE_TI, DIRECCION_TI, TELEFONO_TI, ID_MUN, ID_TIP_TIE) VALUES
    (N'La Estrella Zona 1',       N'6a. Avenida 10-25, Zona 1',     '2230-1000', 1, 1),
    (N'La Estrella Antigua',      N'4a. Calle Poniente #12',        '7832-2000', 3, 1),
    (N'La Estrella Xela Express', N'14 Avenida 3-40, Zona 1',       '7761-3000', 4, 2),
    (N'La Estrella San Salvador', N'Boulevard de los Héroes #1500', '2260-4000', 5, 1);

-- Personas (1-5 empleados, 6-10 clientes)
INSERT INTO PERSONA (NOMBRE_PER, APELLIDO_PER, TELEFONO, CORREO_PER, DIRECCION_PER, ID_MUN) VALUES
    (N'María José',    N'López García',   '5510-2030', N'mjlopez@laestrella.com',    N'Zona 1, Guatemala',          1),
    (N'Juan Pablo',    N'Pérez Castillo', '5520-3040', N'jpperez@laestrella.com',    N'Zona 7, Mixco',              2),
    (N'Ana Lucía',     N'Méndez Ruiz',    '5530-4050', N'amendez@laestrella.com',    N'Calle del Arco, Antigua',    3),
    (N'Carlos',        N'Ramírez Ochoa',  '5540-5060', N'cramirez@laestrella.com',   N'Zona 3, Quetzaltenango',     4),
    (N'Sofía',         N'Hernández Paz',  '7501-1122', N'shernandez@laestrella.com', N'Colonia Escalón',            5),
    (N'Luis Fernando', N'Morales',        '4411-2233', N'lmorales@gmail.com',        N'Zona 10, Guatemala',         1),
    (N'Andrea',        N'Castillo',       '4422-3344', NULL,                         N'Zona 4, Mixco',              2),
    (N'Roberto',       N'Juárez',         '4433-4455', NULL,                         N'San Pedro Las Huertas',      3),
    (N'Gabriela',      N'Estrada',        '4444-5566', N'gestrada@yahoo.com',        N'Zona 1, Quetzaltenango',     4),
    (N'Diego',         N'Martínez',       '7012-3456', N'dmartinez@gmail.com',       N'Colonia San Benito',         5);

-- Empleados (tienda, cargo, persona)
INSERT INTO EMPLEADO (FECHA_CONTRATACION, ID_TI, ID_CAR, ID_PER) VALUES
    ('2024-02-01', 1, 2, 1),   -- 1: Vendedor Zona 1
    ('2023-07-15', 1, 3, 2),   -- 2: Cajero Zona 1
    ('2025-01-10', 2, 2, 3),   -- 3: Vendedor Antigua
    ('2022-03-20', 3, 1, 4),   -- 4: Gerente Xela
    ('2025-06-01', 4, 2, 5);   -- 5: Vendedor San Salvador

-- Clientes (tipo identificación, número, persona)
INSERT INTO CLIENTE (ID_TIP_IDE, NUMERO_IDENTIFICACION, ID_PER) VALUES
    (2, '1234567-8',     6),
    (1, '2547896320101', 7),
    (2, '9876543-2',     8),
    (2, '4567891-0',     9),
    (3, 'SV-A1234567',   10);

-- Productos
INSERT INTO PRODUCTO (NOMBRE_PRO, DESCRIPCION_PRO, ID_CAT, ID_MAR) VALUES
    (N'Refrigeradora 14 pies',    N'Refrigeradora no frost',       1, 1),  -- 1
    (N'Licuadora 10 velocidades', N'Vaso de vidrio 1.5 L',         2, 2),  -- 2
    (N'Smart TV 55" 4K',          N'Televisor UHD',                3, 3),  -- 3
    (N'Lavadora 18 kg',           N'Carga superior, inverter',     1, 4),  -- 4
    (N'Horno microondas 1.1 ft',  N'Microondas digital',           2, 3),  -- 5
    (N'Audífonos inalámbricos',   N'Bluetooth con cancelación',    3, 5),  -- 6
    (N'Sofá 3 plazas',            N'Tela gris, estructura madera', 4, 6),  -- 7
    (N'Cafetera 12 tazas',        N'Cafetera de goteo',            2, 2);  -- 8

-- Catálogo: precio y existencia por tienda
INSERT INTO CATALOGO_PRODUCTO (PRECIO_VIGENTE_CAT_PRO, EXISTENCIA_ACTUAL_CAT_PRO, ID_TI, ID_PRO) VALUES
    -- Tienda 1: Zona 1 (todos los productos; la licuadora con poco stock para pruebas)
    (5499.00, 15, 1, 1), (449.00,  3, 1, 2), (4299.00, 10, 1, 3), (4899.00,  8, 1, 4),
    ( 899.00, 20, 1, 5), (649.00, 25, 1, 6), (3299.00,  6, 1, 7), ( 379.00, 12, 1, 8),
    -- Tienda 2: Antigua
    (5599.00,  5, 2, 1), (4399.00,  6, 2, 3), ( 925.00, 10, 2, 5), ( 659.00, 15, 2, 6), (389.00, 8, 2, 8),
    -- Tienda 3: Xela Express
    ( 459.00,  4, 3, 2), (4299.00,  4, 3, 3), (4950.00,  3, 3, 4), (3299.00,  5, 3, 7),
    -- Tienda 4: San Salvador
    ( 935.00,  6, 4, 5), ( 675.00, 10, 4, 6), ( 395.00,  9, 4, 8);


-- Venta 1 (Zona 1): pago completo → quedará PAGADA (total 6797.00)
INSERT INTO VENTA (FECHA_VEN, ID_TI, ID_EMP, ID_CLI) VALUES ('2026-09-01T10:15:00', 1, 1, 1);
INSERT INTO DESGLOSE_VENTA (CANTIDAD_DES_VEN, PRECIO_UNITARIO_DES_VEN, SUBTOTAL_DES_VEN, ID_VEN, ID_PRO) VALUES
    (1, 5499.00, 5499.00, 1, 1),
    (2,  649.00, 1298.00, 1, 6);
INSERT INTO PAGO (MONTO_PAG, ID_MET_PAG, ID_VEN) VALUES (6797.00, 2, 1);

-- Venta 2 (Antigua): abono parcial → quedará REGISTRADA con saldo (total 5324.00)
INSERT INTO VENTA (FECHA_VEN, ID_TI, ID_EMP, ID_CLI) VALUES ('2026-09-05T15:40:00', 2, 3, 3);
INSERT INTO DESGLOSE_VENTA (CANTIDAD_DES_VEN, PRECIO_UNITARIO_DES_VEN, SUBTOTAL_DES_VEN, ID_VEN, ID_PRO) VALUES
    (1, 4399.00, 4399.00, 2, 3),
    (1,  925.00,  925.00, 2, 5);
INSERT INTO PAGO (MONTO_PAG, ID_MET_PAG, ID_VEN) VALUES (2000.00, 1, 2);

-- Venta 3 (Zona 1): sin pagos → REGISTRADA (total 5657.00)
INSERT INTO VENTA (FECHA_VEN, ID_TI, ID_EMP, ID_CLI) VALUES ('2026-09-12T11:00:00', 1, 2, 2);
INSERT INTO DESGLOSE_VENTA (CANTIDAD_DES_VEN, PRECIO_UNITARIO_DES_VEN, SUBTOTAL_DES_VEN, ID_VEN, ID_PRO) VALUES
    (1, 4899.00, 4899.00, 3, 4),
    (2,  379.00,  758.00, 3, 8);

-- Venta 4 (Xela): dos abonos que completan el total → quedará PAGADA (total 3299.00)
INSERT INTO VENTA (FECHA_VEN, ID_TI, ID_EMP, ID_CLI) VALUES ('2026-09-20T09:30:00', 3, 4, 4);
INSERT INTO DESGLOSE_VENTA (CANTIDAD_DES_VEN, PRECIO_UNITARIO_DES_VEN, SUBTOTAL_DES_VEN, ID_VEN, ID_PRO) VALUES
    (1, 3299.00, 3299.00, 4, 7);
INSERT INTO PAGO (MONTO_PAG, ID_MET_PAG, ID_VEN) VALUES (1500.00, 1, 4);
INSERT INTO PAGO (MONTO_PAG, ID_MET_PAG, ID_VEN) VALUES (1799.00, 4, 4);

-- Venta 5 (Xela): se registra y luego se ANULA (no cuenta en las vistas)
INSERT INTO VENTA (FECHA_VEN, ID_TI, ID_EMP, ID_CLI) VALUES ('2026-09-25T17:10:00', 3, 4, 4);
INSERT INTO DESGLOSE_VENTA (CANTIDAD_DES_VEN, PRECIO_UNITARIO_DES_VEN, SUBTOTAL_DES_VEN, ID_VEN, ID_PRO) VALUES
    (1, 4299.00, 4299.00, 5, 3);
UPDATE VENTA SET ID_ES_VEN = 4 WHERE ID_VEN = 5;

-- Venta 6 (San Salvador): pago completo → quedará PAGADA (total 2420.00)
INSERT INTO VENTA (FECHA_VEN, ID_TI, ID_EMP, ID_CLI) VALUES ('2026-10-02T13:20:00', 4, 5, 5);
INSERT INTO DESGLOSE_VENTA (CANTIDAD_DES_VEN, PRECIO_UNITARIO_DES_VEN, SUBTOTAL_DES_VEN, ID_VEN, ID_PRO) VALUES
    (3, 675.00, 2025.00, 6, 6),
    (1, 395.00,  395.00, 6, 8);
INSERT INTO PAGO (MONTO_PAG, ID_MET_PAG, ID_VEN) VALUES (2420.00, 1, 6);
GO

PRINT 'Base de datos ComercialLaEstrella inicializada correctamente.';
GO