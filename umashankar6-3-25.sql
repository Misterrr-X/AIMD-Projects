-- Task 1:Create tables for books, members, borrowing transactions, and fines.
-- Task 2: Define Relationships (Role: Database Administrator)
-- Establish the following relationships:
-- Members ↔ Borrowing
-- Books ↔ Borrowing
-- Borrowing ↔ Fines
-- Task 4: Implement Triggers (Role: Database Developer)
-- Create a trigger to automatically update the availability_status of a book when a borrowing transaction is completed (set to "borrowed" when borrowed).
-- Create a trigger to automatically update the availability_status 

-- Task 5: Role-based Access Control (Role: Security Administrator)
-- Implement role-based access control to restrict access to sensitive data.
-- Admin Role: Can access and modify all tables.
-- Librarian Role: Can view all books and borrowings, but cannot modify member details.
-- Member Role: Can only view their borrowing history and fines.

create database librarydb;
use librarydb;

create table books(
book_id int primary key auto_increment,
title varchar(50) not null,
author varchar(50) not null,
publication_year int,
genre varchar(50),
available_copies int not null
);

INSERT INTO Books (title, author, publication_year, genre, available_copies) VALUES
('The Catcher in the Rye', 'J.D. Salinger', 1951, 'Fiction', 10),
('To Kill a Mockingbird', 'Harper Lee', 1960, 'Fiction', 5),
('1984', 'George Orwell', 1949, 'Dystopian', 12),
('The Great Gatsby', 'F. Scott Fitzgerald', 1925, 'Classics', 8),
('Moby Dick', 'Herman Melville', 1851, 'Adventure', 3);
alter table books add availability_status enum('available','not available','borrowed' )
not null default 'available';

create table members(
member_id int primary key auto_increment,
first_name varchar(50) not null,
last_name varchar(50) not null,
email varchar(100) unique not null,
join_date date not null,
phone varchar(50)
);

INSERT INTO Members (first_name, last_name, email, join_date, phone) VALUES
('Alice', 'Johnson', 'alice.johnson@example.com', '2022-03-15', '9876543210'),
('Bob', 'Smith', 'bob.smith@example.com', '2021-06-30', '9888776655'),
('Charlie', 'Brown', 'charlie.brown@example.com', '2023-01-10', '9988776655'),
('Diana', 'White', 'diana.white@example.com', '2020-11-25', '9798989898'),
('Eve', 'Davis', 'eve.davis@example.com', '2021-08-14', '9506507700');

create table borrowing_transactions(
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT,
    book_id INT,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

INSERT INTO Borrowing_Transactions (member_id, book_id, borrow_date, due_date, return_date) VALUES
(1, 3, '2025-02-15', '2025-03-01', '2025-02-28'),
(2, 1, '2025-01-10', '2025-01-24', '2025-01-22'),
(3, 2, '2025-02-20', '2025-03-06', NULL),  
(4, 5, '2025-02-05', '2025-02-19', NULL),  
(5, 4, '2025-03-01', '2025-03-15', NULL);  

create table fines(
fine_id int primary key auto_increment,
transaction_id int,
fine_amount decimal(10,2) not null,
fine_date date not null,
payment_date date,
member_id int,
foreign key (transaction_id) references borrowing_transactions(transaction_id),
FOREIGN KEY (member_id) REFERENCES members(member_id)
);


INSERT INTO fines (transaction_id, fine_amount, fine_date, payment_date, member_id) VALUES
(1, 50.00, '2025-02-20', '2025-02-22', 1),
(2, 30.00, '2025-02-25', NULL, 2),
(3, 100.00, '2025-03-01', '2025-03-03', 3),
(4, 75.50, '2025-03-05', NULL, 4),
(5, 20.00, '2025-03-10', '2025-03-12', 5);
-- List all overdue books with member details (include book_id, title, member_id, first_name, last_name, due_date).
select b.book_id, b.title, m.member_id, m.first_name, m.last_name, br.due_date 
from borrowing_transactions br
join books b on br.book_id = b.book_id
join members m on br.member_id = m.member_id
where br.return_date is null and br.due_date < curdate();
-- Generate a monthly report of fines collected, showing fine_id, member_id, fine_amount, and payment_date.
select fine_id,member_id,fine_amount,payment_date
from fines
where month(payment_date)=month(curdate()) and year(payment_date) = year(curdate());

-- Calculate the total fines collected for a given month. 
select fine_id,member_id,fine_amount,payment_date,
(select sum(fine_amount) 
from fines 
where month(payment_date)=month(curdate()) and year(payment_date) = year(curdate())) as total_fine_amt
from fines
where month(payment_date)=month(curdate()) and year(payment_date) = year(curdate());

-- Task 4: Implement Triggers
-- 1. Trigger to update book availability when borrowed

delimiter $$
create trigger after_borrow
after insert on borrowing_transactions
for each row
begin
    update books
    set availability_status = 'borrowed'
    where book_id = new.book_id;
end $$
delimiter;

-- 2. Trigger to update book availability when returned

delimiter $$
create trigger after_return
after update on borrowing_transactions
for each row
begin
  if new.return_date is not null then
  update books
  set availability_status = 'Available'
  where book_id=new.book_id;
 end if;
end $$

delimiter ;

-- Task 5: Role-based Access Control
-- 1. Creating Roles
CREATE ROLE Admin;
CREATE ROLE Librarian;
CREATE ROLE Member;

-- 2. Granting Permissions
GRANT ALL PRIVILEGES ON * TO Admin;
GRANT SELECT, INSERT, UPDATE ON Books TO Librarian;
GRANT SELECT ON Borrowing TO Librarian;
GRANT SELECT ON Borrowing TO Member;
CREATE VIEW Member_Fines AS
SELECT * FROM Fines WHERE member_id = CURRENT_USER();

