package com.employees.employeemanager.dto;

import jakarta.persistence.Column;
import lombok.Data;

@Data
public class EmployeeDto {
    private String name;
    private String email;
    private String jobTitle;
    private String phone;
    private String imageUrl;
    private String employeeCode;
}
