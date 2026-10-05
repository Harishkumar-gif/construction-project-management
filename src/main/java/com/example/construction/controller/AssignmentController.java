package com.example.construction.controller;

import com.example.construction.entity.Assignment;
import com.example.construction.repository.AssignmentRepository;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.sql.CallableStatement;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/assignments")
@CrossOrigin(origins = "*")
public class AssignmentController {
    private final AssignmentRepository repository;
    private final JdbcTemplate jdbc;

    public AssignmentController(AssignmentRepository repository, JdbcTemplate jdbc) {
        this.repository = repository;
        this.jdbc = jdbc;
    }

    @GetMapping
    public List<Assignment> getAll() {
        return repository.findAll();
    }

    /** Assigns a worker by calling the stored procedure assign_worker. */
    @PostMapping
    public Map<String, String> create(@RequestBody Assignment a) {
        if (a.getProjectId() == null || a.getWorkerId() == null || a.getTaskId() == null) {
            throw new IllegalArgumentException("Project, task and worker are all required.");
        }
        jdbc.execute((ConnectionCallback<Void>) con -> {
            try (CallableStatement cs = con.prepareCall("{call assign_worker(?,?,?)}")) {
                cs.setLong(1, a.getProjectId());
                cs.setLong(2, a.getWorkerId());
                cs.setLong(3, a.getTaskId());
                cs.execute();
            }
            return null;
        });
        return Map.of("status", "assigned");
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repository.deleteById(id);
    }
}
