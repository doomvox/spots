/* not strictly part of spots work. TODO MOVE */

/* not in use yet */
CREATE TABLE projects (
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
ON projects
FOR EACH ROW                              
EXECUTE PROCEDURE update_revised_timestamp_function();
