# 🎵 Music Streaming Analytics SQL Project

## Project Overview
**Project Title:** Music Streaming Analytics  
**Level:** Intermediate  
**Database:** Oracle SQL

This project demonstrates SQL skills for analyzing music streaming data. It includes database setup, data insertion, and 12 analytical queries that provide insights into user behavior, content performance, and business metrics for a music streaming platform.

## Objectives
- **Database Design:** Create normalized tables for music streaming operations
- **Data Analysis:** Perform comprehensive analysis of streaming patterns
- **Business Insights:** Generate actionable insights for content strategy and user engagement
- **SQL Proficiency:** Demonstrate advanced SQL querying capabilities

## Project Structure

### Database Schema
**Tables Created:**
- `users` - User profiles and subscription status
- `artists` - Artist information and popularity metrics
- `songs` - Music catalog with streaming statistics
- `playlists` - User-curated music collections
- `playlist_songs` - Relationship between playlists and songs
- `streaming_history` - User listening activity records

### Dataset Summary
- **6 normalized tables**
- **5 artists** including Arijit Singh, Taylor Swift, A.R. Rahman, The Weeknd
- **5 songs** across Bollywood, Pop, Soundtrack, and R&B genres
- **3 users** with mixed subscription types
- **2 playlists** with curated song selections
- **5 streaming history records** showing user listening patterns

## SQL Queries & Analysis

### 1. Top 5 Most Streamed Songs
- Identifies the most popular songs based on total stream counts.
```sql
  SELECT 
    s.song_title,
    a.artist_name,
    s.total_streams ROUND(s.duration_seconds/60, 2) as duration_minutes
 FROM songs s
JOIN artists a ON s.artist_id = a.artist_id
ORDER BY s.total_streams DESC
FETCH FIRST 5 ROWS ONLY;
```
### 2. Artist Popularity Ranking
- Ranks artists by monthly listeners and calculates their total content impact.
```sql
  SELECT 
    artist_name,
    genre,
    monthly_listeners,
    (SELECT COUNT(*) FROM songs WHERE artist_id = a.artist_id) as total_songs,
    (SELECT SUM(total_streams) FROM songs WHERE artist_id = a.artist_id) as total_streams
FROM artists a
ORDER BY monthly_listeners DESC;
 ```
### 3. User Listening Statistics
- Analyzes user engagement through streaming patterns and listening duration.
```sql
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
 ```
### 4. Genre-wise Market Analysis.
- Examines market share and performance across different music genres.
```sql
SELECT 
    genre,
    COUNT(*) as total_songs,
    SUM(total_streams) as total_streams,
    ROUND(AVG(total_streams), 0) as avg_streams_per_song,
    ROUND(SUM(total_streams) * 100.0 / (SELECT SUM(total_streams) FROM songs), 2) as market_share_percent
FROM songs
GROUP BY genre
ORDER BY total_streams DESC;
```
### 5. Premium vs Free User Comparison
- Compares engagement metrics between premium and free users.
```sql
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
```
### 6. User Engagement Ranking
- Ranks users based on their overall platform engagement.
```sql
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
```
### 7. Most Popular Songs by Genre
- Identifies top-performing songs within each genre category.
```sql
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
```
### 8. Personalized Song Recommendations
- Generates song suggestions based on user listening history.
```sql
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
WHERE sh1.user_id = 1001
AND s2.song_id NOT IN (
    SELECT song_id FROM streaming_history WHERE user_id = 1001
)
ORDER BY s2.total_streams DESC
FETCH FIRST 10 ROWS ONLY;
```
### 9. Artist Cross-Promotion Opportunities
- Identifies potential collaboration opportunities between artists.
```sql
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
WHERE a1.artist_id = 1
GROUP BY a1.artist_name, a2.artist_name, a1.artist_id
ORDER BY common_listeners DESC
FETCH FIRST 5 ROWS ONLY;
```
### 10. Daily Streaming Trends
- Analyzes streaming patterns over the last 7 days.
```sql
SELECT 
    TRUNC(stream_date) as streaming_date,
    COUNT(*) as total_streams,
    COUNT(DISTINCT user_id) as daily_active_users,
    ROUND(AVG(duration_played), 0) as avg_session_duration
FROM streaming_history
WHERE stream_date >= SYSDATE - 7
GROUP BY TRUNC(stream_date)
ORDER BY streaming_date DESC;
```
### 11. User Retention Analysis
- Calculates user retention rates for different time periods.
```sql
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
```
### 12. Content Performance by Duration
- Analyzes how song duration affects streaming performance.
```sql
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
```

## Key Findings
- **Blinding Lights** by The Weeknd is the most streamed song
- **The Weeknd** leads in monthly listeners among the artists
- **Premium users** show higher engagement metrics
- **R&B** genre dominates in total streams despite fewer songs
- **User retention** rates provide insights for engagement strategies

## Business Applications
- **Content Strategy:** Focus on high-performing genres and artists
- **User Engagement:** Develop personalized recommendation systems
- **Subscription Model:** Optimize premium tier offerings
- **Artist Relations:** Identify collaboration opportunities
- **Product Development:** Understand optimal song durations

## How to Use
- Execute the table creation scripts in Oracle SQL
- Insert the sample data provided
- Run the analytical queries to generate insights
- Modify queries to explore additional business questions

## Technical Skills Demonstrated
- Database Design and Normalization
- Advanced SQL Querying
- Data Analysis and Business Intelligence
- Window Functions and Complex Joins
- Real-world Business Problem Solving

## Author - Shashi Maurya
This project is part of my portfolio, showcasing the SQL skills essential for Any roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!
