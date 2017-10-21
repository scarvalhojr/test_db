#!/usr/bin/env bash

UPDATE_RATE=1000

while true
do
  RAND_ID_MOD=$((RANDOM % UPDATE_RATE))

  CHECK_STMT="SELECT AVG(salary)
                FROM salaries
               WHERE to_date = '9999-01-01'
                 AND emp_no % $UPDATE_RATE = $RAND_ID_MOD"

  RAISE_STMT="UPDATE salaries
                 SET salary = CAST(salary * 1.05 as INT)
               WHERE to_date = '9999-01-01'
                 AND emp_no % $UPDATE_RATE = $RAND_ID_MOD"

  echo "Checking average salary of employees with ID ending in $RAND_ID_MOD"
  cockroach sql -e "$CHECK_STMT"

  echo "Giving a 5% pay raise to employees with ID ending in $RAND_ID_MOD"
  cockroach sql -e "$RAISE_STMT"

  echo "Checking average salary of employees with ID ending in $RAND_ID_MOD"
  cockroach sql -e "$CHECK_STMT"
done
