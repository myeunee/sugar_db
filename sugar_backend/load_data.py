import json
from app import create_app
from extensions import db
from models import Cafe, Drink, User

def load_cafes(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        cafes = json.load(file)
        db.session.query(Cafe).delete()
        for cafe in cafes:
            new_cafe = Cafe(cafe_name=cafe['cafe_name'])
            db.session.add(new_cafe)
        db.session.commit()

def load_drinks(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        drinks = json.load(file)
        db.session.query(Drink).delete()
        for drink in drinks:
            new_drink = Drink(
                cafe_id=drink['cafe_id'],
                drink_name=drink['drink_name'],
                volume=drink['volume'],
                sugar_content=drink['sugar_content'],
                calories=drink['calories'],
                image_url=drink['image_url']  # Ensure image_url is saved
            )
            db.session.add(new_drink)
        db.session.commit()

def load_users(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        users = json.load(file)
        db.session.query(User).delete()
        for user in users:
            new_user = User(
                username=user['username'],
                email=user['email'],
                password=user['password']
            )
            db.session.add(new_user)
        db.session.commit()

if __name__ == "__main__":
    app = create_app()
    with app.app_context():
        db.create_all()
        load_cafes('database/cafes.json')
        load_drinks('database/drinks.json')
        load_users('database/users.json')
        print("Data loaded successfully")
