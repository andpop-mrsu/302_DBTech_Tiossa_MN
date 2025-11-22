#!/bin/bash

@echo off
chcp 65001

echo ==================================================
echo ТЕСТИРОВАНИЕ ДОБАВЛЕННЫХ ДАННЫХ
echo ==================================================

echo.
echo 1. Создаем и инициализируем базу данных...
echo --------------------------------------------------
sqlite3.exe movies_rating.db < db_init.sql
if %errorlevel% neq 0 (
    echo ОШИБКА: Не удалось выполнить db_init.sql
    goto end
)

echo.
echo 2. Добавляем тестовые данные...
echo --------------------------------------------------
sqlite3.exe movies_rating.db < data_add.sql
if %errorlevel% neq 0 (
    echo ПРЕДУПРЕЖДЕНИЕ: Ошибка в data_add.sql (возможно movies_genres)
)

echo.
echo 3. Проверяем добавленных пользователей...
echo --------------------------------------------------
sqlite3.exe movies_rating.db -box -echo "SELECT id, name, email, gender, register_date FROM users ORDER BY id DESC LIMIT 5;"

echo.
echo 4. Проверяем добавленные фильмы...
echo --------------------------------------------------
sqlite3.exe movies_rating.db -box -echo "SELECT id, title, year FROM movies WHERE title IN ('Космическая одиссея', 'Тайна старого замка', 'Веселые каникулы');"

echo.
echo 5. Проверяем рейтинги от Максима Тиосса...
echo --------------------------------------------------
sqlite3.exe movies_rating.db -box -echo "SELECT u.name as пользователь, m.title as фильм, r.rating as оценка, datetime(r.timestamp, 'unixepoch') as время FROM ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id WHERE u.email = 'maxim.tiossa@example.com' ORDER BY r.rating DESC;"

echo.
echo 6. Проверяем теги от Максима Тиосса...
echo --------------------------------------------------
sqlite3.exe movies_rating.db -box -echo "SELECT u.name as пользователь, m.title as фильм, t.tag as тег, datetime(t.timestamp, 'unixepoch') as время FROM tags t JOIN users u ON t.user_id = u.id JOIN movies m ON t.movie_id = m.id WHERE u.email = 'maxim.tiossa@example.com';"

echo.
echo 7. Проверяем ограничения целостности...
echo --------------------------------------------------
echo Тест уникальности email:
sqlite3.exe movies_rating.db "INSERT INTO users (name, email, gender, occupation_id) VALUES ('Test User', 'maxim.tiossa@example.com', 'male', 1);" >nul 2>&1
if %errorlevel% neq 0 (
    echo OK: Ограничение уникальности email работает
) else (
    echo ОШИБКА: Ограничение уникальности email не сработало!
)

echo.
echo Тест ограничения рейтинга:
sqlite3.exe movies_rating.db "INSERT INTO ratings (user_id, movie_id, rating) VALUES ((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), (SELECT id FROM movies WHERE title = 'Космическая одиссея'), 6.0);" >nul 2>&1
if %errorlevel% neq 0 (
    echo OK: Ограничение на рейтинг работает
) else (
    echo ОШИБКА: Ограничение на рейтинг не сработало!
)

echo.
echo Тест ограничения пола:
sqlite3.exe movies_rating.db "INSERT INTO users (name, email, gender, occupation_id) VALUES ('Test', 'test123@test.com', 'invalid', 1);" >nul 2>&1
if %errorlevel% neq 0 (
    echo OK: Ограничение на пол работает
) else (
    echo ОШИБКА: Ограничение на пол не сработало!
)

echo.
echo 8. Итоговая проверка всех добавленных данных...
echo --------------------------------------------------
sqlite3.exe movies_rating.db -box -echo "SELECT 'Пользователи: ' || COUNT(*) as count FROM users ORDER BY id DESC LIMIT 5;"
sqlite3.exe movies_rating.db -box -echo "SELECT 'Фильмы: ' || COUNT(*) as count FROM movies WHERE title IN ('Космическая одиссея', 'Тайна старого замка', 'Веселые каникулы');"
sqlite3.exe movies_rating.db -box -echo "SELECT 'Рейтинги: ' || COUNT(*) as count FROM ratings WHERE user_id IN (SELECT id FROM users ORDER BY id DESC LIMIT 5);"
sqlite3.exe movies_rating.db -box -echo "SELECT 'Теги: ' || COUNT(*) as count FROM tags WHERE user_id IN (SELECT id FROM users ORDER BY id DESC LIMIT 5);"

:end
echo.
echo ==================================================
echo ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!
echo Файл базы: movies_rating.db
echo ==================================================
echo.
pause