--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg110+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-09-19 03:39:04 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 14 (class 2615 OID 19743)
-- Name: gazetteer; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA gazetteer;


ALTER SCHEMA gazetteer OWNER TO postgres;

--
-- TOC entry 1040 (class 1255 OID 19751)
-- Name: authenticate(); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.authenticate() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
			roles text;
			userinfo jsonb;
        begin
			select current_setting('request.jwt.claim.roles', true) into roles;

            if roles LIKE '%AADC%' then
                set local role to scar_admin;
            else
                set local role to public_user;
            end if;
        end;
$$;


ALTER FUNCTION gazetteer.authenticate() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 288 (class 1259 OID 19752)
-- Name: place_names; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.place_names (
    name_id numeric(10,0) NOT NULL,
    latitude double precision,
    longitude double precision,
    altitude double precision,
    feature_type_code numeric(10,0),
    narrative character varying(4000),
    named_for character varying(4000),
    meeting_date character varying(200),
    meeting_paper character varying(200),
    date_revised date,
    gazetteer character varying(20),
    place_id numeric(10,0),
    coordinate_accuracy double precision,
    altitude_accuracy double precision,
    accepted_by character varying(100),
    source_country_code character varying(100),
    source_name character varying(500),
    source_scale character varying(15),
    scar_map_cat_id numeric(10,0),
    comments character varying(2000),
    source_publisher character varying(100),
    source_identifier character varying(100),
    date_named date,
    location_method_id numeric(10,0),
    geometry public.geometry,
    reason character varying(5000),
    relic_flag boolean,
    place_name_gazetteer character varying(500),
    place_name_mapping character varying(500),
    view_by_public_flag boolean,
    country_code character varying(2),
    narrative_translation character varying(4000),
    machine_translation boolean,
    un_sdg numeric(2,0)
);


ALTER TABLE gazetteer.place_names OWNER TO postgres;

--
-- TOC entry 346 (class 1255 OID 19757)
-- Name: search(text); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.search(search_text text) RETURNS SETOF gazetteer.place_names
    LANGUAGE plpgsql
    AS $$
        BEGIN
			RETURN QUERY
            select * from gazetteer.place_names
            where LOWER(unaccent(place_name_mapping)) like '%' || LOWER(unaccent(search_text)) || '%'
            OR place_id::text = search_text
            OR name_id::text = search_text;
        end;
    $$;


ALTER FUNCTION gazetteer.search(search_text text) OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 19761)
-- Name: feature_types; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.feature_types (
    feature_type_code numeric(10,0) NOT NULL,
    feature_type_name character varying(100),
    aliases character varying(100),
    comments text,
    definition text,
    image_catalogue_nos character varying(100)
);


ALTER TABLE gazetteer.feature_types OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 19770)
-- Name: gazetteers; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.gazetteers (
    gazetteer_id numeric(10,0) NOT NULL,
    gazetteer_code character varying(100),
    gazetteer_name character varying(100),
    national_authority character varying(100),
    agency character varying(100),
    names_urn character varying(100),
    country character varying(100)
);


ALTER TABLE gazetteer.gazetteers OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 19766)
-- Name: gaz_count; Type: VIEW; Schema: gazetteer; Owner: postgres
--

CREATE VIEW gazetteer.gaz_count AS
 SELECT count(name_id) AS name_count,
    count(DISTINCT place_id) AS place_count,
    ( SELECT count(*) AS count
           FROM gazetteer.gazetteers) AS gazetteer_count
   FROM gazetteer.place_names;


ALTER VIEW gazetteer.gaz_count OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 19775)
-- Name: glossary; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.glossary (
    glossary_id numeric(10,0) NOT NULL,
    english_term character varying(100),
    national_term character varying(100),
    language character varying(100),
    scar_feature_class character varying(100),
    scar_feature_type character varying(100),
    feature_type_code character varying(100)
);


ALTER TABLE gazetteer.glossary OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 19780)
-- Name: name_count; Type: VIEW; Schema: gazetteer; Owner: postgres
--

CREATE VIEW gazetteer.name_count AS
 SELECT count(p.name_id) AS name_count,
    p.gazetteer,
    g.country
   FROM (gazetteer.place_names p
     JOIN gazetteer.gazetteers g ON (((g.gazetteer_code)::text = (p.gazetteer)::text)))
  GROUP BY p.gazetteer, g.country
  ORDER BY g.country;


ALTER VIEW gazetteer.name_count OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 19854)
-- Name: themes; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.themes (
    id integer NOT NULL,
    name character varying(1000) NOT NULL,
    description character varying(10000),
    place_names character varying(1000)[]
);


ALTER TABLE gazetteer.themes OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 19861)
-- Name: themes_id_seq; Type: SEQUENCE; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.themes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gazetteer.themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 4461 (class 2606 OID 19812)
-- Name: feature_types feature_type_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.feature_types
    ADD CONSTRAINT feature_type_pkey PRIMARY KEY (feature_type_code);


--
-- TOC entry 4463 (class 2606 OID 19814)
-- Name: gazetteers gazetteers_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.gazetteers
    ADD CONSTRAINT gazetteers_pkey PRIMARY KEY (gazetteer_id);


--
-- TOC entry 4467 (class 2606 OID 19816)
-- Name: glossary glossary_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.glossary
    ADD CONSTRAINT glossary_pkey PRIMARY KEY (glossary_id);


