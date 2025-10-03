-- Create Database
CREATE DATABASE IF NOT EXISTS library_management;
USE library_management;

-- Members Table
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    membership_date DATE NOT NULL,
    status ENUM('active', 'suspended', 'expired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Authors Table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    nationality VARCHAR(50),
    birth_year INT,
    biography TEXT
);

-- Books Table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    publication_year INT,
    genre VARCHAR(50),
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    author_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE SET NULL
);

-- Book Loans Table
CREATE TABLE book_loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('borrowed', 'returned', 'overdue') DEFAULT 'borrowed',
    fine_amount DECIMAL(8,2) DEFAULT 0.00,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Fines Table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    member_id INT NOT NULL,
    amount DECIMAL(8,2) NOT NULL,
    reason VARCHAR(200),
    paid_date DATE NULL,
    status ENUM('pending', 'paid') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES book_loans(loan_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Insert Sample Data
INSERT INTO authors (name, nationality, birth_year) VALUES
('George Orwell', 'British', 1903),
('J.K. Rowling', 'British', 1965),
('J.R.R. Tolkien', 'British', 1892),
('Agatha Christie', 'British', 1890);

INSERT INTO books (title, isbn, publication_year, genre, total_copies, available_copies, author_id) VALUES
('1984', '978-0451524935', 1949, 'Dystopian', 5, 5, 1),
('Animal Farm', '978-0451526342', 1945, 'Satire', 3, 3, 1),
('Harry Potter and the Sorcerer''s Stone', '978-0439708180', 1997, 'Fantasy', 10, 10, 2),
('The Hobbit', '978-0547928227', 1937, 'Fantasy', 8, 8, 3),
('Murder on the Orient Express', '978-0062693662', 1934, 'Mystery', 4, 4, 4);

INSERT INTO members (first_name, last_name, email, phone, membership_date) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '2024-01-15'),
('Sarah', 'Johnson', 'sarah.johnson@email.com', '555-0102', '2024-02-20'),
('Michael', 'Brown', 'michael.brown@email.com', '555-0103', '2024-03-10');


#Task 2: FastAPI CRUD Application 
requirements.txt

fastapi==0.104.1
uvicorn==0.24.0
mysql-connector-python==8.2.0
python-dotenv==1.0.0
pydantic==2.5.0

#main.py
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import mysql.connector
import os
from dotenv import load_dotenv
from datetime import date, datetime, timedelta

load_dotenv()

app = FastAPI(title="Library Management System", version="1.0.0")

# Database configuration
def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "library_management")
    )

# Pydantic Models
class MemberBase(BaseModel):
    first_name: str
    last_name: str
    email: str
    phone: Optional[str] = None

class MemberCreate(MemberBase):
    pass

class Member(MemberBase):
    member_id: int
    membership_date: date
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class BookBase(BaseModel):
    title: str
    isbn: str
    publication_year: Optional[int] = None
    genre: Optional[str] = None
    total_copies: int = 1
    author_id: Optional[int] = None

class BookCreate(BookBase):
    pass

class Book(BookBase):
    book_id: int
    available_copies: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class LoanBase(BaseModel):
    book_id: int
    member_id: int
    loan_date: date
    due_date: date

class LoanCreate(LoanBase):
    pass

class Loan(LoanBase):
    loan_id: int
    return_date: Optional[date] = None
    status: str
    fine_amount: float
    
    class Config:
        from_attributes = True

# Members CRUD Operations
@app.post("/members/", response_model=Member)
def create_member(member: MemberCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    query = """
    INSERT INTO members (first_name, last_name, email, phone, membership_date)
    VALUES (%s, %s, %s, %s, %s)
    """
    values = (member.first_name, member.last_name, member.email, member.phone, date.today())
    
    try:
        cursor.execute(query, values)
        conn.commit()
        member_id = cursor.lastrowid
        
        cursor.execute("SELECT * FROM members WHERE member_id = %s", (member_id,))
        new_member = cursor.fetchone()
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="Email already exists")
    finally:
        cursor.close()
        conn.close()
    
    return new_member

@app.get("/members/", response_model=List[Member])
def read_members(skip: int = 0, limit: int = 100):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM members ORDER BY member_id LIMIT %s OFFSET %s", (limit, skip))
    members = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return members

