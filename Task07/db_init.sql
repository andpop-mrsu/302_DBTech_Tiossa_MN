CREATE TABLE CarCategory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CHECK (name != '')
);

CREATE TABLE Employee (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL CHECK(position IN ('Мастер', 'Администратор', 'Менеджер')),
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100),
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    dismissal_date DATE NULL,
    salary_percent DECIMAL(5,2) NOT NULL DEFAULT 25.00,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CHECK (salary_percent BETWEEN 0 AND 100),
    CHECK (dismissal_date IS NULL OR dismissal_date > hire_date),
    CHECK (phone IS NOT NULL OR email IS NOT NULL),
    CHECK (first_name != '' AND last_name != '')
);

CREATE TABLE Service (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    base_duration_minutes INTEGER NOT NULL DEFAULT 60,
    base_price DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CHECK (base_duration_minutes > 0),
    CHECK (base_price >= 0),
    CHECK (name != '')
);

CREATE TABLE WorkBox (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    number INTEGER NOT NULL UNIQUE,
    name VARCHAR(50),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    max_car_category_id INTEGER NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CHECK (number > 0),
    FOREIGN KEY (max_car_category_id) REFERENCES CarCategory(id),
    CHECK (name IS NOT NULL OR description IS NOT NULL)
);

CREATE TABLE ServicePrice (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    service_id INTEGER NOT NULL,
    car_category_id INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (service_id) REFERENCES Service(id) ON DELETE CASCADE,
    FOREIGN KEY (car_category_id) REFERENCES CarCategory(id) ON DELETE CASCADE,
    CHECK (price >= 0),
    CHECK (duration_minutes > 0),
    CHECK (effective_to IS NULL OR effective_to >= effective_from),
    UNIQUE(service_id, car_category_id, effective_from)
);

