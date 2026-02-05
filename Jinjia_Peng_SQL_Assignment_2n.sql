/* ===========================
   PART 1 — Playlists / Tracks / Artists
   =========================== */

-- Select the top 10 rows from the Artist table
SELECT *
FROM Artist
LIMIT 10;

-- Select the top 10 rows from the Artist table ordered by ArtistId descending
SELECT *
FROM Artist
ORDER BY ArtistId DESC
LIMIT 10;

-- Select the distinct PlaylistIds from the PlaylistTrack table
SELECT DISTINCT PlaylistId
FROM PlaylistTrack;

-- Inner join the Playlist table to PlaylistTrack on the Playlist primary key
SELECT p.PlaylistId,
       p.Name AS PlaylistName,
       pt.TrackId
FROM Playlist      AS p
JOIN PlaylistTrack AS pt
  ON p.PlaylistId = pt.PlaylistId;

-- Inner join Playlist, PlaylistTrack, and Track on their shared keys
SELECT p.PlaylistId,
       p.Name AS PlaylistName,
       t.TrackId,
       t.Name  AS TrackName
FROM Playlist      AS p
JOIN PlaylistTrack AS pt ON p.PlaylistId = pt.PlaylistId
JOIN Track         AS t  ON pt.TrackId   = t.TrackId;

-- Select the PlaylistIds that contain Michael Jackson songs
SELECT DISTINCT p.PlaylistId
FROM Playlist      AS p
JOIN PlaylistTrack AS pt ON p.PlaylistId = pt.PlaylistId
JOIN Track         AS t  ON pt.TrackId   = t.TrackId
JOIN Album         AS a  ON t.AlbumId    = a.AlbumId
JOIN Artist        AS ar ON a.ArtistId   = ar.ArtistId
WHERE ar.Name = 'Michael Jackson';

-- Album titles that appear in playlists for Michael Jackson songs (distinct titles only)
SELECT DISTINCT a.Title AS AlbumTitle
FROM Playlist      AS p
JOIN PlaylistTrack AS pt ON p.PlaylistId = pt.PlaylistId
JOIN Track         AS t  ON pt.TrackId   = t.TrackId
JOIN Album         AS a  ON t.AlbumId    = a.AlbumId
JOIN Artist        AS ar ON a.ArtistId   = ar.ArtistId
WHERE ar.Name = 'Michael Jackson';

-- Which artist has the most tracks on PlaylistTrack?
SELECT ar.Name  AS ArtistName,
       COUNT(*) AS TrackCount
FROM Playlist      AS p
JOIN PlaylistTrack AS pt ON p.PlaylistId = pt.PlaylistId
JOIN Track         AS t  ON pt.TrackId   = t.TrackId
JOIN Album         AS a  ON t.AlbumId    = a.AlbumId
JOIN Artist        AS ar ON a.ArtistId   = ar.ArtistId
GROUP BY ar.Name
ORDER BY TrackCount DESC;

-- Sum of Bytes and Milliseconds for each Genre
SELECT g.Name          AS GenreName,
       SUM(t.Bytes)    AS Bytes_Total,
       SUM(t.Milliseconds) AS Milliseconds_Total
FROM PlaylistTrack AS pt
JOIN Track        AS t ON pt.TrackId = t.TrackId
JOIN Genre        AS g ON t.GenreId  = g.GenreId
GROUP BY g.Name;

-- Bytes per Millisecond for each Genre (ordered descending)
SELECT g.Name AS GenreName,
       CAST(SUM(t.Bytes) AS REAL) / NULLIF(SUM(t.Milliseconds), 0) AS Bytes_per_Millisecond
FROM PlaylistTrack AS pt
JOIN Track        AS t ON pt.TrackId = t.TrackId
JOIN Genre        AS g ON t.GenreId  = g.GenreId
GROUP BY g.Name
ORDER BY Bytes_per_Millisecond DESC;

-- Bytes per Millisecond for each Artist and Genre, excluding Comedy
SELECT ar.Name AS ArtistName,
       g.Name  AS GenreName,
       CAST(SUM(t.Bytes) AS REAL) / NULLIF(SUM(t.Milliseconds), 0) AS Bytes_per_Millisecond
