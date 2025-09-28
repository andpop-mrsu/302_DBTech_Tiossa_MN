import csv
import os

dataset_dir = 'dataset'
output_sql_file = 'db_init.sql'

movies_file = os.path.join(dataset_dir, 'movies.csv')
ratings_file = os.path.join(dataset_dir, 'ratings.csv')
tags_file = os.path.join(dataset_dir, 'tags.csv')
users_file = os.path.join(dataset_dir, 'users.txt')

print("Starting SQL script generation...")

with open(output_sql_file, 'w', encoding='utf-8') as sql_file:
    
    sql_file.write("BEGIN TRANSACTION;\n\n")
    
    
    sql_file.write("DROP TABLE IF EXISTS movies;\n")
    sql_file.write("DROP TABLE IF EXISTS ratings;\n")
    sql_file.write("DROP TABLE IF EXISTS tags;\n")
    sql_file.write("DROP TABLE IF EXISTS users;\n\n")

    
    sql_file.write("""
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    gender TEXT NOT NULL,
    register_date TEXT NOT NULL,
    occupation TEXT NOT NULL
);

\n""")

    
    print("Processing movies.csv...")
    sql_file.write("-- Inserting movies\n")
    with open(movies_file, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            title = row['title'].replace("'", "''")
            
            year = None
            if '(' in title and ')' in title:
                try:
                    open_bracket = title.rfind('(')
                    close_bracket = title.rfind(')')
                    if open_bracket != -1 and close_bracket != -1:
                        year_str = title[open_bracket + 1:close_bracket].strip()
                        if year_str.isdigit() and len(year_str) == 4:
                            year = int(year_str)
                except ValueError:
                    year = None

            genres = row['genres'].replace("'", "''")
            movie_id = row['movieId']
            
            if year:
                sql_line = f"INSERT INTO movies (id, title, year, genres) VALUES ({movie_id}, '{title}', {year}, '{genres}');\n"
            else:
                sql_line = f"INSERT INTO movies (id, title, year, genres) VALUES ({movie_id}, '{title}', NULL, '{genres}');\n"
            
            sql_file.write(sql_line)
    sql_file.write("\n")

    
    print("Processing ratings.csv...")
    sql_file.write("-- Inserting ratings\n")
    with open(ratings_file, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            sql_line = f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES ({row['userId']}, {row['movieId']}, {row['rating']}, {row['timestamp']});\n"
            sql_file.write(sql_line)
    sql_file.write("\n")

    
    print("Processing tags.csv...")
    sql_file.write("-- Inserting tags\n")
    with open(tags_file, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            tag = row['tag'].replace("'", "''")
            sql_line = f"INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES ({row['userId']}, {row['movieId']}, '{tag}', {row['timestamp']});\n"
            sql_file.write(sql_line)
    sql_file.write("\n")

    
    print("Processing users.txt...")
    sql_file.write("-- Inserting users\n")
    
    with open(users_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
                
            parts = line.split('|')
            if len(parts) != 6:
                continue
                
            user_id, name, email, gender, register_date, occupation = parts
            
            name = name.replace("'", "''")
            email = email.replace("'", "''")
            gender = gender.replace("'", "''")
            occupation = occupation.replace("'", "''")
            
            sql_line = f"INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES ({user_id}, '{name}', '{email}', '{gender}', '{register_date}', '{occupation}');\n"
            sql_file.write(sql_line)

   
    sql_file.write("\nCOMMIT;\n")

print(f"SQL script successfully generated: {output_sql_file}")
