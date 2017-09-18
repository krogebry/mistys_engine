FROM ruby:2.4

RUN apt-get update
RUN apt-cache search libsasl2-dev
RUN apt-get install libsasl2-dev

COPY ./web/Gemfile /opt/misty/web/
WORKDIR /opt/misty/web/
RUN bundle update

COPY ./ /opt/misty/

ENTRYPOINT [ "./api.rb" ]
