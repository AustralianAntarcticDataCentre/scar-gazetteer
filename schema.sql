--
-- PostgreSQL database dump
--

\restrict 5IbN8r5v6lhnH8cjx3YkZMbbX7lAqgrTiSdynGyiCieu39418AIzohEnPtktxVM

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg110+1)
-- Dumped by pg_dump version 17.6

-- Started on 2025-11-07 06:32:31 UTC
 
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
-- TOC entry 14 (class 2615 OID 36881)
-- Name: gazetteer; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA gazetteer;


ALTER SCHEMA gazetteer OWNER TO postgres;

--
-- TOC entry 2051 (class 1247 OID 44617)
-- Name: application/vnd.google-earth.kml+xml; Type: DOMAIN; Schema: gazetteer; Owner: postgres
--

CREATE DOMAIN gazetteer."application/vnd.google-earth.kml+xml" AS text;


ALTER DOMAIN gazetteer."application/vnd.google-earth.kml+xml" OWNER TO postgres;

--
-- TOC entry 859 (class 1255 OID 44637)
-- Name: audit_entry(); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.audit_entry() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    primary_column_name TEXT;
    primary_column_value TEXT;
BEGIN
    primary_column_name := TG_ARGV[0];

    EXECUTE format('SELECT (($1).%I)::text', primary_column_name)
    USING NEW
    INTO primary_column_value;

    INSERT INTO gazetteer.audit ("user", entity, entity_id, event_type, event_before, event_after, created_at) 
	VALUES (current_setting('request.jwt.claims', true)::jsonb->'user', TG_TABLE_NAME, primary_column_value, TG_OP, to_jsonb(OLD), to_jsonb(NEW), now());

    RETURN NEW;
END;
$_$;


ALTER FUNCTION gazetteer.audit_entry() OWNER TO postgres;

--
-- TOC entry 855 (class 1255 OID 36882)
-- Name: authenticate(); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.authenticate() RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
	roles jsonb := current_setting('request.jwt.claims', true)::jsonb->>'roles';
begin
	if roles ?| array['AADC', 'AADC_DEV', 'GAZ_EDIT'] then
		set local role to scar_admin;
	else
		set local role to public_user;
	end if;
end;
$$;


ALTER FUNCTION gazetteer.authenticate() OWNER TO postgres;

