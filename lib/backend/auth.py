from flask import Flask, Blueprint,current_app,request,jsonify
from werkzeug.security import check_password_hash, generate_password_hash
import jwt
from datetime import datetime, timedelta, timezone
from functools import wraps
from extension import db



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
    if not data or not data.get("username") or not data.get("email") or not data.get("password"):
        return jsonify({"error":"Incomplete info"})
    username=data["username"]
    password=data["password"]
    email=data["email"]


    #to check if the same username or email exist we check in the dbase
    existing_username=User.query.filter_by(username=username).first()
    existing_email=User.query.filter_by(email=email).first()
    if existing_email or existing_username:
        return jsonify({"error":"User or Email exists!"}),409 #just adding error code for easier use 
    
    password_hash=generate_password_hash(password=password)
    new_user=User(username=username,email=email,password_hash=password_hash,is_administrator=False)

    #adding the user into the dbase
    try:
        db.session.add(new_user)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({"error":"Issue with dbase"}),500
    

    return jsonify({"message":"Successfully created user"}),201



#this function is for login
@auth_bp.route("/login",methods=["POST"])
def login():
        '''
        here we get json with username and possword with like role so if either its citizen or an administrator
        '''
        data=request.get_json()
        if not data or not data.get("username") or not data.get("password") or  "role" not in data:
             return jsonify({"error":"Invalid Request!"}),401
        username=data["username"]
        password=data["password"]
        role_=data["role"]

        user=User.query.filter_by(username=username).first()
 

        if not user or not  check_password_hash(user.password_hash,password) or role_!=user.is_administrator:
             return jsonify({"error":"Invalid username or password!"}),401
        
        access_token=create_access_token(username)
        return jsonify(
             {
                  "message":"Login Sucessful!",
                  "token":access_token,
                  "username":username,
                  "is_admin":user.is_administrator,

             }
        ),200
        
             
             
#this token will create token for every login
def create_access_token(user):
     """
     This function will generate access_token that would be required for authentication and everything
     """

     payload={
          "username":user,
          "exp":datetime.now(timezone.utc)+timedelta(hours=44),
          "iat":datetime.now(timezone.utc)
     }


     token=jwt.encode(
          payload=payload,
          key=current_app.config["SECRET_KEY"],
          algorithm="HS256"
     )
     
     return token

#this is to create a decorator that would actually authenticate users with decoders for every request
def token_required(f):
    @wraps(f)
    def decorated(*args,**kwargs):
        token=None
        auth_header=request.headers.get("Authorization")
        if not auth_header:
             return jsonify({"error":"Authorization header is missing!"}),401
        if auth_header:
            try:
                head=auth_header.split(" ")
                if len(head)!=2 or head[0]!="Bearer":
                     return jsonify({"error":"Wrong token format use = Bearer <token>"}),401
                token=head[1]
            except IndexError:
                 return jsonify({"error":"Wrong token format!"}),401
            if not token:
                 return jsonify({"error":"No token found!"}),401
            
            try:
                 payload=jwt.decode(
                      token,
                      key=current_app.config["SECRET_KEY"],
                      algorithms=["HS256"]
                 )
                 request.user=payload["username"]
            except jwt.ExpiredSignatureError:
                 return jsonify({"error":"token has expired!"}),401
            except jwt.InvalidTokenError:
                 return jsonify({"error":"Invalid token!"}),401
            return f(*args,**kwargs)
    return decorated
            
          
     

@auth_bp.route("/whoami",methods=["GET"])
@token_required
def whoami():
     """this will return  current user information but would require the token
     for now i have not added decoder yet but this can be used for later
     """

     username=request.user
     user=User.query.filter_by(username=username).first()


     if not user:
          return jsonify({"error":"User doesnot exist!"}), 404
     
     return jsonify(
          {
               "username":user.username,
               "id":user.id,
               "message":"User is authenticated!",
               "is_administrator":user.is_administrator,
          }
     ),200