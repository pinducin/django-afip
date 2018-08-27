FROM python:3
ENV PYTHONUNBUFFERED 1
ENV APP_CORS_ALLOW_ALL true
ENV APP_PROFILE production
ENV ALLOWED_HOSTS *
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /
RUN pip install -r /requirements.txt
RUN mkdir /django_afip
ADD django_afip /django_afip
ADD testapp /code/
