create database testdb with template template_postgis;
create user test with encrypted password 'test';
grant all privileges on database testdb to test;
