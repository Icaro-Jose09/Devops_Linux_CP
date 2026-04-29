package com.exemplo.demo;

import jakarta.persistence.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}

@RestController
@RequestMapping("/materiais")
@CrossOrigin(origins = "*")
class MaterialController {

    @Autowired
    private MaterialRepository repository;

    @GetMapping
    public List<Material> listar() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Material> buscar(@PathVariable Long id) {
        return repository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Material criar(@RequestBody Material material) {
        return repository.save(material);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Material> atualizar(@PathVariable Long id, @RequestBody Material dados) {
        return repository.findById(id).map(material -> {
            material.nome = dados.nome;
            material.categoria = dados.categoria;
            material.quantidade = dados.quantidade;
            material.preco = dados.preco;
            return ResponseEntity.ok(repository.save(material));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        if (!repository.existsById(id)) return ResponseEntity.notFound().build();
        repository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

@Entity
class Material {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;
    public String nome;
    public String categoria;
    public Integer quantidade;
    public Double preco;

    public Material() {}
    public Material(String nome, String categoria, Integer quantidade, Double preco) {
        this.nome = nome;
        this.categoria = categoria;
        this.quantidade = quantidade;
        this.preco = preco;
    }
}

interface MaterialRepository extends JpaRepository<Material, Long> {}
