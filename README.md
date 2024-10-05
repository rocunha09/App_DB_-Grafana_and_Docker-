# (App + DB + Grafana) * Docker 
## consumindo dashboards do grafana para monitorar dados de banco dados de aplicações

links de pesquisa:
https://grafana.com/blog/2023/10/10/how-to-embed-grafana-dashboards-into-web-applications/
https://community.grafana.com/t/show-grafana-dashboard-using-iframes/35208/4
https://medium.com/@habbema/grafana-82204ad37366
https://grafana.com/docs/grafana/latest/getting-started/build-first-dashboard/
https://grafana.com/docs/grafana/latest/datasources/mysql/
https://grafana.com/blog/2023/07/07/how-to-visualize-time-series-from-sql-databases-with-grafana/
https://grafana.com/docs/grafana/latest/developers/http_api/
https://stackoverflow.com/questions/68163519/embedding-grafana-dashboard-to-reactjs-app
https://nitin-rachabathuni.medium.com/integrating-grafana-dashboards-into-your-web-application-a-comprehensive-guide-265962732f60

[...]


## scripts usados:
### Criação da estrutura do banco:
```SQL
CREATE TABLE tb_cliente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE tb_quadro_eletrico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    FOREIGN KEY (id_cliente) REFERENCES tb_cliente(id)
);

CREATE TABLE tb_coleta_quadro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_quadro INT,
    r_tensao FLOAT,
    r_corrente FLOAT,
    r_potencia FLOAT,
    s_tensao FLOAT,
    s_corrente FLOAT,
    s_potencia FLOAT,
    t_tensao FLOAT,
    t_corrente FLOAT,
    t_potencia FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_quadro) REFERENCES tb_quadro_eletrico(id)
);

CREATE TABLE tb_quadro_disjuntor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_quadro INT,
    id_disjuntor INT,
    FOREIGN KEY (id_quadro) REFERENCES tb_quadro_eletrico(id)
);

CREATE TABLE tb_coleta_disjuntor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_disjuntor INT,
    status TINYINT(1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_disjuntor) REFERENCES tb_quadro_disjuntor(id)
);

```

### Inserção de dados para teste:

```SQL
INSERT INTO tb_cliente (nome) VALUES ('Teletubes House');

INSERT INTO tb_quadro_eletrico (id_cliente) VALUES (1);

INSERT INTO tb_quadro_disjuntor (id_quadro, id_disjuntor) 
VALUES (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10);

DROP PROCEDURE IF EXISTS insert_fake_coleta_quadro;
DELIMITER $$
CREATE PROCEDURE insert_fake_coleta_quadro()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE fake_time DATETIME DEFAULT NOW(); -- Inicia com o horário atual
    WHILE i < 1440 DO
        INSERT INTO tb_coleta_quadro (
            id_quadro, 
            r_tensao, 
            r_corrente, 
            r_potencia, 
            s_tensao, 
            s_corrente, 
            s_potencia, 
            t_tensao, 
            t_corrente, 
            t_potencia, 
            created_at
        ) VALUES (
            1, 
            RAND()*230, 
            RAND()*10, 
            RAND()*2.3, 
            RAND()*230, 
            RAND()*10, 
            RAND()*2.3, 
            RAND()*230, 
            RAND()*10, 
            RAND()*2.3, 
            fake_time
        );
        SET fake_time = DATE_ADD(fake_time, INTERVAL 1 MINUTE); -- Incrementa o tempo em 1 minuto
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL insert_fake_coleta_quadro();


DROP PROCEDURE IF EXISTS insert_fake_coleta_disjuntor;
DELIMITER $$
CREATE PROCEDURE insert_fake_coleta_disjuntor()
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 1440 DO
        INSERT INTO tb_coleta_disjuntor (id_disjuntor, status)
        SELECT id_disjuntor, FLOOR(RAND()*2) FROM tb_quadro_disjuntor WHERE id_quadro = 1;
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL insert_fake_coleta_disjuntor();


```

### lendo tamanho do banco: 
```SQL
SELECT
    r_tensao, 
    r_corrente, 
    r_potencia, 
    s_tensao, 
    s_corrente, 
    s_potencia, 
    t_tensao, 
    t_corrente, 
    t_potencia, 
    created_at
FROM
    tb_coleta_quadro;

SELECT
    id_disjuntor,
    status,
    created_at AS "time"
FROM
    tb_coleta_disjuntor
WHERE
    id_disjuntor = 1
ORDER BY
    created_at DESC
LIMIT 1;




SELECT 
    CONCAT('SELECT ''', table_name, ''' AS `Table`, COUNT(*) AS `Total Records` FROM `', table_name, '`')
FROM 
    information_schema.tables 
WHERE 
    table_schema = 'oversee';


SELECT 'tb_cliente' AS `Table`, COUNT(*) AS `Total Records` FROM `tb_cliente`;
SELECT 'tb_quadro_eletrico' AS `Table`, COUNT(*) AS `Total Records` FROM `tb_quadro_eletrico`;
SELECT 'tb_coleta_quadro' AS `Table`, COUNT(*) AS `Total Records` FROM `tb_coleta_quadro`;
SELECT 'quadro_disjuntor' AS `Table`, COUNT(*) AS `Total Records` FROM `quadro_disjuntor`;
SELECT 'tb_coleta_disjuntor' AS `Table`, COUNT(*) AS `Total Records` FROM `tb_coleta_disjuntor`;

SELECT 
    'tb_cliente' AS 'Table', COUNT(*) AS 'Total Records' FROM tb_cliente
UNION ALL
SELECT 
    'tb_quadro_eletrico' AS 'Table', COUNT(*) FROM tb_quadro_eletrico
UNION ALL
SELECT 
    'tb_coleta_quadro' AS 'Table', COUNT(*) FROM tb_coleta_quadro
UNION ALL
SELECT 
    'quadro_disjuntor' AS 'Table', COUNT(*) FROM quadro_disjuntor
UNION ALL
SELECT 
    'tb_coleta_disjuntor' AS 'Table', COUNT(*) FROM tb_coleta_disjuntor;


SELECT 
    table_name AS 'Table',
    data_length + index_length AS 'Size Bytes',
    ROUND(((data_length + index_length) / 1024), 2) AS 'Size KB',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size MB',
    ROUND(((data_length + index_length) / 1024 / 1024 / 1024), 2) AS 'Size GB'
FROM 
    information_schema.TABLES 
WHERE 
    table_schema = 'oversee' 
ORDER BY 
    (data_length + index_length) DESC;

```