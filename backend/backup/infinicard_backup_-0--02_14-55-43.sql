--
-- PostgreSQL database dump
--

\restrict odi9Zj20yRwgMDqRSAQcJjfRahnp36OGPPRNi8KLtkQbgXRPVGt0wVqWWbbRLte

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
bdeedc45-2e1a-4098-a487-9cc359e90b53	550e8400-e29b-41d4-a716-446655440000	John Anderson	Senior Software Engineer	TechCorp Solutions	john.anderson@techcorp.com	+1-555-0101	https://techcorp.com	123 Tech Street, Silicon Valley, CA 94025	\N	#1E88E5	t	2025-10-18 08:56:02.632142+00	2025-10-18 08:56:02.632142+00	\N	f
09ec5177-c845-409e-924e-5ab54b7b0016	550e8400-e29b-41d4-a716-446655440000	Sarah Mitchell	Product Manager	InnovateLabs	sarah.mitchell@innovatelabs.com	+1-555-0102	https://innovatelabs.io	456 Innovation Ave, Austin, TX 78701	\N	#4CAF50	f	2025-10-18 08:56:02.632142+00	2025-10-18 08:56:02.632142+00	\N	f
fff43b68-ccd9-4063-bf42-991c8f6aef8b	550e8400-e29b-41d4-a716-446655440000	Michael Chen	UX Designer	DesignHub Studio	michael.chen@designhub.com	+1-555-0103	https://designhub.design	789 Creative Blvd, Portland, OR 97201	\N	#9C27B0	t	2025-10-18 08:56:02.632142+00	2025-10-18 08:56:02.632142+00	\N	f
1930377f-8d03-4474-8c5d-55b366a074a0	550e8400-e29b-41d4-a716-446655440000	Emily Rodriguez	Marketing Director	BrandWorks Agency	emily.rodriguez@brandworks.com	+1-555-0104	https://brandworks.co	321 Marketing Plaza, New York, NY 10001	\N	#FF9800	f	2025-10-18 08:56:02.632142+00	2025-10-18 08:56:02.632142+00	\N	f
48874088-b390-4366-9f64-4e18872bdf69	550e8400-e29b-41d4-a716-446655440000	David Thompson	CEO & Founder	StartupVentures	david@startupventures.io	+1-555-0105	https://startupventures.io	555 Entrepreneur Way, San Francisco, CA 94105	\N	#F44336	t	2025-10-18 08:56:02.632142+00	2025-10-18 08:56:02.632142+00	\N	f
53bf9192-f609-4f9a-b43e-036779bb1662	53862d25-d38b-4a33-8cec-bdf003488a00	JAHNVI AGHERA	Founder	SUN K INNOVATIONS	jahnviaghera@gmail.com	+918799448954	\N	\N	\N	#1e88e5	f	2025-10-18 09:16:11.516023+00	2025-10-18 09:16:11.516023+00	\N	f
\.


--
-- Data for Name: card_social_links; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_social_links (id, card_id, platform, url, display_order, created_at) FROM stdin;
2b026400-64dc-473e-972b-10f5d4e18088	bdeedc45-2e1a-4098-a487-9cc359e90b53	linkedin	https://linkedin.com/in/john-anderson	1	2025-10-18 08:56:02.753758+00
7dc26c66-1771-4422-8dde-5e93796bbb0f	09ec5177-c845-409e-924e-5ab54b7b0016	twitter	https://twitter.com/sarahmitchell	1	2025-10-18 08:56:02.790145+00
\.


