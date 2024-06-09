from flask import Flask
from flask_cors import CORS
from config import Config
from extensions import db, login_manager

def create_app():
    app = Flask(__name__)
    CORS(app, resources={r"/*": {"origins": "*"}})  # CORS 설정 확인
    app.config.from_object(Config)

    db.init_app(app)
    login_manager.init_app(app)

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
