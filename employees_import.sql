SET CLUSTER SETTING experimental.importcsv.enabled = true;

DROP VIEW IF EXISTS dept_emp_latest_date,
                    current_dept_emp;

DROP TABLE IF EXISTS dept_emp,
                     dept_manager,
                     titles,
                     salaries,
                     employees,
                     departments;

IMPORT TABLE departments (
  dept_no     CHAR(4)         NOT NULL,
  dept_name   VARCHAR(40)     NOT NULL,
  PRIMARY KEY (dept_no),
  UNIQUE      (dept_name)
)
CSV DATA ('http://localhost:2015/departments.csv')
WITH
  temp = 'http://localhost:2015/',
  delimiter = e'\t'
;

IMPORT TABLE employees (
  emp_no      INT             NOT NULL,
  birth_date  DATE            NOT NULL,
  first_name  VARCHAR(14)     NOT NULL,
  last_name   VARCHAR(16)     NOT NULL,
  gender      CHAR(1)         NOT NULL,
  hire_date   DATE            NOT NULL,
  PRIMARY KEY (emp_no)
)
CSV DATA ('http://localhost:2015/employees.csv')
WITH
  temp = 'http://localhost:2015/',
  delimiter = e'\t'
;

IMPORT TABLE dept_manager (
  emp_no       INT             NOT NULL,
  dept_no      CHAR(4)         NOT NULL,
  from_date    DATE            NOT NULL,
  to_date      DATE            NOT NULL,
  PRIMARY KEY (emp_no, dept_no)
)
CSV DATA ('http://localhost:2015/dept_manager.csv')
WITH
  temp = 'http://localhost:2015/',
  delimiter = e'\t'
;

CREATE INDEX ON dept_manager (emp_no);

CREATE INDEX ON dept_manager (dept_no);

ALTER TABLE dept_manager ADD CONSTRAINT employee_fk FOREIGN KEY (emp_no) REFERENCES employees (emp_no);

ALTER TABLE dept_manager ADD CONSTRAINT department_fk FOREIGN KEY (dept_no) REFERENCES departments (dept_no);

IMPORT TABLE dept_emp (
  emp_no      INT             NOT NULL,
  dept_no     CHAR(4)         NOT NULL,
  from_date   DATE            NOT NULL,
  to_date     DATE            NOT NULL,
  PRIMARY KEY (emp_no, dept_no)
)
CSV DATA ('http://localhost:2015/dept_emp.csv')
WITH
  temp = 'http://localhost:2015/',
  delimiter = e'\t'
;

CREATE INDEX ON dept_emp (emp_no);

CREATE INDEX ON dept_emp (dept_no);

ALTER TABLE dept_emp ADD CONSTRAINT employee_fk FOREIGN KEY (emp_no) REFERENCES employees (emp_no);

ALTER TABLE dept_emp ADD CONSTRAINT department_fk FOREIGN KEY (dept_no) REFERENCES departments (dept_no);

IMPORT TABLE titles (
  emp_no      INT             NOT NULL,
  title       VARCHAR(50)     NOT NULL,
  from_date   DATE            NOT NULL,
  to_date     DATE,
  PRIMARY KEY (emp_no, title, from_date)
)
CSV DATA ('http://localhost:2015/titles.csv')
WITH
  temp = 'http://localhost:2015/',
  delimiter = e'\t'
;

CREATE INDEX ON titles (emp_no);

ALTER TABLE titles ADD CONSTRAINT employee_fk FOREIGN KEY (emp_no) REFERENCES employees (emp_no);

IMPORT TABLE salaries (
  emp_no      INT             NOT NULL,
  salary      INT             NOT NULL,
  from_date   DATE            NOT NULL,
  to_date     DATE            NOT NULL,
  PRIMARY KEY (emp_no, from_date)
)
CSV DATA ('http://localhost:2015/salaries.csv')
WITH
  temp = 'http://localhost:2015/',
  delimiter = e'\t'
;

CREATE INDEX ON salaries (emp_no);

ALTER TABLE salaries ADD CONSTRAINT employee_fk FOREIGN KEY (emp_no) REFERENCES employees (emp_no);

CREATE VIEW dept_emp_latest_date AS
  SELECT emp_no, MAX(from_date) AS from_date, MAX(to_date) AS to_date
  FROM dept_emp
  GROUP BY emp_no
;

CREATE VIEW current_dept_emp AS
  SELECT l.emp_no, dept_no, l.from_date, l.to_date
  FROM dept_emp d
    INNER JOIN dept_emp_latest_date l
    ON d.emp_no=l.emp_no AND d.from_date=l.from_date AND l.to_date = d.to_date
;
