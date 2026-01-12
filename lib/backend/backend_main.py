from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS 
from dotenv import load_dotenv
import os

load_dotenv()

#creating dbase
db=SQLAlchemy()

def create_app():
    app=Flask(__name__)
    app.config["SECRET_KEY"]=os.getenv("SECRET_KEY","some-default-key-ig")
    app.config["SQLALCHEMY_DATABASE_URI"]=os.getenv("DATABASE_URL","sqlite:///app.db")
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"]=False
    db.init_app(app)


    #setting cors so browser dont block its running
    cors_origin=os.getenv("CORS_ORIGINS","*")
    CORS(app,resources={r"/*":{"origins":cors_origin}})


    #here adding this to add other backend files for inference adding this so i can add later into the future
    from auth import auth_bp
    app.register_blueprint(auth_bp)


    with app.app_context():
        if os.getenv("FLASK_ENV")=="development":
            db.create_all()
            print("Dbase created!-moss ;)")
        
    return app


if __name__=="__main__":
    app=create_app()
    port=int(os.getenv("PORT",6969))


    app.run(
        host="0.0.0.0",
        port=port,
        debug=os.getenv("FLASK_ENV")=="development"
    )



