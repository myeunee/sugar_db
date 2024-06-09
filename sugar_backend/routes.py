from flask import jsonify, request, Blueprint
from flask_login import login_user, logout_user, login_required, current_user
from extensions import db
from models import User, Drink, Cafe, ConsumptionRecord, FavoriteCafe, FavoriteDrink
from datetime import datetime
from werkzeug.utils import secure_filename
import os


bp = Blueprint('routes', __name__)

UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@bp.route('/')
def index():
    return "Hello, Flask!"

# 음료 읽기
@bp.route('/drinks', methods=['GET'])
def get_drinks():
    cafe_id = request.args.get('cafe_id')
    sort_field = request.args.get('sort', 'sugar_content')
    ascending = request.args.get('ascending', 'true').lower() == 'true'
    
    valid_sort_fields = ['sugar_content', 'calories', 'drink_name', 'volume']
    
    if sort_field not in valid_sort_fields:
        sort_field = 'sugar_content'

    query = Drink.query
    if cafe_id:
        query = query.filter_by(cafe_id=cafe_id)
    
    if ascending:
        query = query.order_by(getattr(Drink, sort_field).asc())
    else:
        query = query.order_by(getattr(Drink, sort_field).desc())

    drinks = query.all()
    drinks_list = [{'drink_id': d.drink_id, 'cafe_id': d.cafe_id, 'drink_name': d.drink_name, 'volume': d.volume, 'sugar_content': d.sugar_content, 'calories': d.calories, 'image_url': d.image_url} for d in drinks]
    return jsonify(drinks_list)

@bp.route('/cafes', methods=['GET'])
def get_cafes():
    cafes = Cafe.query.all()
    cafes_list = [{'cafe_id': c.cafe_id, 'cafe_name': c.cafe_name} for c in cafes]
    return jsonify(cafes_list)

# 1. 사용자 인증 기능
# 사용자 등록
@bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    new_user = User(username=data['username'], email=data['email'], password=data['password'])
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'User registered successfully'})

# 사용자 로그인
@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    print(f"Login request received: {data}")  # 로그 추가
    user = User.query.filter_by(username=data['username']).first()
    if user and user.password == data['password']:
        login_user(user)
        print(f"User {data['username']} logged in successfully")  # 로그 추가
        return jsonify({'message': 'Logged in successfully'})
    print(f"Invalid credentials for user {data['username']}")  # 로그 추가
    return jsonify({'message': 'Invalid credentials'}), 401

# 사용자 로그아웃
@bp.route('/logout')
@login_required
def logout():
    logout_user()
    return jsonify({'message': 'Logged out successfully'})

@bp.route('/consume', methods=['POST'])
@login_required
def consume_drink():
    data = request.get_json()
    new_consumption = ConsumptionRecord(user_id=current_user.user_id, drink_id=data['drink_id'], consumption_date=datetime.now())
    db.session.add(new_consumption)
    db.session.commit()
    return jsonify({'message': 'Drink consumed'})

@bp.route('/consumption', methods=['GET'])
@login_required
def get_consumption():
    consumptions = ConsumptionRecord.query.filter_by(user_id=current_user.user_id).all()
    total_sugar = sum([c.drink.sugar_content for c in consumptions])
    return jsonify({'total_sugar': total_sugar})

# 2. 데이터 CRUD 기능 추가
# 음료 생성
@bp.route('/drink', methods=['POST'])
@login_required
def add_drink():
    data = request.get_json()
    new_drink = Drink(
        cafe_id=data['cafe_id'],
        drink_name=data['drink_name'],
        volume=data['volume'],
        sugar_content=data['sugar_content'],
        calories=data['calories']
    )
    db.session.add(new_drink)
    db.session.commit()
    return jsonify({'message': 'Drink added successfully'})

# 음료 수정
@bp.route('/drink/<int:drink_id>', methods=['PUT'])
@login_required
def update_drink(drink_id):
    data = request.get_json()
    drink = Drink.query.get(drink_id)
    if not drink:
        return jsonify({'message': 'Drink not found'}), 404

    drink.cafe_id = data['cafe_id']
    drink.drink_name = data['drink_name']
    drink.volume = data['volume']
    drink.sugar_content = data['sugar_content']
    drink.calories = data['calories']

    db.session.commit()
    return jsonify({'message': 'Drink updated successfully'})

# 음료 삭제
@bp.route('/drink/<int:drink_id>', methods=['DELETE'])
@login_required
def delete_drink(drink_id):
    drink = Drink.query.get(drink_id)
    if not drink:
        return jsonify({'message': 'Drink not found'}), 404

    db.session.delete(drink)
    db.session.commit()
    return jsonify({'message': 'Drink deleted successfully'})

# 이미지 업로드 및 음료 추가
@bp.route('/upload_image', methods=['POST'])
@login_required
def upload_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image part'}), 400
    
    file = request.files['image']
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)
        
        data = request.form
        new_drink = Drink(
            cafe_id=data['cafe_id'],
            drink_name=data['drink_name'],
            volume=data['volume'],
            sugar_content=data['sugar_content'],
            calories=data['calories'],
            image_url=file_path
        )
        db.session.add(new_drink)
        db.session.commit()
        
        return jsonify({'message': 'Drink and image uploaded successfully', 'image_url': file_path}), 200
    else:
        return jsonify({'error': 'Invalid file type'}), 400
