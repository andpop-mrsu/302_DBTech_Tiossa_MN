#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title AS movie_title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id JOIN users u1 ON r1.user_id = u1.id JOIN users u2 ON r2.user_id = u2.id JOIN movies m ON r1.movie_id = m.id WHERE u1.id < u2.id ORDER BY u1.name, u2.name, m.title LIMIT 100;"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title AS 'Название фильма' , u.name AS 'Имя', r.rating as 'Оценка', datetime(r.timestamp, 'unixepoch') AS 'Дата Отзыва' FROM ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id ORDER BY r.timestamp ASC LIMIT 10"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS ( SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year ), min_max AS ( SELECT MIN(avg_rating) AS min_rating, MAX(avg_rating) AS max_rating FROM avg_ratings ) SELECT ar.title, ar.year, ar.avg_rating, CASE WHEN ar.avg_rating = (SELECT max_rating FROM min_max) THEN 'Да' ELSE 'Нет' END AS Рекомендуем FROM avg_ratings ar WHERE ar.avg_rating = (SELECT min_rating FROM min_max) OR ar.avg_rating = (SELECT max_rating FROM min_max) ORDER BY ar.year, ar.title;"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) as 'Количество оценок', AVG(r.rating) as 'Cредняя оценка' FROM ratings r JOIN users u ON r.user_id = u.id WHERE u.gender = 'male' AND strftime('%%Y', datetime(r.timestamp, 'unixepoch')) BETWEEN '2011' AND '2014'"
echo " "

echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, AVG(r.rating) AS avg_rating, COUNT(DISTINCT r.user_id) AS users_count FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year ORDER BY m.year, m.title LIMIT 20;"
echo " "

echo "6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH split_genres AS ( WITH RECURSIVE split(genre, rest) AS ( SELECT '', genres || '|' FROM movies UNION ALL SELECT substr(rest, 1, instr(rest, '|')-1), substr(rest, instr(rest, '|')+1) FROM split WHERE rest != '' ) SELECT trim(genre) AS genre FROM split WHERE genre != '' ) SELECT genre, COUNT(*) AS movie_count FROM split_genres GROUP BY genre ORDER BY movie_count DESC LIMIT 1;"
echo " "

echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации' (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ')+1) || ' ' || substr(name, 1, instr(name, ' ')-1) || '|' || register_date AS user_info FROM users ORDER BY register_date DESC LIMIT 10;"
echo " "

echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE birthdays(year, date, day_of_week) AS (SELECT 2005, date('2005-09-19'), strftime('%%w', '2005-09-19') UNION ALL SELECT year + 1, date((year + 1) || '-09-19'), strftime('%%w', date((year + 1) || '-09-19')) FROM birthdays WHERE year < 2025) SELECT year, date, CASE day_of_week WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS day_name FROM birthdays"
echo " "