--
-- Data for Name: card_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_tags (card_id, tag_id, created_at) FROM stdin;
bdeedc45-2e1a-4098-a487-9cc359e90b53	9d00a4aa-ab3e-4016-ada5-eedb14c3d13b	2025-10-18 08:56:02.7243+00
09ec5177-c845-409e-924e-5ab54b7b0016	1efdb2de-5280-4d4a-944a-69937a0ebe77	2025-10-18 08:56:02.7243+00
fff43b68-ccd9-4063-bf42-991c8f6aef8b	eabdc869-f48a-47f0-9731-57ef2a309ef9	2025-10-18 08:56:02.7243+00
bdeedc45-2e1a-4098-a487-9cc359e90b53	8881e821-4116-472a-b4ea-18c9a87e1984	2025-10-18 08:56:02.7243+00
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
c56c5174-a881-4247-8437-e6dd06412189	550e8400-e29b-41d4-a716-446655440000	Jessica	Taylor	Global Consulting	Senior Consultant	jessica.taylor@globalconsulting.com	+1-555-0201	+1-555-0202	\N	\N	\N	\N	Boston	Massachusetts	\N	USA	\N	t	2025-10-18 08:56:02.662363+00	2025-10-18 08:56:02.662363+00	\N	f
d888143d-8c9c-4641-9ca7-fc075ad0b2d3	550e8400-e29b-41d4-a716-446655440000	Robert	Williams	Finance Corp	Financial Analyst	robert.williams@financecorp.com	+1-555-0203	+1-555-0204	\N	\N	\N	\N	Chicago	Illinois	\N	USA	\N	f	2025-10-18 08:56:02.662363+00	2025-10-18 08:56:02.662363+00	\N	f
9df90a16-38b0-472b-92fb-00e735f6015d	550e8400-e29b-41d4-a716-446655440000	Amanda	Brown	Healthcare Solutions	Director of Operations	amanda.brown@healthcaresol.com	+1-555-0205	+1-555-0206	\N	\N	\N	\N	Seattle	Washington	\N	USA	\N	t	2025-10-18 08:56:02.662363+00	2025-10-18 08:56:02.662363+00	\N	f
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.notifications (id, user_id, type, message, is_read, created_at) FROM stdin;
eae13045-d107-4c16-bb5e-545a998e8739	53862d25-d38b-4a33-8cec-bdf003488a00	card_added	Business card "JAHNVI AGHERA" was added.	f	2025-10-18 09:16:11.79003
\.


--
-- Data for Name: professional_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professional_tags (id, professional_id, tag, created_at) FROM stdin;
24630eb3-259e-4bb2-a509-9cbe749ddc14	f4da467c-40df-44b6-84c9-af99b6a42062	React	2025-10-18 08:56:04.947583+00
1f7bd5aa-2573-4660-a492-e2e520f9c780	f4da467c-40df-44b6-84c9-af99b6a42062	Node.js	2025-10-18 08:56:04.947583+00
c8ec7ce6-fa26-4f07-a2e4-a6f053d9e3ef	f4da467c-40df-44b6-84c9-af99b6a42062	Python	2025-10-18 08:56:04.947583+00
e2d17edf-68fe-46b2-801c-df1773500227	9553004a-2e04-4c76-ace3-0fe7412676b3	UI/UX	2025-10-18 08:56:04.992766+00
bc61d7fe-f7d7-4cdd-8239-84d5811c7d1a	9553004a-2e04-4c76-ace3-0fe7412676b3	Figma	2025-10-18 08:56:04.992766+00
fc2a753c-5f33-42ba-aa73-864f42434ee8	9553004a-2e04-4c76-ace3-0fe7412676b3	Prototyping	2025-10-18 08:56:04.992766+00
41496f25-c7fe-4f1a-894f-eb725d5f37aa	f1c30704-aafb-45bf-9cee-70bdd7738872	Digital Marketing	2025-10-18 08:56:05.03911+00
9ec7d767-cc05-4721-8517-598ececffcb1	f1c30704-aafb-45bf-9cee-70bdd7738872	SEO	2025-10-18 08:56:05.03911+00
509d9e7d-411d-4bea-9e78-200988712087	f1c30704-aafb-45bf-9cee-70bdd7738872	Content	2025-10-18 08:56:05.03911+00
d6e693a8-0182-4ba3-a283-b54a76ba0c1e	fed875c7-729c-4423-bbb3-076d2d4e70d2	ML	2025-10-18 08:56:05.110373+00
83093189-eb29-47d6-94f0-1badc56ac907	fed875c7-729c-4423-bbb3-076d2d4e70d2	Python	2025-10-18 08:56:05.110373+00
cdcb5f95-14c4-48fd-adcc-4cd48ff481ee	fed875c7-729c-4423-bbb3-076d2d4e70d2	Analytics	2025-10-18 08:56:05.110373+00
01fdffb7-242d-460e-93bd-dccdeadd3441	479d89e4-5f9b-43f0-895e-d5e48d728539	Excel	2025-10-18 08:56:05.14526+00
ff816141-3a03-4d88-a0fc-7132ed2322e6	479d89e4-5f9b-43f0-895e-d5e48d728539	SQL	2025-10-18 08:56:05.14526+00
3c2c042b-ec1b-4d67-bb38-1bbf06dd1ea0	479d89e4-5f9b-43f0-895e-d5e48d728539	Tableau	2025-10-18 08:56:05.14526+00
04bfe88c-2a6e-46cf-a1c7-5b18ad8a7b06	3ef6d9d6-ec00-414f-af3b-bec5d2f6ecc5	React	2025-10-18 08:56:05.170754+00
02e2df96-da03-41c5-aad8-8d2376cf4707	3ef6d9d6-ec00-414f-af3b-bec5d2f6ecc5	Vue.js	2025-10-18 08:56:05.170754+00
33bfcb80-05cb-4397-8830-19dfb92feb18	3ef6d9d6-ec00-414f-af3b-bec5d2f6ecc5	TypeScript	2025-10-18 08:56:05.170754+00
ad9fa8a4-966d-4a32-99c9-6d1008f71bd3	6c01f21a-ddc7-4c15-b7f1-ff3b6312ff4b	Copywriting	2025-10-18 08:56:05.196059+00
71fd8599-df31-4c30-b003-5ba9012f4358	6c01f21a-ddc7-4c15-b7f1-ff3b6312ff4b	SEO	2025-10-18 08:56:05.196059+00
9c98ad36-ad0a-4197-b005-f35ee4ebc5ef	6c01f21a-ddc7-4c15-b7f1-ff3b6312ff4b	Blogging	2025-10-18 08:56:05.196059+00
2bb9478c-610d-422f-a7f9-0bbbcd397e3c	f834aa2f-0824-44f2-825e-f1c97417fe3d	User Research	2025-10-18 08:56:05.221631+00
e1be4766-43fd-4d41-950e-0ca41c5d6995	f834aa2f-0824-44f2-825e-f1c97417fe3d	Wireframing	2025-10-18 08:56:05.221631+00
cf903d9e-b49e-4adb-9ffa-f75b23de6656	f834aa2f-0824-44f2-825e-f1c97417fe3d	Testing	2025-10-18 08:56:05.221631+00
\.


