import { Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Employee } from './models/employee';
import { EmployeeService } from './services/employee.service';
import { HttpErrorResponse } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { of } from 'rxjs';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet,CommonModule,FormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent implements OnInit{

  employees$: Observable<Employee[]> | undefined;
  public editEmployee: Employee | undefined;
  public deleteEmployee: Employee | undefined;
  public list = false;

  constructor(private employeeService: EmployeeService){}

  ngOnInit(): void {
      this.getAll();
  }

  public getAll():void {
    this.employees$ = this.employeeService.getEmployees().pipe(
      catchError((error: HttpErrorResponse) => {
        if(error.status == 507){
          this.list = true;
        }else{
          alert(error.status);
          this.list = false;
        }
        
        return of([]);  
      })
    );
  }

  public onAddEmployee(addForm: NgForm): void {
    document.getElementById('add-employee-form')?.click();
    const employee2:Employee = addForm.value;
    console.log(employee2);
    this.employeeService.addEmployee(addForm.value).pipe(
      tap((response: Response) => {
        this.getAll();
        console.log(response);
        addForm.reset();
        this.list = false;
      }),
      catchError((error: HttpErrorResponse) => {
        console.error('Error fetching employees:', error.message); 
        addForm.reset();
        this.list = false;
        return of([]); 
      })

    ).subscribe(); 
  }

  public onUpdateEmployee(employee:Employee): void {
    console.log("llll")
    document.getElementById('add-employee-form')?.click();
    this.employeeService.updateEmployee(employee.id,employee).pipe(
      tap((response: Response) => {
        console.log("llll")
        this.getAll();
        this.list = false;
        console.log(response);
      }),
      catchError((error: HttpErrorResponse) => {
        console.error('Error fetching employees:', error.message); 
        this.list = false;
        return of([]); 
      })

    ).subscribe(); 
  }

  public onDeleteEmployee(employeeId:number| undefined): void {
    document.getElementById('add-employee-form')?.click();
    if (employeeId === undefined) {
      console.error('Employee ID is undefined. Cannot delete employee.');
      return;
    }
    this.employeeService.deleteEmployee(employeeId).pipe(
      tap((response: Response) => {
        this.getAll();
        this.list = false;
      }),
      catchError((error: HttpErrorResponse) => {
        console.error('Error fetching employees:', error); 
        this.list = false;
        return of([]); 
      })

    ).subscribe(); 
  }


  public onOpenModal( mode: string ,employee?:Employee):void{
      const container = document.getElementById('main-container');
      const button = document.createElement('button');
      button.type = 'button';
      button.style.display = 'none';
      button.setAttribute('data-toggle', 'modal');
      button.setAttribute('data-target', '#addEmployeeModal');
      if( mode === 'add' ){
        button.setAttribute('data-target', '#addEmployeeModal');
      }
      if( mode === 'edit' ){
        this.editEmployee = employee;
        button.setAttribute('data-target', '#updateEmployeeModal');
      }
      if( mode === 'delete' ){
        this.deleteEmployee = employee;
        button.setAttribute('data-target', '#deleteEmployeeModal');
      }
      container?.appendChild(button);
      button.click();
  }



}
