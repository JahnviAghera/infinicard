--
-- PostgreSQL database dump
--

\restrict WyKRXUMXT8QXX76ucbnrzyuc9AbP83lFudkUAArJRWvhJoClkIDfXRwnTvLFOBc

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
aa24d4c4-2e95-485b-a365-788fbf675a25	550e8400-e29b-41d4-a716-446655440000	John Anderson	Senior Software Engineer	TechCorp Solutions	john.anderson@techcorp.com	+1-555-0101	https://techcorp.com	123 Tech Street, Silicon Valley, CA 94025	\N	#1E88E5	t	2025-10-18 08:48:20.508355+00	2025-10-18 08:48:20.508355+00	\N	f
d3a0f05d-fe9c-41de-b3e1-f09679b6a433	550e8400-e29b-41d4-a716-446655440000	Sarah Mitchell	Product Manager	InnovateLabs	sarah.mitchell@innovatelabs.com	+1-555-0102	https://innovatelabs.io	456 Innovation Ave, Austin, TX 78701	\N	#4CAF50	f	2025-10-18 08:48:20.508355+00	2025-10-18 08:48:20.508355+00	\N	f
2fbdcc4a-c83e-4f29-a165-2283b807cf45	550e8400-e29b-41d4-a716-446655440000	Michael Chen	UX Designer	DesignHub Studio	michael.chen@designhub.com	+1-555-0103	https://designhub.design	789 Creative Blvd, Portland, OR 97201	\N	#9C27B0	t	2025-10-18 08:48:20.508355+00	2025-10-18 08:48:20.508355+00	\N	f
2d17d019-f89a-4f12-b08b-c9844238e658	550e8400-e29b-41d4-a716-446655440000	Emily Rodriguez	Marketing Director	BrandWorks Agency	emily.rodriguez@brandworks.com	+1-555-0104	https://brandworks.co	321 Marketing Plaza, New York, NY 10001	\N	#FF9800	f	2025-10-18 08:48:20.508355+00	2025-10-18 08:48:20.508355+00	\N	f
1c4f7010-7773-4231-aed2-3318a511c49d	550e8400-e29b-41d4-a716-446655440000	David Thompson	CEO & Founder	StartupVentures	david@startupventures.io	+1-555-0105	https://startupventures.io	555 Entrepreneur Way, San Francisco, CA 94105	\N	#F44336	t	2025-10-18 08:48:20.508355+00	2025-10-18 08:48:20.508355+00	\N	f
\.


--
-- Data for Name: card_social_links; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_social_links (id, card_id, platform, url, display_order, created_at) FROM stdin;
9e637744-8c2c-4ca2-a0b5-8d44c91f6f9d	aa24d4c4-2e95-485b-a365-788fbf675a25	linkedin	https://linkedin.com/in/john-anderson	1	2025-10-18 08:48:20.741484+00
297351cd-f457-462c-bfeb-7eafd7f93d67	d3a0f05d-fe9c-41de-b3e1-f09679b6a433	twitter	https://twitter.com/sarahmitchell	1	2025-10-18 08:48:20.812608+00
\.