--
-- Data for Name: professionals; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professionals (id, user_id, full_name, profession, location, field, avatar_url, bio, connections_count, is_public, created_at, updated_at) FROM stdin;
f4da467c-40df-44b6-84c9-af99b6a42062	\N	Sarah Williams	Full Stack Developer	Mumbai	Technology	https://i.pravatar.cc/150?img=10	Passionate about building scalable web applications	245	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
9553004a-2e04-4c76-ace3-0fe7412676b3	\N	Michael Chen	Product Designer	Bangalore	Design	https://i.pravatar.cc/150?img=11	Creating beautiful user experiences	189	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
f1c30704-aafb-45bf-9cee-70bdd7738872	\N	Priya Sharma	Marketing Manager	Delhi	Marketing	https://i.pravatar.cc/150?img=12	Digital marketing expert with 5+ years experience	312	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
fed875c7-729c-4423-bbb3-076d2d4e70d2	\N	David Kumar	Data Scientist	Pune	Technology	https://i.pravatar.cc/150?img=13	ML and AI enthusiast	156	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
479d89e4-5f9b-43f0-895e-d5e48d728539	\N	Emma Johnson	Business Analyst	Mumbai	Finance	https://i.pravatar.cc/150?img=14	Helping businesses make data-driven decisions	198	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
3ef6d9d6-ec00-414f-af3b-bec5d2f6ecc5	\N	Raj Patel	Frontend Developer	Bangalore	Technology	https://i.pravatar.cc/150?img=15	React and Vue.js specialist	267	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
6c01f21a-ddc7-4c15-b7f1-ff3b6312ff4b	\N	Lisa Anderson	Content Writer	Delhi	Marketing	https://i.pravatar.cc/150?img=16	Crafting compelling stories for brands	134	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
f834aa2f-0824-44f2-825e-f1c97417fe3d	\N	Arjun Singh	UX Researcher	Pune	Design	https://i.pravatar.cc/150?img=17	Understanding user behavior	221	t	2025-10-18 08:56:04.901478+00	2025-10-18 08:56:04.901478+00
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
cc6a0720-f9ce-4a9d-bd5f-d9790fe8b5fc	550e8400-e29b-41d4-a716-446655440000	business_cards	bdeedc45-2e1a-4098-a487-9cc359e90b53	create	2025-10-18 08:56:02.632142+00	\N
1c3fc00e-c310-4f71-8f0b-96a662f15b4a	550e8400-e29b-41d4-a716-446655440000	business_cards	09ec5177-c845-409e-924e-5ab54b7b0016	create	2025-10-18 08:56:02.632142+00	\N
5edbd659-54fb-4d3d-a1b8-d0e5b91bd305	550e8400-e29b-41d4-a716-446655440000	business_cards	fff43b68-ccd9-4063-bf42-991c8f6aef8b	create	2025-10-18 08:56:02.632142+00	\N
b7598e4a-cc8c-4975-a759-a5449925a533	550e8400-e29b-41d4-a716-446655440000	business_cards	1930377f-8d03-4474-8c5d-55b366a074a0	create	2025-10-18 08:56:02.632142+00	\N
6d8d8ca8-b8f2-4293-a08e-9a0fe33dc89d	550e8400-e29b-41d4-a716-446655440000	business_cards	48874088-b390-4366-9f64-4e18872bdf69	create	2025-10-18 08:56:02.632142+00	\N
7587dfb4-20a3-419a-b94d-47c49a749ef2	550e8400-e29b-41d4-a716-446655440000	contacts	c56c5174-a881-4247-8437-e6dd06412189	create	2025-10-18 08:56:02.662363+00	\N
86d29f02-6aba-4540-8d04-19d9d5331992	550e8400-e29b-41d4-a716-446655440000	contacts	d888143d-8c9c-4641-9ca7-fc075ad0b2d3	create	2025-10-18 08:56:02.662363+00	\N
216beb11-cac4-40e4-a78e-14ddb2ec0620	550e8400-e29b-41d4-a716-446655440000	contacts	9df90a16-38b0-472b-92fb-00e735f6015d	create	2025-10-18 08:56:02.662363+00	\N
8377baa0-7843-4286-86a0-4457cf43b4d6	53862d25-d38b-4a33-8cec-bdf003488a00	business_cards	53bf9192-f609-4f9a-b43e-036779bb1662	create	2025-10-18 09:16:11.516023+00	\N
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.tags (id, user_id, name, color, created_at) FROM stdin;
9d00a4aa-ab3e-4016-ada5-eedb14c3d13b	550e8400-e29b-41d4-a716-446655440000	Client	#1E88E5	2025-10-18 08:56:02.69923+00
1efdb2de-5280-4d4a-944a-69937a0ebe77	550e8400-e29b-41d4-a716-446655440000	Partner	#4CAF50	2025-10-18 08:56:02.69923+00
c32f8693-fdb2-4b6e-8ba3-9f79f8a872a9	550e8400-e29b-41d4-a716-446655440000	Vendor	#FF9800	2025-10-18 08:56:02.69923+00
eabdc869-f48a-47f0-9731-57ef2a309ef9	550e8400-e29b-41d4-a716-446655440000	Colleague	#9C27B0	2025-10-18 08:56:02.69923+00
8881e821-4116-472a-b4ea-18c9a87e1984	550e8400-e29b-41d4-a716-446655440000	Urgent	#F44336	2025-10-18 08:56:02.69923+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.users (id, email, username, password_hash, full_name, created_at, updated_at, last_login, is_active) FROM stdin;
550e8400-e29b-41d4-a716-446655440000	demo@infinicard.com	demo_user	123456	Demo User	2025-10-18 08:56:02.590011+00	2025-10-18 09:11:57.87845+00	\N	t
53862d25-d38b-4a33-8cec-bdf003488a00	jahnviaghera@gmail.com	jahnviaghera	$2a$10$ZWTDo5BuYRNtbHs7iI4kOuJOQ4j47dtr3LrE/mKVLngj55gIo5GRK	Jahnvi Aghera	2025-10-18 09:13:07.405844+00	2025-10-18 09:13:07.405844+00	\N	t
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

\unrestrict odi9Zj20yRwgMDqRSAQcJjfRahnp36OGPPRNi8KLtkQbgXRPVGt0wVqWWbbRLte

