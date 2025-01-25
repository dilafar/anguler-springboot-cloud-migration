import requests
import smtplib
import os

def send_notification(email_msg):
    with smtplib.SMTP('smtp.gmail.com',587) as smtp:
        smtp.starttls()
        smtp.ehlo()
        smtp.login("fadhilahamed98@gmail.com", "ueaieuscmdhpfdxx")
        smtp.sendmail("fadhilahamed98@gmail.com","fadhilahamed98@gmail.com",email_msg)
    
try:
    response = requests.get('https://awsvault.cloud-emgmt.com/')
    print(response.status_code)
    #response.status_code == 200
    if response.status_code == 200:
        print('Application is running successfully')
        msg = f"Subject: SITE UP\nApplication Returened {response.status_code} \nFix the issue! Restart the application..."
        send_notification(msg)
    else:
        print('Application is Down. fix it...')
        msg = f"Subject: SITE DOWN\nApplication Returened {response.status_code} \nFix the issue! Restart the application..."
        send_notification(msg)
            

except Exception as ex:
    print(f'Connection error happened: {ex}')
    msg = f"Subject: SITE DOWN \nFApplication not accessable..."
    send_notification(msg)