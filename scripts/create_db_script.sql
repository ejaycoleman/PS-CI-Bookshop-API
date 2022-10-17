CREATE TABLE books(
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  author VARCHAR(50) NOT NULL,
);

INSERT INTO books (name, author) VALUES
  ('The Philosophers Stone', 'J.K Rowling'),
  ('The Famous FIve', 'Enid Blyton');