--
-- PostgreSQL database dump
--

\restrict OJt3dmPOUOc8ALGxJzbdTo3mZyk0JLmKmWU5YgfnEYi84X6RAvaNX8UUkYMx4dC

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: get_cards_with_tags(uuid); Type: FUNCTION; Schema: public; Owner: infinicard_user
--

CREATE FUNCTION public.get_cards_with_tags(p_user_id uuid) RETURNS TABLE(card_id uuid, full_name character varying, company_name character varying, tags json)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bc.id,
        bc.full_name,
        bc.company_name,
        COALESCE(
            json_agg(
                json_build_object('id', t.id, 'name', t.name, 'color', t.color)
            ) FILTER (WHERE t.id IS NOT NULL),
            '[]'::json
        ) AS tags
    FROM business_cards bc
    LEFT JOIN card_tags ct ON bc.id = ct.card_id
    LEFT JOIN tags t ON ct.tag_id = t.id
    WHERE bc.user_id = p_user_id AND bc.is_deleted = FALSE
    GROUP BY bc.id, bc.full_name, bc.company_name
    ORDER BY bc.created_at DESC;
END;
$$;


ALTER FUNCTION public.get_cards_with_tags(p_user_id uuid) OWNER TO infinicard_user;

--
-- Name: log_sync_event(); Type: FUNCTION; Schema: public; Owner: infinicard_user
--

CREATE FUNCTION public.log_sync_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO sync_log (user_id, entity_type, entity_id, action)
        VALUES (NEW.user_id, TG_TABLE_NAME, NEW.id, 'create');
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO sync_log (user_id, entity_type, entity_id, action)
        VALUES (NEW.user_id, TG_TABLE_NAME, NEW.id, 'update');
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sync_log (user_id, entity_type, entity_id, action)
        VALUES (OLD.user_id, TG_TABLE_NAME, OLD.id, 'delete');
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.log_sync_event() OWNER TO infinicard_user;

--
-- Name: search_business_cards(uuid, character varying); Type: FUNCTION; Schema: public; Owner: infinicard_user
--

