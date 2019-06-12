--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2 (Debian 11.2-1.pgdg90+1)
-- Dumped by pg_dump version 11.2 (Debian 11.2-1.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: update_revised_timestamp_function(); Type: FUNCTION; Schema: public; Owner: doom
--

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

--
-- Name: category; Type: TABLE; Schema: public; Owner: doom
--

CREATE TABLE public.category (
    id integer NOT NULL,
    metacat integer,
    name character varying(32)
);


ALTER TABLE public.category OWNER TO doom;

--
-- Name: category_id_seq; Type: SEQUENCE; Schema: public; Owner: doom
--

CREATE SEQUENCE public.category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.category_id_seq OWNER TO doom;

--
-- Name: category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: doom
--

ALTER SEQUENCE public.category_id_seq OWNED BY public.category.id;


--
-- Name: layout; Type: TABLE; Schema: public; Owner: doom
--

CREATE TABLE public.layout (
    id integer NOT NULL,
    category integer NOT NULL,
    x_location integer,
    y_location integer,
    height numeric,
    width integer
);


ALTER TABLE public.layout OWNER TO doom;

--
-- Name: layout_id_seq; Type: SEQUENCE; Schema: public; Owner: doom
--

CREATE SEQUENCE public.layout_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.layout_id_seq OWNER TO doom;

--
-- Name: layout_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: doom
--

ALTER SEQUENCE public.layout_id_seq OWNED BY public.layout.id;


--
-- Name: metacat; Type: TABLE; Schema: public; Owner: doom
--

CREATE TABLE public.metacat (
    id integer NOT NULL,
    sortcode character varying(4),
    name character varying(32)
);


ALTER TABLE public.metacat OWNER TO doom;

--
-- Name: metacat_id_seq; Type: SEQUENCE; Schema: public; Owner: doom
--

CREATE SEQUENCE public.metacat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.metacat_id_seq OWNER TO doom;

--
-- Name: metacat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: doom
--

ALTER SEQUENCE public.metacat_id_seq OWNED BY public.metacat.id;


--
-- Name: spots; Type: TABLE; Schema: public; Owner: doom
--

CREATE TABLE public.spots (
    id integer NOT NULL,
    url character varying(256) NOT NULL,
    label character varying(64),
    static boolean,
    title text,
    description text,
    added timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    revised timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    live boolean,
    category integer
);


ALTER TABLE public.spots OWNER TO doom;

--
-- Name: spots_id_seq; Type: SEQUENCE; Schema: public; Owner: doom
--

CREATE SEQUENCE public.spots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.spots_id_seq OWNER TO doom;

--
-- Name: spots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: doom
--

ALTER SEQUENCE public.spots_id_seq OWNED BY public.spots.id;


--
-- Name: category id; Type: DEFAULT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.category ALTER COLUMN id SET DEFAULT nextval('public.category_id_seq'::regclass);


--
-- Name: layout id; Type: DEFAULT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.layout ALTER COLUMN id SET DEFAULT nextval('public.layout_id_seq'::regclass);


--
-- Name: metacat id; Type: DEFAULT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.metacat ALTER COLUMN id SET DEFAULT nextval('public.metacat_id_seq'::regclass);


--
-- Name: spots id; Type: DEFAULT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.spots ALTER COLUMN id SET DEFAULT nextval('public.spots_id_seq'::regclass);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- Name: layout layout_category_key; Type: CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.layout
    ADD CONSTRAINT layout_category_key UNIQUE (category);


--
-- Name: layout layout_pkey; Type: CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.layout
    ADD CONSTRAINT layout_pkey PRIMARY KEY (id);


--
-- Name: metacat metacat_pkey; Type: CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.metacat
    ADD CONSTRAINT metacat_pkey PRIMARY KEY (id);


--
-- Name: spots spots_pkey; Type: CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.spots
    ADD CONSTRAINT spots_pkey PRIMARY KEY (id);


--
-- Name: spots row_mod_on_spot_trigger; Type: TRIGGER; Schema: public; Owner: doom
--

CREATE TRIGGER row_mod_on_spot_trigger BEFORE UPDATE ON public.spots FOR EACH ROW EXECUTE PROCEDURE public.update_revised_timestamp_function();


--
-- Name: category category_metacat_fkey; Type: FK CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_metacat_fkey FOREIGN KEY (metacat) REFERENCES public.metacat(id);


--
-- Name: layout layout_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.layout
    ADD CONSTRAINT layout_category_fkey FOREIGN KEY (category) REFERENCES public.category(id);


--
-- Name: spots spots_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: doom
--

ALTER TABLE ONLY public.spots
    ADD CONSTRAINT spots_category_fkey FOREIGN KEY (category) REFERENCES public.category(id);


--
-- PostgreSQL database dump complete
--