--
-- TOC entry 863 (class 1255 OID 44621)
-- Name: get_next_id(text, text); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.get_next_id(table_name text, id_column text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
        next_val integer;
    BEGIN
		EXECUTE format('LOCK TABLE gazetteer.%I IN EXCLUSIVE MODE', table_name);
        EXECUTE format('SELECT COALESCE(MAX(%I), 0) + 1 FROM gazetteer.%I', id_column, table_name)
        INTO next_val;
        RETURN next_val;
    END;
    $$;


ALTER FUNCTION gazetteer.get_next_id(table_name text, id_column text) OWNER TO postgres;

--
-- TOC entry 4725 (class 0 OID 0)
-- Dependencies: 863
-- Name: FUNCTION get_next_id(table_name text, id_column text); Type: COMMENT; Schema: gazetteer; Owner: postgres
--

COMMENT ON FUNCTION gazetteer.get_next_id(table_name text, id_column text) IS 'This function exists so that place_ids can be incremented reliably without the risk of a sequence getting out of sync during data imports etc.';


--
-- TOC entry 594 (class 1255 OID 44619)
-- Name: place_names_kml_final(gazetteer."application/vnd.google-earth.kml+xml"); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.place_names_kml_final(data gazetteer."application/vnd.google-earth.kml+xml") RETURNS gazetteer."application/vnd.google-earth.kml+xml"
    LANGUAGE sql
    AS $$
    SELECT
        '<kml xmlns="http://www.opengis.net/kml/2.2">' ||
        '  <Document>' ||
		'
		   <Schema name="SCAR_CGA" id="SCAR_CGA">
		    <SimpleField type="string" name="place_id"/>
			<SimpleField type="string" name="name_id"/>
            <SimpleField type="string" name="place_name_mapping"/>
            <SimpleField type="string" name="place_name_gazetteer"/>
			<SimpleField type="string" name="narrative"/>
        </Schema>
		' ||
        '    <name>SCAR Composite Gazetteer</name>' ||
        data ||
        '  </Document>' ||
        '</kml>' AS kml_document
$$;


ALTER FUNCTION gazetteer.place_names_kml_final(data gazetteer."application/vnd.google-earth.kml+xml") OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 318 (class 1259 OID 36884)
-- Name: place_names; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.place_names (
    name_id integer NOT NULL,
    place_id integer DEFAULT gazetteer.get_next_id('place_names'::text, 'place_id'::text) NOT NULL,
    place_name_mapping text NOT NULL,
    place_name_gazetteer text NOT NULL,
    coordinate_accuracy double precision,
    altitude double precision,
    altitude_accuracy double precision,
    narrative text,
    named_for text,
    un_sdg integer,
    gazetteer character varying(6),
    feature_type_code integer,
    relic_flag boolean DEFAULT FALSE NOT NULL,
    date_named date,
    comments text,
    geometry public.geometry NOT NULL,
    pronunciation_audio_url text,
    country_id integer,
    scar_feature_class text,
    is_complete_flag BOOLEAN,
    view_by_public_flag BOOLEAN,
    is_proposed_flag BOOLEAN,
    accepted_by TEXT,
    verified_by TEXT,
    scar_map_cat_id INTEGER,
    status text,
    status_notes text,
    source_name character varying(500),
    source_publisher character varying(100),
    source_identifier character varying(100),
    source_scale character varying(15),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE gazetteer.place_names OWNER TO postgres;

--
-- TOC entry 391 (class 1255 OID 44618)
-- Name: place_names_kml_trans(text, gazetteer.place_names); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.place_names_kml_trans(state text, next gazetteer.place_names) RETURNS gazetteer."application/vnd.google-earth.kml+xml"
    LANGUAGE sql
    AS $$
    SELECT state || '<Placemark>' 
	|| '  <name>' || next.place_name_gazetteer || '</name>' ||
            ST_AsKML(next.geometry) 
	|| '<ExtendedData><SchemaData schemaUrl="#SCAR_CGA">'
	|| '<SimpleData name="place_id">' || next.place_id || '</SimpleData>'
	|| '<SimpleData name="name_id">' || next.name_id || '</SimpleData>'
	|| '<SimpleData name="place_name_mapping">' || next.place_name_mapping || '</SimpleData>'
    || '<SimpleData name="place_name_gazetteer">' || next.place_name_gazetteer || '</SimpleData>'
	|| '<SimpleData name="narrative">' || regexp_replace(next.narrative, E'<[^>]+>', '', 'gi') || '</SimpleData>'
	|| '</SchemaData></ExtendedData>'
	|| '</Placemark>'
    $$;


ALTER FUNCTION gazetteer.place_names_kml_trans(state text, next gazetteer.place_names) OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 36892)
-- Name: feature_types; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.feature_types (
    feature_type_code integer NOT NULL,
    feature_type_name text NOT NULL,
    aliases text,
    comments text,
    definition text
);


ALTER TABLE gazetteer.feature_types OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 36897)
-- Name: gazetteers; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.gazetteers (
    gazetteer_code character varying(6) NOT NULL,
    gazetteer_name text,
    national_authority text,
    agency text,
    names_url text,
    country_id integer
);


ALTER TABLE gazetteer.gazetteers OWNER TO postgres;

--
-- TOC entry 324 (class 1259 OID 44610)
-- Name: place_names_consolidated; Type: VIEW; Schema: gazetteer; Owner: postgres
--

CREATE VIEW gazetteer.place_names_consolidated AS
 SELECT n.name_id,
    n.place_id,
    n.place_name_mapping,
    n.place_name_gazetteer,
    public.st_y(n.geometry) AS latitude,
    public.st_x(n.geometry) AS longitude,
    n.coordinate_accuracy,
    n.altitude,
    n.altitude_accuracy,
    n.narrative,
    n.named_for,
    n.un_sdg,
    g.gazetteer_code,
    g.gazetteer_name,
    n.feature_type_code,
    f.feature_type_name,
    n.relic_flag AS is_relic,
    n.date_named,
    n.comments
   FROM ((gazetteer.place_names n
     LEFT OUTER JOIN gazetteer.gazetteers g ON (((n.gazetteer)::text = (g.gazetteer_code)::text)))
     LEFT OUTER JOIN gazetteer.feature_types f ON ((n.feature_type_code = f.feature_type_code)));


