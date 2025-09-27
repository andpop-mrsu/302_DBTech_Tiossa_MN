@echo off
echo Starting database initialization...


if exist movies_rating.db del movies_rating.db
if exist movies_rating.db-journal del movies_rating.db-journal
if exist db_init.sql del db_init.sql


python make_db_init.py


if not exist db_init.sql (
    echo Error: db_init.sql was not created
    pause
    exit /b 1
)

echo SQL script generated. Loading into database...


sqlite3 movies_rating.db < db_init.sql


if exist movies_rating.db (
    echo Database created successfully!
    echo.
    echo Records count:
    sqlite3 movies_rating.db "SELECT 'Movies: ' || COUNT(*) FROM movies;"
    sqlite3 movies_rating.db "SELECT 'Ratings: ' || COUNT(*) FROM ratings;"
    sqlite3 movies_rating.db "SELECT 'Tags: ' || COUNT(*) FROM tags;"
    sqlite3 movies_rating.db "SELECT 'Users: ' || COUNT(*) FROM users;"
) else (
    echo Error: Database was not created
)

pause
