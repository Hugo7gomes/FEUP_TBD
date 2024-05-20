-----------------------------------
----- Copying Original Tables -----
-----------------------------------

DROP TABLE Regions_Orig;
CREATE TABLE Regions_Orig AS
SELECT * FROM GTD10.Regions;

DROP TABLE Countries_Orig;
CREATE TABLE Countries_Orig AS
SELECT * FROM GTD10.Countries;

DROP TABLE Locations_Orig;
CREATE TABLE Locations_Orig AS
SELECT * FROM GTD10.Locations;

DROP TABLE Departments_Orig;
CREATE TABLE Departments_Orig AS
SELECT * FROM GTD10.Departments;

DROP TABLE Jobs_Orig;
CREATE TABLE Jobs_Orig AS
SELECT * FROM GTD10.Jobs;

DROP TABLE Job_History_Orig;
CREATE TABLE Job_History_Orig AS
SELECT * FROM GTD10.Job_History;

DROP TABLE Employees_Orig;
CREATE TABLE Employees_Orig AS
SELECT * FROM GTD10.Employees;

-----------------------------------
---- Dropping Tables and Types ----
-----------------------------------

-- Drop Tables 
DROP TABLE Job_History FORCE;
DROP TABLE Employees FORCE;
DROP TABLE Jobs FORCE;
DROP TABLE Departments FORCE;
DROP TABLE Locations FORCE;
DROP TABLE Countries FORCE;
DROP TABLE Regions FORCE;

-- Drop Types 
DROP TYPE Job_History_t FORCE;
DROP TYPE Employee_t FORCE;
DROP TYPE Job_t FORCE;
DROP TYPE Department_t FORCE;
DROP TYPE Location_t FORCE;
DROP TYPE Country_t FORCE;
DROP TYPE Region_t FORCE;
DROP TYPE Countries_ref_table_t force;
DROP TYPE Departments_ref_table_t force;
DROP TYPE Employees_ref_table_t force;
DROP TYPE Job_History_ref_table_t force;
DROP TYPE Locations_ref_table_t force;


-----------------------------------
--------- Declaring Types ---------
-----------------------------------


CREATE TYPE Employee_t;

--Region Type
CREATE TYPE Region_t AS OBJECT(
	region_id INT,
	region_name VARCHAR(100)
)NOT FINAL;

--Country Type
CREATE TYPE Country_t AS OBJECT(
	country_id VARCHAR(2),
	country_name VARCHAR(100),
	REGION REF Region_t
)NOT FINAL;

--Location Type
CREATE TYPE Location_t AS OBJECT(
	location_id INT,
	street_address VARCHAR(255),
	postal_code VARCHAR(20),
	city VARCHAR(100),
	state_province VARCHAR(100),
	COUNTRY REF Country_t
)NOT FINAL;

--Department Type
CREATE TYPE Department_t AS OBJECT(
	department_id INT,
	department_name VARCHAR(100),
	MANAGER REF Employee_t,
	LOCATION REF Location_t
)NOT FINAL;

--Job Type
CREATE TYPE Job_t AS OBJECT(
	job_id VARCHAR(20),
	job_title VARCHAR(100),
	min_salary NUMBER,
	max_salary NUMBER
)NOT FINAL;

--Employee Type
CREATE TYPE Employee_t AS OBJECT (
    employee_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100),
    phone_number VARCHAR(20),
    hire_date DATE,
    JOB REF Job_t,
    salary NUMBER,
    commission_pct NUMBER,
    MANAGER REF Employee_t,
    DEPARTMENT REF Department_t
)NOT FINAL;


--Job History Type
CREATE TYPE Job_History_t AS OBJECT(
	EMPLOYEE REF Employee_t,
	start_date DATE,
	end_date DATE,
	JOB REF Job_t,
	DEPARTMENT REF Department_t
)NOT FINAL;

------------------------------------
---- Declaring Reference Tables ----
------------------------------------

--Countries Reference Table 
CREATE TYPE Countries_ref_table_t AS TABLE OF REF Country_t;

--Locations Reference Table 
CREATE TYPE Locations_ref_table_t AS TABLE OF REF Location_t;

--Departments Reference Table 
CREATE TYPE Departments_ref_table_t AS TABLE OF REF Department_t;

--Employees Reference Table 
CREATE TYPE Employees_ref_table_t AS TABLE OF REF Employee_t;

--Job History Reference Table 
CREATE TYPE Job_History_ref_table_t AS TABLE OF REF Job_History_t;


