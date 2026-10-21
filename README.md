# Driving School Management Database System

A relational database system designed to model and manage driving school operations, including student enrollments, driving license categories, instructor assignments, vehicles, and scheduled lessons. Built using Oracle SQL and PL/SQL, it incorporates integrity constraints, custom collections (nested tables, varrays, associative arrays), parameterized cursors, user-defined exception handling, and automated auditing and business logic enforcement via DML and DDL triggers.

---

## Features

- **Relational Data Modeling:** Normalized relational schema covering students, instructors, vehicles, contracts, license categories, and driving sessions with foreign keys and check constraints.
- **PL/SQL Collections:** Stored procedures utilizing associative arrays (`INDEX BY PLS_INTEGER`), nested tables, and `VARRAY` types with `BULK COLLECT` operations for multi-attribute reporting.
- **Parameterized Cursors:** Nested and parameterized cursor handling for hierarchical queries linking instructors, eligible vehicle categories, and fleet availability.
- **Error & Exception Handling:** User-defined exceptions, validation checks (e.g., CNP length, ID bounds), and standard Oracle exceptions (`NO_DATA_FOUND`, `TOO_MANY_ROWS`).
- **Triggers & Auditing:**
  - Statement-level DML triggers enforcing temporal access constraints.
  - Row-level DML triggers for audit defaults (`DATA_ANGAJARII`) and business logic validation (salary drop prevention).
  - Schema-level DDL trigger logging administrative changes (`CREATE`, `ALTER`, `DROP`) into dedicated audit tables.

---

## Tech Stack

- **Database:** Oracle Database (SQL & PL/SQL)
- **Tools:** Oracle SQL Developer / SQL*Plus / DBeaver
- **Version Control:** Git & GitHub

---

## Database Schema Overview

| Entity | Description |
|---|---|
| `CATEGORIE_PERMIS` | License categories, minimum age requirements, and training hour baselines |
| `CURS` | Courses offered per category with required training hours |
| `ELEV` | Student profiles, contact details, and CNP uniqueness validation |
| `CONTRACT` | Student enrollment contracts, duration dates, fees, and associated courses |
| `AUTOVEHICUL` | Fleet inventory linked to valid driving license categories |
| `INSTRUCTOR` | Instructor registry, employment start dates, and salary figures |
| `SEDINTA` | Driving sessions, scheduled timeframes, and linked instructor/student/vehicle data |
| `CATEGORIE_PERMIS_INSTRUCTOR` | Associative table defining category authorizations per instructor |
| `INFORMATII` | Audit logging target tracking schema DDL events |

---

## Setup & Execution

1. Clone the repository:
   ```bash
   git clone [https://github.com/your-username/your-repository-name.git](https://github.com/your-username/your-repository-name.git)
   cd your-repository-name
