DROP PROCEDURE addDiscount; 
CREATE PROCEDURE addDiscount( IN it_books tt_sales_books, OUT ot_books tt_sales_books) 
    LANGUAGE SQLSCRIPT READS SQL DATA AS 
BEGIN 
  ot_Books = SELECT title, CASE WHEN price > 300 THEN (price - (price / 30)) 
                                ELSE CASE WHEN price > 200 THEN (price - (price / 20)) 
                                          ELSE (price - (price / 10)) 
                                     END 
                           END AS price, crcy 
             FROM :it_books; 
END;

DROP PROCEDURE getSalesBooks; 
DROP VIEW addDiscount_RET; 
CREATE PROCEDURE getSalesBooks( IN minPrice DECIMAL(5, 2), IN currency VARCHAR(3), 
                                IN it_books books, OUT ot_sales tt_sales_books) 
   LANGUAGE SQLSCRIPT READS SQL DATA WITH RESULT VIEW addDiscount_RET AS 
BEGIN 
  lt_expensive_books = SELECT title, price, crcy 
                       FROM :it_books 
                       WHERE price > :minPrice 
                       AND crcy = :currency;

  CALL addDiscount(:lt_expensive_books, lt_on_sale);

  lt_cheap_books = SELECT title, price, crcy 
                   FROM :it_books 
                   WHERE price <= :minPrice 
                   AND crcy = :currency;

  ot_sales = CE_UNION_ALL(:lt_on_sale, :lt_cheap_books); 
END;

CALL getSalesBooks(1.5, '''EUR''', books, op_sales_books); 
TRUNCATE table op_sales_books; 
SELECT * FROM addDiscount_RET WITH PARAMETERS ( 'placeholder' = ('$$minprice$$', '1'), 
                                     'placeholder' = ('$$currency$$', '''EUR'''), 
                                     'placeholder' = ('$$it_books$$', 'books'), 
                                     'placeholder' = ('$$ot_sales$$', 'op_sales_books')); 
TRUNCATE table op_sales_books;