-------------------------------------
--- Adding Nested Tables to Types ---
-------------------------------------

-- Countries to Region
ALTER TYPE Region_t
ADD ATTRIBUTE (Countries Countries_ref_table_t) CASCADE;

-- Locations to Country
ALTER TYPE Country_t
ADD ATTRIBUTE (Locations Locations_ref_table_t) CASCADE;

-- Departments to Location 
ALTER TYPE Location_t
ADD ATTRIBUTE (Departments Departments_ref_table_t) CASCADE;

-- Job_History to Department
ALTER TYPE Department_t
ADD ATTRIBUTE (Job_History Job_History_ref_table_t) CASCADE;

--Employees to Department
ALTER TYPE Department_t
ADD ATTRIBUTE (Employees Employees_ref_table_t) CASCADE;

-- Job_History to Job
ALTER TYPE Job_t
ADD ATTRIBUTE (Job_History Job_History_ref_table_t) CASCADE;

-- Employees to Job
ALTER TYPE Job_t
ADD ATTRIBUTE (Employees Employees_ref_table_t) CASCADE;

-- Job_History to Employee
ALTER TYPE Employee_t
ADD ATTRIBUTE (Job_History Job_History_ref_table_t) CASCADE;

-- Departments to Employee
ALTER TYPE Employee_t
ADD ATTRIBUTE (Departments Departments_ref_table_t) CASCADE;

-- Employees to Employee
ALTER TYPE Employee_t
ADD ATTRIBUTE (Employees Employees_ref_table_t) CASCADE;




---------------------------------
-------- Creating Tables --------
---------------------------------

-- Regions Table
CREATE TABLE Regions of Region_t
	NESTED TABLE Countries STORE AS Countries_Region;

-- Countries Table
CREATE TABLE Countries of Country_t
	NESTED TABLE Locations STORE AS Locations_Country;

-- Locations Table
CREATE TABLE Locations of Location_t
	NESTED TABLE Departments STORE AS Departments_Location;

-- Departments Table
CREATE TABLE Departments of Department_t
	NESTED TABLE Job_History STORE AS Job_History_Department,
	NESTED TABLE Employees STORE AS Employees_Department;

-- Jobs Table
CREATE TABLE Jobs of Job_t
	NESTED TABLE Job_History STORE AS Job_History_Job,
	NESTED TABLE Employees STORE AS Employees_Job;

-- Employees Table
CREATE TABLE Employees of Employee_t
	NESTED TABLE Job_History STORE AS Job_History_Employee,
	NESTED TABLE Departments STORE AS Departments_Employee,
	NESTED TABLE Employees STORE AS Employees_Manager;

-- Job_History Table
CREATE TABLE Job_History of Job_History_t;


---------------------------------
------- Populating Tables -------
---------------------------------


--Populating Regions Table
DELETE FROM Regions;
INSERT INTO Regions (region_id, region_name)
select r.region_id, r.region_name
from Regions_Orig r;

-- Populating Countries Table
DELETE FROM Countries;
INSERT INTO Countries (country_id, country_name, REGION)
SELECT c.country_id, c.country_name, REF(r)
FROM Countries_Orig c
JOIN Regions r ON c.region_id = r.region_id;

-- Populating Locations Table
DELETE FROM Locations;
INSERT INTO Locations (location_id, street_address, postal_code, city, state_province, COUNTRY)
SELECT l.location_id, l.street_address, l.postal_code, l.city, l.state_province, REF(c)
FROM Locations_Orig l
JOIN Countries c ON l.country_id = c.country_id;

-- Populating Departments Table
DELETE FROM Departments;
INSERT INTO Departments (department_id, department_name, MANAGER, LOCATION)
SELECT d.department_id,
       d.department_name,
       (SELECT REF(e) FROM Employees e WHERE e.employee_id = d.manager_id),
       (SELECT REF(l) FROM Locations l WHERE l.location_id = d.location_id)
FROM Departments_Orig d;

--Populating Jobs Table
DELETE FROM Jobs;
INSERT INTO Jobs (job_id, job_title, min_salary, max_salary)
SELECT j.job_id, j.job_title, j.min_salary, j.max_salary
FROM Jobs_Orig j;

