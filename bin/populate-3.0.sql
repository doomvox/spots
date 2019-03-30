/* /home/doom/End/Cave/Spots/Wall/Spots/bin/populate-3.0.sql

SYNOPSIS

  cd /home/doom/End/Cave/Spots/Wall/Spots/bin/
  psql -d spots -f populate-3.0.sql
  psql -d spots_test -f populate-3.0.sql

*/

INSERT INTO projects (schema_version, name) VALUES ('3.0', 'metacats'); 

INSERT INTO metacat (name, sortcode) VALUES
('first',        '0010'),
('local',        '0020'),
('news',         '0030'),
('politics',     '0040'),
('democracy',    '0050'),
('infostrut',    '0060'),
('web',          '0070'),
('prog',         '0080'),
('doing',        '0090'),
('working',      '0100'),
('fiction',      '0110'),
('sound',        '0120'),
('misc',         '0130'),
('scitech',      '0140'),
('geoengineer',  '0150');

UPDATE category SET metacat=1  WHERE id IN 
(43);

UPDATE category SET metacat=2  WHERE id IN 
 (1,
  2,
 57,
  5,
  6,
 58,
 59);                                

UPDATE category SET metacat=3  WHERE id IN 
( 7,
 14);
    
UPDATE category SET metacat=4  WHERE id IN 
(44,
 45,
 46,
 47,
 48,
 36);                                

UPDATE category SET metacat=5  WHERE id IN 
(42);                                
    
UPDATE category SET metacat=6     WHERE id IN 
( 4,
  9,
 15,
 27);                                

UPDATE category SET metacat=7  WHERE id IN 
(12);                                
    
UPDATE category SET metacat=8     WHERE id IN 
(16,
 17,
 18,
 19,
 33,
 37,
 34,
 35,
 50,
 51);                                

UPDATE category SET metacat=9  WHERE id IN 
(49,
 60,
 61);                                

UPDATE category SET metacat=10  WHERE id IN 
 (3);                                

UPDATE category SET metacat=11  WHERE id IN 
(20,
 10,
 21,
 22,
 23,
 24);                                

UPDATE category SET metacat=12  WHERE id IN 
(30,
 25,
 26);                                

UPDATE category SET metacat=13  WHERE id IN 
(29,
 28,
 31,
 41);                                

UPDATE category SET metacat=14  WHERE id IN 
(11,
 13,
 32);
    
UPDATE category SET metacat=15  WHERE id IN 
(39,
 38,
 40,
  8);                                
