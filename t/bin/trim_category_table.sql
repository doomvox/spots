/*
cd /home/doom/End/Cave/Spots/Wall/Spots/t/bin/
psql -d spots_test -f trim_category_table.sql
*/

TRUNCATE TABLE category;
COPY public.category (id, name, metacat) FROM stdin;
1	oakland	2
2	sf	2
3	jobs	10
\.


/*
4	search	6
5	weather	2
6	events	2
7	news	3
8	nuclear	15
9	talk	6
*/

