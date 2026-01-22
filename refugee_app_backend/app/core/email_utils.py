from typing import List, Dict, Any
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from pydantic import EmailStr
from app.core.config import settings
import os

# Configuration for FastAPI Mail
# In a real scenario, these values come from .env
username = os.getenv("MAIL_USERNAME", "apikey")
password = os.getenv("MAIL_PASSWORD", "")
server = os.getenv("MAIL_SERVER", "smtp-relay.brevo.com")
port = int(os.getenv("MAIL_PORT", 587))
sender = os.getenv("MAIL_FROM", "no-reply@relivo-app.com")

print(f"DEBUG: Email Config - Server: {server}:{port}")
print(f"DEBUG: Email Config - User: {username}")
print(f"DEBUG: Email Config - From: {sender}")
print(f"DEBUG: Email Config - Password set: {'Yes' if password else 'No'}")

conf = ConnectionConfig(
    MAIL_USERNAME=username,
    MAIL_PASSWORD=password,
    MAIL_FROM=sender,
    MAIL_PORT=port,
    MAIL_SERVER=server,
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True
)

async def send_verification_email(email_to: EmailStr, code: str):
    """
    Sends a verification email with the OTP code.
    """
    print(f"Attempting to send email to {email_to} via {conf.MAIL_SERVER}...")
    
    html = f"""
    <html>
        <body>
            <div style="font-family: Arial, sans-serif; padding: 20px;">
                <h2>Email Verification</h2>
                <p>Thank you for registering. Please use the following code to verify your email address:</p>
                <h1 style="color: #4CAF50; letter-spacing: 5px;">{code}</h1>
                <p>If you did not request this code, please ignore this email.</p>
            </div>
        </body>
    </html>
    """

    message = MessageSchema(
        subject="Your Verification Code",
        recipients=[email_to],
        body=html,
        subtype=MessageType.html
    )

    fm = FastMail(conf)
    try:
        await fm.send_message(message)
        print(f"✅ Email sent successfully to {email_to}")
        return True
    except Exception as e:
        print(f"❌ Failed to send email: {e}")
        print(f"DEBUGGING INFO: Server={conf.MAIL_SERVER} Port={conf.MAIL_PORT} User={conf.MAIL_USERNAME}")
        return False
