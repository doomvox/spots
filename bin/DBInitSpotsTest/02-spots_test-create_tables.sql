/*
/home/doom/End/Cave/Spots/bin/DBInitSpotsTest/02-spots_test-create_tables.sql

SYNOPSIS

   cd /home/doom/End/Cave/Spots/bin/DBInitSpotsTest
   psql -d spots_test -f 02-spots_test-create_tables.sql

Then run 03-*.sql

*/

\connect spots_test

CREATE TABLE spots (
       id           SERIAL PRIMARY KEY NOT NULL,
       url          VARCHAR(256) NOT NULL,
       label        VARCHAR(64),
       static       BOOLEAN,
       title        TEXT, -- from <TITLE>
       description  TEXT, 
       added        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
       revised      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- needs trigger
       live         BOOLEAN,
       categories   INTEGER);

CREATE TABLE categories (
       id           SERIAL PRIMARY KEY NOT NULL,
       name VARCHAR(32)
);

CREATE TABLE layout (
       id           SERIAL PRIMARY KEY NOT NULL,
       categories  INTEGER,
       x_location  INTEGER,
       y_location  INTEGER,
       height      INTEGER,
       width       INTEGER
);


CREATE OR REPLACE FUNCTION update_revised_timestamp_function()
RETURNS TRIGGER 
AS 
$$
BEGIN
    /* assumes the table has a "revised" column */
    NEW.revised  = now(); 
    RETURN NEW;               
END;                          
$$                            
language 'plpgsql';           
                              
/* create a trigger on each table with an 'revised' column */
CREATE TRIGGER row_mod_on_spot_trigger
BEFORE UPDATE                             
ON spots
FOR EACH ROW                              
EXECUTE PROCEDURE update_revised_timestamp_function();
