
CREATE DATABASE IF NOT EXISTS etl_db;
USE etl_db;


CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    domain VARCHAR(100),
    location VARCHAR(100),
    value BIGINT,
    transaction_count INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
