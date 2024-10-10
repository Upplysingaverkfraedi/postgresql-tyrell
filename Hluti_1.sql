-- Spurning 1 
SELECT
        k.name AS kingdom_id,
        h.name AS house_id
    FROM
        atlas.kingdoms k
    FULL OUTER JOIN
        got.houses h ON k.name = h.region;


CREATE TABLE IF NOT EXISTS tyrell.tables_mapping (
    kingdom_name TEXT,
    house_name TEXT,
    UNIQUE(kingdom_name, house_name)
);

WITH kingdom_house_mapping AS (
    SELECT
        k.gid AS kingdom_id,
        h.id AS house_id
    FROM
        atlas.kingdoms k
    FULL OUTER JOIN
        got.houses h ON k.name = h.region
)
INSERT INTO tyrell.tables_mapping (kingdom_id, house_id)
SELECT kingdom_id, house_id FROM kingdom_house_mapping
ON CONFLICT (house_id) DO NOTHING;

SELECT * FROM tyrell.tables_mapping; --skoða töfluna

-- sækja öll entries frá tables_mapping table
SELECT * FROM tyrell.tables_mapping;



-- Spurning 2 
WITH gagntaek_vorpun AS (
    SELECT
        l.gid AS location_id,
        l.name AS location_name,
        h.id AS house_id,
        h.name AS house_name
    FROM
        atlas.locations l
    JOIN
        got.houses h ON l.name = ANY(h.seats)
)


INSERT INTO tyrell.tables_mapping (house_id, location_id)
SELECT
    house_id,
    location_id
FROM
    gagntaek_vorpun
WHERE NOT EXISTS (
    SELECT 1
    FROM tyrell.tables_mapping otm
    WHERE otm.house_id = gagntaek_vorpun.house_id
      AND otm.location_id = gagntaek_vorpun.location_id
);


--Spurning 3
-- sql fyrirspurn sem finnur stærstu ættir allra norðmanna
WITH northern_houses AS (
    SELECT id, unnest(sworn_members) AS member_id
    FROM got.houses
    WHERE region = 'The North' 
),
northern_characters AS (
    SELECT nh.member_id, split_part(c.name, ' ', array_length(string_to_array(c.name, ' '), 1)) AS family_name
    FROM northern_houses nh
    JOIN got.characters c ON nh.member_id = c.id
),
family_counts AS (
    SELECT family_name, COUNT(*) AS member_count
    FROM northern_characters
    GROUP BY family_name
    HAVING COUNT(*) > 5
)
SELECT family_name, member_count
FROM family_counts
ORDER BY member_count DESC, family_name ASC;
