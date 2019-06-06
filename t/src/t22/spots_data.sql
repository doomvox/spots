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
-- Data for Name: metacat; Type: TABLE DATA; Schema: public; Owner: doom
--

COPY public.metacat (id, sortcode, name) FROM stdin;
1	0010	first
2	0020	local
3	0030	news
4	0040	politics
5	0050	democracy
6	0060	infostrut
7	0070	web
8	0080	prog
9	0090	doing
10	0100	working
11	0110	fiction
12	0120	sound
13	0130	misc
14	0140	scitech
15	0150	geoengineer
\.


--
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: doom
--

COPY public.category (id, metacat, name) FROM stdin;
1	2	oakland
2	2	sf
3	10	jobs
\.


--
-- Data for Name: layout; Type: TABLE DATA; Schema: public; Owner: doom
--

COPY public.layout (id, category, x_location, y_location, height, width) FROM stdin;
\.


--
-- Data for Name: spots; Type: TABLE DATA; Schema: public; Owner: doom
--

COPY public.spots (id, url, label, static, title, description, added, revised, live, category) FROM stdin;
1	http://museumca.org/	oakmus	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
5	http://www.oaklandlibrary.org/	oaklib	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
6	http://www2.oaklandnet.com/	oaknet	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
7	http://actransit.org	actransit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
8	https://oaklandoctopus.org/	oakoct	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
10	http://sf.streetsblog.org/	sfstreet	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
12	http://jobs.perl.org/	perl_jobs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	3
14	http://www.theatlanticcities.com	citylab	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
15	http://www.sfbike.org/	sfbike	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
17	http://obsidianrook.com/spots/art_for_money.html	artmoney	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	3
18	http://obsidianrook.com/spots/jobs.html	mojobs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	3
21	http://www.bikescape.blogspots.com/	bikescape	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
28	https://bikeeastbay.org/	bikeebay	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
29	https://closecalldatabase.com/	closecall	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
30	http://www2.oaklandnet.com/Government/o/PWA/o/EC/s/TelegraphAvenue/	telegraph	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
209	http://www.baycitizen.org/	baycit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
217	http://www.topix.net/oakland	topoak	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:29:43.490493-07	\N	1
\.


--
-- Name: category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: doom
--

SELECT pg_catalog.setval('public.category_id_seq', 1, false);


--
-- Name: layout_id_seq; Type: SEQUENCE SET; Schema: public; Owner: doom
--

SELECT pg_catalog.setval('public.layout_id_seq', 1, false);


--
-- Name: metacat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: doom
--

SELECT pg_catalog.setval('public.metacat_id_seq', 1, false);


--
-- Name: spots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: doom
--

SELECT pg_catalog.setval('public.spots_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

