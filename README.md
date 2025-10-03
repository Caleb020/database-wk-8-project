Project Overview

The Library Management System is a complete full-stack application designed to efficiently manage library operations. It provides a robust backend API built with FastAPI and a relational database using MySQL, offering comprehensive CRUD functionality for managing books, members, and book loans. The system handles core library workflows including member registration, book inventory management, borrowing processes, and return tracking with proper availability management.
Technical Architecture

Built with modern technologies, the backend utilizes FastAPI for high-performance REST API endpoints with automatic OpenAPI documentation. The database schema follows relational design principles with proper constraints, foreign key relationships, and normalization. Key features include member management with unique email validation, book inventory with real-time availability tracking, loan management with due date handling, and a fine system for overdue books. The API supports full CRUD operations for all major entities with proper error handling and data validation.
Getting Started

The project is easy to set up with clear installation instructions. After cloning the repository, users need to initialize the MySQL database using the provided SQL schema, configure environment variables for database connection, install Python dependencies, and start the FastAPI server. The application includes comprehensive API documentation available through Swagger UI and ReDoc, along with a Postman collection for easy testing. The modular codebase is organized for maintainability and follows best practices for database operations and API design.
