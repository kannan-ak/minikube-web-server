from flask import Flask
import json

app = Flask(__name__)

# 
@app.route('/tree', methods=["GET"])
def tree():
    response = {"myFavouriteTree": "Avocado"}
    return json.dumps(response)

# Adding healthcheck
@app.route('/ping', methods=["GET"])
def healthcheck():
    return "Pong"

