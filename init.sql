SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF DB_ID(N'ComercialLaEstrella') IS NULL
    CREATE DATABASE ComercialLaEstrella;
GO

USE ComercialLaEstrella;
GO

PRINT 'Base de datos ComercialLaEstrella creada (init de prueba).';
GO