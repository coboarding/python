from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/fill-form', methods=['POST', 'GET'])
def fill_form():
    # Tu logika automatycznego wypełniania formularza
    return jsonify({"status": "ok", "message": "Form filled (mock response)"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
