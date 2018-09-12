FROM python:3.6-alpine
ADD . .
RUN pip install -r requirements.txt
EXPOSE 8080
CMD ["python", "aggregator.py"]