-- Populating Employees Table
DELETE FROM Employees;
INSERT INTO Employees (employee_id, first_name, last_name, email, phone_number, hire_date, JOB, salary, commission_pct, MANAGER, DEPARTMENT)
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.email,
       e.phone_number,
       e.hire_date,
       (SELECT REF(J) FROM Jobs J WHERE J.job_id = e.job_id),
       e.salary,
       e.commission_pct,
       NULL,
       (SELECT REF(D) FROM Departments D WHERE D.department_id = e.department_id)
FROM Employees_Orig e;

UPDATE Employees e
set e.Manager = (Select ref(Manager) From Employees Manager Where Manager.Employee_Id = (Select manager_id from Employees_Orig Where Employees_Orig.Employee_id = e.Employee_id));

-- Populating Job_History Table
delete from Job_History;
insert into Job_History (EMPLOYEE,START_DATE,END_DATE,JOB,DEPARTMENT)
select (select ref(e) From Employees e Where e.employee_id = jh.employee_id), jh.START_DATE, jh.END_DATE, (select ref(j) From Jobs j where j.job_id = jh.job_id), (select ref(d) From Departments d where d.department_id=jh.department_id)
from Job_History_Orig jh;

--------------------------------
------- Nested Migration -------
--------------------------------

-- Populate Job_History nested table in Jobs
update Jobs j
set j.Job_History = 
cast(multiset(select ref(jh) from Job_History jh where j.job_id = jh.job.job_id) as Job_History_ref_table_t);

-- Populate Employees nested table in Jobs
update Jobs j
set j.Employees = 
cast(multiset(select ref(e) from Employees e where j.job_id = e.job.job_id) as Employees_ref_table_t);

-- Populate Employees nested table in Employees
update Employees e
set e.Employees = 
cast(multiset(select ref(e2) from Employees e2 where e.employee_id = e2.manager.employee_id) as Employees_ref_table_t);

--Populate Departments nested table in Employees
update Employees e
set e.Departments = 
cast(multiset(select ref(d) from Departments d where e.employee_id = d.manager.employee_id) as Departments_ref_table_t);

--Populate Job_History nested table in Departments
update Departments d
set d.Job_History = 
cast(multiset(select ref(jh) from Job_History jh where d.department_id = jh.department.department_id) as Job_History_ref_table_t);

--Populate Employees nested table in Departments
update Departments d
set d.Employees = 
cast(multiset(select ref(e) from Employees e where d.department_id = e.department.department_id) as Employees_ref_table_t);

--Populate Departments nested table in Locations
update Locations l
set l.Departments = 
cast(multiset(select ref(d) from Departments d where l.location_id = d.location.location_id) as Departments_ref_table_t);

--Populate Locations nested table in Countries
update Countries c
set c.Locations =   
cast(multiset(select ref(l) from Locations l where c.country_id = l.country.country_id) as Locations_ref_table_t);

--Populate Countries nested table in Regions
update Regions r
set r.Countries = 
cast(multiset(select ref(c) from Countries c where r.region_id = c.region.region_id) as Countries_ref_table_t);

--Populate Job_History nested table in Employees
update Employees e
set e.Job_History = 
cast(multiset(select ref(JH) from Job_History JH where e.employee_id = JH.employee.employee_id) as Job_History_ref_table_t);


--------------------------------
---- Add Functions to types ----
--------------------------------

ALTER TYPE Employee_t
    ADD MEMBER FUNCTION GetMaxSalary(d REF Department_t) RETURN FLOAT CASCADE;

ALTER TYPE Employee_t
    ADD MEMBER FUNCTION GetNumberOfEmployees(d REF Department_t) RETURN INT CASCADE;

ALTER TYPE Employee_t
    ADD MEMBER FUNCTION GetAverageSalary(d REF Department_t) RETURN NUMBER CASCADE;

ALTER TYPE Employee_t
    ADD MEMBER FUNCTION GetAverageSalary(d REF Department_t, j REF Job_t) RETURN NUMBER CASCADE;

ALTER TYPE Employee_t
    ADD MEMBER FUNCTION GetNumberOfEmployees(d REF Department_t, j REF Job_t) RETURN INT CASCADE;

ALTER TYPE Country_t
    ADD MEMBER FUNCTION GetNumberOfEmployees(c REF Country_t) RETURN INT CASCADE;

ALTER TYPE Country_t
    ADD MEMBER FUNCTION GetAverageSalary(c REF Country_t) RETURN NUMBER CASCADE;


-------------------------------
---------- Functions ----------
-------------------------------

