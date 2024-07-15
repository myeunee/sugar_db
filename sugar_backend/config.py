import os

class Config:
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://myuser:mypassword@localhost/sugar'
    SECRET_KEY = 'j-9xLc8AFO2lM_NlaV_ps_lFPX9XyDiLEIuogyDcVd8^'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = 'IDToU04xdIQuA5GBo3aT2JcKE8q-hqOru098Y65vHNk'