--
-- Data for Name: card_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_tags (card_id, tag_id, created_at) FROM stdin;
aa24d4c4-2e95-485b-a365-788fbf675a25	39d70b08-78f3-444c-a190-9f6e582a0862	2025-10-18 08:48:20.671393+00
d3a0f05d-fe9c-41de-b3e1-f09679b6a433	7610ffd0-51f8-4053-a2fa-f881b95b2cfa	2025-10-18 08:48:20.671393+00
2fbdcc4a-c83e-4f29-a165-2283b807cf45	59ad7d5b-1b90-4f23-ae6b-c65eac8022f2	2025-10-18 08:48:20.671393+00
aa24d4c4-2e95-485b-a365-788fbf675a25	1ffc2919-3f75-4b1b-bddb-67e8fe6acf9e	2025-10-18 08:48:20.671393+00
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
268eb94e-eb4d-42e4-93a2-a5da0f37834f	550e8400-e29b-41d4-a716-446655440000	Jessica	Taylor	Global Consulting	Senior Consultant	jessica.taylor@globalconsulting.com	+1-555-0201	+1-555-0202	\N	\N	\N	\N	Boston	Massachusetts	\N	USA	\N	t	2025-10-18 08:48:20.554786+00	2025-10-18 08:48:20.554786+00	\N	f
cbe96a15-8ce2-422f-88e7-28a931c89555	550e8400-e29b-41d4-a716-446655440000	Robert	Williams	Finance Corp	Financial Analyst	robert.williams@financecorp.com	+1-555-0203	+1-555-0204	\N	\N	\N	\N	Chicago	Illinois	\N	USA	\N	f	2025-10-18 08:48:20.554786+00	2025-10-18 08:48:20.554786+00	\N	f
55b67285-1246-44c5-ab42-b48eb8450ab7	550e8400-e29b-41d4-a716-446655440000	Amanda	Brown	Healthcare Solutions	Director of Operations	amanda.brown@healthcaresol.com	+1-555-0205	+1-555-0206	\N	\N	\N	\N	Seattle	Washington	\N	USA	\N	t	2025-10-18 08:48:20.554786+00	2025-10-18 08:48:20.554786+00	\N	f
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
ddecf7a4-4a70-4bbc-ba58-bbf0c7f17a1f	f1d569db-7f9c-458d-8709-0d7339a9fcc3	React	2025-10-18 08:48:23.911218+00
c19c5857-e0fb-4ad0-8f8f-0d547537aea4	f1d569db-7f9c-458d-8709-0d7339a9fcc3	Node.js	2025-10-18 08:48:23.911218+00
411a9bee-fdae-47a4-8944-653e96830063	f1d569db-7f9c-458d-8709-0d7339a9fcc3	Python	2025-10-18 08:48:23.911218+00
7f97c84f-df9a-4117-b862-776efb6f1dae	1d900ae4-dbd4-41f3-975d-00b735f17383	UI/UX	2025-10-18 08:48:23.957003+00
f10ddd9a-2a67-4298-bba2-b103e3f90ede	1d900ae4-dbd4-41f3-975d-00b735f17383	Figma	2025-10-18 08:48:23.957003+00
c2aa32e6-6c08-4e06-a3c8-6872a1d0f99e	1d900ae4-dbd4-41f3-975d-00b735f17383	Prototyping	2025-10-18 08:48:23.957003+00
adf9aa70-469c-4a01-bde1-b65f5262deeb	deb4744e-60aa-4b4b-a2c1-39f9e1a206ed	Digital Marketing	2025-10-18 08:48:24.002854+00
caf2549b-2a49-4a19-8f0f-17bdd39669c6	deb4744e-60aa-4b4b-a2c1-39f9e1a206ed	SEO	2025-10-18 08:48:24.002854+00
0904ae45-02bd-412e-b9d4-a187b84360c2	deb4744e-60aa-4b4b-a2c1-39f9e1a206ed	Content	2025-10-18 08:48:24.002854+00
82548d81-a2d9-4814-bcd2-49a6d12494be	b73e2c04-1d6e-446a-8412-b2f4ac16f5cd	ML	2025-10-18 08:48:24.034704+00
2a889de8-aaab-4030-8d33-e89fb58a1591	b73e2c04-1d6e-446a-8412-b2f4ac16f5cd	Python	2025-10-18 08:48:24.034704+00
d3efa850-beea-4160-93ac-e264340f6424	b73e2c04-1d6e-446a-8412-b2f4ac16f5cd	Analytics	2025-10-18 08:48:24.034704+00
f296c6be-1d50-4317-a5a6-84dc58458faf	34034d10-0201-4ed5-a2fd-4b9d7b46c673	Excel	2025-10-18 08:48:24.07397+00
dd600984-f521-4349-b3ba-a9916622b1ae	34034d10-0201-4ed5-a2fd-4b9d7b46c673	SQL	2025-10-18 08:48:24.07397+00
2cbccc0e-0ded-4985-bfbe-3f01e2b23585	34034d10-0201-4ed5-a2fd-4b9d7b46c673	Tableau	2025-10-18 08:48:24.07397+00
bed997dd-5e10-4f67-93aa-df61358061e3	9a4db7eb-7647-4982-982e-32267ea35dfc	React	2025-10-18 08:48:24.11962+00
e90ffa08-b62f-47b7-b92d-78c359d10252	9a4db7eb-7647-4982-982e-32267ea35dfc	Vue.js	2025-10-18 08:48:24.11962+00
5a459504-fd77-4ee4-8138-daec5238588e	9a4db7eb-7647-4982-982e-32267ea35dfc	TypeScript	2025-10-18 08:48:24.11962+00
9b62cfce-18a0-4bc9-9629-89da7715f3c7	790abdf0-f40d-4adf-ac42-7f0de4d9c61d	Copywriting	2025-10-18 08:48:24.14507+00
2391739a-27cd-4313-a067-85a5fd104c10	790abdf0-f40d-4adf-ac42-7f0de4d9c61d	SEO	2025-10-18 08:48:24.14507+00
9ab94dbd-182e-4633-80dc-46c82349f0bf	790abdf0-f40d-4adf-ac42-7f0de4d9c61d	Blogging	2025-10-18 08:48:24.14507+00
9588be77-ca7e-4948-8730-c8484f9a7965	938757b1-dcbb-451e-8df9-5335e9b6ff8a	User Research	2025-10-18 08:48:24.170475+00
4bcdac3c-f019-4705-8452-0449dab1dea4	938757b1-dcbb-451e-8df9-5335e9b6ff8a	Wireframing	2025-10-18 08:48:24.170475+00
f808fe51-55c0-4d5c-a629-278ff49ee4d4	938757b1-dcbb-451e-8df9-5335e9b6ff8a	Testing	2025-10-18 08:48:24.170475+00
\.


