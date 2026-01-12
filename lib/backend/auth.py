from flask import Flask, Blueprint,current_app,request
from backend_main import db
from werkzeug.security import check_password_hash, generate_password_hash
import jwt
from datetime import datetime, timedelta
from functools import wraps




auth_bp=Blueprint("auth",__name__,url_prefix="/auth")

#this would be the table for user
class User(db.Model):
    __tablename__="users"
    id=db.Column(db.Integer, primary_key=True)
    username=db.Column(db.String(100),nullable=False,unique=True,index=True)
    email=db.Column(db.String(100),nullable=False,unique=True,index=True)
    password_hash=db.Column(db.String(100),nullable=False)

    def __repr__(self):
        return f"{self.username}"
    

#for signup
@auth_bp.route("/signup",Methods=["POST"])