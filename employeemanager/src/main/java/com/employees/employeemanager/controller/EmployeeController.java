package com.employees.employeemanager.controller;

import com.employees.employeemanager.constants.EmployeeConstants;
import com.employees.employeemanager.dto.EmployeeDto;
import com.employees.employeemanager.dto.ResponseDto;
import com.employees.employeemanager.entity.Employee;
import com.employees.employeemanager.service.IEmployeeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping(path = "/api",produces = {MediaType.APPLICATION_JSON_VALUE})
public class EmployeeController {
    private final IEmployeeService employeeService;

    @Autowired
    public EmployeeController(IEmployeeService employeeService){
        this.employeeService = employeeService;
    }

    @PostMapping("/create")
    public ResponseEntity<ResponseDto> createEmployee(@RequestBody EmployeeDto employeeDto){
        employeeService.createEmployee(employeeDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDto(EmployeeConstants.STATUS_201,EmployeeConstants.MESSAGE_201));
    }

    @DeleteMapping("/delete")
    public ResponseEntity<ResponseDto> deleteEmployee(@RequestParam Long id){
        boolean isUpdated = employeeService.deleteEmployee(id);
        if(isUpdated){
            return ResponseEntity.status(HttpStatus.OK).body(new ResponseDto(EmployeeConstants.STATUS_200,EmployeeConstants.MESSAGE_200));
        }else {
            return ResponseEntity.status(HttpStatus.EXPECTATION_FAILED).body(new ResponseDto(EmployeeConstants.STATUS_417,EmployeeConstants.MESSAGE_417_DELETE));
        }
    }

    @PutMapping("/update")
    public ResponseEntity<ResponseDto> updateEmployee(@RequestParam Long id,@RequestBody EmployeeDto employeeDto){
        boolean isUpdated = employeeService.updateEmployee(id,employeeDto);
        if (isUpdated){
            return ResponseEntity.status(HttpStatus.OK).body(new ResponseDto(EmployeeConstants.STATUS_200,EmployeeConstants.MESSAGE_200));
        }else {
            return ResponseEntity.status(HttpStatus.EXPECTATION_FAILED).body(new ResponseDto(EmployeeConstants.STATUS_417,EmployeeConstants.MESSAGE_417_UPDATE));
        }
    }

    @GetMapping
    public ResponseEntity<List<Employee>> fetchAllEmployees(){
        List<Employee> employees = employeeService.fetchEmployees();
        return ResponseEntity.status(HttpStatus.OK).body(employees);
    }

    @GetMapping("/fetch")
    public ResponseEntity<Employee> fetchEmployee(@RequestParam Long id){
        Employee employee = employeeService.fetchEmployee(id);
        return ResponseEntity.status(HttpStatus.OK).body(employee);
    }
}