--
-- TOC entry 4459 (class 2606 OID 19818)
-- Name: place_names place_names_new_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.place_names
    ADD CONSTRAINT place_names_new_pkey PRIMARY KEY (name_id);


--
-- TOC entry 4469 (class 2606 OID 19860)
-- Name: themes themes_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (id);


--
-- TOC entry 4465 (class 2606 OID 19820)
-- Name: gazetteers uk_code; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.gazetteers
    ADD CONSTRAINT uk_code UNIQUE (gazetteer_code);


--
-- TOC entry 4470 (class 2606 OID 19821)
-- Name: place_names feature_types_fk; Type: FK CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.place_names
    ADD CONSTRAINT feature_types_fk FOREIGN KEY (feature_type_code) REFERENCES gazetteer.feature_types(feature_type_code) NOT VALID;


--
-- TOC entry 4471 (class 2606 OID 19826)
-- Name: place_names gazetteer_fk; Type: FK CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.place_names
    ADD CONSTRAINT gazetteer_fk FOREIGN KEY (gazetteer) REFERENCES gazetteer.gazetteers(gazetteer_code);


--
-- TOC entry 4637 (class 3256 OID 19869)
-- Name: place_names delete_place_names; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY delete_place_names ON gazetteer.place_names FOR DELETE TO scar_admin USING (true);


--
-- TOC entry 4629 (class 3256 OID 19831)
-- Name: place_names edit_place_names; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY edit_place_names ON gazetteer.place_names FOR UPDATE TO scar_admin USING (true) WITH CHECK (true);


--
-- TOC entry 4625 (class 0 OID 19761)
-- Dependencies: 289
-- Name: feature_types; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.feature_types ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4630 (class 3256 OID 19832)
-- Name: place_names full_edit; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY full_edit ON gazetteer.place_names FOR UPDATE TO scar_admin USING (true);


--
-- TOC entry 4639 (class 3256 OID 19870)
-- Name: themes full_edit; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY full_edit ON gazetteer.themes TO scar_admin USING (true) WITH CHECK (true);


--
-- TOC entry 4631 (class 3256 OID 19833)
-- Name: place_names full_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY full_view ON gazetteer.place_names FOR SELECT TO scar_admin USING (true);


--
-- TOC entry 4626 (class 0 OID 19770)
-- Dependencies: 291
-- Name: gazetteers; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.gazetteers ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4627 (class 0 OID 19775)
-- Dependencies: 292
-- Name: glossary; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.glossary ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4632 (class 3256 OID 19834)
-- Name: place_names insert_place_names; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY insert_place_names ON gazetteer.place_names FOR INSERT TO scar_admin WITH CHECK (true);


--
-- TOC entry 4624 (class 0 OID 19752)
-- Dependencies: 288
-- Name: place_names; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.place_names ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4633 (class 3256 OID 19835)
-- Name: feature_types public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.feature_types FOR SELECT TO scar_admin, public_user USING (true);


--
-- TOC entry 4634 (class 3256 OID 19836)
-- Name: gazetteers public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.gazetteers FOR SELECT TO scar_admin, public_user USING (true);


--
-- TOC entry 4635 (class 3256 OID 19837)
-- Name: glossary public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.glossary FOR SELECT TO scar_admin, public_user USING (true);


--
-- TOC entry 4636 (class 3256 OID 19838)
-- Name: place_names public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.place_names FOR SELECT TO public_user USING ((view_by_public_flag = true));


--
-- TOC entry 4638 (class 3256 OID 19866)
-- Name: themes public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.themes FOR SELECT TO public_user USING (true);


--
-- TOC entry 4628 (class 0 OID 19854)
-- Dependencies: 294
-- Name: themes; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.themes ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4645 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA gazetteer; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA gazetteer TO public_user;
GRANT USAGE ON SCHEMA gazetteer TO scar_admin;


--
-- TOC entry 4646 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE place_names; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.place_names TO public_user;
GRANT ALL ON TABLE gazetteer.place_names TO scar_admin;


--
-- TOC entry 4647 (class 0 OID 0)
-- Dependencies: 289
-- Name: TABLE feature_types; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.feature_types TO public_user;
GRANT ALL ON TABLE gazetteer.feature_types TO scar_admin;


--
-- TOC entry 4648 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE gazetteers; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.gazetteers TO public_user;
GRANT ALL ON TABLE gazetteer.gazetteers TO scar_admin;


--
-- TOC entry 4649 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE gaz_count; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.gaz_count TO public_user;
GRANT SELECT ON TABLE gazetteer.gaz_count TO scar_admin;


--
-- TOC entry 4650 (class 0 OID 0)
-- Dependencies: 292
-- Name: TABLE glossary; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.glossary TO public_user;
GRANT ALL ON TABLE gazetteer.glossary TO scar_admin;


--
-- TOC entry 4651 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE name_count; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.name_count TO public_user;
GRANT SELECT ON TABLE gazetteer.name_count TO scar_admin;


--
-- TOC entry 4652 (class 0 OID 0)
-- Dependencies: 294
-- Name: TABLE themes; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.themes TO public_user;
GRANT ALL ON TABLE gazetteer.themes TO scar_admin;


-- Completed on 2025-09-19 03:39:04 UTC

--
-- PostgreSQL database dump complete
--

