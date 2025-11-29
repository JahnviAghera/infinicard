--
-- PostgreSQL database dump
--

\restrict Tr2qefZp4bgxVrZoS7Or40bQHBJSjrBcKSVzBYPrcCJRua01MqMZLRWojsWZJTo

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
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.users (id, email, username, password_hash, full_name, created_at, updated_at, last_login, is_active) FROM stdin;
550e8400-e29b-41d4-a716-446655440000	demo@infinicard.com	demo_user	$2a$10$YourHashedPasswordHere	Demo User	2025-10-18 08:40:02.317374+00	2025-10-18 08:40:02.317374+00	\N	t
\.


--
-- Data for Name: business_cards; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.business_cards (id, user_id, full_name, job_title, company_name, email, phone, website, address, notes, color, is_favorite, created_at, updated_at, synced_at, is_deleted) FROM stdin;
f2fc837a-0886-4242-ad9b-153511552763	550e8400-e29b-41d4-a716-446655440000	John Anderson	Senior Software Engineer	TechCorp Solutions	john.anderson@techcorp.com	+1-555-0101	https://techcorp.com	123 Tech Street, Silicon Valley, CA 94025	\N	#1E88E5	t	2025-10-18 08:40:02.365954+00	2025-10-18 08:40:02.365954+00	\N	f
4952e262-70e1-485b-ba60-854dc1130082	550e8400-e29b-41d4-a716-446655440000	Sarah Mitchell	Product Manager	InnovateLabs	sarah.mitchell@innovatelabs.com	+1-555-0102	https://innovatelabs.io	456 Innovation Ave, Austin, TX 78701	\N	#4CAF50	f	2025-10-18 08:40:02.365954+00	2025-10-18 08:40:02.365954+00	\N	f
785c6a0c-71a3-4785-b5d0-af93fdbe5116	550e8400-e29b-41d4-a716-446655440000	Michael Chen	UX Designer	DesignHub Studio	michael.chen@designhub.com	+1-555-0103	https://designhub.design	789 Creative Blvd, Portland, OR 97201	\N	#9C27B0	t	2025-10-18 08:40:02.365954+00	2025-10-18 08:40:02.365954+00	\N	f
8bd98838-12e5-46f5-9eec-d441fcdeff8a	550e8400-e29b-41d4-a716-446655440000	Emily Rodriguez	Marketing Director	BrandWorks Agency	emily.rodriguez@brandworks.com	+1-555-0104	https://brandworks.co	321 Marketing Plaza, New York, NY 10001	\N	#FF9800	f	2025-10-18 08:40:02.365954+00	2025-10-18 08:40:02.365954+00	\N	f
301cd95e-d97c-4567-888f-1f52b193640d	550e8400-e29b-41d4-a716-446655440000	David Thompson	CEO & Founder	StartupVentures	david@startupventures.io	+1-555-0105	https://startupventures.io	555 Entrepreneur Way, San Francisco, CA 94105	\N	#F44336	t	2025-10-18 08:40:02.365954+00	2025-10-18 08:40:02.365954+00	\N	f
\.


--
-- Data for Name: card_social_links; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_social_links (id, card_id, platform, url, display_order, created_at) FROM stdin;
801a9dd4-94cb-4172-92a1-a6f877f58111	f2fc837a-0886-4242-ad9b-153511552763	linkedin	https://linkedin.com/in/john-anderson	1	2025-10-18 08:40:02.755949+00
e9c41394-6dd2-466e-b5fe-fb5b58047590	4952e262-70e1-485b-ba60-854dc1130082	twitter	https://twitter.com/sarahmitchell	1	2025-10-18 08:40:02.796617+00
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.tags (id, user_id, name, color, created_at) FROM stdin;
ebc53a3c-e794-4075-ae26-dceed7184352	550e8400-e29b-41d4-a716-446655440000	Client	#1E88E5	2025-10-18 08:40:02.587857+00
62473a1b-11c4-42a5-bc2a-c38b36341656	550e8400-e29b-41d4-a716-446655440000	Partner	#4CAF50	2025-10-18 08:40:02.587857+00
f75de0b6-83fb-499c-98bd-56af89fe6230	550e8400-e29b-41d4-a716-446655440000	Vendor	#FF9800	2025-10-18 08:40:02.587857+00
c0d2fc7a-a51f-4826-9630-1fb47c7ac5d8	550e8400-e29b-41d4-a716-446655440000	Colleague	#9C27B0	2025-10-18 08:40:02.587857+00
e97d0e58-2496-4cf7-b0ed-4b78898f6462	550e8400-e29b-41d4-a716-446655440000	Urgent	#F44336	2025-10-18 08:40:02.587857+00
\.