@app.get("/members/{member_id}", response_model=Member)
def read_member(member_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM members WHERE member_id = %s", (member_id,))
    member = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    if member is None:
        raise HTTPException(status_code=404, detail="Member not found")
    return member

@app.put("/members/{member_id}", response_model=Member)
def update_member(member_id: int, member: MemberCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    query = """
    UPDATE members 
    SET first_name = %s, last_name = %s, email = %s, phone = %s
    WHERE member_id = %s
    """
    values = (member.first_name, member.last_name, member.email, member.phone, member_id)
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        cursor.execute("SELECT * FROM members WHERE member_id = %s", (member_id,))
        updated_member = cursor.fetchone()
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="Email already exists")
    finally:
        cursor.close()
        conn.close()
    
    if updated_member is None:
        raise HTTPException(status_code=404, detail="Member not found")
    return updated_member

@app.delete("/members/{member_id}")
def delete_member(member_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM members WHERE member_id = %s", (member_id,))
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return {"message": "Member deleted successfully"}

# Books CRUD Operations
@app.post("/books/", response_model=Book)
def create_book(book: BookCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    query = """
    INSERT INTO books (title, isbn, publication_year, genre, total_copies, available_copies, author_id)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    values = (book.title, book.isbn, book.publication_year, book.genre, 
              book.total_copies, book.total_copies, book.author_id)
    
    try:
        cursor.execute(query, values)
        conn.commit()
        book_id = cursor.lastrowid
        
        cursor.execute("SELECT * FROM books WHERE book_id = %s", (book_id,))
        new_book = cursor.fetchone()
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="ISBN already exists")
    finally:
        cursor.close()
        conn.close()
    
    return new_book

@app.get("/books/", response_model=List[Book])
def read_books(skip: int = 0, limit: int = 100):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM books ORDER BY book_id LIMIT %s OFFSET %s", (limit, skip))
    books = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return books

@app.get("/books/{book_id}", response_model=Book)
def read_book(book_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM books WHERE book_id = %s", (book_id,))
    book = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    if book is None:
        raise HTTPException(status_code=404, detail="Book not found")
    return book

@app.put("/books/{book_id}", response_model=Book)
def update_book(book_id: int, book: BookCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get current available copies to calculate new available copies
    cursor.execute("SELECT total_copies, available_copies FROM books WHERE book_id = %s", (book_id,))
    current_book = cursor.fetchone()
    
    if current_book is None:
        raise HTTPException(status_code=404, detail="Book not found")
    
    copies_diff = book.total_copies - current_book['total_copies']
    new_available_copies = current_book['available_copies'] + copies_diff
    
    query = """
    UPDATE books 
    SET title = %s, isbn = %s, publication_year = %s, genre = %s, 
        total_copies = %s, available_copies = %s, author_id = %s
    WHERE book_id = %s
    """
    values = (book.title, book.isbn, book.publication_year, book.genre, 
              book.total_copies, new_available_copies, book.author_id, book_id)
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        cursor.execute("SELECT * FROM books WHERE book_id = %s", (book_id,))
        updated_book = cursor.fetchone()
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="ISBN already exists")
    finally:
        cursor.close()
        conn.close()
    
    return updated_book

@app.delete("/books/{book_id}")
def delete_book(book_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM books WHERE book_id = %s", (book_id,))
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return {"message": "Book deleted successfully"}

# Loan Operations
@app.post("/loans/", response_model=Loan)
def create_loan(loan: LoanCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Check if book is available
    cursor.execute("SELECT available_copies FROM books WHERE book_id = %s", (loan.book_id,))
    book = cursor.fetchone()
    
    if book is None:
        raise HTTPException(status_code=404, detail="Book not found")
    
    if book['available_copies'] <= 0:
        raise HTTPException(status_code=400, detail="Book not available")
    
    # Create loan
    query = """
    INSERT INTO book_loans (book_id, member_id, loan_date, due_date, status)
    VALUES (%s, %s, %s, %s, 'borrowed')
    """
    values = (loan.book_id, loan.member_id, loan.loan_date, loan.due_date)
    
    cursor.execute(query, values)
    
    # Update available copies
    cursor.execute("UPDATE books SET available_copies = available_copies - 1 WHERE book_id = %s", (loan.book_id,))
    
    conn.commit()
    loan_id = cursor.lastrowid
    
    cursor.execute("SELECT * FROM book_loans WHERE loan_id = %s", (loan_id,))
    new_loan = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    return new_loan

@app.get("/loans/", response_model=List[Loan])
def read_loans(skip: int = 0, limit: int = 100):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM book_loans ORDER BY loan_id LIMIT %s OFFSET %s", (limit, skip))
    loans = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return loans

@app.put("/loans/{loan_id}/return")
def return_loan(loan_id: int):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get loan details
    cursor.execute("SELECT book_id FROM book_loans WHERE loan_id = %s", (loan_id,))
    loan = cursor.fetchone()
    
    if loan is None:
        raise HTTPException(status_code=404, detail="Loan not found")
    
    # Update loan
    cursor.execute("""
    UPDATE book_loans 
    SET return_date = %s, status = 'returned' 
    WHERE loan_id = %s
    """, (date.today(), loan_id))
    
    # Update available copies
    cursor.execute("UPDATE books SET available_copies = available_copies + 1 WHERE book_id = %s", (loan['book_id'],))
    
    conn.commit()
    
    cursor.close()
    conn.close()
    
    return {"message": "Book returned successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
# .env file
env

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=library_management

#Setup Instructions:

    #Database Setup:

    bash

mysql -u root -p < library_management.sql

#Run FastAPI Application:

bash

pip install -r requirements.txt
uvicorn main:app --reload

#Access API Documentation:

    Swagger UI: http://localhost:8000/docs

    ReDoc: http://localhost:8000/redoc
