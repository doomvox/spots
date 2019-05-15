/*
cd /home/doom/End/Cave/Spots/Wall/Spots/t/bin/
psql -d spots_test -f repop_category_table.sql
*/
TRUNCATE TABLE category;
COPY public.layout (id, category, x_location, y_location, height, width) FROM stdin;
34	34	123	100	\N	\N
35	35	151	100	\N	\N
36	36	215	100	\N	\N
37	37	270	100	\N	\N
38	38	370	100	\N	\N
39	39	470	100	\N	\N
40	40	561	100	\N	\N
41	41	5	121	\N	\N
42	42	69	121	\N	\N
44	44	170	121	\N	\N
45	45	261	121	\N	\N
46	46	352	121	\N	\N
47	47	470	121	\N	\N
48	48	543	121	\N	\N
49	50	5	138	\N	\N
50	51	114	138	\N	\N
51	57	169	138	\N	\N
53	59	288	138	\N	\N
54	49	370	138	\N	\N
55	60	443	138	\N	\N
56	61	507	138	\N	\N
1	1	5	0	\N	\N
2	2	96	0	\N	\N
3	3	187	0	\N	\N
4	4	278	0	\N	\N
5	5	369	0	\N	\N
6	6	505	0	\N	\N
7	7	605	0	\N	\N
8	8	705	0	\N	\N
9	9	5	28	\N	\N
10	10	78	28	\N	\N
11	11	178	28	\N	\N
12	12	287	28	\N	\N
13	13	387	28	\N	\N
14	14	469	28	\N	\N
15	15	569	28	\N	\N
16	16	669	28	\N	\N
17	17	5	55	\N	\N
19	19	115	55	\N	\N
20	20	215	55	\N	\N
21	21	324	55	\N	\N
23	23	470	55	\N	\N
25	25	5	79	\N	\N
26	26	123	79	\N	\N
27	27	277	79	\N	\N
28	28	404	79	\N	\N
30	30	505	79	\N	\N
31	31	587	79	\N	\N
32	32	732	79	\N	\N
33	33	5	100	\N	\N
\.
