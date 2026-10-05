package com.example.construction.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Read-only endpoints that expose the JOIN, subquery and function from the database. */
@RestController
@RequestMapping("/reports")
@CrossOrigin(origins = "*")
public class ReportController {
    private final JdbcTemplate jdbc;

    public ReportController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** JOIN: assignments with project, worker and task details. */
    @GetMapping("/assignment-details")
    public List<Map<String, Object>> assignmentDetails() {
        return jdbc.queryForList("""
            SELECT a.assignment_id AS assignmentId, a.project_id AS projectId, a.worker_id AS workerId,
                   a.task_id AS taskId, p.project_name AS projectName, p.location AS location,
                   w.worker_name AS workerName, w.role AS role, w.phone AS phone,
                   t.task_name AS taskName, t.status AS taskStatus, a.assigned_date AS assignedDate
            FROM assignments a
            JOIN projects p ON a.project_id = p.project_id
            JOIN workers  w ON a.worker_id  = w.worker_id
            JOIN tasks    t ON a.task_id    = t.task_id
            ORDER BY a.assignment_id
            """);
    }

    /** SUBQUERY: projects having more tasks than the average. */
    @GetMapping("/busy-projects")
    public List<Map<String, Object>> busyProjects() {
        return jdbc.queryForList("""
            SELECT p.project_id AS projectId, p.project_name AS projectName, p.status AS status,
                   COUNT(t.task_id) AS totalTasks,
                   count_completed_tasks(p.project_id) AS completedTasks,
                   (SELECT AVG(c.cnt) FROM (SELECT COUNT(*) AS cnt FROM tasks GROUP BY project_id) c) AS averageTasks
            FROM projects p
            JOIN tasks t ON p.project_id = t.project_id
            GROUP BY p.project_id, p.project_name, p.status
            HAVING COUNT(t.task_id) > (
                SELECT AVG(x.cnt) FROM (SELECT COUNT(*) AS cnt FROM tasks GROUP BY project_id) x)
            ORDER BY totalTasks DESC
            """);
    }

    /** FUNCTION: total and completed task counts for every project. */
    @GetMapping("/projects-summary")
    public List<Map<String, Object>> projectsSummary() {
        return jdbc.queryForList("""
            SELECT p.project_id AS projectId, p.project_name AS projectName, p.status AS status,
                   COUNT(t.task_id) AS totalTasks,
                   count_completed_tasks(p.project_id) AS completedTasks
            FROM projects p
            LEFT JOIN tasks t ON t.project_id = p.project_id
            GROUP BY p.project_id, p.project_name, p.status
            ORDER BY p.project_id
            """);
    }

    @GetMapping("/completed-tasks/{projectId}")
    public Map<String, Object> completedTasks(@PathVariable Long projectId) {
        Integer n = jdbc.queryForObject("SELECT count_completed_tasks(?)", Integer.class, projectId);
        return Map.of("projectId", projectId, "completedTasks", n == null ? 0 : n);
    }
}
