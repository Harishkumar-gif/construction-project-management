package com.example.construction.controller;

import com.example.construction.entity.Worker;
import com.example.construction.repository.WorkerRepository;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/workers")
@CrossOrigin(origins = "*")
public class WorkerController {
    private final WorkerRepository repository;

    public WorkerController(WorkerRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Worker> getAll() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public Worker getOne(@PathVariable Long id) {
        return repository.findById(id).orElseThrow();
    }

    @PostMapping
    public Worker create(@RequestBody Worker worker) {
        return repository.save(worker);
    }

    @PutMapping("/{id}")
    public Worker update(@PathVariable Long id, @RequestBody Worker worker) {
        worker.setWorkerId(id);
        return repository.save(worker);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repository.deleteById(id);
    }
}
