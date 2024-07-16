CREATE DATABASE LUXTOYS_DB
USE LUXTOYS_DB

CREATE TABLE Customers(
cusID VARCHAR(10) PRIMARY KEY,
uName VARCHAR(100),
uAddress VARCHAR(255),
uRegion VARCHAR(255),
uLevel VARCHAR(10)
);

CREATE TABLE Store(
storeID VARCHAR(10) PRIMARY KEY,
storeName VARCHAR(100),
storeArea VARCHAR(50),
storeType VARCHAR(10)
);

CREATE TABLE Employee(
stafID VARCHAR(10) PRIMARY KEY,
stafName VARCHAR(100),
stafLevel VARCHAR(10),
stafEntryDate DATETIME,
stafExitDate DATETIME,
staf_stat VARCHAR(10)
);

CREATE TABLE Product(
prodID VARCHAR(10) PRIMARY KEY,
prodName VARCHAR(200),
prodCategory VARCHAR(50),
prodStatus VARCHAR(50),
prodPrice INT
);

CREATE TABLE Warehouse(
waID VARCHAR(10) PRIMARY KEY,
waRegion VARCHAR(50),
stafID VARCHAR(10) FOREIGN KEY REFERENCES Employee(stafID)
);

CREATE TABLE stockDetailWarehouse(
prodID VARCHAR(10) FOREIGN KEY REFERENCES Product(prodID),
waID VARCHAR(10) FOREIGN KEY REFERENCES Warehouse(waID),
qty_available INT
);

CREATE TABLE stockDetailStore(
prodID VARCHAR(10) FOREIGN KEY REFERENCES Product(prodID),
storeID VARCHAR(10) FOREIGN KEY REFERENCES Store(storeID),
qty_available INT
);

CREATE TABLE Transact(
trID VARCHAR(10) PRIMARY KEY,
trDate DATETIME,
cusID VARCHAR(10) FOREIGN KEY REFERENCES Customers(cusID),
storeID VARCHAR(10) FOREIGN KEY REFERENCES Store(storeID),
disc_tr DECIMAL(10,2),
gross_tr DECIMAL(10,2),
nett_tr DECIMAL(10,2),
payType VARCHAR(20)
);

CREATE TABLE transactDetail(
trID VARCHAR(10) FOREIGN KEY REFERENCES Transact(trID),
prodID VARCHAR(10) FOREIGN KEY REFERENCES Product(prodID),
qty INT,
is_campaign BIT,
disc_detail DECIMAL(10,2),
gross_detail DECIMAL(10,2),
nett_detail DECIMAL(10,2)
);
