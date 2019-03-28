/*
/home/doom/End/Cave/Spots/bin/DBInitSpotsTest/01-spots_test-drop_and_recreate.sql

SYNOPSIS

   cd /home/doom/End/Cave/Spots/bin/DBInitSpotsTest
   psql -f 01-spots_test-drop_and_recreate.sql

Then run 02-*.sql

*/


DROP DATABASE spots_test;
CREATE DATABASE spots_test WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
ALTER DATABASE spots_test OWNER TO postgres;
\connect spots_test

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

CREATE FUNCTION public.update_revised_timestamp_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    /* assumes the table has a "revised" column */
    NEW.revised  = now(); 
    RETURN NEW;               
END;                          
$$;


ALTER FUNCTION public.update_revised_timestamp_function() OWNER TO doom;

SET default_tablespace = '';

SET default_with_oids = false;


