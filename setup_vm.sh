#!/bin/bash

echo "1. Atualizando a lista de pacotes..."
sudo apt update -y

echo "2. Instalando pré-requisitos..."
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "3. Configurando repositório oficial do Docker..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "4. Instalando Docker e Docker Compose..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "5. Adicionando o usuário ao grupo do Docker..."
sudo usermod -aG docker $USER

echo "6. Criando a estrutura do projeto..."
mkdir -p ~/meu-projeto/src/main/java/com/exemplo/demo
mkdir -p ~/meu-projeto/src/main/resources/static
cd ~/meu-projeto

cat << 'EOF' > docker-compose.yml
services:
  banco-de-dados:
    image: mysql:8.0
    container_name: mysql_db
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: db_ficticio
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  aplicacao-backend:
    build: .
    container_name: spring_app
    ports:
      - "8080:8080"
    depends_on:
      - banco-de-dados
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://banco-de-dados:3306/db_ficticio?useSSL=false&allowPublicKeyRetrieval=true&connectTimeout=60000&socketTimeout=300000
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: root
      SPRING_JPA_HIBERNATE_DDL_AUTO: update

volumes:
  mysql_data:
EOF

cat << 'EOF' > Dockerfile
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

cat << 'EOF' > pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.4</version>
    </parent>
    <groupId>com.exemplo</groupId>
    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
        <dependency><groupId>com.mysql</groupId><artifactId>mysql-connector-j</artifactId><scope>runtime</scope></dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin>
        </plugins>
    </build>
</project>
EOF

cat << 'EOF' > src/main/java/com/exemplo/demo/DemoApplication.java
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
EOF