ALTER VIEW gazetteer.place_names_consolidated OWNER TO postgres;

--
-- TOC entry 481 (class 1255 OID 44615)
-- Name: search(text); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.search(search_text text) RETURNS SETOF gazetteer.place_names_consolidated
    LANGUAGE plpgsql
    AS $$
        BEGIN
			RETURN QUERY
            SELECT * FROM gazetteer.place_names_consolidated
            WHERE LOWER(unaccent(place_name_mapping)) LIKE '%' || LOWER(unaccent(search_text)) || '%'
            OR place_id::text = search_text
            OR name_id::text = search_text;
        END;
    $$;


ALTER FUNCTION gazetteer.search(search_text text) OWNER TO postgres;

--
-- TOC entry 470 (class 1255 OID 44627)
-- Name: update_updated(); Type: FUNCTION; Schema: gazetteer; Owner: postgres
--

CREATE FUNCTION gazetteer.update_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION gazetteer.update_updated() OWNER TO postgres;

--
-- TOC entry 2081 (class 1255 OID 44620)
-- Name: place_names_kml_agg(gazetteer.place_names); Type: AGGREGATE; Schema: gazetteer; Owner: postgres
--

CREATE AGGREGATE gazetteer.place_names_kml_agg(gazetteer.place_names) (
    SFUNC = gazetteer.place_names_kml_trans,
    STYPE = gazetteer."application/vnd.google-earth.kml+xml",
    INITCOND = '',
    FINALFUNC = gazetteer.place_names_kml_final
);


ALTER AGGREGATE gazetteer.place_names_kml_agg(gazetteer.place_names) OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 44646)
-- Name: audit; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.audit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "user" jsonb,
    entity text,
    entity_id text,
    event_type text,
    event_before jsonb,
    event_after jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE gazetteer.audit OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 36902)
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
-- TOC entry 322 (class 1259 OID 36906)
-- Name: glossary; Type: TABLE; Schema: gazetteer; Owner: postgres
--

CREATE TABLE gazetteer.glossary (
    glossary_id integer NOT NULL,
    english_term text NOT NULL,
    national_term text NOT NULL,
    language text NOT NULL,
    feature_type_code integer
);


ALTER TABLE gazetteer.glossary OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 44605)
-- Name: name_count; Type: VIEW; Schema: gazetteer; Owner: postgres
--

CREATE VIEW gazetteer.name_count AS
 SELECT count(p.name_id) AS name_count,
    p.gazetteer,
    g.country_id
   FROM (gazetteer.place_names p
     JOIN gazetteer.gazetteers g ON (((g.gazetteer_code)::text = (p.gazetteer)::text)))
  GROUP BY p.gazetteer, g.country_id
  ORDER BY g.country_id;


ALTER VIEW gazetteer.name_count OWNER TO postgres;

--
-- TOC entry 317 (class 1259 OID 36883)
-- Name: place_names_name_id_seq; Type: SEQUENCE; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.place_names ALTER COLUMN name_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME gazetteer.place_names_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 4539 (class 2606 OID 36923)
-- Name: feature_types feature_type_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.feature_types
    ADD CONSTRAINT feature_type_pkey PRIMARY KEY (feature_type_code);


--
-- TOC entry 4541 (class 2606 OID 44559)
-- Name: gazetteers gazetteers_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.gazetteers
    ADD CONSTRAINT gazetteers_pkey PRIMARY KEY (gazetteer_code);


--
-- TOC entry 4545 (class 2606 OID 36927)
-- Name: glossary glossary_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.glossary
    ADD CONSTRAINT glossary_pkey PRIMARY KEY (glossary_id);


