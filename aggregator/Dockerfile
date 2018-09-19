FROM python:3.6-alpine
ADD . .
RUN pip install -r requirements.txt
EXPOSE 8080
ENTRYPOINT ["python", "aggregator.py"]