cat << 'EOF' > src/main/resources/static/index.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Materiais Escolares</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: Arial, sans-serif; background: #f0f2f5; color: #333; }
    header { background: #4a148c; color: white; padding: 20px 40px; }
    header h1 { font-size: 24px; }
    header p { font-size: 13px; opacity: 0.8; margin-top: 4px; }
    .container { max-width: 960px; margin: 30px auto; padding: 0 20px; }
    .card { background: white; border-radius: 8px; padding: 24px; margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    .card h2 { font-size: 16px; margin-bottom: 16px; color: #4a148c; border-bottom: 2px solid #ede7f6; padding-bottom: 8px; }
    .form-row { display: flex; gap: 12px; flex-wrap: wrap; }
    .form-group { flex: 1; min-width: 160px; }
    label { display: block; font-size: 13px; font-weight: bold; margin-bottom: 6px; color: #555; }
    input, select { width: 100%; padding: 10px 12px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; }
    input:focus, select:focus { outline: none; border-color: #4a148c; }
    .btn-row { margin-top: 16px; display: flex; gap: 10px; }
    button { padding: 10px 20px; border: none; border-radius: 6px; font-size: 14px; cursor: pointer; font-weight: bold; }
    .btn-primary { background: #4a148c; color: white; }
    .btn-primary:hover { background: #6a1b9a; }
    .btn-secondary { background: #ede7f6; color: #4a148c; }
    .btn-secondary:hover { background: #d1c4e9; }
    table { width: 100%; border-collapse: collapse; font-size: 14px; }
    th { background: #ede7f6; color: #4a148c; padding: 12px; text-align: left; font-size: 13px; }
    td { padding: 12px; border-bottom: 1px solid #f0f0f0; }
    tr:hover td { background: #fafafa; }
    .btn-edit { background: #fff3e0; color: #e65100; padding: 6px 12px; font-size: 12px; border-radius: 4px; border: none; cursor: pointer; font-weight: bold; }
    .btn-delete { background: #fce4ec; color: #c62828; padding: 6px 12px; font-size: 12px; border-radius: 4px; border: none; cursor: pointer; font-weight: bold; margin-left: 6px; }
    .btn-edit:hover { background: #ffe0b2; }
    .btn-delete:hover { background: #f8bbd0; }
    .msg { padding: 10px 16px; border-radius: 6px; font-size: 13px; margin-bottom: 16px; display: none; }
    .msg.success { background: #e8f5e9; color: #2e7d32; display: block; }
    .msg.error { background: #fce4ec; color: #c62828; display: block; }
    .empty { text-align: center; color: #999; padding: 30px; font-size: 14px; }
    #edit-banner { background: #fff8e1; border: 1px solid #ffe082; border-radius: 6px; padding: 10px 16px; font-size: 13px; color: #f57f17; margin-bottom: 12px; display: none; }
    .preco { color: #4a148c; font-weight: bold; }
    .badge { display: inline-block; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; background: #ede7f6; color: #4a148c; }
    .qtd-baixa { color: #c62828; font-weight: bold; }
  </style>
</head>
<body>
  <header>
    <h1>✏️ Gestão de Materiais Escolares</h1>
    <p>CRUD completo — Spring Boot + MySQL</p>
  </header>
  <div class="container">
    <div class="card">
      <h2 id="form-title">➕ Novo Material</h2>
      <div id="edit-banner">✏️ Editando material ID <span id="edit-id-label"></span> — <a href="#" onclick="cancelarEdicao()">Cancelar</a></div>
      <div id="msg" class="msg"></div>
      <input type="hidden" id="edit-id">
      <div class="form-row">
        <div class="form-group">
          <label>Nome</label>
          <input type="text" id="nome" placeholder="Ex: Caderno 10 matérias">
        </div>
        <div class="form-group">
          <label>Categoria</label>
          <select id="categoria">
            <option value="">Selecione...</option>
            <option>Caderno</option>
            <option>Caneta</option>
            <option>Lápis</option>
            <option>Borracha</option>
            <option>Régua</option>
            <option>Mochila</option>
            <option>Estojo</option>
            <option>Tesoura</option>
            <option>Cola</option>
            <option>Outro</option>
          </select>
        </div>
        <div class="form-group">
          <label>Quantidade</label>
          <input type="number" id="quantidade" placeholder="Ex: 100" min="0">
        </div>
        <div class="form-group">
          <label>Preço (R$)</label>
          <input type="number" id="preco" placeholder="Ex: 12.90" step="0.01" min="0">
        </div>
      </div>
      <div class="btn-row">
        <button class="btn-primary" onclick="salvar()">💾 Salvar</button>
        <button class="btn-secondary" onclick="limpar()">🔄 Limpar</button>
      </div>
    </div>
    <div class="card">
      <h2>📋 Materiais Cadastrados</h2>
      <table>
        <thead>
          <tr><th>ID</th><th>Nome</th><th>Categoria</th><th>Quantidade</th><th>Preço</th><th>Ações</th></tr>
        </thead>
        <tbody id="tabela"></tbody>
      </table>
      <div id="empty" class="empty" style="display:none">Nenhum material cadastrado ainda.</div>
    </div>
  </div>
  <script>
    const API = '/materiais';
    async function carregar() {
      const res = await fetch(API);
      const materiais = await res.json();
      const tbody = document.getElementById('tabela');
      const empty = document.getElementById('empty');
      tbody.innerHTML = '';
      if (materiais.length === 0) { empty.style.display = 'block'; return; }
      empty.style.display = 'none';
      materiais.forEach(m => {
        const qtdClass = m.quantidade <= 5 ? 'qtd-baixa' : '';
        tbody.innerHTML += `<tr>
          <td>${m.id}</td>
          <td>${m.nome}</td>
          <td><span class="badge">${m.categoria}</span></td>
          <td class="${qtdClass}">${m.quantidade}</td>
          <td class="preco">R$ ${m.preco.toFixed(2)}</td>
          <td>
            <button class="btn-edit" onclick="editar(${m.id},'${m.nome}','${m.categoria}',${m.quantidade},${m.preco})">✏️ Editar</button>
            <button class="btn-delete" onclick="deletar(${m.id})">🗑️ Excluir</button>
          </td></tr>`;
      });
    }
    async function salvar() {
      const id = document.getElementById('edit-id').value;
      const body = {
        nome: document.getElementById('nome').value.trim(),
        categoria: document.getElementById('categoria').value,
        quantidade: parseInt(document.getElementById('quantidade').value),
        preco: parseFloat(document.getElementById('preco').value)
      };
      if (!body.nome || !body.categoria || isNaN(body.quantidade) || isNaN(body.preco)) {
        mostrarMsg('Preencha todos os campos corretamente.', 'error'); return;
      }
      const url = id ? `${API}/${id}` : API;
      const method = id ? 'PUT' : 'POST';
      const res = await fetch(url, { method, headers: {'Content-Type':'application/json'}, body: JSON.stringify(body) });
      if (res.ok) { mostrarMsg(id ? 'Material atualizado!' : 'Material cadastrado!', 'success'); limpar(); carregar(); }
      else { mostrarMsg('Erro ao salvar.', 'error'); }
    }
    async function deletar(id) {
      if (!confirm('Excluir este material?')) return;
      const res = await fetch(`${API}/${id}`, { method: 'DELETE' });
      if (res.ok) { mostrarMsg('Material excluído.', 'success'); carregar(); }
    }
    function editar(id, nome, categoria, quantidade, preco) {
      document.getElementById('edit-id').value = id;
      document.getElementById('nome').value = nome;
      document.getElementById('categoria').value = categoria;
      document.getElementById('quantidade').value = quantidade;
      document.getElementById('preco').value = preco;
      document.getElementById('form-title').textContent = '✏️ Editar Material';
      document.getElementById('edit-id-label').textContent = id;
      document.getElementById('edit-banner').style.display = 'block';
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    function cancelarEdicao() { limpar(); return false; }
    function limpar() {
      document.getElementById('edit-id').value = '';
      document.getElementById('nome').value = '';
      document.getElementById('categoria').value = '';
      document.getElementById('quantidade').value = '';
      document.getElementById('preco').value = '';
      document.getElementById('form-title').textContent = '➕ Novo Material';
      document.getElementById('edit-banner').style.display = 'none';
    }
    function mostrarMsg(texto, tipo) {
      const el = document.getElementById('msg');
      el.textContent = texto;
      el.className = `msg ${tipo}`;
      setTimeout(() => el.className = 'msg', 3000);
    }
    carregar();
  </script>
</body>
</html>
EOF

echo "7. Subindo MySQL e aguardando inicialização..."
sudo docker compose up -d banco-de-dados
echo "Aguardando 45 segundos para o MySQL inicializar..."
sleep 45

echo "8. Subindo a aplicação Spring Boot..."
sudo docker compose up -d --build aplicacao-backend

echo "================================================================="
echo "Concluído!"
echo "Acompanhe com: sudo docker logs spring_app --follow"
echo "Acesse: http://$(curl -s ifconfig.me):8080"
echo "================================================================="
