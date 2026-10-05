# Construction Project Management System

Spring Boot 3 + Spring Data JPA + MySQL REST API with a single-page frontend.

## Setup
1. In MySQL Workbench, run the whole of `database/construction_db.sql` (it drops and recreates `construction_db`).
2. Open this folder in IntelliJ IDEA and reload Maven.
3. In `src/main/resources/application.properties` set `spring.datasource.password` to your MySQL password.
4. Run `ConstructionApplication`.
5. Open http://localhost:8080 (the UI is served from `src/main/resources/static/index.html`).

## Requirements and where they live
| Requirement | Database | REST endpoint | UI |
|---|---|---|---|
| JOIN: assignments with project and worker details | query in SQL script | `GET /reports/assignment-details` | Assignments page |
| Subquery: projects with more tasks than average | query in SQL script | `GET /reports/busy-projects` | Reports page |
| Procedure: assign worker | `assign_worker` | `POST /assignments` | Assign worker form |
| Function: count completed tasks | `count_completed_tasks` | `GET /reports/projects-summary`, `GET /reports/completed-tasks/{id}` | Project cards, Reports page |
| Trigger: update task/project status | `update_project_status`, `tasks_after_insert`, `tasks_after_delete`, `assignment_starts_task` | automatic | Task board, project status |

## CRUD endpoints
`/projects`, `/workers`, `/tasks`: GET, POST, PUT /{id}, DELETE /{id}. `/assignments`: GET, POST, DELETE /{id}.
Deleting a project, worker or task also removes its linked records (ON DELETE CASCADE).
Errors come back as JSON `{ "message": "..." }`.