CREATE OR REPLACE TYPE BODY Employee_t AS
    MEMBER FUNCTION GetMaxSalary(d REF Department_t) RETURN FLOAT IS
        max_salary FLOAT;
    BEGIN
        SELECT MAX(e.salary) INTO max_salary FROM Employees e WHERE e.department = d;
        RETURN max_salary;
    END GetMaxSalary;

    MEMBER FUNCTION GetNumberOfEmployees(d REF Department_t) RETURN INT IS
        num_employees INT;
    BEGIN
        SELECT COUNT(*) INTO num_employees FROM Employees e WHERE e.department = d;
        RETURN num_employees;
    END GetNumberOfEmployees;

    MEMBER FUNCTION GetAverageSalary(d REF Department_t) RETURN NUMBER IS
        avg_salary NUMBER;
    BEGIN
        SELECT AVG(salary) INTO avg_salary FROM Employees e WHERE e.department = d;
        RETURN avg_salary;
    END GetAverageSalary;

    MEMBER FUNCTION GetAverageSalary(d REF Department_t, j REF Job_t) RETURN NUMBER IS
        avg_salary NUMBER;
    BEGIN
        SELECT AVG(e.salary) INTO avg_salary FROM Employees e WHERE e.department = d AND e.job = j;
        RETURN avg_salary;
    END GetAverageSalary;

    MEMBER FUNCTION GetNumberOfEmployees(d REF Department_t, j REF Job_t) RETURN INT IS
        num_employees INT;
    BEGIN
        SELECT COUNT(*) INTO num_employees FROM Employees e WHERE e.department = d AND e.job = j;
        RETURN num_employees;
    END GetNumberOfEmployees;
END;


CREATE OR REPLACE TYPE BODY Country_t AS
    MEMBER FUNCTION GetNumberOfEmployees(c REF Country_t) RETURN INT IS
        num_employees INT;
    BEGIN
        SELECT COUNT(*) INTO num_employees FROM Countries c1, table(c1.Locations) l, table(value(l).departments) d, table(value(d).Employees) e
        WHERE c = ref(c1);
        RETURN num_employees;
    END GetNumberOfEmployees;

    MEMBER FUNCTION GetAverageSalary(c REF Country_t) RETURN NUMBER IS
        avg_salary NUMBER;
    BEGIN
        SELECT nvl(AVG(value(e).salary),0) INTO avg_salary FROM Countries c1, table(c1.Locations) l, table(value(l).departments) d, table(value(d).Employees) e
        WHERE c = ref(c1);
        RETURN avg_salary;
    END GetAverageSalary;
END;

-----------------------------
---------- Queries ----------
-----------------------------

-- Query 1
SELECT d.department_name, e.GetNumberOfEmployees(REF(d)) AS total_employees
FROM Departments d, Employees e
WHERE e.department = REF(d);

-- Query 2
SELECT DISTINCT e.department.department_name as department_name, e.job.job_title as Job_Title, e.GetNumberOfEmployees(e.department,e.job) as NumberEmployees 
FROM Employees e;

-- Query 3
SELECT e.employee_id, e.first_name, e.last_name, e.department.department_name as Department, e.salary
FROM Employees e
WHERE e.salary = e.GetMaxSalary(e.department);

-- Query 4
SELECT 
    R.employee_id, 
    E.hire_date,
    round(CURRENT_DATE - E.hire_date, 2) AS days_since_hire
FROM (
    SELECT E.employee_id AS employee_id
    FROM employees E
    JOIN job_history JH1 ON JH1.employee = REF(E)
    JOIN job_history JH2 ON JH2.employee = REF(E) 
                         AND JH2.start_date = JH1.end_date + INTERVAL '1' DAY
    UNION
    SELECT employee_id
    FROM job_history JH
    JOIN employees E ON JH.employee = REF(E)
    GROUP BY employee_id
    HAVING COUNT(*) = 1
) R 
JOIN employees E ON E.employee_id = R.employee_id
ORDER BY days_since_hire;

-- Query 5
SELECT c.country_id, c.country_name, round(c.GetAverageSalary(REF(C))) 
FROM Countries c;

-- Query 6
-- Get the average salary of employees within each department located in Seattle
SELECT DISTINCT l.city,
        value(d).department_name,
        round(e.getAverageSalary(d.column_value),2) as Average_Salary
FROM Locations l,
table (l.departments) D,
     Employees e
WHERE l.city = 'Seattle' and
e.department = D.column_value
ORDER BY l.city, value(D).department_name;

    





