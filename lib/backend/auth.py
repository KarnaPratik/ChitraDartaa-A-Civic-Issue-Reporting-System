from flask import Flask, Blueprint,current_app,request,jsonify
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
    is_administrator=db.Column(db.Boolean,nullable=False,default=False)

    def __repr__(self):
        return f"{self.username}"
    

#for signup
@auth_bp.route("/signup",methods=["POST"])
def signup():
    #for signup ig we gotta expect username, email and password and from sign up we just assign citizens as only citizens can sign up for administrator we have decided to add them separately
    data=request.get_json()
    if not data or not data.get("username") or not data.get("email"), or not data.get("password"):
        return jsonify({"error":"Incomplete info"})
    username=data["username"]
    password=data["password"]
    email=data["email"]


    #to check if the same username or email exist we check in the dbase
    existing_username=User.query.filter_by(username=username).first()
    existing_email=User.query.filter_by(email=email)
    if existing_email or existing_username:
        return jsonify({"error":"User or Email exists!"})
    
    pasword_hash=generate_password_hash(password=password)
    new_user=User(username=username,email=email,password=pasword_hash,is_administrator=False)

    #adding the user into the dbase
    try:
        db.session.add(new_user)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({"error":"Issue with dbase"})
    

    return jsonify({"message":"Successfully created user"}),201



    