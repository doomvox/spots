/* 
   /home/doom/End/Cave/Spots/bin/spots_schema.sql 
   Thursday March  7, 2019   3:52 PM 
   
   version 4.0, post-2019 series  Rev: May 21, 2019

   immediate goal: generation of a browser homepage, ala my old mah_moz_ohm.html

SYNOPSIS

  createdb --owner=postgres spots
  psql -d spots -f /home/doom/End/Cave/Spots/Wall/Spots/bin/spots_schema.sql
                   
  sql alternate to createdb:
  CREATE DATABASE spots WITH OWNER='postgres';

*/

/*
CREATE DATABASE spots WITH OWNER='postgres';
CONNECT spots;  -- inside psql monitor would use  \c spots 
*/

CREATE OR REPLACE FUNCTION update_revised_timestamp_function()
RETURNS TRIGGER 
AS 
$$
BEGIN
    /* assumes the table has a "revised" column */
    NEW.revised  = now(); 
    RETURN NEW;               
END;                          
$$                            
language 'plpgsql';           


CREATE TABLE metacat (
       id           SERIAL PRIMARY KEY NOT NULL,
       sortcode     VARCHAR(4),  
       name         VARCHAR(32)
);

CREATE TABLE category (
       id           SERIAL PRIMARY KEY NOT NULL,
       metacat      INTEGER  REFERENCES metacat (id),
       name         VARCHAR(32)
);

CREATE TABLE spots (
       id           SERIAL PRIMARY KEY NOT NULL,
       url          VARCHAR(256) NOT NULL,
       label        VARCHAR(64),  -- short (choosen by me)
       static       BOOLEAN,
       title        TEXT,         -- from <TITLE>
       description  TEXT, 
       added        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
       revised      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- needs trigger
       live         BOOLEAN,
       category     INTEGER  REFERENCES category (id)
       );
                              
/* create a trigger on any table with a 'revised' column */
CREATE TRIGGER row_mod_on_spot_trigger
BEFORE UPDATE                             
ON spots
FOR EACH ROW                              
EXECUTE PROCEDURE update_revised_timestamp_function();

CREATE TABLE layout (
       id           SERIAL PRIMARY KEY NOT NULL,
       category     INTEGER UNIQUE NOT NULL REFERENCES category (id),
       x_location   INTEGER,
       y_location   INTEGER,
       height       NUMERIC,  -- in rem:  
       width        INTEGER   -- in px
);


/*
insert into spots (url, label) VALUES ('http://slashdot.net', 'slash'), ('http://www.transbaycalendar.org/', 'transbay');
update spots set url='https://slashdot.net' where label='slash';
*/

/*
COPY spots(category,label,url,description) FROM '/home/doom/End/Cave/Spots/dat/spot1.tsv'  DELIMITER E'\t' CSV HEADER;
*/

/*
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
*/


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

COPY public.category (id, name, metacat) FROM stdin;
43	daily	1
1	oakland	2
2	sf	2
5	weather	2
6	events	2
57	san_francisco	2
58	oakland_talk	2
59	oakland_news	2
7	news	3
14	world	3
36	politics	4
44	politics_data	4
45	politics_left	4
46	politics_one_left	4
47	politics_mid	4
48	politics_libertarian	4
42	electoral_integrity	5
4	search	6
9	talk	6
15	industry	6
27	cog	6
12	web	7
16	perl	8
17	postgres	8
18	mysql	8
19	emacs	8
33	linux	8
34	perl6	8
35	rlang	8
37	prog	8
50	perl_news	8
51	perl_monks	8
49	make_perl	9
60	make_code	9
61	git	9
3	jobs	10
10	comics	11
20	lit	11
21	skiffy	11
22	manga	11
23	otaku	11
24	kdrama	11
25	music	12
26	econ	12
30	radio	12
28	wonk	13
29	art	13
31	philos	13
41	sex	13
11	tech	14
13	science	14
32	space	14
8	nuclear	15
38	enviro	15
39	globwarm	15
40	energy	15
\.



