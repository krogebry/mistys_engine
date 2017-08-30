FROM ruby:2.4

COPY ./web/Gemfile /opt/misty/
WORKDIR /opt/misty/web
RUN bundle update

COPY ./libs/* /opt/misty/libs/
COPY ./web/* /opt/misty/web/
COPY ./web/views/ /opt/misty/web/views/
COPY ./web/public/ /opt/misty/web/public/

ENTRYPOINT [ "./api.rb" ]
