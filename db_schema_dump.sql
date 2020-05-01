--
-- PostgreSQL database dump
--

-- Dumped from database version 12.0 (Debian 12.0-2.pgdg100+1)
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


--
-- Name: versioned; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA versioned;


ALTER SCHEMA versioned OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: example; Type: TABLE; Schema: versioned; Owner: postgres
--

CREATE TABLE versioned.example (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    v_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb,
    deleted boolean
);

--
-- Name: TABLE example; Type: COMMENT; Schema: versioned; Owner: postgres
--

COMMENT ON TABLE versioned.example IS 'an example table';


--
-- Name: example; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.example AS
 WITH last_version AS (
         SELECT v_e.v_id,
            v_e.id,
            v_e.created_at AS updated_at,
            v_e.data
           FROM (versioned.example v_e
             LEFT JOIN versioned.example v_e2 ON (((v_e.v_id < v_e2.v_id) AND (v_e.id = v_e2.id))))
          WHERE ((v_e2.v_id IS NULL) AND (v_e.deleted IS NULL))
        ), first_version AS (
         SELECT v_e.id,
            v_e.created_at
           FROM (versioned.example v_e
             LEFT JOIN versioned.example v_e2 ON (((v_e.v_id > v_e2.v_id) AND (v_e.id = v_e2.id))))
          WHERE (v_e2.v_id IS NULL)
        )
 SELECT lv.id,
    lv.v_id,
    lv.updated_at,
    lv.data,
    fv.created_at
   FROM (last_version lv
     LEFT JOIN first_version fv ON ((fv.id = lv.id)));

--
-- Name: VIEW example; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.example IS 'an example view:)';


--
-- Name: example_v_id_seq; Type: SEQUENCE; Schema: versioned; Owner: postgres
--

CREATE SEQUENCE versioned.example_v_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: example_v_id_seq; Type: SEQUENCE OWNED BY; Schema: versioned; Owner: postgres
--

ALTER SEQUENCE versioned.example_v_id_seq OWNED BY versioned.example.v_id;


--
-- Name: example v_id; Type: DEFAULT; Schema: versioned; Owner: postgres
--

ALTER TABLE ONLY versioned.example ALTER COLUMN v_id SET DEFAULT nextval('versioned.example_v_id_seq'::regclass);


--
-- Data for Name: example; Type: TABLE DATA; Schema: versioned; Owner: postgres
--


--
-- Name: example example_pkey; Type: CONSTRAINT; Schema: versioned; Owner: postgres
--

ALTER TABLE ONLY versioned.example
    ADD CONSTRAINT example_pkey PRIMARY KEY (v_id);


--
-- PostgreSQL database dump complete
--