COPY public.spots (id, url, label, static, title, description, added, revised, live, category) FROM stdin;
1	http://museumca.org/	oakmus	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
3	http://duckduckgo.com/	duckgo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	4
4	http://citeseerx.ist.psu.edu/	citeseerx	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	4
5	http://www.oaklandlibrary.org/	oaklib	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
6	http://www2.oaklandnet.com/	oaknet	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
7	http://actransit.org	actransit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
8	https://oaklandoctopus.org/	oakoct	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
9	http://obsidianrook.com/spots/bing.com	bing	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	4
10	http://sf.streetsblog.org/	sfstreet	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
12	http://jobs.perl.org/	perl_jobs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	3
13	http://www.google.com/advanced_search?hl=en	goog	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	4
14	http://www.theatlanticcities.com	citylab	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
15	http://www.sfbike.org/	sfbike	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
16	http://slack.yak.net/	yak	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
17	http://obsidianrook.com/spots/art_for_money.html	artmoney	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	3
18	http://obsidianrook.com/spots/jobs.html	mojobs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	3
19	http://groups.google.com/advanced_search?hl=en&q=&hl=en&	groups	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
20	http://reports.abag.ca.gov	abag.ca	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
21	http://www.bikescape.blogspots.com/	bikescape	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
22	http://www.weatherunderground.com/US/CA/San_Francisco.html	sf_skies	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	5
23	https://www.wunderground.com/weather/us/ca/san-francisco/94102	sf_skies_again	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	5
24	http://www.altavista.com/sites/search/sites/search/textadv	alta	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	4
25	http://antwrp.gsfc.nasa.gov/apod/	astro	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
26	https://astronomytopicoftheday.wordpress.com/	astday	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
27	http://www.alexa.com/	alexa	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	4
28	https://bikeeastbay.org/	bikeebay	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
29	https://closecalldatabase.com/	closecall	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
30	http://www2.oaklandnet.com/Government/o/PWA/o/EC/s/TelegraphAvenue/	telegraph	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	2
33	http://www.techmeme.com/	ebizcrap	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
34	http://digg.com/	digg	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
35	http://highscalability.com/	highscale	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
36	http://slashdot.org/users.pl	slashme	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
37	http://arstechnica.com/	arstechnica	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	11
39	http://en.wikipedia.org/wiki/Special:Watchlist	wikiped	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
40	http://www.bayimproviser.com/calendar.asp	bayimp	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	61
42	http://www.transbaycalendar.org/	transbay	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
43	http://grayarea.org/events/	grayarea	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
44	http://www.thechapelsf.com/	thechapel	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
46	https://www.dnalounge.com/	dna	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
48	http://www.democracynow.org/	democ_now	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
49	http://news.google.com/news/section?pz=1&cf=all&ned=us&topic=w&ict=ln	oogienews	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
50	http://www.nytimes.com/	nyt	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
51	https://whatthefuckjusthappenedtoday.com/	wtftoday	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
52	http://vox.com	vox	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
54	http://www.guardiannews.com/	guarduk	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
55	http://topics.nytimes.com/top/news/business/energy-environment/coal/index.html?inline=nyt-classifier	nyt_coal	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	38
56	http://www.motherjones.com/	mojo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
57	http://atomicinsights.com	atomicrod	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
59	http://neinuclearnotes.blogspots.com	nei	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
60	https://www.eia.gov/tools/faqs/	eiafaq	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	40
62	http://nucleargreen.blogspots.com	ngreen	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
63	http://spectrum.ieee.org/blog/energywise	ieeenergy	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	40
65	http://www.nucleartownhall.com	ntown	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
66	https://www.nytimes.com/by/brad-plumer	bradplumer	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	38
68	http://bravenewclimate.com/	bnclim	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	39
69	https://www.nytimes.com/by/eduardo-porter	porter	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	38
71	http://nukepowertalk.blogspots.com/	nupow	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
72	http://thisweekinnuclear.com/	weeknu	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
41	https://ourworldindata.org/	owdata	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:03:39.630646-07	\N	44
47	https://theintercept.com/	intercept	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
58	http://www.thenation.com/	nation	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
61	http://fair.org/	fair	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
53	http://www.nytimes.com/pages/opinion/index.html	wits	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:06:59.384082-07	\N	47
2	http://www.thenewparkway.com/?page_id=13	newparkway	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 08:54:15.896472-07	\N	6
38	http://sf.funcheap.com/	funcheap	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:31:31.00379-07	\N	6
45	http://www.kinokuniya.com/us/	kinokiniya	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:37:35.534958-07	\N	57
11	https://www.noisebridge.net/wiki/Noisebridge	noisebridge	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:36:03.926481-07	\N	57
32	http://slashdot.org/	slash	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:58:40.388796-07	\N	9
75	http://www.sciencedirect.com/journal/process-safety-and-environmental-protection?sdc=1	processafe	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
76	http://www.phyast.pitt.edu/~blc/book/chapter9.html	neo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
77	http://www.safetymattersblog.com/	safemat	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
78	http://ansnuclearcafe.org	nukecafe	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
79	https://www.reddit.com/message/unread/	unred	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
80	http://neutronbytes.com/	neutbyte	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
81	http://nuclearstreet.com	nukestreet	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
82	http://www.reddit.com/	reddit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
83	http://www.theenergycollective.com	energcoll	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	40
89	http://www.realclearenergy.org	rce	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	50
91	http://cravenspowertosavetheworld.com/	cravens	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
93	http://fukushimainform.ca/	fukuinfo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
96	https://www.reddit.com/r/NuclearPower	rnukepow	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
97	https://www.dailykos.com/user/marinechemist	marchem	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
99	https://www.nrc.gov	nrc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	8
100	http://crookedtimber.org/	timber	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
101	http://www.3ammagazine.com/	3am	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
102	https://blog.archive.org/author/jasonscott/	jasonscott	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
103	http://jwz.org/blog	jwz	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
104	https://erinhorakova.wordpress.com/	erin	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
105	http://strangehorizons.com/	stranghor	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
108	http://www.doonesbury.com/	doonesbury	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
109	http://www.miller-mccune.com/	mmc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
110	http://xkcd.com/	xkcd	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
112	http://www.haaretz.com/	ha'aretz	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
113	http://zippythepinhead.com/	zip	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
114	http://www.salon.com/comics/index.html	waylaid	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
115	http://www.thanhniennews.com/	than_nien	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
116	http://www.faqs.org/rfcs/	rfcs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
117	http://pappysgoldenage.blogspots.com/	pap	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
118	http://www.gocomics.com/boondocks/	boondocks	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
119	http://www.abc.net.au/	news_au	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
120	http://www.japantimes.co.jp/	jtimes	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
121	http://wiki.apache.org/httpd/	apachewiki	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
122	http://c2.com/cgi/wiki	c2	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
123	http://www.rhymeswithorange.com/	rwo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
124	http://www.smithmag.net/pekarproject/	pekar	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	10
125	http://www.huffingtonpost.com/	huffpo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
126	http://obsidianrook.com/docster/libapache-mod-perl-doc/html/docs/2.0	modperldoc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
127	http://www.unicode.org/faq/	unicode	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
128	http://www.hindustantimes.com/	hindustan	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
129	http://www.thejakartapost.com/	jakarta	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
130	http://obsidianrook.com/manual/en/index.html	apachedoc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	12
131	http://www.scienceblog.com/	SciBlog	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
132	http://english.aljazeera.net	aljazerra	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
133	http://dailynewsegypt.com	egypt	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
134	http://www.apacheweek.com/	apacheweek	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	12
136	http://www.techreview.com/	techedrev	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	11
137	https://www.elnuevodia.com/english/	puertorico	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
138	http://www.masonhq.com/browse/recent_changes.html	mason	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
139	http://www.counterpane.com/crypto-gram.html	cryptogram	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
140	http://www.newscientist.com/	newsci	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
141	http://news.yahoo.com/	ya_news	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
142	http://www.ndtv.com/topic/agence-france-presse	france	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
143	http://slashcode.org/	/code	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
144	http://www.useit.com/	useit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	12
145	http://www.sciam.com/	sciam	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
146	http://en.wikinews.org/	wikinews	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
147	http://www.perl.com/pub/2012/04/perlunicook-standard-preamble.html	perlunicook	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
148	http://www.independent.co.uk/	indep	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
149	http://www.webdevelopersjournal.com/books/booklead.html	webdev	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	12
86	http://www.marklynas.org	marklynas	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 23:50:23.403531-07	\N	27
84	http://www.suzannewaldman.net/	waldman	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 23:53:12.404032-07	\N	8
87	https://www.acsh.org/profile/alex-berezow	berezow	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 23:53:41.315196-07	\N	13
88	http://www.reddit.com/r/sandersforpresident	rsand	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
85	http://www.reddit.com/r/politics	rpol	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:06:59.384082-07	\N	47
106	http://github.com	github	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 10:07:55.693288-07	\N	60
150	http://www.sciencedaily.com/	scidaily	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
151	http://www.madewithmolecules.com/blog/	fflower	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	13
152	http://mozillazine.org/	mozine	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	12
153	http://www.wired.com/	wired	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
154	http://answers.oreilly.com/index.php?	answers	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
155	http://kuro5hin.org/	kuro	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
156	http://www.perl.com/	perl.com	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
157	https://stackoverflow.com/questions/tagged/perl6	p6stack	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
158	http://baudehlo.wordpress.com/	mhack	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
160	http://www.perlfoundation.org/perl5/index.cgi?perl_5_wiki	p5wiki	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
161	https://perl6.org/	p6	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	34
162	http://perlsphere.net/	sphere	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
164	http://www.perldoc.org/	perldoc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
165	http://www.iinteractive.com/moose/	moose	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
166	http://justatheory.com/	wheeler	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
167	http://korflab.ucdavis.edu/Unix_and_Perl/index.html	bioperl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
168	http://research.stlouisfed.org/fred2/	fred	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
170	http://mappinghacks.com/	maphacks	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
171	http://www.openswartz.com/	swartz	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
172	http://search.cpan.org/%7Ebirney/bioperl-1.4/bptutorial.pl	bioperl_tut	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
175	http://use.perl.org/%7EOvid/journal/38616	ovid	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
176	http://plasmasturm.org/	ap	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
177	http://www.worldpublicopinion.org/	worldpub	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
179	http://blog.timbunce.org/	bunce	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
180	http://www.modernperlbooks.com/	mp	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
181	http://obsidianrook.com/spots/modern_perl.html	readperl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
183	http://www.gabrielweinberg.com/blog/	gabriel_w	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
187	http://blog.gmane.org/gmane.comp.lang.perl.modules.module-build	m::b	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
188	https://www.indybay.org/	indybay	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
190	http://github.com/gitpan	gitpan	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
191	http://www.salonmagazine.com/	salon	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
192	http://www.factcheck.org/	factcheck	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
193	http://politifact.com/truth-o-meter/	politifact	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
194	http://metacpan.org/	cpan	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
195	http://cpanratings.perl.org/	cpanrat	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
196	http://iht.com/	iht	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
197	http://sf.indymedia.org/	sfindy	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
198	http://www.freepress.org/index2.php	freep	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
199	http://counterpunch.org/	cpunch	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
202	http://www.economist.com/	econ	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
205	http://dailynews.yahoo.com/h/ts/nm/?u	reuters	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
209	http://www.baycitizen.org/	baycit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	1
215	http://www.indymedia.org/	indymed	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	7
219	http://www.electoral-vote.com/	evote	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	36
224	https://emacsdojo.github.io/	emacsdojo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
173	http://thomas.loc.gov/	thomas	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:03:39.630646-07	\N	44
182	http://www.pipa.org/	pipa	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:03:39.630646-07	\N	44
220	http://www.politicalwire.com/	polwire	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
216	http://www.opednews.com/	opeds	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:06:59.384082-07	\N	47
206	http://www.reason.com/	reason	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:07:28.191443-07	\N	48
207	http://libertyunbound.com/	liberty	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:07:28.191443-07	\N	48
211	http://obsidianrook.com/devnotes/elisp-for-perl-programmers.html	elisp4perl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 08:58:44.605405-07	\N	19
204	http://static.cpantesters.org/distro/E/Emacs-Run.html	E::R	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 08:58:47.573051-07	\N	19
169	http://www.perlmonks.org/	monks	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:27.956827-07	\N	51
163	http://use.perl.org/%7Edoom/journal/	doom	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:15:59.38866-07	\N	49
184	https://pause.perl.org/	pause	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:15:59.38866-07	\N	49
200	http://testers.cpan.org/	testers	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:15:59.38866-07	\N	49
159	http://use.perl.org/	usePerl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:21.412601-07	\N	50
185	http://perlbuzz.com/	perlbuzz	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:21.412601-07	\N	50
189	http://planet.perl.org/	planetp	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:21.412601-07	\N	50
201	http://search.cpan.org/recent/	recent_cpan	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:21.412601-07	\N	50
174	http://www.perlmonks.org/?node_id=43037	links	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:27.956827-07	\N	51
178	http://www.perlmonks.org/?node_id=674668	tags	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:21:27.956827-07	\N	51
210	http://www.sfbg.com/	sfbg	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
217	http://www.topix.net/oakland	topoak	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:29:43.490493-07	\N	1
212	http://www.insidebayarea.com/breaking-news	insideba	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
213	http://www.sfexaminer.com/	examiner	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
214	http://www.sfgate.com/	gate	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
218	http://www.eastbayexpress.com/	ebexp	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
227	http://www.emacswiki.org/cgi-bin/wiki/RecentChanges	emacswiki	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
228	http://rand-mh.sourceforge.net/book/	mh	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
229	http://mh-e.sourceforge.net/manual/html/	mh-e	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
230	http://lists.gnu.org/archive/html/emacs-devel/	emacs-dev	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
231	http://www.mysqlperformanceblog.com/	squeal	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
232	http://thedailywtf.com/	wtf	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
233	http://www.digitalhumanities.org/	digihum	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	28
234	http://rationalwiki.org/wiki/Main_Page	ratwiki	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
235	http://sachachua.com/wp/	sacha	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
236	http://emacs-fu.blogspots.com/	emacsfu	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
237	http://www.nplusonemag.com/	n+1	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
238	http://emacsblog.org/	eblg	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
239	http://trey-jackson.blogspots.com/	trey	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
240	http://www.varlena.com/GeneralBits/	varlena	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
241	http://it.toolbox.com/blogs/database-soup	berkus	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
242	http://www.antipope.org/charlie/blog-static/	stross	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
243	http://emacsredux.com/	ered	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
244	http://momjian.us	momjian	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
245	http://boingboing.net/	boing	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
246	https://www.r-bloggers.com/	rblogs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	35
247	https://code-cartoons.com/	codecart	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
248	http://www.postgresonline.com/	pgon	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
249	http://planet.postgresql.org/	planet_pg	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
250	http://www.databaseanswers.org/data_models/index.htm	dba_dm	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
251	http://www.barcelonareview.com/	barcelona	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
252	http://debaday.debian.net/	debaday	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
253	http://www.postgresql.org/	postgresql	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
254	http://www.postgresql.org/docs/8.3/interactive/index.html	docs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
255	http://www.nytimes.com/pages/books/review/index.html	nyt_bookrev	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
256	http://kernelnewbies.org/	kern_newbs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
258	http://rhaas.blogspots.com/	pg_haas	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	17
259	http://www.nybooks.com/	nyrb	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
260	http://en.wikipedia.org/wiki/List_of_cognitive_biases	cogbias	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
261	http://www.c2es.org/	c2es	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
262	http://www.debian-administration.org/	debadmin	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
263	http://www.the-tls.co.uk/	tls	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
264	http://linuxtoday.com/	today	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
265	http://www.oreillynet.com/	oreilly_i_do	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
266	http://www.lrb.co.uk/	lrb	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
267	http://www.culturalcognition.net/	cultcog	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
268	http://www.skepticalscience.com	skepsci	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
269	http://www.csicop.org/si	csicop	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
270	http://www.linuxnews.com/	news	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
271	http://highwire.stanford.edu/	highwire	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
272	http://linuxmafia.com/	mafia	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
273	http://apress.com/	apress	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	11
275	http://familiardiversions.blogspots.com/	librarygirl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
278	http://www.wattpad.com/user/Amber786	amber	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
279	http://linuxhomepage.com/	hpage	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
281	http://gweberblog.wordpress.com/	gloria_w	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
283	http://www.sfsite.com/	sfsite	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
284	http://www.gutenberg.org/wiki/Main_Page	gut	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
285	http://nerdreactor.com	nerdreact	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
287	http://blog.longnow.org/	longblog	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
288	http://sfbook.com/	sfbook	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
289	http://www.barnesandnoble.com/search.asp	bn	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
291	http://www.prospectmagazine.co.uk/author/brian-eno	eno	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
292	http://www.lewisshiner.com/liberation/index.htm	shiner	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
294	http://blog.wired.com/sterling/	sterling	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
295	http://file770.com/	file770	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
296	http://www.thewaythefutureblogs.com/	pohl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
297	http://daily.sightline.org/author/eric-de-place/	de_place	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	40
298	http://www.phoronix.com/scan.php?page=home	phoronix	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
299	http://ronsilliman.blogspots.com/	silliman	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
300	http://www.infinitematrix.net/	infinitematrix	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
301	http://stevereads.com/	stevereads	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
226	http://www.truthdig.com/	truthdig	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
274	http://www.zmag.org/	zmag	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
257	http://technet.oracle.com/docs/products/oracle8i/doc_index.htm	oracledoc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 10:11:13.550417-07	\N	17
282	http://gitready.com/	gitready	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 10:12:50.910812-07	\N	61
286	http://book.git-scm.com/	gcommunity	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 10:12:50.910812-07	\N	61
290	http://learn.github.com/	glearn	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 10:12:50.910812-07	\N	61
302	http://linuxmafia.com/bale/	bale	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
303	http://hackaday.com/	hack	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
304	http://kenmacleod.blogspots.com/	macleod	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
305	http://escapepod.org/	escapepod	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
306	http://www.dicum.com/	dicum	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	20
308	http://www.j-pop.com/	jpop_summit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
309	http://www.krakencon.com/	kraken	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
310	https://kotaku.com/	kotaku	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
311	http://museumfire.com/	firemuseum	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
312	http://www.haruhisuzumiya.net/	haruhi	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
313	http://www.sankakucomplex.com/	sankakucomplex	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
314	http://www.otakuusamagazine.com/LatestNews/Public/News.aspx	otaku_usa	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
315	https://nhentai.net/	doujin	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
316	http://otaku-usa.com/	notousa	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
318	http://www.riaaradar.com/zeitgeist_topamazonsafe.asp	riaafree	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
319	http://www.animenewsnetwork.com/	animenewsnetwork	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
320	http://www.fandom.com	fandom_anime	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
321	http://www.amoebamusic.com/	amoeba	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
322	http://crunchyroll.com	crunchyroll	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
323	http://www.japantoday.com	japtoday	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
324	http://akihabaranews.com	akihba	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
326	http://www.reddit.com/r/SkipBeat	rskipbeat	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
327	http://tatsukida.blogspots.com/	dreamer	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
328	http://nekopop.com/	nekopop	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
329	http://blog.fromjapan.co.jp	jblog	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
330	https://chusmartinez1.wordpress.com/	chusm	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	41
331	http://www.gr-sf.com/	gr-sf	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	21
332	http://kzsu.stanford.edu/	zoo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
333	https://twitter.com/kzsu	ztwit	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
334	http://zookeeper.stanford.edu/	keep	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
335	http://www.windworld.com/emi/	exp_mus_inst	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
336	http://cscs.umich.edu/%7Ecrshalizi/	cosma	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
337	http://cscs.umich.edu/%7Ecrshalizi/weblog/	shalizi	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
338	http://wedgeradio.wordpress.com/	wedge	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
339	http://cscs.umich.edu/%7Ecrshalizi/notebooks/	notebooks	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
340	http://www.spacecowboys.org/	spacecow	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
341	http://www.aquariusrecords.org/	aquarius	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
342	http://cscs.umich.edu/%7Ecrshalizi/reviews/	bactra review	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
343	http://adeeplust.blogspots.com/	adeeplust	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	28
344	http://laughingsquid.com/squidlist/events/	squid	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
345	http://www.othermusic.com/	other	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
346	http://www.google.com/search?q=Michel+Meyer	michel_meyer	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	31
347	http://www.google.com/search?q=Stephen+Toulmin	stephen_toulmin	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	31
348	http://alltherecords.tumblr.com/	husband	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
349	http://www.thewire.co.uk/	the_wire	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
351	http://www.dustedmagazine.com/	dusted	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
353	http://www.guardian.co.uk/profile/josephstiglitz	stiglitz	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
354	http://www.noisypeople.com/	noisy people	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	25
355	http://ww4report.com/blog/2	weinberg	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
356	http://ww4report.com/	ww4	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	14
357	http://www.21grand.org/wpress/index.php?s=award	21grand	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
358	http://krugman.blogs.nytimes.com/	krugman	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
359	http://robertreich.org/	reich	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
361	http://www.caferoyale-sf.com/home.shtml	caferoyale	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	6
365	http://www.bradford-delong.com	delong	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
369	http://electionlawblog.org/	electlaw	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
370	http://www.blackboxvoting.org/	blackbox	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
371	http://www.electionintegrity.org/	freeman	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
372	https://ballotpedia.org/	ballotp	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
373	http://www.bradblog.com/	bradblog	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
374	http://www.democracyfornewhampshire.com/	dfnh	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
375	http://www.eschatonblog.com/	atrios	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	9
376	http://www.economy.com/dismal/	dismal_scientist	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
360	http://www.monbiot.com/	monbiot	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:53.431077-07	\N	46
352	http://jamesfallows.theatlantic.com/	fallows	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:06:59.384082-07	\N	47
367	http://lessig.org/blog/	lessig	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:06:59.384082-07	\N	47
368	http://nymag.com/author/jonathan%20chait/	chait	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:06:59.384082-07	\N	47
350	http://thrillpeddlers.com/	thrillped	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 08:54:15.896472-07	\N	6
307	http://bayareaanarchistbookfair.com/	anarchy	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 08:55:46.424005-07	\N	6
317	http://www.sfheart.com/ArtPoetryEvents.html	poets	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:29:58.163025-07	\N	6
325	http://www.tokyokinky.com	tokink	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-22 18:28:38.486237-07	\N	41
379	http://noahpinionblog.blogspots.com/	noah_s	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
380	http://kpfa.org/home	kpfa	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
381	http://blogs.reuters.com/felix-salmon/	felix_salmon	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
382	http://www.calculatedriskblog.com/	calcrisk	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
383	http://archive.wbai.org/	wbai	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
384	http://stream.wbai.org/	wbainow	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
385	http://200.35.148.107:8000/listen.pls	sfsnd	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
386	http://www.piratecatradio.com/	pcat	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
387	http://www.kdvs.org/schedule	kdvs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
388	http://economistsview.typepad.com/	Thoma	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	26
389	http://www.2600.com/offthehook/archive_ra.html	hook	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
390	http://podcasts.radiovalencia.fm/ask_dr_hal/	drhal	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
391	http://pcrcollective.org/	mutiny	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
392	http://ktru.org/	ktru	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
393	http://ashokarao.com/	ashok	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
394	http://www.archive.org/details/audio	audioarc	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
395	http://www.kpdo.org/	kpdo	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
396	http://radiovalencia.fm/shows/	valencia	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
397	http://longnow.org/	longnow	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
398	http://web.me.com/stewartbrand/DISCIPLINE_footnotes/Contents.html	brand	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	28
399	http://earlywarn.blogspots.com/	earlywarn	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	39
401	http://www.ted.com/talks	ted	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	28
402	http://perlcast.com/	perlcast	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	16
403	http://www.edge.org/	edge	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
404	http://www.twit.tv/FLOSS	floss	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	33
405	http://loudcity.com/stations	loudcity	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	30
406	https://www.reddit.com/r/spacex/	rspacex	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	32
407	http://www.voiceofthevoters.org/	voxvoters	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	42
408	http://www.defectivebydesign.org/	drm	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
409	https://stallman.org	rms	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
414	http://www.43folders.com/	43f	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	23
415	http://lifehacker.com/	lifehack	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	27
416	http://www.cspeirce.com/	peirce_gate	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	31
417	http://www.emacswiki.org/emacs/OrgMode	orgmode	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	19
418	http://www.peirce.org/	peirce.org	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	31
419	http://books.google.com/books?id=iy76kUCZYb0C	continuity	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	31
420	http://pipedot.org/	pipedot	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
421	http://stackoverflow.com/	stacko	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	37
422	http://technocrat.net/	technocrat	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 18:26:48.260727-07	\N	15
424	http://www.propublica.com	propub	\N	\N	\N	2019-03-15 23:44:52.340055-07	2019-03-15 23:44:52.340055-07	\N	7
74	https://politico.com	politico	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-15 23:55:13.876055-07	\N	7
70	http://www.realclearpolitics.com/	realclear	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:03:39.630646-07	\N	44
73	https://fivethirtyeight.com/	538	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:03:39.630646-07	\N	44
64	http://www.democraticunderground.com/	demounder	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
67	http://theprogressivewing.com/	progwing	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
90	http://www.reddit.com/r/kossacks_for_sanders	rkosand	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
92	https://www.reddit.com/r/Political_Revolution/	rpolrevha	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
95	http://caucus99percent.com/	cacu99	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
98	https://www.dailykos.com/user/subir	subir	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
378	http://www.opensecrets.org/	opensec	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:08.928183-07	\N	45
362	http://inthesetimes.com/community/profile/192	parry	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:53.431077-07	\N	46
363	http://news.independent.co.uk/fisk/	fisk	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:53.431077-07	\N	46
364	http://gregpalast.com/	palast	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:53.431077-07	\N	46
366	http://normanfinkelstein.com/	finkelstein	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:53.431077-07	\N	46
400	https://www.jacobinmag.com/author/seth-ackerman/	jacobin_seth	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 00:05:53.431077-07	\N	46
203	https://pause.perl.org/pause/authenquery	pause	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:15:59.38866-07	\N	49
208	http://rt.perl.org/	pbugs	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-16 09:15:59.38866-07	\N	49
412	http://sfpl.lib.ca.us/	sfpl	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:36:03.926481-07	\N	57
221	https://goldengatedistrict.nextdoor.com	ndoor	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
222	http://48hillsonline.org/	48hill	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 09:39:46.959833-07	\N	59
293	https://git.wiki.kernel.org/index.php/GitFaq	gitfaq	\N	\N	\N	2019-03-15 18:26:48.260727-07	2019-03-17 10:12:50.910812-07	\N	61
\.
