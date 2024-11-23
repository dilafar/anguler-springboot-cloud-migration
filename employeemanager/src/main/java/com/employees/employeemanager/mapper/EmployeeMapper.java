package com.employees.employeemanager.mapper;

import com.employees.employeemanager.dto.EmployeeDto;
import com.employees.employeemanager.entity.Employee;

public class EmployeeMapper {
    public static Employee mapToEmployee(EmployeeDto employeeDto, Employee employee){
        employee.setEmail(employeeDto.getEmail());
        employee.setEmployeeCode(employeeDto.getEmployeeCode());
        employee.setName(employeeDto.getName());
        employee.setPhone(employeeDto.getPhone());
        employee.setImageUrl(employeeDto.getImageUrl());
        employee.setJobTitle(employeeDto.getJobTitle());

        return employee;
    }
}
