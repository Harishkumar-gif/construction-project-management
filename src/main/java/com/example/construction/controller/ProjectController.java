package com.example.construction.controller;

import com.example.construction.entity.Project;
import com.example.construction.repository.ProjectRepository;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/projects")
@CrossOrigin(origins = "*")
public class ProjectController {
    private final ProjectRepository repository;

    public ProjectController(ProjectRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Project> getAll() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public Project getOne(@PathVariable Long id) {
        return repository.findById(id).orElseThrow();
    }

    @PostMapping
    public Project create(@RequestBody Project project) {
        return repository.save(project);
    }

    @PutMapping("/{id}")
    public Project update(@PathVariable Long id, @RequestBody Project project) {
        project.setProjectId(id);
        return repository.save(project);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repository.deleteById(id);
    }
}
