Music Streaming SQL- Project

-- Simple tables without sequences
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) UNIQUE NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    country VARCHAR2(50),
    premium_member CHAR(1) DEFAULT 'N'
);

CREATE TABLE artists (
    artist_id NUMBER PRIMARY KEY,
    artist_name VARCHAR2(100) NOT NULL,
    genre VARCHAR2(50),
    monthly_listeners NUMBER DEFAULT 0
);

CREATE TABLE songs (
    song_id NUMBER PRIMARY KEY,
    song_title VARCHAR2(100) NOT NULL,
    artist_id NUMBER NOT NULL,
    duration_seconds NUMBER,
    genre VARCHAR2(50),
    total_streams NUMBER DEFAULT 0,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE playlists (
    playlist_id NUMBER PRIMARY KEY,
    playlist_name VARCHAR2(100) NOT NULL,
    user_id NUMBER NOT NULL,
    created_date DATE DEFAULT SYSDATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE playlist_songs (
    playlist_id NUMBER,
    song_id NUMBER,
    added_date DATE DEFAULT SYSDATE,
    PRIMARY KEY (playlist_id, song_id),
    FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id),
    FOREIGN KEY (song_id) REFERENCES songs(song_id)
);

CREATE TABLE streaming_history (
    stream_id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    song_id NUMBER NOT NULL,
    stream_date DATE DEFAULT SYSDATE,
    duration_played NUMBER,
    completed CHAR(1) DEFAULT 'N',
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (song_id) REFERENCES songs(song_id));
-- Insert artists
INSERT INTO artists VALUES (1, 'Arijit Singh', 'Bollywood', 50000000);
INSERT INTO artists VALUES (2, 'Taylor Swift', 'Pop', 80000000);
INSERT INTO artists VALUES (3, 'A.R. Rahman', 'Soundtrack', 45000000);
INSERT INTO artists VALUES (4, 'The Weeknd', 'R&B', 70000000);

-- Insert songs
INSERT INTO songs VALUES (101, 'Tum Hi Ho', 1, 290, 'Bollywood', 150000000);
INSERT INTO songs VALUES (102, 'Chahun Main Ya Naa', 1, 330, 'Bollywood', 120000000);
INSERT INTO songs VALUES (103, 'Anti-Hero', 2, 200, 'Pop', 300000000);
INSERT INTO songs VALUES (104, 'Jai Ho', 3, 320, 'Soundtrack', 250000000);
INSERT INTO songs VALUES (105, 'Blinding Lights', 4, 220, 'R&B', 2000000000);

-- Insert users
INSERT INTO users VALUES (1001, 'amit_music', 'amit@email.com', 'India', 'Y');
INSERT INTO users VALUES (1002, 'priya_swift', 'priya@email.com', 'India', 'N');
INSERT INTO users VALUES (1003, 'rahul_weeknd', 'rahul@email.com', 'USA', 'Y');

-- Insert playlists
INSERT INTO playlists VALUES (5001, 'My Fav Bollywood', 1001, SYSDATE);
INSERT INTO playlists VALUES (5002, 'Workout Mix', 1002, SYSDATE);

-- Insert playlist songs
INSERT INTO playlist_songs VALUES (5001, 101, SYSDATE);
INSERT INTO playlist_songs VALUES (5001, 102, SYSDATE);
INSERT INTO playlist_songs VALUES (5002, 105, SYSDATE);

-- Insert streaming history
INSERT INTO streaming_history VALUES (6001, 1001, 101, SYSDATE, 290, 'Y');
INSERT INTO streaming_history VALUES (6002, 1001, 102, SYSDATE-1, 200, 'N');
INSERT INTO streaming_history VALUES (6003, 1002, 103, SYSDATE-2, 200, 'Y');
INSERT INTO streaming_history VALUES (6004, 1003, 105, SYSDATE, 220, 'Y');
INSERT INTO streaming_history VALUES (6005, 1001, 105, SYSDATE, 220, 'Y');

COMMIT;
-- Top 5 most streamed songs
SELECT 
    s.song_title,
    a.artist_name,
    s.total_streams,
    ROUND(s.duration_seconds/60, 2) as duration_minutes
FROM songs s
JOIN artists a ON s.artist_id = a.artist_id
ORDER BY s.total_streams DESC
FETCH FIRST 5 ROWS ONLY;

-- Artist popularity ranking
SELECT 
    artist_name,
    genre,
    monthly_listeners,
    (SELECT COUNT(*) FROM songs WHERE artist_id = a.artist_id) as total_songs,
    (SELECT SUM(total_streams) FROM songs WHERE artist_id = a.artist_id) as total_streams
FROM artists a
ORDER BY monthly_listeners DESC;

-- User listening statistics
SELECT 
    u.username,
    u.premium_member,
    COUNT(sh.stream_id) as total_streams,
    COUNT(DISTINCT sh.song_id) as unique_songs_played,
    SUM(sh.duration_played) as total_seconds_listened
FROM users u
LEFT JOIN streaming_history sh ON u.user_id = sh.user_id
GROUP BY u.user_id, u.username, u.premium_member
ORDER BY total_seconds_listened DESC;

-- Genre-wise market analysis
SELECT 
    genre,
    COUNT(*) as total_songs,
    SUM(total_streams) as total_streams,
    ROUND(AVG(total_streams), 0) as avg_streams_per_song,
    ROUND(SUM(total_streams) * 100.0 / (SELECT SUM(total_streams) FROM songs), 2) as market_share_percent
FROM songs
GROUP BY genre
ORDER BY total_streams DESC;

-- Premium vs Free user comparison
SELECT 
    premium_member,
    COUNT(DISTINCT u.user_id) as user_count,
    ROUND(AVG(stream_count), 0) as avg_streams_per_user,
    ROUND(AVG(total_seconds)/3600, 2) as avg_hours_per_user
FROM users u
JOIN (
    SELECT user_id, COUNT(*) as stream_count, SUM(duration_played) as total_seconds
    FROM streaming_history 
    GROUP BY user_id
) sh ON u.user_id = sh.user_id
GROUP BY premium_member;

-- User engagement ranking
SELECT 
    u.username,
    u.country,
    u.premium_member,
    COUNT(sh.stream_id) as total_streams,
    COUNT(DISTINCT sh.song_id) as unique_songs,
    COUNT(DISTINCT p.playlist_id) as playlists_created,
    RANK() OVER (ORDER BY COUNT(sh.stream_id) DESC) as engagement_rank
FROM users u
LEFT JOIN streaming_history sh ON u.user_id = sh.user_id
LEFT JOIN playlists p ON u.user_id = p.user_id
GROUP BY u.user_id, u.username, u.country, u.premium_member
ORDER BY engagement_rank;

-- Most popular songs by genre
SELECT 
    genre,
    song_title,
    artist_name,
    total_streams,
    RANK() OVER (PARTITION BY genre ORDER BY total_streams DESC) as genre_rank
FROM songs s
JOIN artists a ON s.artist_id = a.artist_id
WHERE genre IS NOT NULL
QUALIFY RANK() OVER (PARTITION BY genre ORDER BY total_streams DESC) <= 3
ORDER BY genre, genre_rank;

-- Users who might like similar songs (basic recommendation)
SELECT DISTINCT
    s2.song_title,
    s2.artist_name,
    s2.genre,
    s2.total_streams
FROM streaming_history sh1
JOIN streaming_history sh2 ON sh1.user_id = sh2.user_id AND sh1.song_id != sh2.song_id
JOIN songs s1 ON sh1.song_id = s1.song_id
JOIN songs s2 ON sh2.song_id = s2.song_id
JOIN artists a ON s2.artist_id = a.artist_id
WHERE sh1.user_id = 1001  -- Amit's ID
AND s2.song_id NOT IN (
    SELECT song_id FROM streaming_history WHERE user_id = 1001
)
ORDER BY s2.total_streams DESC
FETCH FIRST 10 ROWS ONLY;

-- Artist cross-promotion opportunities
SELECT 
    a1.artist_name as artist_A,
    a2.artist_name as artist_B,
    COUNT(DISTINCT u.user_id) as common_listeners,
    ROUND(COUNT(DISTINCT u.user_id) * 100.0 / (
        SELECT COUNT(*) FROM user_followers WHERE artist_id = a1.artist_id
    ), 2) as overlap_percent
FROM user_followers uf1
JOIN user_followers uf2 ON uf1.user_id = uf2.user_id AND uf1.artist_id != uf2.artist_id
JOIN artists a1 ON uf1.artist_id = a1.artist_id
JOIN artists a2 ON uf2.artist_id = a2.artist_id
WHERE a1.artist_id = 1  -- Arijit Singh
GROUP BY a1.artist_name, a2.artist_name, a1.artist_id
ORDER BY common_listeners DESC
FETCH FIRST 5 ROWS ONLY;

-- Daily streaming trends (last 7 days)
SELECT 
    TRUNC(stream_date) as streaming_date,
    COUNT(*) as total_streams,
    COUNT(DISTINCT user_id) as daily_active_users,
    ROUND(AVG(duration_played), 0) as avg_session_duration
FROM streaming_history
WHERE stream_date >= SYSDATE - 7
GROUP BY TRUNC(stream_date)
ORDER BY streaming_date DESC;

-- User retention analysis
SELECT 
    'Last 7 days' as period,
    COUNT(DISTINCT user_id) as active_users,
    (SELECT COUNT(*) FROM users) as total_users,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / (SELECT COUNT(*) FROM users), 2) as retention_rate
FROM streaming_history
WHERE stream_date >= SYSDATE - 7

UNION ALL

SELECT 
    'Last 30 days' as period,
    COUNT(DISTINCT user_id) as active_users,
    (SELECT COUNT(*) FROM users) as total_users,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / (SELECT COUNT(*) FROM users), 2) as retention_rate
FROM streaming_history
WHERE stream_date >= SYSDATE - 30;

-- Content performance by duration
SELECT 
    CASE 
        WHEN duration_seconds < 180 THEN 'Short (<3 min)'
        WHEN duration_seconds BETWEEN 180 AND 300 THEN 'Medium (3-5 min)'
        ELSE 'Long (>5 min)'
    END as duration_category,
    COUNT(*) as song_count,
    ROUND(AVG(total_streams), 0) as avg_streams,
    SUM(total_streams) as total_streams
FROM songs
GROUP BY 
    CASE 
        WHEN duration_seconds < 180 THEN 'Short (<3 min)'
        WHEN duration_seconds BETWEEN 180 AND 300 THEN 'Medium (3-5 min)'
        ELSE 'Long (>5 min)'
    END
ORDER BY total_streams DESC;

