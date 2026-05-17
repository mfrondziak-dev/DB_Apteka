CREATE DATABASE AptekaDB;
GO
USE AptekaDB;
GO

CREATE TABLE Kategorie (
    ID_Kategorii   INT           PRIMARY KEY IDENTITY(1,1),
    Nazwa          NVARCHAR(100) NOT NULL,
    Opis           NVARCHAR(MAX)
);

CREATE TABLE Producenci (
    ID_Producenta  INT           PRIMARY KEY IDENTITY(1,1),
    Nazwa          NVARCHAR(150) NOT NULL,
    Kraj           NVARCHAR(50),
    Kontakt        NVARCHAR(255) 
);

CREATE TABLE Produkty (
    ID_Produktu       INT           PRIMARY KEY IDENTITY(1,1),
    Nazwa             NVARCHAR(200) NOT NULL,
    Postac            NVARCHAR(50),      
    Dawka             NVARCHAR(50),
    Substancja_Czynna NVARCHAR(200),
    Kod_EAN           CHAR(13)      UNIQUE,
    Czy_Na_Recepte    BIT           DEFAULT 0,
    Stawka_VAT        DECIMAL(5,2)  DEFAULT 8.00,
    Przeciwwskazania  NVARCHAR(MAX),
    ID_Kategorii      INT           FOREIGN KEY REFERENCES Kategorie(ID_Kategorii),
    ID_Producenta     INT           FOREIGN KEY REFERENCES Producenci(ID_Producenta)
);

CREATE TABLE Zamienniki (
    ID_Produktu_A INT FOREIGN KEY REFERENCES Produkty(ID_Produktu),
    ID_Produktu_B INT FOREIGN KEY REFERENCES Produkty(ID_Produktu),
    PRIMARY KEY (ID_Produktu_A, ID_Produktu_B),
    CHECK (ID_Produktu_A <> ID_Produktu_B)
);
GO

CREATE TRIGGER trg_Zamienniki
ON Zamienniki
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Zamienniki (ID_Produktu_A, ID_Produktu_B)
    SELECT i.ID_Produktu_B, i.ID_Produktu_A
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1 FROM Zamienniki z
        WHERE z.ID_Produktu_A = i.ID_Produktu_B
          AND z.ID_Produktu_B = i.ID_Produktu_A
    );
END;
GO

CREATE TABLE Hurtownie (
    ID_Hurtowni  INT           PRIMARY KEY IDENTITY(1,1),
    Nazwa        NVARCHAR(150) NOT NULL,
    NIP          CHAR(10)      UNIQUE,
    Adres        NVARCHAR(255),
    Telefon      VARCHAR(20)
);

CREATE TABLE Pacjenci (
    ID_Pacjenta     INT           PRIMARY KEY IDENTITY(1,1),
    Imie            NVARCHAR(50),
    Nazwisko        NVARCHAR(50),
    PESEL           CHAR(11)      UNIQUE,
    Telefon         VARCHAR(20),
);

CREATE TABLE Lekarze (
    ID_Lekarza     INT         PRIMARY KEY IDENTITY(1,1),
    Imie           NVARCHAR(50),
    Nazwisko       NVARCHAR(50),
    PWZ_Lekarza    VARCHAR(20), 
    Specjalizacja  NVARCHAR(100)
);

CREATE TABLE Pracownicy (
    ID_Pracownika    INT          PRIMARY KEY IDENTITY(1,1),
    Imie             NVARCHAR(50),
    Nazwisko         NVARCHAR(50),
    Rola             NVARCHAR(30),              
    Numer_PWZ        VARCHAR(20)  UNIQUE,       
    Login_Systemowy  NVARCHAR(50) UNIQUE NOT NULL,
    Haslo_Hash       NVARCHAR(256) NOT NULL, 
    Data_Zatrudnienia DATE         DEFAULT GETDATE(),
    Aktywny          BIT          DEFAULT 1
);

