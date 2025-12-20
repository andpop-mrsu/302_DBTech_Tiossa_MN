<?php
// Скрипт для инициализации базы данных SQLite СТО

$dbPath = __DIR__ . '/data/sto.db';

try {
    // Создаем подключение к базе данных
    $pdo = new PDO('sqlite:' . $dbPath);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Создаем таблицу мастеров
    $pdo->exec("CREATE TABLE IF NOT EXISTS masters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surname TEXT NOT NULL,
        firstname TEXT NOT NULL,
        patronymic TEXT,
        specialization TEXT NOT NULL
    )");

    // Создаем таблицу графика работы
    $pdo->exec("CREATE TABLE IF NOT EXISTS work_schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        master_id INTEGER NOT NULL,
        day_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        FOREIGN KEY (master_id) REFERENCES masters(id) ON DELETE CASCADE
    )");

    // Создаем таблицу выполненных работ
    $pdo->exec("CREATE TABLE IF NOT EXISTS completed_works (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        master_id INTEGER NOT NULL,
        service_name TEXT NOT NULL,
        work_date DATE NOT NULL,
        cost REAL NOT NULL,
        FOREIGN KEY (master_id) REFERENCES masters(id) ON DELETE CASCADE
    )");

    // Проверяем, есть ли уже данные
    $stmt = $pdo->query("SELECT COUNT(*) FROM masters");
    $count = $stmt->fetchColumn();

    // Если таблица пустая, добавляем тестовые данные
    if ($count == 0) {
        // Добавляем мастеров
        $pdo->exec("INSERT INTO masters (surname, firstname, patronymic, specialization) VALUES
            ('Кузнецов', 'Михаил', 'Владимирович', 'Диагност'),
            ('Смирнова', 'Анна', 'Олеговна', 'Электрик'),
            ('Васильев', 'Сергей', 'Петрович', 'Механик')
        ");

        // Добавляем график работы
        $pdo->exec("INSERT INTO work_schedule (master_id, day_of_week, start_time, end_time) VALUES
            (1, 'Понедельник', '08:30', '17:30'),
            (1, 'Вторник', '08:30', '17:30'),
            (1, 'Среда', '08:30', '17:30'),
            (2, 'Понедельник', '09:00', '18:00'),
            (2, 'Четверг', '09:00', '18:00'),
            (3, 'Пятница', '07:00', '16:00')
        ");

        // Добавляем выполненные работы
        $pdo->exec("INSERT INTO completed_works (master_id, service_name, work_date, cost) VALUES
            (1, 'Компьютерная диагностика', '2024-12-10', 3500.00),
            (1, 'Проверка систем автомобиля', '2024-12-12', 2800.00),
            (2, 'Замена аккумулятора', '2024-12-11', 4500.00),
            (3, 'Замена тормозных колодок', '2024-12-09', 6200.00)
        ");

        echo "База данных успешно создана и заполнена тестовыми данными!\n";
    } else {
        echo "База данных уже существует и содержит данные.\n";
    }

} catch (PDOException $e) {
    die("Ошибка при создании базы данных: " . $e->getMessage() . "\n");
}