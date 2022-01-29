# syntax=docker/dockerfile:1

FROM python:3.8-slim-buster

WORKDIR /app

COPY app.py test_app.py requirements.txt /app

RUN pip3 install -r requirements.txt

RUN python3 -m pytest

CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=8080"]
