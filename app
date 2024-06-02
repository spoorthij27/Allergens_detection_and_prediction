from flask import Flask,request,jsonify
import pickle
import cv2
import pytesseract
import re
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
#model= pickle.load(open('bin_class .pkl','rb'))

from PIL import Image
import io
import base64

app = Flask(__name__)

@app.route('/')
def home():
    return "Allergen App"

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get the image from the request
        image_data = request.form.get('image')
        
        if image_data is None:
            return jsonify({'error': 'No image provided'}), 400
        
        # Decode the base64 encoded image data
        image_bytes = base64.b64decode(image_data)
        
        # Convert bytes to a PIL Image
        image = Image.open(io.BytesIO(image_bytes))
        
        # Save the image in JPEG format
        image_jpeg = io.BytesIO()
        image.save(image_jpeg, format='JPEG')
        image_jpeg.seek(0)

        # Optionally, process the image and make predictions here
        # For this example, we'll just return a simple response
        
        response = {
            'message': 'Image received and processed successfully!'
        }
        
        return jsonify(response), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500



def extract_text_from_image(image_jpeg):

    img = cv2.imread(image_jpeg)
    print(img)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    ret, thresh1 = cv2.threshold(gray, 0, 255, cv2.THRESH_OTSU | cv2.THRESH_BINARY_INV)

    rect_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (18, 18))
    dilation = cv2.dilate(thresh1, rect_kernel, iterations=1)

    contours, hierarchy = cv2.findContours(dilation, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)

    im2 = img.copy()

   
    with open("recognized.txt", "w") as file:
        for cnt in contours:
            x, y, w, h = cv2.boundingRect(cnt)
            rect = cv2.rectangle(im2, (x, y), (x + w, y + h), (0, 255, 0), 2)
            cropped = im2[y:y + h, x:x + w]
            
            text = pytesseract.image_to_string(cropped)
            file.write(text + "\n")




def extract_ingredients_paragraphs(input_file, start_word, output_file):
    # Flag to indicate whether to start extracting paragraphs
    extract_flag = False
    # Counter to track consecutive empty lines
    empty_line_count = 0
    # Store the extracted paragraphs
    matched_paragraphs = []

    with open(input_file, 'r') as file:
        for line in file:
            # Normalize line endings and remove unwanted characters
            line = re.sub(r'[^A-Za-z\s,]', '', line.strip())

            # Check if the line contains the start_word
            if start_word.upper() in line.upper():
                extract_flag = True
                matched_paragraphs.append(line)
            
            # If extraction flag is True, add the line to the matched_paragraphs list
            elif extract_flag:
                matched_paragraphs.append(line)
                # Reset the empty line counter if a non-empty line is encountered
                if line.strip():
                    empty_line_count = 0
                else:
                    # Increment the empty line counter
                    empty_line_count += 1
                    # If 5 consecutive empty lines are encountered, it marks the end of the paragraph
                    if empty_line_count >= 2:
                        break

    # Write the matched paragraphs to the output file
    with open(output_file, 'w') as file:
        for paragraph in matched_paragraphs:
            file.write(paragraph + '\n')


def clean_paragraph(paragraph):
    # Split the paragraph into words
    words = paragraph.split()
    cleaned_words = []
    # Iterate through the words
    for word in words:
        # Check if the word is "INGREDIENTS"
        if word == 'NGREDIENTS':
            continue  # Skip this word
        # Check if the word starts with a comma followed by a space
        elif ', ' in word:
            # Split the word by comma and space and add each part on a new line
            cleaned_words.extend(word.split(', '))
        else:
            # Add the word as is
            cleaned_words.append(word)
    # Join the cleaned words
    cleaned_paragraph = ' '.join(cleaned_words)
    return cleaned_paragraph

def clean_file(input_file, output_file):
    # Read input from the input file
    with open(input_file, 'r') as file:
        input_paragraph = file.read()

    # Clean the paragraph
    cleaned_text = clean_paragraph(input_paragraph)

    # Write the cleaned text to the output file
    with open(output_file, 'w') as file:
        file.write(cleaned_text)


def separate_by_comma(input_string):
    # Split the input string at each comma followed by a space
    words = input_string.split(', ')
    # Join the words with newline characters
    output_string = '\n'.join(words)
    return output_string

def separate_by_comma_from_file(input_file, output_file):
    # Read input from the input file
    with open(input_file, 'r') as file:
        input_string = file.read()

    # Get the output string using the provided function
    output_string = separate_by_comma(input_string)

    # Write the output string to the output file
    print(output_string)

# Example usage
    
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', ssl_context=('cert.pem', 'key.pem'))