CREATE TABLE EmployeeSpecialization (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    proficiency_level VARCHAR(20) DEFAULT 'базовый' CHECK(proficiency_level IN ('базовый', 'опытный', 'эксперт')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES Employee(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES Service(id) ON DELETE CASCADE,
    UNIQUE(employee_id, service_id)
);

CREATE TABLE Appointment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_name VARCHAR(100) NOT NULL,
    client_phone VARCHAR(20) NOT NULL,
    client_email VARCHAR(100),
    car_model VARCHAR(100) NOT NULL,
    car_license_plate VARCHAR(20),
    car_category_id INTEGER NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'запланирован' 
        CHECK(status IN ('запланирован', 'подтвержден', 'в процессе', 'выполнен', 'отменен', 'неявка')),
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    prepayment DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by_employee_id INTEGER,
    FOREIGN KEY (car_category_id) REFERENCES CarCategory(id),
    FOREIGN KEY (created_by_employee_id) REFERENCES Employee(id),
    CHECK (end_time > start_time),
    CHECK (total_price >= 0),
    CHECK (prepayment >= 0 AND prepayment <= total_price),
    CHECK (client_name != ''),
    CHECK (appointment_date >= DATE('now'))
);

CREATE TABLE AppointmentService (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    box_id INTEGER NOT NULL,
    scheduled_price DECIMAL(10,2) NOT NULL,
    scheduled_duration INTEGER NOT NULL,
    sequence_number INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    FOREIGN KEY (appointment_id) REFERENCES Appointment(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES Service(id),
    FOREIGN KEY (employee_id) REFERENCES Employee(id),
    FOREIGN KEY (box_id) REFERENCES WorkBox(id),
    CHECK (scheduled_price >= 0),
    CHECK (scheduled_duration > 0),
    CHECK (sequence_number > 0),
    UNIQUE(appointment_id, sequence_number)
);

CREATE TABLE WorkRecord (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_service_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    box_id INTEGER NOT NULL,
    actual_start_time DATETIME NOT NULL,
    actual_end_time DATETIME NOT NULL,
    actual_price DECIMAL(10,2) NOT NULL,
    actual_duration INTEGER GENERATED ALWAYS AS (
        CAST((julianday(actual_end_time) - julianday(actual_start_time)) * 24 * 60 AS INTEGER)
    ) VIRTUAL,
    status VARCHAR(20) NOT NULL DEFAULT 'выполнено' 
        CHECK(status IN ('выполнено', 'отменено', 'перенесено')),
    quality_rating INTEGER CHECK(quality_rating BETWEEN 1 AND 5),
    client_feedback TEXT,
    notes TEXT,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    recorded_by_employee_id INTEGER,
    FOREIGN KEY (appointment_service_id) REFERENCES AppointmentService(id),
    FOREIGN KEY (employee_id) REFERENCES Employee(id),
    FOREIGN KEY (box_id) REFERENCES WorkBox(id),
    FOREIGN KEY (recorded_by_employee_id) REFERENCES Employee(id),
    CHECK (actual_price >= 0),
    CHECK (actual_end_time > actual_start_time)
);

CREATE TABLE SalaryCalculation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    calculation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_revenue DECIMAL(12,2) NOT NULL DEFAULT 0,
    applicable_percent DECIMAL(5,2) NOT NULL,
    calculated_amount DECIMAL(12,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    deduction DECIMAL(10,2) DEFAULT 0,
    final_amount DECIMAL(12,2) GENERATED ALWAYS AS (calculated_amount + bonus - deduction) VIRTUAL,
    payment_date DATE NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'рассчитано' 
        CHECK(status IN ('рассчитано', 'подтверждено', 'выплачено', 'отложено')),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES Employee(id),
    CHECK (period_start <= period_end),
    CHECK (period_end <= calculation_date),
    CHECK (total_revenue >= 0),
    CHECK (applicable_percent BETWEEN 0 AND 100),
    CHECK (calculated_amount >= 0),
    CHECK (bonus >= 0),
    CHECK (deduction >= 0),
    CHECK (payment_date IS NULL OR payment_date >= calculation_date)
);

CREATE INDEX idx_employee_active ON Employee(is_active, position);
CREATE INDEX idx_employee_name ON Employee(last_name, first_name);

CREATE INDEX idx_appointment_date ON Appointment(appointment_date, status);
CREATE INDEX idx_appointment_datetime ON Appointment(appointment_date, start_time, end_time);
CREATE INDEX idx_appointment_client ON Appointment(client_phone, client_name);
CREATE INDEX idx_appointment_status ON Appointment(status);

CREATE INDEX idx_workrecord_employee_date ON WorkRecord(employee_id, actual_start_time);
CREATE INDEX idx_workrecord_box_date ON WorkRecord(box_id, actual_start_time);
CREATE INDEX idx_workrecord_appointment ON WorkRecord(appointment_service_id);

CREATE INDEX idx_salary_employee_period ON SalaryCalculation(employee_id, period_start, period_end);
CREATE INDEX idx_salary_status ON SalaryCalculation(status, payment_date);

CREATE INDEX idx_serviceprice_current ON ServicePrice(service_id, car_category_id, effective_from, effective_to);
CREATE INDEX idx_serviceprice_date ON ServicePrice(effective_from, effective_to);

CREATE INDEX idx_appointmentservice_box_time ON AppointmentService(box_id);
CREATE INDEX idx_workbox_active ON WorkBox(is_active, max_car_category_id);

BEGIN TRANSACTION;

INSERT INTO CarCategory (name, description) VALUES
('Легковые (A-B)', 'Малые и средние легковые автомобили'),
('Легковые (C-D)', 'Крупные легковые и бизнес-класс'),
('Кроссоверы', 'Внедорожники и кроссоверы до 5м'),
('Внедорожники', 'Крупные внедорожники и SUV'),
('Минивэны', 'Минивэны и микроавтобусы'),
('Коммерческие', 'Грузовики малой грузоподъемности');

INSERT INTO Employee (first_name, last_name, position, phone, email, hire_date, salary_percent) VALUES
('Иван', 'Петров', 'Мастер', '+7-912-111-2233', 'ivan.petrov@carwash.ru', '2023-01-15', 30.00),
('Анна', 'Сидорова', 'Мастер', '+7-912-222-3344', 'anna.sidorova@carwash.ru', '2023-02-20', 28.50),
('Сергей', 'Козлов', 'Мастер', '+7-912-333-4455', 'sergey.kozlov@carwash.ru', '2023-03-10', 32.00),
('Елена', 'Смирнова', 'Администратор', '+7-912-444-5566', 'elena.smirnova@carwash.ru', '2023-01-10', 0.00),
('Алексей', 'Волков', 'Менеджер', '+7-912-555-6677', 'alexey.volkov@carwash.ru', '2023-04-01', 0.00);

INSERT INTO Employee (first_name, last_name, position, phone, email, hire_date, dismissal_date, is_active, salary_percent) VALUES
('Дмитрий', 'Николаев', 'Мастер', '+7-912-666-7788', 'dmitry.nikolaev@carwash.ru', '2022-08-01', '2023-12-15', 0, 27.00);

INSERT INTO WorkBox (number, name, description, max_car_category_id) VALUES
(1, 'Бокс 1', 'Основной бокс для легковых авто', 2),
(2, 'Бокс 2', 'Бокс для кроссоверов и внедорожников', 4),
(3, 'Бокс 3', 'Универсальный бокс', 5),
(4, 'Бокс 4', 'Бокс для коммерческого транспорта', 6),
(5, 'Бокс 5', 'Экспресс-бокс', 2);

INSERT INTO Service (name, description, base_duration_minutes, base_price) VALUES
('Экспресс-мойка', 'Быстрая мойка кузова', 15, 500.00),
('Стандартная мойка', 'Мойка кузова с сушкой', 25, 800.00),
('Комплексная мойка', 'Полная мойка кузова, стекол, колес', 45, 1500.00),
('Детейлинг-мойка', 'Глубокая чистка с консервацией', 90, 3500.00),
('Химчистка салона', 'Полная чистка салона', 120, 5000.00),
('Полировка кузова', 'Восстановительная полировка', 180, 8000.00),
('Нанесение защитного покрытия', 'Керамическое или восковое покрытие', 240, 12000.00);

INSERT INTO ServicePrice (service_id, car_category_id, price, duration_minutes) VALUES
(1, 1, 500.00, 15), (1, 2, 550.00, 15), (1, 3, 700.00, 20), (1, 4, 800.00, 20), (1, 5, 600.00, 20), (1, 6, 900.00, 25),
(2, 1, 800.00, 25), (2, 2, 900.00, 25), (2, 3, 1100.00, 30), (2, 4, 1300.00, 30), (2, 5, 1000.00, 30), (2, 6, 1500.00, 35),
(3, 1, 1500.00, 45), (3, 2, 1700.00, 45), (3, 3, 2000.00, 50), (3, 4, 2300.00, 55), (3, 5, 1800.00, 50), (3, 6, 2500.00, 60);

INSERT INTO EmployeeSpecialization (employee_id, service_id, proficiency_level) VALUES
(1, 1, 'эксперт'), (1, 2, 'эксперт'), (1, 3, 'опытный'), (1, 5, 'базовый'),
(2, 1, 'опытный'), (2, 2, 'эксперт'), (2, 3, 'опытный'), (2, 4, 'базовый'),
(3, 3, 'эксперт'), (3, 4, 'эксперт'), (3, 5, 'опытный'), (3, 6, 'базовый'),
(6, 1, 'опытный'), (6, 2, 'опытный');

INSERT INTO Appointment (client_name, client_phone, client_email, car_model, car_license_plate, car_category_id, appointment_date, start_time, end_time, total_price, status, created_by_employee_id) VALUES
('Андрей Соколов', '+7-911-123-4567', 'andrey@sokolov.ru', 'Toyota Camry', 'А123ВС777', 2, '2024-01-20', '10:00', '11:00', 2300.00, 'подтвержден', 4),
('Елена Воробьева', '+7-911-234-5678', 'elena@vorobeva.ru', 'Honda CR-V', 'В234СТ777', 3, '2024-01-20', '11:30', '12:45', 3100.00, 'запланирован', 4),
('Павел Орлов', '+7-911-345-6789', 'pavel@orlov.ru', 'Lada Vesta', 'С345МН777', 1, '2024-01-20', '14:00', '15:30', 1500.00, 'запланирован', 4),
('Ольга Лебедева', '+7-911-456-7890', 'olga@lebedeva.ru', 'BMW X5', 'Е456ОР777', 4, '2024-01-21', '09:00', '12:00', 12000.00, 'подтвержден', 5);

INSERT INTO AppointmentService (appointment_id, service_id, employee_id, box_id, scheduled_price, scheduled_duration, sequence_number) VALUES
(1, 2, 1, 1, 900.00, 25, 1),
(1, 3, 1, 1, 1400.00, 45, 2),
(2, 3, 2, 2, 2000.00, 50, 1),
(3, 1, 3, 1, 500.00, 15, 1),
(4, 3, 1, 3, 2300.00, 55, 1),
(4, 5, 3, 3, 6000.00, 120, 2),
(4, 6, 3, 3, 3700.00, 180, 3);

INSERT INTO WorkRecord (appointment_service_id, employee_id, box_id, actual_start_time, actual_end_time, actual_price, status, quality_rating, notes) VALUES
(1, 1, 1, '2024-01-19 10:05:00', '2024-01-19 10:25:00', 900.00, 'выполнено', 5, 'Клиент доволен'),
(2, 1, 1, '2024-01-19 10:30:00', '2024-01-19 11:10:00', 1400.00, 'выполнено', 4, 'Небольшая задержка из-за сложных загрязнений'),
(3, 2, 2, '2024-01-19 11:35:00', '2024-01-19 12:20:00', 2000.00, 'выполнено', 5, 'Отличная работа'),
(4, 3, 1, '2024-01-19 14:05:00', '2024-01-19 14:25:00', 500.00, 'выполнено', 5, 'Быстро и качественно');

INSERT INTO SalaryCalculation (employee_id, period_start, period_end, total_revenue, applicable_percent, calculated_amount, bonus, status, payment_date) VALUES
(1, '2024-01-01', '2024-01-15', 18500.00, 30.00, 5550.00, 500.00, 'выплачено', '2024-01-20'),
(2, '2024-01-01', '2024-01-15', 12400.00, 28.50, 3534.00, 300.00, 'выплачено', '2024-01-20'),
(3, '2024-01-01', '2024-01-15', 8900.00, 32.00, 2848.00, 200.00, 'выплачено', '2024-01-20'),
(6, '2024-01-01', '2024-01-15', 7600.00, 27.00, 2052.00, 0.00, 'рассчитано', NULL);

COMMIT;

CREATE VIEW BoxLoadReport AS
SELECT 
    wb.number as box_number,
    wb.name as box_name,
    COUNT(DISTINCT a.id) as total_appointments,
    COUNT(DISTINCT wr.id) as completed_works,
    SUM(CASE WHEN wr.id IS NOT NULL THEN wr.actual_price ELSE 0 END) as total_revenue,
    ROUND(AVG(CASE WHEN wr.id IS NOT NULL THEN wr.actual_duration ELSE NULL END), 1) as avg_duration_minutes,
    ROUND(CAST(COUNT(DISTINCT wr.id) * 100.0 / 
          (SELECT COUNT(*) FROM WorkRecord WHERE DATE(actual_start_time) = DATE('now', '-7 days')) 
          AS DECIMAL(5,2)), 1) as load_percentage
FROM WorkBox wb
LEFT JOIN AppointmentService aps ON wb.id = aps.box_id
LEFT JOIN Appointment a ON aps.appointment_id = a.id
LEFT JOIN WorkRecord wr ON aps.id = wr.appointment_service_id
    AND DATE(wr.actual_start_time) >= DATE('now', '-30 days')
GROUP BY wb.id, wb.number, wb.name
ORDER BY total_revenue DESC;

CREATE VIEW ServicePopularityReport AS
SELECT 
    s.name as service_name,
    cc.name as car_category,
    COUNT(wr.id) as times_performed,
    SUM(wr.actual_price) as total_revenue,
    ROUND(AVG(wr.actual_duration), 1) as avg_actual_duration,
    ROUND(AVG(wr.quality_rating), 1) as avg_quality_rating,
    ROUND(CAST(COUNT(wr.id) * 100.0 / 
          (SELECT COUNT(*) FROM WorkRecord WHERE DATE(actual_start_time) >= DATE('now', '-30 days')) 
          AS DECIMAL(5,2)), 1) as popularity_percentage
FROM Service s
JOIN ServicePrice sp ON s.id = sp.service_id
JOIN CarCategory cc ON sp.car_category_id = cc.id
LEFT JOIN AppointmentService aps ON s.id = aps.service_id
LEFT JOIN WorkRecord wr ON aps.id = wr.appointment_service_id
    AND DATE(wr.actual_start_time) >= DATE('now', '-30 days')
GROUP BY s.id, s.name, cc.id, cc.name
ORDER BY total_revenue DESC;

CREATE VIEW EmployeeRevenueReport AS
SELECT 
    e.id,
    e.first_name || ' ' || e.last_name as employee_name,
    e.position,
    e.salary_percent,
    e.is_active,
    COUNT(DISTINCT wr.id) as completed_works,
    SUM(wr.actual_price) as total_revenue,
    ROUND(SUM(wr.actual_price) * e.salary_percent / 100, 2) as estimated_salary,
    ROUND(AVG(wr.quality_rating), 1) as avg_quality_rating,
    MIN(wr.actual_start_time) as first_work_date,
    MAX(wr.actual_start_time) as last_work_date
FROM Employee e
LEFT JOIN WorkRecord wr ON e.id = wr.employee_id
    AND DATE(wr.actual_start_time) >= DATE('now', '-90 days')
GROUP BY e.id, e.first_name, e.last_name, e.position, e.salary_percent, e.is_active
ORDER BY total_revenue DESC NULLS LAST;

CREATE VIEW DailyAppointmentsReport AS
SELECT 
    a.appointment_date,
    COUNT(a.id) as total_appointments,
    SUM(CASE WHEN a.status = 'выполнен' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN a.status = 'отменен' THEN 1 ELSE 0 END) as cancelled,
    SUM(CASE WHEN a.status = 'неявка' THEN 1 ELSE 0 END) as no_show,
    SUM(a.total_price) as scheduled_revenue,
    SUM(CASE WHEN a.status = 'выполнен' THEN a.total_price ELSE 0 END) as actual_revenue,
    ROUND(CAST(SUM(CASE WHEN a.status = 'выполнен' THEN a.total_price ELSE 0 END) * 100.0 / 
          NULLIF(SUM(a.total_price), 0) AS DECIMAL(5,2)), 1) as conversion_rate
FROM Appointment a
WHERE a.appointment_date >= DATE('now', '-30 days')
GROUP BY a.appointment_date
ORDER BY a.appointment_date DESC;

CREATE VIEW ClientReport AS
SELECT 
    a.client_phone,
    a.client_name,
    COUNT(DISTINCT a.id) as total_visits,
    SUM(a.total_price) as total_spent,
    ROUND(AVG(a.total_price), 2) as avg_check,
    MIN(a.appointment_date) as first_visit,
    MAX(a.appointment_date) as last_visit,
    GROUP_CONCAT(DISTINCT a.car_model) as cars_serviced
FROM Appointment a
WHERE a.status IN ('выполнен', 'подтвержден')
GROUP BY a.client_phone, a.client_name
HAVING COUNT(DISTINCT a.id) >= 1
ORDER BY total_spent DESC;

CREATE TRIGGER UpdateAppointmentTotal
AFTER INSERT ON AppointmentService
BEGIN
    UPDATE Appointment 
    SET total_price = (
        SELECT COALESCE(SUM(scheduled_price), 0)
        FROM AppointmentService 
        WHERE appointment_id = NEW.appointment_id
    )
    WHERE id = NEW.appointment_id;
END;

CREATE TRIGGER UpdateAppointmentEndTime
AFTER INSERT ON AppointmentService
BEGIN
    UPDATE Appointment 
    SET end_time = TIME(
        start_time, 
        '+' || (
            SELECT SUM(scheduled_duration) + (COUNT(*) - 1) * 5
            FROM AppointmentService 
            WHERE appointment_id = NEW.appointment_id
        ) || ' minutes'
    )
    WHERE id = NEW.appointment_id;
END;

CREATE TRIGGER CheckBoxAvailability
BEFORE INSERT ON AppointmentService
WHEN EXISTS (
    SELECT 1 FROM Appointment a
    JOIN AppointmentService aps ON a.id = aps.appointment_id
    WHERE aps.box_id = NEW.box_id
    AND a.appointment_date = (SELECT appointment_date FROM Appointment WHERE id = NEW.appointment_id)
    AND (
        (NEW.sequence_number = 1 AND a.start_time < (SELECT end_time FROM Appointment WHERE id = NEW.appointment_id)
         AND a.end_time > (SELECT start_time FROM Appointment WHERE id = NEW.appointment_id))
        OR
        (aps.sequence_number = NEW.sequence_number AND aps.appointment_id = NEW.appointment_id)
    )
    AND a.status NOT IN ('отменен', 'неявка')
)
BEGIN
    SELECT RAISE(ABORT, 'Бокс уже занят в это время');
END;

CREATE TRIGGER CreateWorkRecordOnCompletion
AFTER UPDATE OF status ON Appointment
WHEN NEW.status = 'выполнен' AND OLD.status != 'выполнен'
BEGIN
    INSERT INTO WorkRecord (appointment_service_id, employee_id, box_id, actual_start_time, actual_end_time, actual_price, status, recorded_by_employee_id)
    SELECT 
        aps.id,
        aps.employee_id,
        aps.box_id,
        DATETIME(NEW.appointment_date || ' ' || NEW.start_time),
        DATETIME(NEW.appointment_date || ' ' || NEW.end_time),
        aps.scheduled_price,
        'выполнено',
        NEW.created_by_employee_id
    FROM AppointmentService aps
    WHERE aps.appointment_id = NEW.id;
END;

CREATE TRIGGER MarkNoShowAppointments
AFTER INSERT ON WorkRecord
BEGIN
    UPDATE Appointment 
    SET status = 'неявка'
    WHERE status IN ('запланирован', 'подтвержден')
    AND appointment_date < DATE('now')
    AND (appointment_date || ' ' || end_time) < DATETIME('now', '-1 hour');
END;

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;