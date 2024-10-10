
CREATE VIEW tyrell.v_pov_characters_human_readable AS
WITH personur_upplysingar AS (
    SELECT
        ch.id,
        ch.name || COALESCE(', ' || ch.titles[1], '') AS full_name,
        ch.gender,

        COALESCE(father_ch.name, 'Unknown') AS father,
        COALESCE(mother_ch.name, 'Unknown') AS mother,
        COALESCE(spouse_ch.name, 'Unknown') AS spouse,

        CASE
            WHEN ch.born IS NOT NULL AND ch.born SIMILAR TO '% AC%' THEN CAST(regexp_replace(ch.born, '.*(\d+)\s*AC.*', '\1') AS INTEGER)
            WHEN ch.born IS NOT NULL AND ch.born SIMILAR TO '% BC%' THEN -CAST(regexp_replace(ch.born, '.*(\d+)\s*BC.*', '\1') AS INTEGER)
        END AS born_year,

        CASE
            WHEN ch.died IS NOT NULL AND ch.died SIMILAR TO '% AC%' THEN CAST(regexp_replace(ch.died, '.*(\d+)\s*AC.*', '\1') AS INTEGER)
            WHEN ch.died IS NOT NULL AND ch.died SIMILAR TO '% BC%' THEN -CAST(regexp_replace(ch.died, '.*(\d+)\s*BC.*', '\1') AS INTEGER)
        END AS died_year
    FROM got.characters AS ch
    LEFT JOIN got.characters AS father_ch ON ch.father = father_ch.id
    LEFT JOIN got.characters AS mother_ch ON ch.mother = mother_ch.id
    LEFT JOIN got.characters AS spouse_ch ON ch.spouse = spouse_ch.id
),
personur_aldur AS (
    SELECT
        id,
        full_name,
        gender,
        father,
        mother,
        spouse,
        born_year,
        died_year,
        COALESCE(died_year - born_year, 300 - born_year) AS age,
        (died_year IS NULL) AS alive
    FROM personur_upplysingar
),
bok_komfram AS (
    SELECT
        cb.character_id AS id,
        ARRAY_AGG(b.name ORDER BY b.released) AS books
    FROM got.character_books AS cb
    JOIN got.books AS b ON cb.book_id = b.id
    WHERE cb.pov = TRUE
    GROUP BY cb.character_id
)
SELECT
    ca.full_name,
    ca.gender,
    ca.father,
    ca.mother,
    ca.spouse,
    ca.born_year,
    ca.died_year,
    ca.age,
    ca.alive,
    ba.books 
FROM personur_aldur AS ca
JOIN bok_komfram AS ba ON ca.id = ba.id
ORDER BY ca.alive DESC, ca.age DESC;

SELECT * FROM tyrell.v_pov_characters_human_readable ORDER BY alive DESC, age DESC;