--
-- TOC entry 4537 (class 2606 OID 36890)
-- Name: place_names place_names_pkey; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.place_names
    ADD CONSTRAINT place_names_pkey PRIMARY KEY (name_id);


--
-- TOC entry 4543 (class 2606 OID 44557)
-- Name: gazetteers uk_code; Type: CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.gazetteers
    ADD CONSTRAINT uk_code UNIQUE (gazetteer_code);


--
-- TOC entry 4546 (class 1259 OID 44653)
-- Name: idx_audit_entity; Type: INDEX; Schema: gazetteer; Owner: postgres
--

CREATE INDEX idx_audit_entity ON gazetteer.audit USING btree (entity) WITH (deduplicate_items='true');


--
-- TOC entry 4547 (class 1259 OID 44654)
-- Name: idx_audit_entity_id; Type: INDEX; Schema: gazetteer; Owner: postgres
--

CREATE INDEX idx_audit_entity_id ON gazetteer.audit USING btree (entity_id) WITH (deduplicate_items='true');


--
-- TOC entry 4533 (class 1259 OID 44623)
-- Name: idx_place_names_place_id; Type: INDEX; Schema: gazetteer; Owner: postgres
--

CREATE INDEX idx_place_names_place_id ON gazetteer.place_names USING btree (place_id) WITH (deduplicate_items='true');


--
-- TOC entry 4534 (class 1259 OID 44625)
-- Name: idx_place_names_place_name_gazetteer; Type: INDEX; Schema: gazetteer; Owner: postgres
--

CREATE INDEX idx_place_names_place_name_gazetteer ON gazetteer.place_names USING btree (place_name_gazetteer) WITH (deduplicate_items='true');


--
-- TOC entry 4535 (class 1259 OID 44624)
-- Name: idx_place_names_place_name_mapping; Type: INDEX; Schema: gazetteer; Owner: postgres
--

CREATE INDEX idx_place_names_place_name_mapping ON gazetteer.place_names USING btree (place_name_mapping) WITH (deduplicate_items='true');


--
-- TOC entry 4551 (class 2620 OID 44644)
-- Name: place_names place_names_audit_tg; Type: TRIGGER; Schema: gazetteer; Owner: postgres
--

CREATE TRIGGER place_names_audit_tg AFTER INSERT OR DELETE OR UPDATE ON gazetteer.place_names FOR EACH ROW EXECUTE FUNCTION gazetteer.audit_entry('name_id');


--
-- TOC entry 4552 (class 2620 OID 44641)
-- Name: place_names place_names_updated_tg; Type: TRIGGER; Schema: gazetteer; Owner: postgres
--

CREATE TRIGGER place_names_updated_tg BEFORE UPDATE ON gazetteer.place_names FOR EACH ROW EXECUTE FUNCTION gazetteer.update_updated();


--
-- TOC entry 4550 (class 2606 OID 36942)
-- Name: glossary feature_type_code_fk; Type: FK CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.glossary
    ADD CONSTRAINT feature_type_code_fk FOREIGN KEY (feature_type_code) REFERENCES gazetteer.feature_types(feature_type_code);


--
-- TOC entry 4548 (class 2606 OID 36932)
-- Name: place_names feature_types_fk; Type: FK CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.place_names
    ADD CONSTRAINT feature_types_fk FOREIGN KEY (feature_type_code) REFERENCES gazetteer.feature_types(feature_type_code);


--
-- TOC entry 4549 (class 2606 OID 44572)
-- Name: place_names gazetteer_fk; Type: FK CONSTRAINT; Schema: gazetteer; Owner: postgres
--

ALTER TABLE ONLY gazetteer.place_names
    ADD CONSTRAINT gazetteer_fk FOREIGN KEY (gazetteer) REFERENCES gazetteer.gazetteers(gazetteer_code);


--
-- TOC entry 4710 (class 3256 OID 36947)
-- Name: place_names delete_place_names; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY delete_place_names ON gazetteer.place_names FOR DELETE TO scar_admin USING (true);


--
-- TOC entry 4711 (class 3256 OID 36948)
-- Name: place_names edit_place_names; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY edit_place_names ON gazetteer.place_names FOR UPDATE TO scar_admin USING (true) WITH CHECK (true);