--
-- Data for Name: card_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.card_tags (card_id, tag_id, created_at) FROM stdin;
f2fc837a-0886-4242-ad9b-153511552763	ebc53a3c-e794-4075-ae26-dceed7184352	2025-10-18 08:40:02.680019+00
4952e262-70e1-485b-ba60-854dc1130082	62473a1b-11c4-42a5-bc2a-c38b36341656	2025-10-18 08:40:02.680019+00
785c6a0c-71a3-4785-b5d0-af93fdbe5116	c0d2fc7a-a51f-4826-9630-1fb47c7ac5d8	2025-10-18 08:40:02.680019+00
f2fc837a-0886-4242-ad9b-153511552763	e97d0e58-2496-4cf7-b0ed-4b78898f6462	2025-10-18 08:40:02.680019+00
\.


--
-- Data for Name: connections; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.connections (id, sender_id, receiver_id, status, message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.contacts (id, user_id, first_name, last_name, company, job_title, email, phone, mobile, fax, website, address_line1, address_line2, city, state, postal_code, country, notes, is_favorite, created_at, updated_at, synced_at, is_deleted) FROM stdin;
b334c74b-e5b1-4aae-b58c-c16970e7643f	550e8400-e29b-41d4-a716-446655440000	Jessica	Taylor	Global Consulting	Senior Consultant	jessica.taylor@globalconsulting.com	+1-555-0201	+1-555-0202	\N	\N	\N	\N	Boston	Massachusetts	\N	USA	\N	t	2025-10-18 08:40:02.522295+00	2025-10-18 08:40:02.522295+00	\N	f
117590fe-221c-401e-85c5-763b5990ae46	550e8400-e29b-41d4-a716-446655440000	Robert	Williams	Finance Corp	Financial Analyst	robert.williams@financecorp.com	+1-555-0203	+1-555-0204	\N	\N	\N	\N	Chicago	Illinois	\N	USA	\N	f	2025-10-18 08:40:02.522295+00	2025-10-18 08:40:02.522295+00	\N	f
8b80e7f3-4a27-420d-824c-f4d13a335e65	550e8400-e29b-41d4-a716-446655440000	Amanda	Brown	Healthcare Solutions	Director of Operations	amanda.brown@healthcaresol.com	+1-555-0205	+1-555-0206	\N	\N	\N	\N	Seattle	Washington	\N	USA	\N	t	2025-10-18 08:40:02.522295+00	2025-10-18 08:40:02.522295+00	\N	f
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
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.notifications (id, user_id, type, message, is_read, created_at) FROM stdin;
\.


--
-- Data for Name: professionals; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professionals (id, user_id, full_name, profession, location, field, avatar_url, bio, connections_count, is_public, created_at, updated_at) FROM stdin;
d26ea87e-665d-4154-989b-5839b8df26cc	\N	Sarah Williams	Full Stack Developer	Mumbai	Technology	https://i.pravatar.cc/150?img=10	Passionate about building scalable web applications	245	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
fb2b78e4-da50-4dbe-be4b-59199b68b3f6	\N	Michael Chen	Product Designer	Bangalore	Design	https://i.pravatar.cc/150?img=11	Creating beautiful user experiences	189	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
0ec32aef-9adf-4643-80a4-e49752621348	\N	Priya Sharma	Marketing Manager	Delhi	Marketing	https://i.pravatar.cc/150?img=12	Digital marketing expert with 5+ years experience	312	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
60a81d6e-303d-4091-8476-e1e34058ab62	\N	David Kumar	Data Scientist	Pune	Technology	https://i.pravatar.cc/150?img=13	ML and AI enthusiast	156	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
3b29181f-f90f-4b6e-9b3b-57fa73057bf6	\N	Emma Johnson	Business Analyst	Mumbai	Finance	https://i.pravatar.cc/150?img=14	Helping businesses make data-driven decisions	198	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
f3ce18df-299c-4be4-b20b-1faa9042ee9e	\N	Raj Patel	Frontend Developer	Bangalore	Technology	https://i.pravatar.cc/150?img=15	React and Vue.js specialist	267	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
a93dcaaf-8337-47f4-9cc1-63ff360ff6b9	\N	Lisa Anderson	Content Writer	Delhi	Marketing	https://i.pravatar.cc/150?img=16	Crafting compelling stories for brands	134	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
6e59eb31-7701-4be8-89d6-13af489de47d	\N	Arjun Singh	UX Researcher	Pune	Design	https://i.pravatar.cc/150?img=17	Understanding user behavior	221	t	2025-10-18 08:40:05.278175+00	2025-10-18 08:40:05.278175+00
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
-- Data for Name: professional_tags; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.professional_tags (id, professional_id, tag, created_at) FROM stdin;
2c6e4be9-01e6-43b7-b98b-93ee1bf4cc49	d26ea87e-665d-4154-989b-5839b8df26cc	React	2025-10-18 08:40:05.324195+00
b42869d5-5e90-4732-94f6-5f1ae69fb364	d26ea87e-665d-4154-989b-5839b8df26cc	Node.js	2025-10-18 08:40:05.324195+00
3ce47eab-81b7-4759-bd55-193fe69dc9d5	d26ea87e-665d-4154-989b-5839b8df26cc	Python	2025-10-18 08:40:05.324195+00
7ea615c6-6ac8-4d12-88e2-e1ab6fc2ea04	fb2b78e4-da50-4dbe-be4b-59199b68b3f6	UI/UX	2025-10-18 08:40:05.369367+00
2df2f42e-f1d4-4fe1-8a43-a5f31f9f96f4	fb2b78e4-da50-4dbe-be4b-59199b68b3f6	Figma	2025-10-18 08:40:05.369367+00
3cfae1f0-a117-4d67-8e39-8d0b567a9df5	fb2b78e4-da50-4dbe-be4b-59199b68b3f6	Prototyping	2025-10-18 08:40:05.369367+00
046605f5-a594-4de6-92f3-4db2d4a362fd	0ec32aef-9adf-4643-80a4-e49752621348	Digital Marketing	2025-10-18 08:40:05.395294+00
7af6be5c-472c-43ef-9ec6-5bf46e7fddc1	0ec32aef-9adf-4643-80a4-e49752621348	SEO	2025-10-18 08:40:05.395294+00
867b4855-aedc-4c61-befb-f1d9a41e3fcd	0ec32aef-9adf-4643-80a4-e49752621348	Content	2025-10-18 08:40:05.395294+00
4efe8f73-d7e6-45ed-a634-1206ef79f71b	60a81d6e-303d-4091-8476-e1e34058ab62	ML	2025-10-18 08:40:05.420389+00
1c4d69e7-ba4b-4959-87a3-bb633f204a17	60a81d6e-303d-4091-8476-e1e34058ab62	Python	2025-10-18 08:40:05.420389+00
b8387ffc-d346-4923-8d44-d5a74eadc78f	60a81d6e-303d-4091-8476-e1e34058ab62	Analytics	2025-10-18 08:40:05.420389+00
13d6cc08-5508-4115-be75-992193249603	3b29181f-f90f-4b6e-9b3b-57fa73057bf6	Excel	2025-10-18 08:40:05.44606+00
5e6ffef9-6181-4f5e-bc36-15405f463a06	3b29181f-f90f-4b6e-9b3b-57fa73057bf6	SQL	2025-10-18 08:40:05.44606+00
84d4075a-e37b-4659-84ab-2e40ce38be67	3b29181f-f90f-4b6e-9b3b-57fa73057bf6	Tableau	2025-10-18 08:40:05.44606+00
10f396be-67ae-4fde-a18e-bc44842bf642	f3ce18df-299c-4be4-b20b-1faa9042ee9e	React	2025-10-18 08:40:05.470948+00
399e7b8d-2aeb-46a6-ae2d-07db686e4b1e	f3ce18df-299c-4be4-b20b-1faa9042ee9e	Vue.js	2025-10-18 08:40:05.470948+00
bd1463cd-5684-4f23-934d-a35fff936250	f3ce18df-299c-4be4-b20b-1faa9042ee9e	TypeScript	2025-10-18 08:40:05.470948+00
ec15bee1-1e39-47b3-8323-48be4005983d	a93dcaaf-8337-47f4-9cc1-63ff360ff6b9	Copywriting	2025-10-18 08:40:05.49695+00
6afa7ad2-7129-4306-9629-750e859648b8	a93dcaaf-8337-47f4-9cc1-63ff360ff6b9	SEO	2025-10-18 08:40:05.49695+00
30b8bab4-e60e-4fd6-8f95-59dbd470d141	a93dcaaf-8337-47f4-9cc1-63ff360ff6b9	Blogging	2025-10-18 08:40:05.49695+00
5432bc9f-59ac-4c3e-a68e-fb96071be5df	6e59eb31-7701-4be8-89d6-13af489de47d	User Research	2025-10-18 08:40:05.521859+00
d82694d3-25d4-4960-b7fd-034bfe25f8a5	6e59eb31-7701-4be8-89d6-13af489de47d	Wireframing	2025-10-18 08:40:05.521859+00
4585b121-6280-4f89-8b9f-c4ca8f6be3af	6e59eb31-7701-4be8-89d6-13af489de47d	Testing	2025-10-18 08:40:05.521859+00
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
-- Data for Name: scan_history; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.scan_history (id, user_id, card_id, image_path, ocr_text, scan_date, processing_time_ms, success) FROM stdin;
\.


--
-- Data for Name: sync_log; Type: TABLE DATA; Schema: public; Owner: infinicard_user
--

COPY public.sync_log (id, user_id, entity_type, entity_id, action, synced_at, device_id) FROM stdin;
6b2c0c9b-3556-4d7c-82c6-213b9d6f59cb	550e8400-e29b-41d4-a716-446655440000	business_cards	f2fc837a-0886-4242-ad9b-153511552763	create	2025-10-18 08:40:02.365954+00	\N
3325be22-ba65-4ae8-8cdc-0d4e5a63102e	550e8400-e29b-41d4-a716-446655440000	business_cards	4952e262-70e1-485b-ba60-854dc1130082	create	2025-10-18 08:40:02.365954+00	\N
23ce2030-36e0-4981-abe3-55dc07815daa	550e8400-e29b-41d4-a716-446655440000	business_cards	785c6a0c-71a3-4785-b5d0-af93fdbe5116	create	2025-10-18 08:40:02.365954+00	\N
e4d2fb41-f804-4672-a261-d23804571dde	550e8400-e29b-41d4-a716-446655440000	business_cards	8bd98838-12e5-46f5-9eec-d441fcdeff8a	create	2025-10-18 08:40:02.365954+00	\N
8c1e62bd-a030-4b3e-9f55-06698e790c6a	550e8400-e29b-41d4-a716-446655440000	business_cards	301cd95e-d97c-4567-888f-1f52b193640d	create	2025-10-18 08:40:02.365954+00	\N
1333d189-f819-44c1-948f-105a6e4fd891	550e8400-e29b-41d4-a716-446655440000	contacts	b334c74b-e5b1-4aae-b58c-c16970e7643f	create	2025-10-18 08:40:02.522295+00	\N
a6651ac3-1f5b-43b1-8b8f-b4a285d1f79b	550e8400-e29b-41d4-a716-446655440000	contacts	117590fe-221c-401e-85c5-763b5990ae46	create	2025-10-18 08:40:02.522295+00	\N
95796899-05c0-4e46-acd4-60b60fe46277	550e8400-e29b-41d4-a716-446655440000	contacts	8b80e7f3-4a27-420d-824c-f4d13a335e65	create	2025-10-18 08:40:02.522295+00	\N
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
-- PostgreSQL database dump complete
--

\unrestrict Tr2qefZp4bgxVrZoS7Or40bQHBJSjrBcKSVzBYPrcCJRua01MqMZLRWojsWZJTo

