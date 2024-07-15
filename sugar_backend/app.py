from flask import Flask
from flask_cors import CORS
from config import Config
from extensions import db, login_manager
from flask_jwt_extended import JWTManager

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['DEBUG'] = True
    
    CORS(app, resources={r"/*": {"origins": "*", "allow_headers": ["Authorization", "Content-Type"]}})

    db.init_app(app)
    login_manager.init_app(app)
    jwt = JWTManager(app)  # Initialize JWT Manager

    from models import User
    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    with app.app_context():
        from routes import bp as routes_bp
        app.register_blueprint(routes_bp)

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)
