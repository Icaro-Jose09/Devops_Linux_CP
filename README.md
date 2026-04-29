CheckPoint - DevOps & Linux
Aluno: Icaro Jose dos Santos

RM: 562403

Turma: 2TDSPW

🚀 Como Rodar o Projeto
No terminal da sua VM Azure, execute os comandos:

Bash
cd ~/checkpoint_material
sudo docker compose up -d
🔗 Endpoints (Acesso Direto)
A aplicação está rodando no IP da Azure:

Listar Materiais: http://20.87.24.39:8080/api/materiais

Status do Banco: Porta 3306 liberada para o MySQL.

🛠️ Comandos de Verificação
Para provar que o banco e a aplicação estão funcionando:

1. Ver containers ativos:

Bash
sudo docker ps
2. Ver dados no banco (CRUD Material Escolar):

Bash
sudo docker exec -it mysql-db mysql -u root -pfiap_password -e "USE escola_db; SELECT * FROM material_escolar;"
