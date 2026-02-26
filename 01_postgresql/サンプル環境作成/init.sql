-- Usersテーブルの作成
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    age INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employeesテーブルの作成
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    position VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Productsテーブルの作成
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(20) NOT NULL UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_quantity INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usersテーブルに50,000件のデータを挿入
INSERT INTO users (username, email, first_name, last_name, age)
SELECT
    'user' || i::text,
    'user' || i::text || '@example.com',
    'FirstName' || i::text,
    'LastName' || i::text,
    20 + (i % 50)
FROM generate_series(1, 50000) AS i;

-- Employeesテーブルに50,000件のデータを挿入
INSERT INTO employees (employee_code, first_name, last_name, department, position, salary, hire_date)
SELECT
    'EMP' || LPAD(i::TEXT, 8, '0'),
    'FirstName' || i::TEXT,
    'LastName' || i::TEXT,
    CASE (i % 5)
        WHEN 0 THEN 'Sales'
        WHEN 1 THEN 'Engineering'
        WHEN 2 THEN 'Marketing'
        WHEN 3 THEN 'HR'
        ELSE 'Finance'
    END,
    CASE (i % 4)
        WHEN 0 THEN 'Manager'
        WHEN 1 THEN 'Senior'
        WHEN 2 THEN 'Junior'
        ELSE 'Intern'
    END,
    30000 + (i % 100) * 1000,
    CURRENT_DATE - (i % 3650)
FROM generate_series(1, 50000) AS i;

-- Productsテーブルに50,000件のデータを挿入
INSERT INTO products (product_code, product_name, category, price, stock_quantity, description)
SELECT
    'PRD' || LPAD(i::TEXT, 8, '0'),
    'Product ' || i::TEXT,
    CASE (i % 6)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Books'
        WHEN 3 THEN 'Food'
        WHEN 4 THEN 'Furniture'
        ELSE 'Sports'
    END,
    (10 + (i % 990)) * 1.0,
    i % 1000,
    'Description for product ' || i::TEXT
FROM generate_series(1, 50000) AS i;

-- インデックスの作成
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);
