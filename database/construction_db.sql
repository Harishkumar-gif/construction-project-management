DROP DATABASE IF EXISTS construction_db;
CREATE DATABASE construction_db;
USE construction_db;

-- ============ TABLES ============
CREATE TABLE projects (
    project_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    location     VARCHAR(150),
    start_date   DATE,
    end_date     DATE,
    status       VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT chk_project_status CHECK (status IN ('PLANNED','IN_PROGRESS','COMPLETED','ON_HOLD')),
    CONSTRAINT chk_project_dates  CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE workers (
    worker_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(100) NOT NULL,
    role        VARCHAR(100),
    phone       VARCHAR(20)
);

CREATE TABLE tasks (
    task_id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT NOT NULL,
    task_name  VARCHAR(150) NOT NULL,
    status     VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT chk_task_status CHECK (status IN ('PENDING','IN_PROGRESS','COMPLETED')),
    FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE CASCADE
);

CREATE TABLE assignments (
    assignment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id    BIGINT NOT NULL,
    worker_id     BIGINT NOT NULL,
    task_id       BIGINT NOT NULL,
    assigned_date DATE,
    UNIQUE (worker_id, task_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE CASCADE,
    FOREIGN KEY (worker_id)  REFERENCES workers(worker_id)   ON DELETE CASCADE,
    FOREIGN KEY (task_id)    REFERENCES tasks(task_id)       ON DELETE CASCADE
);

-- ============ SAMPLE DATA ============
INSERT INTO projects (project_name, location, start_date, end_date, status) VALUES
('Chennai Mall', 'Chennai', '2026-01-10', '2027-06-30', 'IN_PROGRESS'),
('IT Park Building', 'Bangalore', '2026-02-15', '2027-02-28', 'IN_PROGRESS'),
('Hospital Construction', 'Coimbatore', '2026-03-01', '2027-08-31', 'IN_PROGRESS'),
('Apartment Project', 'Chennai', '2026-04-10', '2027-04-30', 'PLANNED');

INSERT INTO workers (worker_name, role, phone) VALUES
('Ravi Kumar', 'Civil Engineer', '9876543210'),
('Arun Kumar', 'Electrician', '9876543211'),
('Suresh', 'Plumber', '9876543212'),
('Karthik', 'Mason', '9876543213'),
('Vijay', 'Carpenter', '9876543214'),
('Manoj', 'Site Supervisor', '9876543215');

INSERT INTO tasks (project_id, task_name, status) VALUES
(1, 'Foundation Work', 'COMPLETED'),
(1, 'Concrete Work', 'COMPLETED'),
(1, 'Electrical Work', 'IN_PROGRESS'),
(1, 'Painting Work', 'PENDING'),
(2, 'Building Foundation', 'COMPLETED'),
(2, 'Structural Work', 'IN_PROGRESS'),
(2, 'Electrical Installation', 'PENDING'),
(3, 'Ground Work', 'COMPLETED'),
(3, 'Plumbing Work', 'IN_PROGRESS'),
(3, 'Roof Construction', 'PENDING'),
(3, 'Painting Work', 'PENDING'),
(4, 'Site Preparation', 'PENDING'),
(4, 'Foundation Work', 'PENDING');

INSERT INTO assignments (project_id, worker_id, task_id, assigned_date) VALUES
(1,1,1,'2026-01-12'),(1,4,2,'2026-01-20'),(1,2,3,'2026-02-10'),(1,5,4,'2026-03-01'),
(2,1,5,'2026-02-20'),(2,4,6,'2026-03-01'),(2,2,7,'2026-03-15'),
(3,4,8,'2026-03-10'),(3,3,9,'2026-04-01'),(3,1,10,'2026-05-01'),(3,5,11,'2026-06-01'),
(4,6,12,'2026-04-15'),(4,4,13,'2026-05-01');

-- ============ REQUIREMENT 1: JOIN ============
-- Assignments with project, worker and task details
SELECT a.assignment_id, p.project_name, p.location,
       w.worker_name, w.role, w.phone, t.task_name,
       t.status AS task_status, a.assigned_date
FROM assignments a
JOIN projects p ON a.project_id = p.project_id
JOIN workers  w ON a.worker_id  = w.worker_id
JOIN tasks    t ON a.task_id    = t.task_id;

-- ============ REQUIREMENT 2: SUBQUERY ============
-- Projects having more tasks than the average
SELECT p.project_id, p.project_name, COUNT(t.task_id) AS total_tasks
FROM projects p
JOIN tasks t ON p.project_id = t.project_id
GROUP BY p.project_id, p.project_name
HAVING COUNT(t.task_id) > (
    SELECT AVG(task_count)
    FROM (SELECT COUNT(*) AS task_count FROM tasks GROUP BY project_id) x
);

DELIMITER //

-- ============ REQUIREMENT 4: FUNCTION ============
CREATE FUNCTION count_completed_tasks(p_project_id BIGINT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE completed_count INT;
    SELECT COUNT(*) INTO completed_count
    FROM tasks
    WHERE project_id = p_project_id AND status = 'COMPLETED';
    RETURN completed_count;
END //

-- ============ REQUIREMENT 3: PROCEDURE ============
CREATE PROCEDURE assign_worker(
    IN p_project_id BIGINT,
    IN p_worker_id  BIGINT,
    IN p_task_id    BIGINT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE task_id = p_task_id AND project_id = p_project_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'That task does not belong to the selected project.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM workers WHERE worker_id = p_worker_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'That worker does not exist.';
    END IF;
    IF EXISTS (SELECT 1 FROM assignments WHERE worker_id = p_worker_id AND task_id = p_task_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This worker is already assigned to that task.';
    END IF;
    INSERT INTO assignments(project_id, worker_id, task_id, assigned_date)
    VALUES (p_project_id, p_worker_id, p_task_id, CURDATE());
END //

-- ============ REQUIREMENT 5: TRIGGERS (task + project status) ============
-- Recalculates a project's status from its tasks
CREATE PROCEDURE refresh_project_status(IN p_project_id BIGINT)
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_started INT DEFAULT 0;

    SELECT COUNT(*), COALESCE(SUM(status = 'COMPLETED'), 0), COALESCE(SUM(status <> 'PENDING'), 0)
      INTO v_total, v_done, v_started
      FROM tasks WHERE project_id = p_project_id;

    IF v_total > 0 THEN
        UPDATE projects
           SET status = CASE WHEN v_done = v_total THEN 'COMPLETED'
                             WHEN v_started > 0     THEN 'IN_PROGRESS'
                             ELSE 'PLANNED' END
         WHERE project_id = p_project_id AND status <> 'ON_HOLD';
    END IF;
END //

-- task changed -> update project status
CREATE TRIGGER update_project_status
AFTER UPDATE ON tasks
FOR EACH ROW
BEGIN
    CALL refresh_project_status(NEW.project_id);
    IF OLD.project_id <> NEW.project_id THEN
        CALL refresh_project_status(OLD.project_id);
    END IF;
END //

-- task added -> update project status
CREATE TRIGGER tasks_after_insert
AFTER INSERT ON tasks
FOR EACH ROW
BEGIN
    CALL refresh_project_status(NEW.project_id);
END //

-- task removed -> update project status
CREATE TRIGGER tasks_after_delete
AFTER DELETE ON tasks
FOR EACH ROW
BEGIN
    CALL refresh_project_status(OLD.project_id);
END //

-- worker assigned -> a pending task becomes in progress (which then updates the project)
CREATE TRIGGER assignment_starts_task
AFTER INSERT ON assignments
FOR EACH ROW
BEGIN
    UPDATE tasks SET status = 'IN_PROGRESS'
     WHERE task_id = NEW.task_id AND status = 'PENDING';
END //

DELIMITER ;

-- Try the function:
SELECT project_name, count_completed_tasks(project_id) AS completed_tasks FROM projects;
