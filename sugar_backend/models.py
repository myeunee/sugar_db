from extensions import db
from flask_login import UserMixin

class Cafe(db.Model):
    __tablename__ = 'cafes'
    cafe_id = db.Column(db.Integer, primary_key=True)
    cafe_name = db.Column(db.String(255), nullable=False)

class Drink(db.Model):
    __tablename__ = 'drinks'
    drink_id = db.Column(db.Integer, primary_key=True)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.cafe_id'), nullable=False)
    drink_name = db.Column(db.String(255), nullable=False)
    volume = db.Column(db.Float, nullable=False)
    sugar_content = db.Column(db.Float, nullable=False)
    calories = db.Column(db.Float, nullable=False)
    image_url = db.Column(db.String(255), nullable=False)
    cafe = db.relationship('Cafe', backref=db.backref('drinks', lazy=True))

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(255), nullable=False)
    password = db.Column(db.String(255), nullable=False)

    def get_id(self):
        return str(self.user_id)

class ConsumptionRecord(db.Model):
    __tablename__ = 'consumptionrecords'
    record_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    drink_id = db.Column(db.Integer, db.ForeignKey('drinks.drink_id'), nullable=False)
    consumption_date = db.Column(db.DateTime, nullable=False)
    user = db.relationship('User', backref=db.backref('consumption_records', lazy=True))
    drink = db.relationship('Drink', backref=db.backref('consumption_records', lazy=True))

class FavoriteCafe(db.Model):
    __tablename__ = 'favoritecafes'
    favorite_cafe_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.cafe_id'), nullable=False)
    user = db.relationship('User', backref=db.backref('favorite_cafes', lazy=True))
    cafe = db.relationship('Cafe', backref=db.backref('favorite_cafes', lazy=True))

class FavoriteDrink(db.Model):
    __tablename__ = 'favoritedrinks'
    favorite_drink_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=False)
    drink_id = db.Column(db.Integer, db.ForeignKey('drinks.drink_id'), nullable=False)
    __table_args__ = (db.UniqueConstraint('user_id', 'drink_id', name='unique_user_drink'),)
    user = db.relationship('User', backref=db.backref('favorite_drinks', lazy=True))
    drink = db.relationship('Drink', backref=db.backref('favorite_drinks', lazy=True))
