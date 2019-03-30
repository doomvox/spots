/* /home/doom/End/Cave/Spots/Wall/Spots/bin/roll_forward_2.0_3.0.sql
   Thursday March 28, 2019   6:13 PM

   To version 3.0

   Manually revised spots_schema.sql, and entered sql to spots and spots_test

SYNOPSIS

  cd /home/doom/End/Cave/Spots/Wall/Spots/bin/
  psql -d spots -f roll_forward_2.0_3.0.sql
  psql -d spots_test -f roll_forward_2.0_3.0.sql

*/

ALTER TABLE categories RENAME TO category;
ALTER TABLE spots RENAME COLUMN categories TO category;
ALTER TABLE layout RENAME COLUMN categories TO category;

CREATE TABLE metacat (
       id           SERIAL PRIMARY KEY NOT NULL,
       sortcode     VARCHAR(4),  
       name         VARCHAR(32)
);

ALTER TABLE category ADD COLUMN metacat INTEGER;

CREATE TABLE project (
       id  SERIAL PRIMARY KEY NOT NULL,
       schema_version   VARCHAR(16),    -- e.g. "3.0"
       name             VARCHAR(128),
       description      TEXT,
       changes          TEXT,
       added            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
       revised          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- needs trigger
       notes_file       TEXT
);

CREATE TRIGGER row_mod_on_spot_trigger
BEFORE UPDATE                             
ON project
FOR EACH ROW                              
EXECUTE PROCEDURE update_revised_timestamp_function();


/* Did this manually later, spots and *_test (and removed from
create above): ALTER TABLE metacat DROP COLUMN category; */