FROM PlaylistTrack AS pt
JOIN Track        AS t  ON pt.TrackId  = t.TrackId
JOIN Album        AS a  ON t.AlbumId   = a.AlbumId
JOIN Artist       AS ar ON a.ArtistId  = ar.ArtistId
JOIN Genre        AS g  ON t.GenreId   = g.GenreId
WHERE g.Name <> 'Comedy'
GROUP BY ar.Name, g.Name
ORDER BY Bytes_per_Millisecond DESC;


/* ===========================
   PART 2 — Invoices / Sales
   =========================== */

-- Select the top 10 rows from the Invoice table
SELECT *
FROM Invoice
LIMIT 10;

-- Select all rows from the Invoice table where the BillingCountry is Germany
SELECT *
FROM Invoice
WHERE BillingCountry = 'Germany';

-- Filter invoices more recent than 2010-01-01
SELECT *
FROM Invoice
WHERE InvoiceDate > '2010-01-01';

-- Base join: Invoice → InvoiceLine → Track
SELECT i.InvoiceId,
       i.InvoiceDate,
       i.BillingCity,
       i.BillingCountry,
       il.InvoiceLineId,
       il.TrackId,
       il.Quantity,
       il.UnitPrice,
       t.Name AS TrackName
FROM Invoice     AS i
JOIN InvoiceLine AS il ON i.InvoiceId = il.InvoiceId
JOIN Track       AS t  ON il.TrackId  = t.TrackId;

-- Same base join (streamlined projection to mirror template)
SELECT i.InvoiceId,
       i.InvoiceDate,
       i.BillingCity,
       i.BillingCountry,
       t.TrackId,
       t.Name AS TrackName
FROM Invoice     AS i
JOIN InvoiceLine AS il ON i.InvoiceId = il.InvoiceId
JOIN Track       AS t  ON il.TrackId  = t.TrackId;

-- German city with the largest average invoice
SELECT BillingCity,
       AVG(Total) AS AvgInvoice
FROM Invoice
WHERE BillingCountry = 'Germany'
GROUP BY BillingCity
ORDER BY AvgInvoice DESC
LIMIT 1;

-- Most popular genre for each German city
WITH CityGenreAgg AS (
  SELECT i.BillingCity,
         g.Name AS GenreName,
         COUNT(*) AS GenreCount
  FROM Invoice     AS i
  JOIN InvoiceLine AS il ON i.InvoiceId = il.InvoiceId
  JOIN Track       AS t  ON il.TrackId  = t.TrackId
  JOIN Genre       AS g  ON t.GenreId   = g.GenreId
  WHERE i.BillingCountry = 'Germany'
  GROUP BY i.BillingCity, g.Name
),
CityGenreRanked AS (
  SELECT BillingCity,
         GenreName,
         GenreCount,
         ROW_NUMBER() OVER (
           PARTITION BY BillingCity
           ORDER BY GenreCount DESC, GenreName
         ) AS rn
  FROM CityGenreAgg
)
SELECT BillingCity, GenreName, GenreCount
FROM CityGenreRanked
WHERE rn = 1
ORDER BY BillingCity;

-- Largest average invoice per city across Germany, USA, Canada, and Argentina
SELECT BillingCountry,
       BillingCity,
       AVG(Total) AS AvgInvoice
FROM Invoice
WHERE BillingCountry IN ('Germany', 'USA', 'Canada', 'Argentina')
GROUP BY BillingCountry, BillingCity
ORDER BY AvgInvoice DESC;

