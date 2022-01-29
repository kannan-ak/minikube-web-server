from app import app


def healthcheck():
    response = app.test_client().get('/ping')

    assert response.status_code == 200
    assert response.data == b'Pong'


def test_app():
    response = app.test_client().get('/tree')

    assert response.status_code == 200
    assert response.data == b'{"myFavouriteTree": "Avocado"}'