--
-- Data for Name: professionals; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professionals (id, user_id, full_name, profession, location, field, avatar_url, bio, connections_count, is_public, created_at, updated_at) FROM stdin;
f1d569db-7f9c-458d-8709-0d7339a9fcc3	\N	Sarah Williams	Full Stack Developer	Mumbai	Technology	https://i.pravatar.cc/150?img=10	Passionate about building scalable web applications	245	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
1d900ae4-dbd4-41f3-975d-00b735f17383	\N	Michael Chen	Product Designer	Bangalore	Design	https://i.pravatar.cc/150?img=11	Creating beautiful user experiences	189	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
deb4744e-60aa-4b4b-a2c1-39f9e1a206ed	\N	Priya Sharma	Marketing Manager	Delhi	Marketing	https://i.pravatar.cc/150?img=12	Digital marketing expert with 5+ years experience	312	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
b73e2c04-1d6e-446a-8412-b2f4ac16f5cd	\N	David Kumar	Data Scientist	Pune	Technology	https://i.pravatar.cc/150?img=13	ML and AI enthusiast	156	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
34034d10-0201-4ed5-a2fd-4b9d7b46c673	\N	Emma Johnson	Business Analyst	Mumbai	Finance	https://i.pravatar.cc/150?img=14	Helping businesses make data-driven decisions	198	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
9a4db7eb-7647-4982-982e-32267ea35dfc	\N	Raj Patel	Frontend Developer	Bangalore	Technology	https://i.pravatar.cc/150?img=15	React and Vue.js specialist	267	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
790abdf0-f40d-4adf-ac42-7f0de4d9c61d	\N	Lisa Anderson	Content Writer	Delhi	Marketing	https://i.pravatar.cc/150?img=16	Crafting compelling stories for brands	134	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
938757b1-dcbb-451e-8df9-5335e9b6ff8a	\N	Arjun Singh	UX Researcher	Pune	Design	https://i.pravatar.cc/150?img=17	Understanding user behavior	221	t	2025-10-18 08:48:23.865951+00	2025-10-18 08:48:23.865951+00
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
2f894516-88c7-437a-b377-86cb21bb4548	550e8400-e29b-41d4-a716-446655440000	business_cards	aa24d4c4-2e95-485b-a365-788fbf675a25	create	2025-10-18 08:48:20.508355+00	\N
36530c41-3222-4f65-a244-c4bace7a90fd	550e8400-e29b-41d4-a716-446655440000	business_cards	d3a0f05d-fe9c-41de-b3e1-f09679b6a433	create	2025-10-18 08:48:20.508355+00	\N
7c34f609-59a6-4cfd-8987-400855cc4547	550e8400-e29b-41d4-a716-446655440000	business_cards	2fbdcc4a-c83e-4f29-a165-2283b807cf45	create	2025-10-18 08:48:20.508355+00	\N
0d36ac98-ef18-4944-b02e-675ac791dda3	550e8400-e29b-41d4-a716-446655440000	business_cards	2d17d019-f89a-4f12-b08b-c9844238e658	create	2025-10-18 08:48:20.508355+00	\N
9364dafc-b0f5-4a40-bf6e-6d10e22fb09d	550e8400-e29b-41d4-a716-446655440000	business_cards	1c4f7010-7773-4231-aed2-3318a511c49d	create	2025-10-18 08:48:20.508355+00	\N
1913537a-a53d-4c04-9a10-09faf0289acd	550e8400-e29b-41d4-a716-446655440000	contacts	268eb94e-eb4d-42e4-93a2-a5da0f37834f	create	2025-10-18 08:48:20.554786+00	\N
58ee43a5-676b-4093-ab7c-fe8bf64bfde4	550e8400-e29b-41d4-a716-446655440000	contacts	cbe96a15-8ce2-422f-88e7-28a931c89555	create	2025-10-18 08:48:20.554786+00	\N
eff3ca6e-d9ff-4bdd-859d-413eaedb8900	550e8400-e29b-41d4-a716-446655440000	contacts	55b67285-1246-44c5-ab42-b48eb8450ab7	create	2025-10-18 08:48:20.554786+00	\N
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.tags (id, user_id, name, color, created_at) FROM stdin;
39d70b08-78f3-444c-a190-9f6e582a0862	550e8400-e29b-41d4-a716-446655440000	Client	#1E88E5	2025-10-18 08:48:20.598895+00
7610ffd0-51f8-4053-a2fa-f881b95b2cfa	550e8400-e29b-41d4-a716-446655440000	Partner	#4CAF50	2025-10-18 08:48:20.598895+00
27b47e9d-b9db-4c38-8a22-1efce539de34	550e8400-e29b-41d4-a716-446655440000	Vendor	#FF9800	2025-10-18 08:48:20.598895+00
59ad7d5b-1b90-4f23-ae6b-c65eac8022f2	550e8400-e29b-41d4-a716-446655440000	Colleague	#9C27B0	2025-10-18 08:48:20.598895+00
1ffc2919-3f75-4b1b-bddb-67e8fe6acf9e	550e8400-e29b-41d4-a716-446655440000	Urgent	#F44336	2025-10-18 08:48:20.598895+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.users (id, email, username, password_hash, full_name, created_at, updated_at, last_login, is_active) FROM stdin;
550e8400-e29b-41d4-a716-446655440000	demo@infinicard.com	demo_user	$2a$10$YourHashedPasswordHere	Demo User	2025-10-18 08:48:20.470485+00	2025-10-18 08:48:20.470485+00	\N	t
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

\unrestrict WyKRXUMXT8QXX76ucbnrzyuc9AbP83lFudkUAArJRWvhJoClkIDfXRwnTvLFOBc

