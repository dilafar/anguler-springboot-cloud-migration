package com.employees.employeemanager.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.INSUFFICIENT_STORAGE)
public class EmptyResourceListException extends RuntimeException{
    public EmptyResourceListException(String message){
        super(message);
    }
}
