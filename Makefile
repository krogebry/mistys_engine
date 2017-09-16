VERSION="0.4.0"

docker_image: 
	docker build -t misty:${VERSION} .

push:
	docker tag misty:${VERSION} ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/misty:latest
	docker tag misty:${VERSION} ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/misty:${VERSION}

	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/misty:latest
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/misty:${VERSION}