CREATE TABLE Dostawy (
    ID_Dostawy          INT           PRIMARY KEY IDENTITY(1,1),
    ID_Hurtowni         INT           FOREIGN KEY REFERENCES Hurtownie(ID_Hurtowni),
    Data_Przyjecia      DATETIME      DEFAULT GETDATE(),
    Nr_Faktury_Zakupu   NVARCHAR(50)  NOT NULL
);

CREATE TABLE Partie (
    ID_Partii              INT           PRIMARY KEY IDENTITY(1,1),
    ID_Produktu            INT           FOREIGN KEY REFERENCES Produkty(ID_Produktu),
    ID_Dostawy             INT           FOREIGN KEY REFERENCES Dostawy(ID_Dostawy),
    Numer_Serii            NVARCHAR(50)  NOT NULL,
    Data_Waznosci          DATE          NOT NULL,
    Cena_Zakupu_Netto      DECIMAL(10,2) CHECK (Cena_Zakupu_Netto > 0),
    Ilosc_Poczatkowa       INT           NOT NULL,
    Ilosc_Aktualna         INT           NOT NULL CHECK (Ilosc_Aktualna >= 0),
    Lokalizacja_Magazynowa NVARCHAR(50)
);

CREATE TABLE Recepty (
    ID_Recepty       INT         PRIMARY KEY IDENTITY(1,1),
    Kod_Dostepu      CHAR(4),
    Numer_Recepty    VARCHAR(50) UNIQUE,
    ID_Pacjenta      INT         FOREIGN KEY REFERENCES Pacjenci(ID_Pacjenta),
    ID_Lekarza       INT         FOREIGN KEY REFERENCES Lekarze(ID_Lekarza),
    Data_Wystawienia DATE
);

CREATE TABLE Sprzedaz (
    ID_Sprzedazy     INT           PRIMARY KEY IDENTITY(1,1),
    Data_Transakcji  DATETIME      DEFAULT GETDATE(),
    ID_Pracownika    INT           FOREIGN KEY REFERENCES Pracownicy(ID_Pracownika),
    ID_Pacjenta      INT           FOREIGN KEY REFERENCES Pacjenci(ID_Pacjenta) NULL,
    Suma_Brutto      DECIMAL(10,2),
    Metoda_Platnosci NVARCHAR(20)  CHECK (Metoda_Platnosci IN ('Gotówka', 'Karta', 'Blik')),
    Czy_Anulowana    BIT           DEFAULT 0
);

CREATE TABLE Pozycje_Sprzedazy (
    ID_Pozycji              INT           PRIMARY KEY IDENTITY(1,1),
    ID_Sprzedazy            INT           FOREIGN KEY REFERENCES Sprzedaz(ID_Sprzedazy),
    ID_Partii               INT           FOREIGN KEY REFERENCES Partie(ID_Partii),
    Ilosc                   INT           CHECK (Ilosc > 0),
    Cena_Jednostkowa_Brutto DECIMAL(10,2),
    ID_Recepty              INT           FOREIGN KEY REFERENCES Recepty(ID_Recepty) NULL
);

CREATE TABLE Logi_Magazynowe (
    ID_Logu        INT           PRIMARY KEY IDENTITY(1,1),
    ID_Partii      INT           FOREIGN KEY REFERENCES Partie(ID_Partii),
    Typ_Operacji   NVARCHAR(50),                        
    Zmiana_Ilosci  INT,
    Data_Operacji  DATETIME      DEFAULT GETDATE(),
    ID_Pracownika  INT           FOREIGN KEY REFERENCES Pracownicy(ID_Pracownika)
);
GO

CREATE UNIQUE INDEX UIX_Pracownicy_NumerPWZ
ON Pracownicy(Numer_PWZ)
WHERE Numer_PWZ IS NOT NULL;

CREATE INDEX IX_Produkty_EAN         ON Produkty(Kod_EAN);

CREATE INDEX IX_Pacjenci_PESEL       ON Pacjenci(PESEL);

CREATE INDEX IX_Partie_DataWaznosci  ON Partie(Data_Waznosci);

CREATE INDEX IX_Sprzedaz_Data        ON Sprzedaz(Data_Transakcji);

CREATE INDEX IX_Sprzedaz_Pracownik   ON Sprzedaz(ID_Pracownika);
GO