-- Most popular genre per city across Germany, USA, Canada, and Argentina
WITH CityGenreAllAgg AS (
  SELECT i.BillingCountry,
         i.BillingCity,
         g.Name AS GenreName,
         COUNT(*) AS GenreCount
  FROM Invoice     AS i
  JOIN InvoiceLine AS il ON i.InvoiceId = il.InvoiceId
  JOIN Track       AS t  ON il.TrackId  = t.TrackId
  JOIN Genre       AS g  ON t.GenreId   = g.GenreId
  WHERE i.BillingCountry IN ('Germany', 'USA', 'Canada', 'Argentina')
  GROUP BY i.BillingCountry, i.BillingCity, g.Name
),
CityGenreAllRanked AS (
  SELECT BillingCountry,
         BillingCity,
         GenreName,
         GenreCount,
         ROW_NUMBER() OVER (
           PARTITION BY BillingCountry, BillingCity
           ORDER BY GenreCount DESC, GenreName
         ) AS rn
  FROM CityGenreAllAgg
)
SELECT BillingCountry, BillingCity, GenreName, GenreCount
FROM CityGenreAllRanked
WHERE rn = 1
ORDER BY BillingCountry, BillingCity;

-- Most popular track we invoice for (by count of invoice lines)
SELECT t.Name AS TrackName,
       COUNT(*) AS SalesCount
FROM InvoiceLine AS il
JOIN Track       AS t ON il.TrackId = t.TrackId
GROUP BY t.Name
ORDER BY SalesCount DESC
LIMIT 1;

-- Best-selling album by country
WITH AlbumCountryAgg AS (
  SELECT i.BillingCountry,
         a.Title AS AlbumTitle,
         COUNT(*) AS SalesCount
  FROM Invoice     AS i
  JOIN InvoiceLine AS il ON i.InvoiceId = il.InvoiceId
  JOIN Track       AS t  ON il.TrackId  = t.TrackId
  JOIN Album       AS a  ON t.AlbumId   = a.AlbumId
  GROUP BY i.BillingCountry, a.Title
),
AlbumCountryRanked AS (
  SELECT BillingCountry,
         AlbumTitle,
         SalesCount,
         ROW_NUMBER() OVER (
           PARTITION BY BillingCountry
           ORDER BY SalesCount DESC, AlbumTitle
         ) AS rn
  FROM AlbumCountryAgg
)
SELECT BillingCountry, AlbumTitle, SalesCount
FROM AlbumCountryRanked
WHERE rn = 1
ORDER BY BillingCountry;

-- Best-selling album by genre
WITH AlbumGenreAgg AS (
  SELECT g.Name  AS GenreName,
         a.Title AS AlbumTitle,
         COUNT(*) AS SalesCount
  FROM InvoiceLine AS il
  JOIN Track       AS t ON il.TrackId  = t.TrackId
  JOIN Genre       AS g ON t.GenreId   = g.GenreId
  JOIN Album       AS a ON t.AlbumId   = a.AlbumId
  GROUP BY g.Name, a.Title
),
AlbumGenreRanked AS (
  SELECT GenreName,
         AlbumTitle,
         SalesCount,
         ROW_NUMBER() OVER (
           PARTITION BY GenreName
           ORDER BY SalesCount DESC, AlbumTitle
         ) AS rn
  FROM AlbumGenreAgg
)
SELECT GenreName, AlbumTitle, SalesCount
FROM AlbumGenreRanked
WHERE rn = 1
ORDER BY GenreName;

-- Largest and smallest revenue invoice, where revenue = SUM(UnitPrice / Bytes) per invoice
WITH RevenuePerInvoice AS (
  SELECT i.InvoiceId,
         SUM(il.UnitPrice / NULLIF(CAST(t.Bytes AS REAL), 0)) AS Revenue
  FROM Invoice     AS i
  JOIN InvoiceLine AS il ON i.InvoiceId = il.InvoiceId
  JOIN Track       AS t  ON il.TrackId  = t.TrackId
  GROUP BY i.InvoiceId
),
Largest AS (
  SELECT 'Largest' AS Bucket, InvoiceId, Revenue
  FROM RevenuePerInvoice
  ORDER BY Revenue DESC
  LIMIT 1
),
Smallest AS (
  SELECT 'Smallest' AS Bucket, InvoiceId, Revenue
  FROM RevenuePerInvoice
  ORDER BY Revenue ASC
  LIMIT 1
)
SELECT * FROM Largest
UNION ALL
SELECT * FROM Smallest;
