import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Employee } from '../models/employee';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class EmployeeService {
  private apiServerUrl = environment.apiServerUrl;

  constructor(private http: HttpClient) { }

  public getEmployees(): Observable<Employee[]> {
    return this.http.get<Employee[]>(`${this.apiServerUrl}`);
  }

  public addEmployee(employee:Employee): Observable<Response> {
    return this.http.post<Response>(`${this.apiServerUrl}/create`,employee);
  }

  public updateEmployee(id:number,employee:Employee): Observable<Response> {
    return this.http.put<Response>(`${this.apiServerUrl}/update?id=${id}`,employee);
  }

  public deleteEmployee(id:number): Observable<Response> {
    return this.http.delete<Response>(`${this.apiServerUrl}/delete?id=${id}`);
  }
}