CREATE FUNCTION public.search_business_cards(p_user_id uuid, p_search_term character varying) RETURNS TABLE(id uuid, full_name character varying, job_title character varying, company_name character varying, email character varying, phone character varying, color character varying, is_favorite boolean, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bc.id,
        bc.full_name,
        bc.job_title,
        bc.company_name,
        bc.email,
        bc.phone,
        bc.color,
        bc.is_favorite,
        bc.created_at
    FROM business_cards bc
    WHERE bc.user_id = p_user_id
        AND bc.is_deleted = FALSE
        AND (
            bc.full_name ILIKE '%' || p_search_term || '%'
            OR bc.company_name ILIKE '%' || p_search_term || '%'
            OR bc.job_title ILIKE '%' || p_search_term || '%'
            OR bc.email ILIKE '%' || p_search_term || '%'
            OR bc.phone ILIKE '%' || p_search_term || '%'
        )
    ORDER BY bc.is_favorite DESC, bc.created_at DESC;
END;
$$;


ALTER FUNCTION public.search_business_cards(p_user_id uuid, p_search_term character varying) OWNER TO infinicard_user;

--
-- Name: search_contacts(uuid, character varying); Type: FUNCTION; Schema: public; Owner: infinicard_user
--

CREATE FUNCTION public.search_contacts(p_user_id uuid, p_search_term character varying) RETURNS TABLE(id uuid, first_name character varying, last_name character varying, company character varying, email character varying, phone character varying, is_favorite boolean, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.company,
        c.email,
        c.phone,
        c.is_favorite,
        c.created_at
    FROM contacts c
    WHERE c.user_id = p_user_id
        AND c.is_deleted = FALSE
        AND (
            c.first_name ILIKE '%' || p_search_term || '%'
            OR c.last_name ILIKE '%' || p_search_term || '%'
            OR c.company ILIKE '%' || p_search_term || '%'
            OR c.email ILIKE '%' || p_search_term || '%'
            OR c.phone ILIKE '%' || p_search_term || '%'
        )
    ORDER BY c.is_favorite DESC, c.created_at DESC;
END;
$$;


ALTER FUNCTION public.search_contacts(p_user_id uuid, p_search_term character varying) OWNER TO infinicard_user;

--
-- Name: update_connections_count(); Type: FUNCTION; Schema: public; Owner: infinicard_user
--

CREATE FUNCTION public.update_connections_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count + 1 
        WHERE user_id = NEW.sender_id OR user_id = NEW.receiver_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status != 'accepted' AND NEW.status = 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count + 1 
        WHERE user_id = NEW.sender_id OR user_id = NEW.receiver_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count - 1 
        WHERE user_id = NEW.sender_id OR user_id = NEW.receiver_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count - 1 
        WHERE user_id = OLD.sender_id OR user_id = OLD.receiver_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_connections_count() OWNER TO infinicard_user;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: infinicard_user
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO infinicard_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: business_cards; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.business_cards (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    full_name character varying(255) NOT NULL,
    job_title character varying(255),
    company_name character varying(255),
    email character varying(255),
    phone character varying(50),
    website character varying(500),
    address text,
    notes text,
    color character varying(20) DEFAULT '#1E88E5'::character varying,
    is_favorite boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    synced_at timestamp with time zone,
    is_deleted boolean DEFAULT false
);


ALTER TABLE public.business_cards OWNER TO infinicard_user;

--
-- Name: card_social_links; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.card_social_links (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    card_id uuid,
    platform character varying(50) NOT NULL,
    url character varying(500) NOT NULL,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.card_social_links OWNER TO infinicard_user;

--
-- Name: card_tags; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.card_tags (
    card_id uuid NOT NULL,
    tag_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.card_tags OWNER TO infinicard_user;

--
-- Name: connections; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.connections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sender_id uuid,
    receiver_id uuid,
    status character varying(50) DEFAULT 'pending'::character varying,
    message text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.connections OWNER TO infinicard_user;

--
-- Name: contact_social_links; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.contact_social_links (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contact_id uuid,
    platform character varying(50) NOT NULL,
    url character varying(500) NOT NULL,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contact_social_links OWNER TO infinicard_user;

--
-- Name: contact_tags; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.contact_tags (
    contact_id uuid NOT NULL,
    tag_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contact_tags OWNER TO infinicard_user;

--
-- Name: contacts; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.contacts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    first_name character varying(255) NOT NULL,
    last_name character varying(255),
    company character varying(255),
    job_title character varying(255),
    email character varying(255),
    phone character varying(50),
    mobile character varying(50),
    fax character varying(50),
    website character varying(500),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(100),
    postal_code character varying(20),
    country character varying(100),
    notes text,
    is_favorite boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    synced_at timestamp with time zone,
    is_deleted boolean DEFAULT false
);


ALTER TABLE public.contacts OWNER TO infinicard_user;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type character varying(32) NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO infinicard_user;

--
-- Name: professional_tags; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.professional_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    professional_id uuid,
    tag character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.professional_tags OWNER TO infinicard_user;

--
-- Name: professionals; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.professionals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    full_name character varying(255) NOT NULL,
    profession character varying(255),
    location character varying(255),
    field character varying(255),
    avatar_url text,
    bio text,
    connections_count integer DEFAULT 0,
    is_public boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.professionals OWNER TO infinicard_user;

--
-- Name: scan_history; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.scan_history (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    card_id uuid,
    image_path character varying(500),
    ocr_text text,
    scan_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    processing_time_ms integer,
    success boolean DEFAULT true
);


ALTER TABLE public.scan_history OWNER TO infinicard_user;

--
-- Name: sync_log; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.sync_log (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    action character varying(20) NOT NULL,
    synced_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    device_id character varying(255)
);


ALTER TABLE public.sync_log OWNER TO infinicard_user;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.tags (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    name character varying(100) NOT NULL,
    color character varying(20) DEFAULT '#1E88E5'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tags OWNER TO infinicard_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: infinicard_user
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp with time zone,
    is_active boolean DEFAULT true
);


ALTER TABLE public.users OWNER TO infinicard_user;

--
-- Data for Name: business_cards; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.business_cards (id, user_id, full_name, job_title, company_name, email, phone, website, address, notes, color, is_favorite, created_at, updated_at, synced_at, is_deleted) FROM stdin;
5339ceb7-2138-4a79-9e18-a862959a8a12	550e8400-e29b-41d4-a716-446655440000	John Anderson	Senior Software Engineer	TechCorp Solutions	john.anderson@techcorp.com	+1-555-0101	https://techcorp.com	123 Tech Street, Silicon Valley, CA 94025	\N	#1E88E5	t	2025-10-18 08:30:50.3403+00	2025-10-18 08:30:50.3403+00	\N	f
4d34a682-8096-4205-a8ca-52f9b988f6ad	550e8400-e29b-41d4-a716-446655440000	Sarah Mitchell	Product Manager	InnovateLabs	sarah.mitchell@innovatelabs.com	+1-555-0102	https://innovatelabs.io	456 Innovation Ave, Austin, TX 78701	\N	#4CAF50	f	2025-10-18 08:30:50.3403+00	2025-10-18 08:30:50.3403+00	\N	f
55871298-87eb-44b9-8967-e0eabf5f977b	550e8400-e29b-41d4-a716-446655440000	Michael Chen	UX Designer	DesignHub Studio	michael.chen@designhub.com	+1-555-0103	https://designhub.design	789 Creative Blvd, Portland, OR 97201	\N	#9C27B0	t	2025-10-18 08:30:50.3403+00	2025-10-18 08:30:50.3403+00	\N	f
5c492ada-8f01-4fe6-8829-18a123023e2c	550e8400-e29b-41d4-a716-446655440000	Emily Rodriguez	Marketing Director	BrandWorks Agency	emily.rodriguez@brandworks.com	+1-555-0104	https://brandworks.co	321 Marketing Plaza, New York, NY 10001	\N	#FF9800	f	2025-10-18 08:30:50.3403+00	2025-10-18 08:30:50.3403+00	\N	f
1e523a1c-d10b-4fc4-932d-4a30c8444521	550e8400-e29b-41d4-a716-446655440000	David Thompson	CEO & Founder	StartupVentures	david@startupventures.io	+1-555-0105	https://startupventures.io	555 Entrepreneur Way, San Francisco, CA 94105	\N	#F44336	t	2025-10-18 08:30:50.3403+00	2025-10-18 08:30:50.3403+00	\N	f
\.


--
-- Data for Name: card_social_links; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_social_links (id, card_id, platform, url, display_order, created_at) FROM stdin;
a8bc4aae-bfc1-410b-8195-d07a37f98d18	5339ceb7-2138-4a79-9e18-a862959a8a12	linkedin	https://linkedin.com/in/john-anderson	1	2025-10-18 08:30:50.583779+00
5c74f5e3-b1c6-489c-abe6-2d63a8b2d0b8	4d34a682-8096-4205-a8ca-52f9b988f6ad	twitter	https://twitter.com/sarahmitchell	1	2025-10-18 08:30:50.623044+00
\.


--
-- Data for Name: card_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_tags (card_id, tag_id, created_at) FROM stdin;
5339ceb7-2138-4a79-9e18-a862959a8a12	b7308684-cb21-41c2-adf5-b74fa753f7ec	2025-10-18 08:30:50.539974+00
4d34a682-8096-4205-a8ca-52f9b988f6ad	0b35edfe-cc04-4b96-a10b-6c10784ddd45	2025-10-18 08:30:50.539974+00
55871298-87eb-44b9-8967-e0eabf5f977b	b2e12510-50db-45c4-9380-048c035085d7	2025-10-18 08:30:50.539974+00
5339ceb7-2138-4a79-9e18-a862959a8a12	7cb0c64d-3a6c-488e-a375-ec5a10f74efc	2025-10-18 08:30:50.539974+00
\.


--
-- Data for Name: connections; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.connections (id, sender_id, receiver_id, status, message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contact_social_links; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.contact_social_links (id, contact_id, platform, url, display_order, created_at) FROM stdin;
\.


--
-- Data for Name: contact_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.contact_tags (contact_id, tag_id, created_at) FROM stdin;
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.contacts (id, user_id, first_name, last_name, company, job_title, email, phone, mobile, fax, website, address_line1, address_line2, city, state, postal_code, country, notes, is_favorite, created_at, updated_at, synced_at, is_deleted) FROM stdin;
12397669-5ba3-48ce-8df3-98b6c56d769f	550e8400-e29b-41d4-a716-446655440000	Jessica	Taylor	Global Consulting	Senior Consultant	jessica.taylor@globalconsulting.com	+1-555-0201	+1-555-0202	\N	\N	\N	\N	Boston	Massachusetts	\N	USA	\N	t	2025-10-18 08:30:50.441399+00	2025-10-18 08:30:50.441399+00	\N	f
7dd11788-26b5-436f-b0f6-6e87c4e9a7ea	550e8400-e29b-41d4-a716-446655440000	Robert	Williams	Finance Corp	Financial Analyst	robert.williams@financecorp.com	+1-555-0203	+1-555-0204	\N	\N	\N	\N	Chicago	Illinois	\N	USA	\N	f	2025-10-18 08:30:50.441399+00	2025-10-18 08:30:50.441399+00	\N	f
1b377da0-2c69-4973-a0f8-fefdb9ec9a09	550e8400-e29b-41d4-a716-446655440000	Amanda	Brown	Healthcare Solutions	Director of Operations	amanda.brown@healthcaresol.com	+1-555-0205	+1-555-0206	\N	\N	\N	\N	Seattle	Washington	\N	USA	\N	t	2025-10-18 08:30:50.441399+00	2025-10-18 08:30:50.441399+00	\N	f
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.notifications (id, user_id, type, message, is_read, created_at) FROM stdin;
\.


--
-- Data for Name: professional_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professional_tags (id, professional_id, tag, created_at) FROM stdin;
25dce4eb-fb7d-47b6-8f24-ee886f428599	b37d4654-92ed-4291-afb5-f0d1b72e9dca	React	2025-10-18 08:30:53.058538+00
0cc47db0-e9e9-40a2-90a2-e5967654e03b	b37d4654-92ed-4291-afb5-f0d1b72e9dca	Node.js	2025-10-18 08:30:53.058538+00
4e8b3b14-0c79-4869-99ed-e1e50e50f1ff	b37d4654-92ed-4291-afb5-f0d1b72e9dca	Python	2025-10-18 08:30:53.058538+00
2be05e97-bea7-420c-9dee-3760bd28ec20	6c91f815-fa5f-40f8-b272-43e1a19c35cb	UI/UX	2025-10-18 08:30:53.119582+00
88167427-9ee0-4585-a5c1-e9c79c583b4d	6c91f815-fa5f-40f8-b272-43e1a19c35cb	Figma	2025-10-18 08:30:53.119582+00
10511358-7d21-4085-964b-5e10f04bde29	6c91f815-fa5f-40f8-b272-43e1a19c35cb	Prototyping	2025-10-18 08:30:53.119582+00
6aa1ef27-9cdb-4564-9c3e-80e0c0033c0b	600cfb3b-b82e-4ea7-8603-0bb869873cb3	Digital Marketing	2025-10-18 08:30:53.168438+00
420564a2-0dc0-4ce1-85fe-a984fd1e72d7	600cfb3b-b82e-4ea7-8603-0bb869873cb3	SEO	2025-10-18 08:30:53.168438+00
84a81bb6-0ca5-42d3-99ab-4dccf0e93451	600cfb3b-b82e-4ea7-8603-0bb869873cb3	Content	2025-10-18 08:30:53.168438+00
97b61089-6a31-466e-a513-bb0fa1f45e2f	82f0e573-1f69-493b-ad5b-2099638fefd1	ML	2025-10-18 08:30:53.192498+00
445d7ecd-4d5b-472c-b6d2-55ce545dbd8e	82f0e573-1f69-493b-ad5b-2099638fefd1	Python	2025-10-18 08:30:53.192498+00
13127ce5-ba4d-45f5-99de-59345493bac5	82f0e573-1f69-493b-ad5b-2099638fefd1	Analytics	2025-10-18 08:30:53.192498+00
f04b26f9-3257-4f51-9598-35de7d5a3fac	7052f7f5-a95f-43ad-84de-008d9024df3b	Excel	2025-10-18 08:30:53.230056+00
12249e27-a40e-4049-8f12-1ab6397a4cbe	7052f7f5-a95f-43ad-84de-008d9024df3b	SQL	2025-10-18 08:30:53.230056+00
073c6b82-7faf-4dcc-8958-ac8997f0e0dd	7052f7f5-a95f-43ad-84de-008d9024df3b	Tableau	2025-10-18 08:30:53.230056+00
78920ed0-f2e0-4013-8a74-1d1ee22f9a36	be402b5e-11fd-42f9-a8b4-9faf6d69b1f3	React	2025-10-18 08:30:53.272717+00
84320fc0-78e4-45cb-96ae-d499ee340f30	be402b5e-11fd-42f9-a8b4-9faf6d69b1f3	Vue.js	2025-10-18 08:30:53.272717+00
80f88f1f-5db7-44a3-8447-623f6966faa3	be402b5e-11fd-42f9-a8b4-9faf6d69b1f3	TypeScript	2025-10-18 08:30:53.272717+00
a5513c70-f198-4b79-b42b-f4c76bbda328	3b31168d-caba-43d8-ab30-7caf73fe79ea	Copywriting	2025-10-18 08:30:53.291218+00
27dda461-66a0-4699-9df8-14567fed154e	3b31168d-caba-43d8-ab30-7caf73fe79ea	SEO	2025-10-18 08:30:53.291218+00
d377b6b7-e385-4f76-acac-304dbbeee551	3b31168d-caba-43d8-ab30-7caf73fe79ea	Blogging	2025-10-18 08:30:53.291218+00
d3c40d32-9690-443d-81a0-ab4443e88969	14a5db72-d1cb-4dea-aaf7-e40becc973ec	User Research	2025-10-18 08:30:53.334288+00
f16406b1-41d9-4873-9dc6-d425daf86f5c	14a5db72-d1cb-4dea-aaf7-e40becc973ec	Wireframing	2025-10-18 08:30:53.334288+00
ed5f7f1b-03ec-4fcb-9646-9dabb38640d9	14a5db72-d1cb-4dea-aaf7-e40becc973ec	Testing	2025-10-18 08:30:53.334288+00
\.


--
-- Data for Name: professionals; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professionals (id, user_id, full_name, profession, location, field, avatar_url, bio, connections_count, is_public, created_at, updated_at) FROM stdin;
b37d4654-92ed-4291-afb5-f0d1b72e9dca	\N	Sarah Williams	Full Stack Developer	Mumbai	Technology	https://i.pravatar.cc/150?img=10	Passionate about building scalable web applications	245	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
6c91f815-fa5f-40f8-b272-43e1a19c35cb	\N	Michael Chen	Product Designer	Bangalore	Design	https://i.pravatar.cc/150?img=11	Creating beautiful user experiences	189	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
600cfb3b-b82e-4ea7-8603-0bb869873cb3	\N	Priya Sharma	Marketing Manager	Delhi	Marketing	https://i.pravatar.cc/150?img=12	Digital marketing expert with 5+ years experience	312	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
82f0e573-1f69-493b-ad5b-2099638fefd1	\N	David Kumar	Data Scientist	Pune	Technology	https://i.pravatar.cc/150?img=13	ML and AI enthusiast	156	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
7052f7f5-a95f-43ad-84de-008d9024df3b	\N	Emma Johnson	Business Analyst	Mumbai	Finance	https://i.pravatar.cc/150?img=14	Helping businesses make data-driven decisions	198	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
be402b5e-11fd-42f9-a8b4-9faf6d69b1f3	\N	Raj Patel	Frontend Developer	Bangalore	Technology	https://i.pravatar.cc/150?img=15	React and Vue.js specialist	267	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
3b31168d-caba-43d8-ab30-7caf73fe79ea	\N	Lisa Anderson	Content Writer	Delhi	Marketing	https://i.pravatar.cc/150?img=16	Crafting compelling stories for brands	134	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
14a5db72-d1cb-4dea-aaf7-e40becc973ec	\N	Arjun Singh	UX Researcher	Pune	Design	https://i.pravatar.cc/150?img=17	Understanding user behavior	221	t	2025-10-18 08:30:53.005671+00	2025-10-18 08:30:53.005671+00
\.


--
-- Data for Name: scan_history; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.scan_history (id, user_id, card_id, image_path, ocr_text, scan_date, processing_time_ms, success) FROM stdin;
\.


--
-- Data for Name: sync_log; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.sync_log (id, user_id, entity_type, entity_id, action, synced_at, device_id) FROM stdin;
4b7ed8c9-b853-4436-bb89-f19e37693053	550e8400-e29b-41d4-a716-446655440000	business_cards	5339ceb7-2138-4a79-9e18-a862959a8a12	create	2025-10-18 08:30:50.3403+00	\N
e96c3969-313b-407b-b2c9-b58a31a10ca7	550e8400-e29b-41d4-a716-446655440000	business_cards	4d34a682-8096-4205-a8ca-52f9b988f6ad	create	2025-10-18 08:30:50.3403+00	\N
92d5c0af-1965-4716-a873-bbac99ffca0b	550e8400-e29b-41d4-a716-446655440000	business_cards	55871298-87eb-44b9-8967-e0eabf5f977b	create	2025-10-18 08:30:50.3403+00	\N
3b46b656-e804-47fe-848f-c7da45eb2953	550e8400-e29b-41d4-a716-446655440000	business_cards	5c492ada-8f01-4fe6-8829-18a123023e2c	create	2025-10-18 08:30:50.3403+00	\N
e23d61ab-e10b-4ce3-a072-f498491064bf	550e8400-e29b-41d4-a716-446655440000	business_cards	1e523a1c-d10b-4fc4-932d-4a30c8444521	create	2025-10-18 08:30:50.3403+00	\N
b477ea46-ee8d-4639-9547-c4687fb73c5f	550e8400-e29b-41d4-a716-446655440000	contacts	12397669-5ba3-48ce-8df3-98b6c56d769f	create	2025-10-18 08:30:50.441399+00	\N
d861240b-1804-413c-8aa5-1ec6a864f3e8	550e8400-e29b-41d4-a716-446655440000	contacts	7dd11788-26b5-436f-b0f6-6e87c4e9a7ea	create	2025-10-18 08:30:50.441399+00	\N
474167bb-78f1-4aba-b2cf-e9e9e6139d9c	550e8400-e29b-41d4-a716-446655440000	contacts	1b377da0-2c69-4973-a0f8-fefdb9ec9a09	create	2025-10-18 08:30:50.441399+00	\N
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.tags (id, user_id, name, color, created_at) FROM stdin;
b7308684-cb21-41c2-adf5-b74fa753f7ec	550e8400-e29b-41d4-a716-446655440000	Client	#1E88E5	2025-10-18 08:30:50.481579+00
0b35edfe-cc04-4b96-a10b-6c10784ddd45	550e8400-e29b-41d4-a716-446655440000	Partner	#4CAF50	2025-10-18 08:30:50.481579+00
494214a4-2a17-4430-b6bd-3b35f86de562	550e8400-e29b-41d4-a716-446655440000	Vendor	#FF9800	2025-10-18 08:30:50.481579+00
b2e12510-50db-45c4-9380-048c035085d7	550e8400-e29b-41d4-a716-446655440000	Colleague	#9C27B0	2025-10-18 08:30:50.481579+00
7cb0c64d-3a6c-488e-a375-ec5a10f74efc	550e8400-e29b-41d4-a716-446655440000	Urgent	#F44336	2025-10-18 08:30:50.481579+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.users (id, email, username, password_hash, full_name, created_at, updated_at, last_login, is_active) FROM stdin;
550e8400-e29b-41d4-a716-446655440000	demo@infinicard.com	demo_user	$2a$10$YourHashedPasswordHere	Demo User	2025-10-18 08:30:50.30656+00	2025-10-18 08:30:50.30656+00	\N	t
0d07335d-2444-4a3b-9404-1bb085486be0	jahnviaghera@gmail.com	jahnviaghera	$2a$10$8Lklo91gLf5w8.SfMjspwe3UCHp/.QWa1OA5D2U1CKY8itO1APgh2	Jahnvi Aghera	2025-10-18 08:33:51.191098+00	2025-10-18 08:33:51.191098+00	\N	t
\.


--
-- Name: business_cards business_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.business_cards
    ADD CONSTRAINT business_cards_pkey PRIMARY KEY (id);


--
-- Name: card_social_links card_social_links_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.card_social_links
    ADD CONSTRAINT card_social_links_pkey PRIMARY KEY (id);


--
-- Name: card_tags card_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.card_tags
    ADD CONSTRAINT card_tags_pkey PRIMARY KEY (card_id, tag_id);


--
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: connections connections_sender_id_receiver_id_key; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_sender_id_receiver_id_key UNIQUE (sender_id, receiver_id);


--
-- Name: contact_social_links contact_social_links_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contact_social_links
    ADD CONSTRAINT contact_social_links_pkey PRIMARY KEY (id);


--
-- Name: contact_tags contact_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contact_tags
    ADD CONSTRAINT contact_tags_pkey PRIMARY KEY (contact_id, tag_id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: professional_tags professional_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.professional_tags
    ADD CONSTRAINT professional_tags_pkey PRIMARY KEY (id);


--
-- Name: professionals professionals_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.professionals
    ADD CONSTRAINT professionals_pkey PRIMARY KEY (id);


--
-- Name: scan_history scan_history_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.scan_history
    ADD CONSTRAINT scan_history_pkey PRIMARY KEY (id);


--
-- Name: sync_log sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.sync_log
    ADD CONSTRAINT sync_log_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tags tags_user_id_name_key; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_user_id_name_key UNIQUE (user_id, name);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_card_social_links_card_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_card_social_links_card_id ON public.card_social_links USING btree (card_id);


--
-- Name: idx_card_tags_card_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_card_tags_card_id ON public.card_tags USING btree (card_id);


--
-- Name: idx_card_tags_tag_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_card_tags_tag_id ON public.card_tags USING btree (tag_id);


--
-- Name: idx_cards_created_at; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_cards_created_at ON public.business_cards USING btree (created_at DESC);


--
-- Name: idx_cards_is_deleted; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_cards_is_deleted ON public.business_cards USING btree (is_deleted) WHERE (is_deleted = false);


--
-- Name: idx_cards_is_favorite; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_cards_is_favorite ON public.business_cards USING btree (is_favorite) WHERE (is_favorite = true);


--
-- Name: idx_cards_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_cards_user_id ON public.business_cards USING btree (user_id);


--
-- Name: idx_connections_receiver; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_connections_receiver ON public.connections USING btree (receiver_id);


--
-- Name: idx_connections_sender; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_connections_sender ON public.connections USING btree (sender_id);


--
-- Name: idx_connections_status; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_connections_status ON public.connections USING btree (status);


--
-- Name: idx_contact_social_links_contact_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contact_social_links_contact_id ON public.contact_social_links USING btree (contact_id);


--
-- Name: idx_contact_tags_contact_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contact_tags_contact_id ON public.contact_tags USING btree (contact_id);


--
-- Name: idx_contact_tags_tag_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contact_tags_tag_id ON public.contact_tags USING btree (tag_id);


--
-- Name: idx_contacts_created_at; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contacts_created_at ON public.contacts USING btree (created_at DESC);


--
-- Name: idx_contacts_is_deleted; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contacts_is_deleted ON public.contacts USING btree (is_deleted) WHERE (is_deleted = false);


--
-- Name: idx_contacts_is_favorite; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contacts_is_favorite ON public.contacts USING btree (is_favorite) WHERE (is_favorite = true);


--
-- Name: idx_contacts_name; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contacts_name ON public.contacts USING btree (first_name, last_name);


--
-- Name: idx_contacts_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_contacts_user_id ON public.contacts USING btree (user_id);


--
-- Name: idx_notifications_is_read; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_notifications_is_read ON public.notifications USING btree (is_read);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_professional_tags_professional_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_professional_tags_professional_id ON public.professional_tags USING btree (professional_id);


--
-- Name: idx_professionals_field; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_professionals_field ON public.professionals USING btree (field);


--
-- Name: idx_professionals_location; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_professionals_location ON public.professionals USING btree (location);


--
-- Name: idx_professionals_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_professionals_user_id ON public.professionals USING btree (user_id);


--
-- Name: idx_scan_history_scan_date; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_scan_history_scan_date ON public.scan_history USING btree (scan_date DESC);


--
-- Name: idx_scan_history_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_scan_history_user_id ON public.scan_history USING btree (user_id);


--
-- Name: idx_sync_log_synced_at; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_sync_log_synced_at ON public.sync_log USING btree (synced_at DESC);


--
-- Name: idx_sync_log_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_sync_log_user_id ON public.sync_log USING btree (user_id);


--
-- Name: idx_tags_user_id; Type: INDEX; Schema: public; Owner: infinicard_user
--

CREATE INDEX idx_tags_user_id ON public.tags USING btree (user_id);


--
-- Name: business_cards sync_log_business_cards; Type: TRIGGER; Schema: public; Owner: infinicard_user
--

CREATE TRIGGER sync_log_business_cards AFTER INSERT OR DELETE OR UPDATE ON public.business_cards FOR EACH ROW EXECUTE FUNCTION public.log_sync_event();


--
-- Name: contacts sync_log_contacts; Type: TRIGGER; Schema: public; Owner: infinicard_user
--

CREATE TRIGGER sync_log_contacts AFTER INSERT OR DELETE OR UPDATE ON public.contacts FOR EACH ROW EXECUTE FUNCTION public.log_sync_event();


--
-- Name: connections trigger_update_connections_count; Type: TRIGGER; Schema: public; Owner: infinicard_user
--

CREATE TRIGGER trigger_update_connections_count AFTER INSERT OR DELETE OR UPDATE ON public.connections FOR EACH ROW EXECUTE FUNCTION public.update_connections_count();


--
-- Name: business_cards update_business_cards_updated_at; Type: TRIGGER; Schema: public; Owner: infinicard_user
--

CREATE TRIGGER update_business_cards_updated_at BEFORE UPDATE ON public.business_cards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: contacts update_contacts_updated_at; Type: TRIGGER; Schema: public; Owner: infinicard_user
--

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON public.contacts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: infinicard_user
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: business_cards business_cards_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.business_cards
    ADD CONSTRAINT business_cards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: card_social_links card_social_links_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.card_social_links
    ADD CONSTRAINT card_social_links_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.business_cards(id) ON DELETE CASCADE;


--
-- Name: card_tags card_tags_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.card_tags
    ADD CONSTRAINT card_tags_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.business_cards(id) ON DELETE CASCADE;


--
-- Name: card_tags card_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.card_tags
    ADD CONSTRAINT card_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: connections connections_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: connections connections_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: contact_social_links contact_social_links_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contact_social_links
    ADD CONSTRAINT contact_social_links_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_tags contact_tags_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contact_tags
    ADD CONSTRAINT contact_tags_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_tags contact_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contact_tags
    ADD CONSTRAINT contact_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: professional_tags professional_tags_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.professional_tags
    ADD CONSTRAINT professional_tags_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professionals(id) ON DELETE CASCADE;


--
-- Name: professionals professionals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.professionals
    ADD CONSTRAINT professionals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: scan_history scan_history_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.scan_history
    ADD CONSTRAINT scan_history_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.business_cards(id) ON DELETE SET NULL;


--
-- Name: scan_history scan_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.scan_history
    ADD CONSTRAINT scan_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sync_log sync_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.sync_log
    ADD CONSTRAINT sync_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: tags tags_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: infinicard_user
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict OJt3dmPOUOc8ALGxJzbdTo3mZyk0JLmKmWU5YgfnEYi84X6RAvaNX8UUkYMx4dC

