import os
import io
from google.cloud import vision
import pandas as pd
import os.path

# import firebase_admin
# from firebase_admin import credentials
# from firebase_admin import db

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = r"fpvcImageLabelDetection-f35066ad156f.json"

def localize_objects(path, dictionary):
    """Localize objects in the local image.

    Args:
    path: The path to the local file.
    """
    from google.cloud import vision
    client = vision.ImageAnnotatorClient()

    with open(path, 'rb') as image_file:
        content = image_file.read()
    image = vision.types.Image(content=content)

    objects = client.object_localization(
        image=image).localized_object_annotations

    print('Number of objects found: {}'.format(len(objects)))
    for object_ in objects:
        if (not object_.name in dictionary['objects']):
        	dictionary['objects'].append(object_.name)

def print_labels_in_image(number_images, dictionary):

	current_image = 1;

	for i in range(number_images):
		if (current_image < 10):
			image_name = '000{}w.jpg'.format(current_image)
		elif (current_image < 100):
			image_name = '00{}w.jpg'.format(current_image)
		elif (current_image < 1000):
			image_name = '0{}w.jpg'.format(current_image)

		

		client = vision.ImageAnnotatorClient()

		file_name = r'{}'.format(image_name)
		image_path = f'phillipsTargetImages/{file_name}'

		picture_contents = {
			'image': file_name,
			'objects': [],
			'labels': []
		}

		localize_objects(image_path, picture_contents)

		if (os.path.exists(image_path)):
			with io.open(image_path, 'rb') as image_file:
			    content = image_file.read()

			# construct an iamge instance
			image = vision.types.Image(content=content)
			response = client.label_detection(image=image)
			labels = response.label_annotations

			df = pd.DataFrame(columns = ['description', 'score', 'topicality'])

			for label in labels:
				if (not label.description in picture_contents['labels']):
					picture_contents['labels'].append(label.description)
					
		print(picture_contents)
		current_image += 1


def print_object_labels_dict(): 
	picture_contents = {
		'objects': [],
		'labels': []
	}

	print_labels_in_image(3, picture_contents)

print_object_labels_dict()

