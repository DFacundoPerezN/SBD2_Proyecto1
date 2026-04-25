import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://usuario:password@cluster.mongodb.net/")
DB_NAME = "mundiales_futbol"
CSV_DIR = os.path.join(os.path.dirname(__file__), "..", "output_csv")
