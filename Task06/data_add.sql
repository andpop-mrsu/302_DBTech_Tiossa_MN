-- 1. Добавление новых пользователей
INSERT INTO users (name, email, gender, register_date, occupation_id)
VALUES 
('Максим Тиосса', 'maxim.tiossa@example.com', 'male', date('now'), 
    (SELECT id FROM occupations WHERE name = 'student')),
('Данила Тужин', 'danila.tujin@example.com', 'male', date('now'), 
    (SELECT id FROM occupations WHERE name = 'engineer')),
('Никита Учуваткин', 'nikita.uchuvatkin@example.com', 'male', date('now'), 
    (SELECT id FROM occupations WHERE name = 'programmer')),
('Алексей Шапошников', 'alexei.shaposhnikov@example.com', 'male', date('now'), 
    (SELECT id FROM occupations WHERE name = 'programmer')),
('Ольга Шиляева', 'olga.shilyaeva@example.com', 'female', date('now'), 
    (SELECT id FROM occupations WHERE name = 'student'));


INSERT INTO movies (title, year)
VALUES 
('Космическая одиссея', 2024),
('Тайна старого замка', 2010),
('Веселые каникулы', 2019);


INSERT INTO movies_genres (movie_id, genre_id)
VALUES 
-- Космическая одиссея: Sci-Fi, Adventure
((SELECT id FROM movies WHERE title = 'Космическая одиссея'), 
 (SELECT id FROM genres WHERE name = 'Sci-Fi')),
((SELECT id FROM movies WHERE title = 'Космическая одиссея'),  
 (SELECT id FROM genres WHERE name = 'Adventure')),

-- Тайна старого замка: Mystery, Drama
((SELECT id FROM movies WHERE title = 'Тайна старого замка'), 
 (SELECT id FROM genres WHERE name = 'Mystery')),
((SELECT id FROM movies WHERE title = 'Тайна старого замка'), 
 (SELECT id FROM genres WHERE name = 'Drama')),

-- Веселые каникулы: Comedy, Family
((SELECT id FROM movies WHERE title = 'Веселые каникулы'), 
 (SELECT id FROM genres WHERE name = 'Comedy')),
((SELECT id FROM movies WHERE title = 'Веселые каникулы'), 
 (SELECT id FROM genres WHERE name = 'Family'));

-- 4. Добавление отзывов
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
VALUES 
((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), 
 (SELECT id FROM movies WHERE title = 'Космическая одиссея'), 5.0, strftime('%s', 'now')),
((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), 
 (SELECT id FROM movies WHERE title = 'Тайна старого замка'), 4.5, strftime('%s', 'now')),
((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), 
 (SELECT id FROM movies WHERE title = 'Веселые каникулы'), 4.8, strftime('%s', 'now'));

-- 5. Добавление тегов
INSERT INTO tags (user_id, movie_id, tag, timestamp)
VALUES 
((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), 
 (SELECT id FROM movies WHERE title = 'Космическая одиссея'), 'захватывающее зрелище', strftime('%s', 'now')),
((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), 
 (SELECT id FROM movies WHERE title = 'Тайна старого замка'), 'загадочно', strftime('%s', 'now')),
((SELECT id FROM users WHERE email = 'maxim.tiossa@example.com'), 
 (SELECT id FROM movies WHERE title = 'Веселые каникулы'), 'смешно до слез', strftime('%s', 'now'));