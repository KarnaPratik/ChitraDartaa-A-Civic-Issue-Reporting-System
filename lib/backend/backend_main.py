from flask import Flask, jsonify, request

from flask_cors import CORS 
from dotenv import load_dotenv
import os
from extension import db
load_dotenv()
import models
from inference import inference_bp
#creating dbase


def create_app():
    app=Flask(__name__)
    app.config["SECRET_KEY"]=os.getenv("SECRET_KEY","some-default-key-ig")
    app.config["SQLALCHEMY_DATABASE_URI"]=os.getenv("DATABASE_URL","sqlite:///app.db")
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"]=False
    db.init_app(app)


    #setting cors so browser dont block its running
    cors_origin=os.getenv("CORS_ORIGINS","*")
    CORS(app,resources={r"/*": {"origins": "*"}}, 
     expose_headers=["Content-Type", "Authorization"],
     allow_headers=["Content-Type", "Authorization"],
     methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"])



    #here adding this to add other backend files for inference adding this so i can add later into the future, fuck you mahesh
    from auth import auth_bp
    from admin_endpoint import admin_bp
    from inference import inference_bp
    app.register_blueprint(auth_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(inference_bp)



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




#All done guys, backend up and stable.