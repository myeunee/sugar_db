from app import create_app
from extensions import db
from models import Cafe, Drink, User, ConsumptionRecord, FavoriteCafe, FavoriteDrink

app = create_app()

with app.app_context():
    db.drop_all()
    db.create_all()
    print("Database reset successfully")
