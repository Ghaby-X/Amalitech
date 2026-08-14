-- Runs automatically on first container start via /docker-entrypoint-initdb.d
-- (the mysql image only executes this when the data volume is empty)

CREATE TABLE IF NOT EXISTS visits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    visited_at DATETIME NOT NULL
);
