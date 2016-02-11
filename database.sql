-- Creates the articles table and inserts initial link
CREATE TABLE articles (id SERIAL, link VARCHAR(255), processed BOOLEAN, content TEXT)
INSERT INTO articles (link, processed) VALUES ('http://www.onet.pl', 'f');
