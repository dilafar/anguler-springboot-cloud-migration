package com.employees.employeemanager.service;

import com.employees.employeemanager.dto.EmployeeDto;
import com.employees.employeemanager.entity.Employee;

import java.util.List;

public interface IEmployeeService {
    void createEmployee(EmployeeDto employeeDto);
    List<Employee> fetchEmployees();
    boolean updateEmployee(Long employeeId ,EmployeeDto employeeDto);
    boolean deleteEmployee(Long employeeId);
    Employee fetchEmployee(Long employeeId);
}
