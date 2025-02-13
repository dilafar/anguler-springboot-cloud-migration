package com.employees.employeemanager.controller;

import com.employees.employeemanager.constants.EmployeeConstants;
import com.employees.employeemanager.dto.EmployeeDto;
import com.employees.employeemanager.dto.ResponseDto;
import com.employees.employeemanager.entity.Employee;
import com.employees.employeemanager.service.IEmployeeService;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
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

    private final MeterRegistry meterRegistry;

    @Autowired
    public EmployeeController(IEmployeeService employeeService, MeterRegistry meterRegistry){
        this.employeeService = employeeService;
        this.meterRegistry = meterRegistry;
    }

    @PostMapping("/create")
    public ResponseEntity<ResponseDto> createEmployee(@RequestBody EmployeeDto employeeDto){
        Timer apiCreateSecondsCount = Timer.builder("employee_create")
                .tags("method", "POST", "status", "201") // Adjust status as needed
                .register(meterRegistry);
        apiCreateSecondsCount.record(() -> {
            employeeService.createEmployee(employeeDto);
        });
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDto(EmployeeConstants.STATUS_201,EmployeeConstants.MESSAGE_201));
    }

    @DeleteMapping("/delete")
    public ResponseEntity<ResponseDto> deleteEmployee(@RequestParam Long id){
        Timer apiCreateSecondsCount = Timer.builder("employee_delete")
                .tags("method", "DELETE", "status", "204") // Adjust status as needed
                .register(meterRegistry);

        boolean isUpdated = employeeService.deleteEmployee(id);
        if(isUpdated){
            apiCreateSecondsCount.record(() -> {
                System.out.println("successfully deleted...");
            });
            return ResponseEntity.status(HttpStatus.OK).body(new ResponseDto(EmployeeConstants.STATUS_200,EmployeeConstants.MESSAGE_200));
        }else {
            return ResponseEntity.status(HttpStatus.EXPECTATION_FAILED).body(new ResponseDto(EmployeeConstants.STATUS_417,EmployeeConstants.MESSAGE_417_DELETE));
        }
    }

    @PutMapping("/update")
    public ResponseEntity<ResponseDto> updateEmployee(@RequestParam Long id,@RequestBody EmployeeDto employeeDto){
        Timer apiCreateSecondsCount = Timer.builder("employee_update")
                .tags("method", "PUT", "status", "204") // Adjust status as needed
                .register(meterRegistry);
        boolean isUpdated = employeeService.updateEmployee(id,employeeDto);
        if (isUpdated){
            apiCreateSecondsCount.record(() -> {
                System.out.println("successfully updated...");
            });
            return ResponseEntity.status(HttpStatus.OK).body(new ResponseDto(EmployeeConstants.STATUS_200,EmployeeConstants.MESSAGE_200));
        }else {
            return ResponseEntity.status(HttpStatus.EXPECTATION_FAILED).body(new ResponseDto(EmployeeConstants.STATUS_417,EmployeeConstants.MESSAGE_417_UPDATE));
        }
    }

    @GetMapping
    public ResponseEntity<List<Employee>> fetchAllEmployees(){
        Timer apiCreateSecondsCount = Timer.builder("employee_get")
                .tags("method", "GET", "status", "200") // Adjust status as needed
                .register(meterRegistry);
        List<Employee> employees = employeeService.fetchEmployees();
        apiCreateSecondsCount.record(() -> {
            System.out.println("successfully fetched...");
        });
        return ResponseEntity.status(HttpStatus.OK).body(employees);
    }

    @GetMapping("/fetch")
    public ResponseEntity<Employee> fetchEmployee(@RequestParam Long id){
        Employee employee = employeeService.fetchEmployee(id);
        return ResponseEntity.status(HttpStatus.OK).body(employee);
    }
}
