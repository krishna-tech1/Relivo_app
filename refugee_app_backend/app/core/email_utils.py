import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

# Configuration from .env
MAIL_USERNAME = os.getenv("MAIL_USERNAME")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
MAIL_SERVER = os.getenv("MAIL_SERVER")
# Default to 465 if not set, but it should be set in .env
MAIL_PORT = int(os.getenv("MAIL_PORT", 465))
MAIL_FROM = os.getenv("MAIL_FROM")

def send_verification_email(email_to: str, code: str):
    try:
        print(f"DEBUG: Preparing to send email to {email_to} via {MAIL_SERVER}:{MAIL_PORT}")
        msg = MIMEMultipart()
        msg["From"] = MAIL_FROM
        msg["To"] = email_to
        msg["Subject"] = "Your Verification Code"

        body = f"Your verification code is: {code}"
        msg.attach(MIMEText(body, "plain"))

        print("DEBUG: Connecting to SMTP server (SSL)...")
        server = smtplib.SMTP_SSL(MAIL_SERVER, MAIL_PORT)
        
        print("DEBUG: Logging in...")
        server.login(MAIL_USERNAME, MAIL_PASSWORD)
        
        print("DEBUG: Sending email...")
        server.sendmail(MAIL_FROM, email_to, msg.as_string())
        
        server.quit()
        print("✅ OTP email sent successfully")
        return True
    except Exception as e:
        print("❌ Email error:", str(e))
        return False
