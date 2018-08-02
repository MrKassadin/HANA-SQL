DROP SCHEMA SqlScriptDocumentation CASCADE;

CREATE SCHEMA SqlScriptDocumentation;

ALTER SESSION
SET CURRENT_SCHEMA = SqlScriptDocumentation;

--test data 
CREATE COLUMN TABLE publishers (
	pub_id INTEGER PRIMARY KEY,
	name VARCHAR (50),
	street VARCHAR (50),
	post_code VARCHAR (10),
	city VARCHAR (50),
	country VARCHAR (50)
);

INSERT INTO publishers
VALUES
	(
		1,
		'Oldenburg Wissenschaftsverlag GmbH',
		'Rosenheimer Strasse 145',
		'81671',
		'Muenchen',
		'Germany'
	);

INSERT INTO publishers
VALUES
	(
		2,
		'Pearson Education Deutschland GmbH',
		'Martin-Kollar-Strasse 10-12',
		'81829',
		'Muenchen',
		'Germany'
	);

INSERT INTO publishers
VALUES
	(
		3,
		'mitp & bhv-Buch',
		'Augustinusstrasse 9d',
		'50226',
		'Frechen',
		'Germany'
	);

INSERT INTO publishers
VALUES
	(
		4,
		'Roof Music',
		'Prinz-Regent-Strasse 50-60',
		'44795',
		'Bochum',
		'Germany'
	);

CREATE COLUMN TABLE books (
	isbn VARCHAR (20) PRIMARY KEY,
	title VARCHAR (50),
	publisher INTEGER,
	edition INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

INSERT INTO books
VALUES
	(
		'978-3-486-57690-0',
		'Datenbanksysteme: Eine Einfuehrung',
		1,
		6,
		'2006',
		'39.80',
		'EUR'
	);

INSERT INTO books
VALUES
	(
		'978-3-86894-012-1',
		'Grundlagen von Datenbanken',
		2,
		3,
		'2009',
		'29.95',
		'EUR'
	);

INSERT INTO books
VALUES
	(
		'978-3-8266-1664-8',
		'Datenbanken: Konzepte und Sprachen',
		3,
		3,
		'2008',
		'39.95',
		'EUR'
	);

CREATE COLUMN TABLE audiobooks (
	isbn VARCHAR (20) PRIMARY KEY,
	title VARCHAR (50),
	publisher INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

INSERT INTO audiobooks
VALUES
	(
		'978-39388781-37-1',
		'Ich bin dann mal weg',
		4,
		'2006',
		'24.90',
		'EUR'
	);

--output tables 
CREATE TABLE op_publishers (
	publisher INTEGER,
	name VARCHAR (50),
	price DECIMAL,
	cnt INTEGER
);

CREATE TABLE op_years (
	YEAR VARCHAR (4),
	price DECIMAL,
	cnt INTEGER
);

CREATE COLUMN TABLE op_audiobooks1 (
	isbn VARCHAR (20) PRIMARY KEY,
	title VARCHAR (50),
	publisher INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE COLUMN TABLE op_audiobooks2 (
	isbn VARCHAR (20) PRIMARY KEY,
	title VARCHAR (50),
	publisher INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TABLE op_proj_books (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	price_vat DECIMAL (5, 2),
	currency VARCHAR (3)
);

CREATE TABLE op_colt_books (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	price_vat DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TABLE op_colt_books1 (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE COLUMN TABLE op_books (
	isbn VARCHAR (20) PRIMARY KEY,
	title VARCHAR (50),
	publisher INTEGER,
	edition INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TABLE op_join_books_pubs (
	publisher INTEGER,
	name VARCHAR (50),
	street VARCHAR (50),
	post_code VARCHAR (10),
	city VARCHAR (50),
	country VARCHAR (50),
	isbn VARCHAR (20),
	title VARCHAR (50),
	edition INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TABLE op_join_books_pubs2 (
	publisher INTEGER,
	name VARCHAR (50),
	street VARCHAR (50),
	post_code VARCHAR (10),
	city VARCHAR (50),
	country VARCHAR (50),
	isbn VARCHAR (20),
	title VARCHAR (50),
	edition INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TABLE op_joinp_books_pubs1 (
	title VARCHAR (50),
	name VARCHAR (50),
	publisher INTEGER,
	YEAR VARCHAR (4)
);

CREATE TABLE op_joinp_books_pubs2 (
	title VARCHAR (50),
	name VARCHAR (50),
	publisher INTEGER,
	YEAR VARCHAR (4)
);

CREATE TABLE op_agg_books1 (
	publisher INTEGER,
	YEAR VARCHAR (4)
);

CREATE TABLE op_agg_books2 (
	publisher INTEGER,
	YEAR VARCHAR (4)
);

CREATE COLUMN TABLE books1 (
	isbn VARCHAR (20) PRIMARY KEY,
	title VARCHAR (50),
	publisher INTEGER,
	edition INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE INSERT ONLY COLUMN TABLE op_sales_books (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

-- drop table type 
DROP TYPE tt_publishers CASCADE;

DROP TYPE tt_years CASCADE;

-- create table type
CREATE TYPE tt_publishers AS TABLE (
	publisher INTEGER,
	name VARCHAR (50),
	price DECIMAL,
	cnt INTEGER
);

CREATE TYPE tt_years AS TABLE (
	YEAR VARCHAR (4),
	price DECIMAL,
	cnt INTEGER
);

CREATE TYPE tt_sales_books AS TABLE (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TYPE tt_agg_books AS TABLE (
	publisher INTEGER,
	YEAR VARCHAR (4)
);

CREATE TYPE tt_proj_books AS TABLE (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	price_vat DECIMAL (5, 2),
	currency VARCHAR (3)
);

CREATE TYPE tt_colt_books AS TABLE (
	title VARCHAR (50),
	price DECIMAL (5, 2),
	price_vat DECIMAL (5, 2),
	crcy VARCHAR (3)
);

CREATE TYPE tt_join_books_pubs AS TABLE (
	publisher INTEGER,
	name VARCHAR (50),
	street VARCHAR (50),
	post_code VARCHAR (10),
	city VARCHAR (50),
	country VARCHAR (50),
	isbn VARCHAR (20),
	title VARCHAR (50),
	edition INTEGER,
	YEAR VARCHAR (4),
	price DECIMAL (5, 2),
	crcy VARCHAR (3)
);

-- tracing for procedures 
DROP TABLE message_box;

CREATE TABLE message_box (
	message VARCHAR (200),
	log_time TIMESTAMP
);

DROP PROCEDURE ins_msg_proc;

CREATE PROCEDURE ins_msg_proc (p_msg VARCHAR(200)) LANGUAGE SQLSCRIPT AS
BEGIN
	INSERT INTO message_box
VALUES
	(: p_msg, CURRENT_TIMESTAMP) ;
END ; DROP PROCEDURE init_proc ; CREATE PROCEDURE init_proc LANGUAGE SQLSCRIPT AS
BEGIN
	DELETE
FROM
	message_box ;
END ;