--
-- TOC entry 4707 (class 0 OID 36892)
-- Dependencies: 319
-- Name: feature_types; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.feature_types ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4712 (class 3256 OID 36949)
-- Name: place_names full_edit; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY full_edit ON gazetteer.place_names FOR UPDATE TO scar_admin USING (true);


--
-- TOC entry 4713 (class 3256 OID 36951)
-- Name: place_names full_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY full_view ON gazetteer.place_names FOR SELECT TO scar_admin USING (true);


--
-- TOC entry 4708 (class 0 OID 36897)
-- Dependencies: 320
-- Name: gazetteers; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.gazetteers ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4709 (class 0 OID 36906)
-- Dependencies: 322
-- Name: glossary; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.glossary ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4714 (class 3256 OID 36952)
-- Name: place_names insert_place_names; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY insert_place_names ON gazetteer.place_names FOR INSERT TO scar_admin WITH CHECK (true);


--
-- TOC entry 4706 (class 0 OID 36884)
-- Dependencies: 318
-- Name: place_names; Type: ROW SECURITY; Schema: gazetteer; Owner: postgres
--

ALTER TABLE gazetteer.place_names ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4715 (class 3256 OID 36953)
-- Name: feature_types public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.feature_types FOR SELECT TO public_user, scar_admin USING (true);


--
-- TOC entry 4716 (class 3256 OID 36954)
-- Name: gazetteers public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.gazetteers FOR SELECT TO public_user, scar_admin USING (true);


--
-- TOC entry 4717 (class 3256 OID 36955)
-- Name: glossary public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.glossary FOR SELECT TO public_user, scar_admin USING (true);


--
-- TOC entry 4718 (class 3256 OID 36956)
-- Name: place_names public_view; Type: POLICY; Schema: gazetteer; Owner: postgres
--

CREATE POLICY public_view ON gazetteer.place_names FOR SELECT TO public_user USING (true);


--
-- TOC entry 4724 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA gazetteer; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA gazetteer TO public_user;
GRANT USAGE ON SCHEMA gazetteer TO scar_admin;


--
-- TOC entry 4726 (class 0 OID 0)
-- Dependencies: 318
-- Name: TABLE place_names; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.place_names TO public_user;
GRANT ALL ON TABLE gazetteer.place_names TO scar_admin;


--
-- TOC entry 4727 (class 0 OID 0)
-- Dependencies: 319
-- Name: TABLE feature_types; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.feature_types TO public_user;
GRANT SELECT ON TABLE gazetteer.feature_types TO scar_admin;


--
-- TOC entry 4728 (class 0 OID 0)
-- Dependencies: 320
-- Name: TABLE gazetteers; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.gazetteers TO public_user;
GRANT SELECT ON TABLE gazetteer.gazetteers TO scar_admin;


--
-- TOC entry 4729 (class 0 OID 0)
-- Dependencies: 324
-- Name: TABLE place_names_consolidated; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.place_names_consolidated TO public_user;
GRANT SELECT ON TABLE gazetteer.place_names_consolidated TO scar_admin;


--
-- TOC entry 4730 (class 0 OID 0)
-- Dependencies: 321
-- Name: TABLE gaz_count; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.gaz_count TO public_user;
GRANT SELECT ON TABLE gazetteer.gaz_count TO scar_admin;

--
-- TOC entry 4730 (class 0 OID 0)
-- Dependencies: 321
-- Name: TABLE gaz_count; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.name_count TO public_user;
GRANT SELECT ON TABLE gazetteer.name_count TO scar_admin;


--
-- TOC entry 4731 (class 0 OID 0)
-- Dependencies: 322
-- Name: TABLE glossary; Type: ACL; Schema: gazetteer; Owner: postgres
--

GRANT SELECT ON TABLE gazetteer.glossary TO public_user;
GRANT SELECT ON TABLE gazetteer.glossary TO scar_admin;


-- Completed on 2025-11-07 06:32:32 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict 5IbN8r5v6lhnH8cjx3YkZMbbX7lAqgrTiSdynGyiCieu39418AIzohEnPtktxVM

