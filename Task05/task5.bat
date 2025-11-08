#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма выведите его название, год выпуска и средний рейтинг. Дополнительно добавьте столбец rank_by_avg_rating, в котором укажите ранг фильма среди всех фильмов по убыванию среднего рейтинга (фильмы с одинаковым средним рейтингом должны получить одинаковый ранг). Используйте оконную функцию RANK() или DENSE_RANK(). В результирующем наборе данных оставить 10 фильмов с наибольшим рангом."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH movie_ratings AS ( SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating, DENSE_RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rank_by_avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year HAVING COUNT(r.rating) >= 1 ) SELECT title, year, ROUND(avg_rating, 2) AS avg_rating, rank_by_avg_rating FROM movie_ratings WHERE rank_by_avg_rating <= 10 ORDER BY rank_by_avg_rating, title LIMIT 10;"
echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies. Для каждого жанра рассчитать средний рейтинг avg_rating фильмов в этом жанре. Выведите genre, avg_rating и ранг жанра по убыванию среднего рейтинга, используя оконную функцию RANK()."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS ( SELECT id, '', genres || '|' FROM movies WHERE genres IS NOT NULL UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|')-1), substr(rest, instr(rest, '|')+1) FROM split WHERE rest != '' ), movie_genres AS ( SELECT movie_id, trim(genre) AS genre FROM split WHERE genre != '' ), genre_ratings AS ( SELECT mg.genre, r.rating FROM movie_genres mg JOIN ratings r ON mg.movie_id = r.movie_id ) SELECT genre, ROUND(AVG(rating), 2) AS avg_rating, RANK() OVER (ORDER BY AVG(rating) DESC) AS rating_rank FROM genre_ratings GROUP BY genre ORDER BY rating_rank;"
echo " "

echo "3. Посчитайте количество фильмов в каждом жанре. Выведите два столбца: genre и movie_count, отсортировав результат по убыванию количества фильмов."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(genre, rest) AS ( SELECT '', genres || '|' FROM movies WHERE genres IS NOT NULL UNION ALL SELECT substr(rest, 1, instr(rest, '|')-1), substr(rest, instr(rest, '|')+1) FROM split WHERE rest != '' ) SELECT trim(genre) AS genre, COUNT(*) AS movie_count FROM split WHERE genre != '' GROUP BY genre ORDER BY movie_count DESC;"
echo " "

echo "4. Найдите жанры, в которых чаще всего оставляют теги (комментарии). Для этого подсчитайте общее количество записей в таблице tags для фильмов каждого жанра. Выведите genre, tag_count и долю этого жанра в общем числе тегов (tag_share), выраженную в процентах."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS ( SELECT id, '', genres || '|' FROM movies WHERE genres IS NOT NULL UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|')-1), substr(rest, instr(rest, '|')+1) FROM split WHERE rest != '' ), movie_genres AS ( SELECT DISTINCT movie_id, trim(genre) AS genre FROM split WHERE genre != '' ), genre_tags AS ( SELECT mg.genre, COUNT(DISTINCT t.id) AS tag_count FROM movie_genres mg JOIN tags t ON mg.movie_id = t.movie_id GROUP BY mg.genre ), total AS ( SELECT SUM(tag_count) AS total_count FROM genre_tags ) SELECT gt.genre, gt.tag_count, ROUND(gt.tag_count * 100.0 / t.total_count, 2) AS tag_share FROM genre_tags gt, total t ORDER BY gt.tag_count DESC;"
echo " "

echo "5. Для каждого пользователя рассчитайте: общее количество выставленных оценок, средний выставленный рейтинг, дату первой и последней оценки (по полю timestamp в таблице ratings). Выведите user_id, rating_count, avg_rating, first_rating_date, last_rating_date. Отсортируйте результат по убыванию количества оценок и выведите только 10 первых строк."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u.id AS user_id, COUNT(r.id) AS rating_count, ROUND(AVG(r.rating), 2) AS avg_rating, datetime(MIN(r.timestamp), 'unixepoch') AS first_rating_date, datetime(MAX(r.timestamp), 'unixepoch') AS last_rating_date FROM users u JOIN ratings r ON u.id = r.user_id GROUP BY u.id ORDER BY rating_count DESC LIMIT 10;"
echo " "

echo "6. Сегментируйте пользователей по типу поведения: «Комментаторы» — пользователи, у которых количество тегов (tags) больше количества оценок (ratings), «Оценщики» — наоборот, оценок больше, чем тегов, «Активные» — и оценок, и тегов ≥ 10, «Пассивные» — и оценок, и тегов < 5. Выведите user_id, общее число оценок, общее число тегов и категорию поведения. Используйте CASE."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH user_stats AS (SELECT u.id AS user_id, COUNT(DISTINCT r.id) AS rating_count, COUNT(DISTINCT t.id) AS tag_count FROM users u LEFT JOIN ratings r ON u.id = r.user_id LEFT JOIN tags t ON u.id = t.user_id GROUP BY u.id) SELECT user_id, rating_count, tag_count, CASE WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные' WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' ELSE 'Сбалансированные' END AS behavior_category FROM user_stats ORDER BY user_id;"
echo " "

echo "7. Для каждого пользователя выведите его имя и последний фильм, который он оценил (по времени из ratings.timestamp). Если пользователь не оценивал ни одного фильма, он всё равно должен быть в результате (с NULL в полях фильма). Результат: user_id, name, last_rated_movie_title, last_rating_timestamp."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH last_user_ratings AS (SELECT r.user_id, r.movie_id, r.timestamp, m.title, ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY r.timestamp DESC) as rn FROM ratings r JOIN movies m ON r.movie_id = m.id)SELECT u.id AS user_id, u.name, lur.title AS last_rated_movie_title, datetime(lur.timestamp, 'unixepoch') AS last_rating_timestamp FROM users u LEFT JOIN last_user_ratings lur ON u.id = lur.user_id AND lur.rn = 1 ORDER BY u.id;"
echo " "

pause